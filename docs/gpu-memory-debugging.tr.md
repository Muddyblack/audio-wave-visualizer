# plasmashell bellek artışını hata ayıklama

Görselleştirici animasyon yaparken `plasmashell` belleği artıyorsa hangi GPU yolunun buna neden olduğunu belirleyin.

## Hızlı test

```sh
bash tools/awv-ab.sh
```

Betik her testten önce `plasmashell` sürecini bir kez yeniden başlatır; pencereleriniz açık kalır. Her seferinde widget'ın ayar penceresini açın, Enter'a basın, 20 saniye bekleyin, pencereyi kapatın ve yeniden Enter'a basın. Sonuçlar Plasma, Qt ve NVIDIA sürücü sürümleriyle birlikte `~/awv-ab.txt` dosyasına yazılır. Daha uzun ölçüm için `AWV_AB_SECONDS=60 bash tools/awv-ab.sh` komutunu kullanın.

| Çalıştırma | Devre dışı bırakılan | Bunun yerine görülen |
| --- | --- | --- |
| `baseline` | Hiçbiri | Referans ölçüm |
| `all` | Aşağıdaki üçü de | Tüm efektler kapalı |
| `layers` | Her `layer.effect` ve görünür `MultiEffect` | Yazılım yedekleri; parıltı ve gölge yok |
| `sources` | Her `ShaderEffectSource` (cam bulanıklığı, kapak yansıması) | Cam bulanıklığı ve yansıma yok |
| `shaders` | WaveShader / OrbitShader `ShaderEffect` bileşenleri | *Basit çizim* ile aynı şekilde Canvas |
| `vulkan` | Efektler açık kalır; Qt OpenGL yerine Vulkan kullanır | Vulkan yolunun karşılaştırması |

`baseline` artarken bir test sabit kalıyorsa soruna o yol neden oluyor olabilir. Yalnızca `vulkan` sabitse OpenGL sürücüsünden şüphelenin. Her şey artıyorsa neden widget efektlerinin dışındaki bir şey olabilir.

## Anahtarları elle ayarlama

Testler widget'ın gizli `gpuDebug` girdisine `layers`, `sources`, `shaders`, `all` veya `layers,sources` gibi bir liste yazar. Varsayılan olarak boştur; bu durumda hiçbir şeyi değiştirmez ve ek maliyet getirmez. Yeniden başlatmadan canlı olarak uygulanır:

```sh
set_debug() { qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    for (const c of desktops().concat(panels()))
        for (const w of c.widgets('org.muddyblack.plasmaAudioVisualizer')) {
            w.currentConfigGroup = ['General']; w.writeConfig('gpuDebug', '$1'); }"; }
set_debug shaders
journalctl --user -b | grep 'gpuDebug layers' | tail -1
set_debug ""   # geri al
```

Her 5 saniyede bir bellek kaydı almak için:

```sh
pid=$(pgrep -xo plasmashell); while sleep 5; do echo "$(date +%T) $(( $(awk '/VmRSS/{print $2}' /proc/$pid/status) / 1024 )) MB"; done
```

## Önceki vaka: #10 numaralı sorun

NVIDIA'da `plasmashell`, `baseline` ile 20 saniyede yaklaşık 6,5 GB büyürken `shaders` ve `vulkan` testlerinde sabit kaldı. Gölgelendirici paketlerinde geçersiz GLSL 120 / ES 100 kodu (tamsayılarla `min()`/`max()`/`clamp()`) vardı; sürücü kodu reddediyor ve Qt her karede yeniden deniyordu. `build_shaders.py --check` (`make test` hedefinin bir parçası), artık tüm GLSL varyantlarını glslangValidator ile derliyor.
