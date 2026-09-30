#!/usr/bin/env python3
"""Assemble the common GLSL prelude and bake every ShaderEffect family."""

import argparse
import shutil
import subprocess
import tempfile
from pathlib import Path

SHADER_DIR = Path(__file__).resolve().parent
FAMILIES = (
    "visualizer",
    "viz_linear",
    "viz_radial",
    "viz_particles",
    "viz_sparkles",
    "viz_ribbon",
    "viz_terrain",
    "viz_tunnel",
    "viz_fluid",
    "viz_scope",
    "glass_refraction",
    "viz_orbit",
    "text_fade",
    "karaoke_fill",
)
QSB_FLAGS = ("--glsl", "100es,120,150", "--hlsl", "50", "--msl", "12")
GLSL_VERSIONS = ("100 es", "120", "150")


def validate_glsl(package, qsb, glslang):
    """Compile every GLSL variant: qsb emits them unchecked, and a driver that
    rejects one (e.g. NVIDIA on GLSL 120) retries it every frame."""
    stage = package.name.split(".")[1]
    with tempfile.TemporaryDirectory(prefix="audio-visualizer-glsl-") as directory:
        for version in GLSL_VERSIONS:
            source = (
                Path(directory) / f"{package.stem}.{version.replace(' ', '')}.{stage}"
            )
            subprocess.run(
                [qsb, "-x", f"glsl,{version}", "-o", str(source), str(package)],
                check=True,
            )
            result = subprocess.run(
                [glslang, str(source)], capture_output=True, text=True
            )
            if result.returncode:
                errors = "\n".join(
                    line for line in result.stdout.splitlines() if "ERROR" in line
                )
                raise SystemExit(f"{package.name} GLSL {version} is invalid:\n{errors}")


def build(output_dir, qsb="qsb"):
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    common = (SHADER_DIR / "viz_common.glsl").read_text()
    with tempfile.TemporaryDirectory(prefix="audio-visualizer-glsl-") as directory:
        for family in FAMILIES:
            source = Path(directory) / f"{family}.frag"
            prelude = common.replace(
                "#version 440\n", f"#version 440\n#define {family.upper()} 1\n", 1
            )
            source.write_text(
                (
                    ""
                    if family
                    in ("viz_orbit", "text_fade", "glass_refraction", "karaoke_fill")
                    else prelude + "\n"
                )
                + (SHADER_DIR / f"{family}.frag").read_text()
            )
            subprocess.run(
                [
                    qsb,
                    *QSB_FLAGS,
                    "-o",
                    str(output_dir / f"{family}.frag.qsb"),
                    str(source),
                ],
                check=True,
            )

        # Share the exact uniform layout and indexed particle access with the
        # fragment stage; Qt reflects uniforms across both shader stages.
        uniform = common[common.index("layout(std140") : common.index("};") + 2]
        accessor = common[
            common.index("vec4 particleAt") : common.index(
                "#endif", common.index("vec4 particleAt")
            )
        ]
        vertex = Path(directory) / "viz_particles.vert"
        vertex.write_text(
            "#version 440\n#define VIZ_PARTICLES 1\n"
            + uniform
            + "\n"
            + accessor
            + (SHADER_DIR / "viz_particles.vert").read_text()
        )
        subprocess.run(
            [
                qsb,
                *QSB_FLAGS,
                "-o",
                str(output_dir / "viz_particles.vert.qsb"),
                str(vertex),
            ],
            check=True,
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=SHADER_DIR)
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify checked-in packages without modifying them",
    )
    args = parser.parse_args()
    qsb = shutil.which("qsb")
    if not qsb:
        raise SystemExit(
            "qsb is required; run make shaders in the Qt development environment"
        )
    if args.check:
        glslang = shutil.which("glslangValidator")
        if not glslang:
            print("SKIP: glslangValidator is not on PATH; GLSL variants not compiled")
        with tempfile.TemporaryDirectory(prefix="audio-visualizer-qsb-") as directory:
            build(directory, qsb)
            for name in [f"{family}.frag.qsb" for family in FAMILIES] + [
                "viz_particles.vert.qsb"
            ]:
                if glslang:
                    validate_glsl(SHADER_DIR / name, qsb, glslang)
                family = name.split(".")[0]
                if (Path(directory) / name).read_bytes() != (
                    SHADER_DIR / name
                ).read_bytes():
                    raise SystemExit(f"{name} is out of date: run make shaders")
                print(
                    f"PASS: compiled shader matches {name.removesuffix('.qsb')}"
                    + (
                        ""
                        if family
                        in (
                            "viz_orbit",
                            "text_fade",
                            "glass_refraction",
                            "karaoke_fill",
                        )
                        else " + viz_common.glsl"
                    )
                )
    else:
        build(args.output_dir, qsb)


if __name__ == "__main__":
    main()
