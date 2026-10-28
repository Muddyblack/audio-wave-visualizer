# plasmashell bellek artışını hata ayıklama

Görselleştirici animasyon yaparken `plasmashell` belleği artıyorsa hangi GPU yolunun buna neden olduğunu belirlemeye çalışın.

## Hızlı test

```sh
bash tools/awv-ab.sh
```

Betik her testten önce `plasmashell` sürecini yeniden başlatır; açık pencereleriniz kalır. Her testte widget'ın ayar penceresini açın, Enter'a basın, 20 saniye bekleyin, pencereyi kapatın ve yeniden Enter'a basın. Sonuçlar Plasma, Qt ve NVIDIA sürücü sürümleriyle birlikte `~/awv-ab.txt` dosyasına yazılır. Daha uzun ölçüm için `AWV_AB_SECONDS=60 bash tools/awv-ab.sh` komutunu kullanın.

| Test | Devre dışı bırakılan | Bunun yerine görülen |
| --- | --- | --- |
| `baseline` | Hiçbiri | Referans ölçüm |
| `all` | Aşağıdaki üç yolun tümü | Tüm efektler kapalı |
| `layers` | Her `layer.effect` ve görünür `MultiEffect` | Yazılım yedekleri; parıltı ve gölge yok |
| `sources` | Her `ShaderEffectSource` (cam bulanıklığı ve kapak yansıması) | Cam bulanıklığı ve yansıma yok |
| `shaders` | WaveShader / OrbitShader `ShaderEffect` bileşenleri | Canvas ile basit çizim |
| `vulkan` | Efektler açık kalır; Qt OpenGL yerine Vulkan kullanır | Vulkan yolunun karşılaştırması |

`baseline` artarken bir test sabit kalıyorsa soruna o yol neden oluyor olabilir. Yalnızca `vulkan` sabitse OpenGL sürücüsünden şüphelenin. Her testte bellek artıyorsa neden widget efektlerinin dışında olabilir.

## Anahtarları elle ayarlama

Testler widget'ın gizli `gpuDebug` ayarına `layers`, `sources`, `shaders`, `all` veya `layers,sources` gibi bir liste yazar. Varsayılan değer boştur; bu durumda hiçbir şeyi değiştirmez. Değer yeniden başlatmadan uygulanır:

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

NVIDIA'da `plasmashell`, temel testte 20 saniyede yaklaşık 6,5 GB büyürken `shaders` ve `vulkan` testlerinde sabit kaldı. Gölgelendirici paketlerinde geçersiz GLSL 120 / ES 100 kodu vardı (`min()`, `max()` ve `clamp()` fonksiyonlarına tamsayı verilmesi); sürücü kodu reddediyor ve Qt her karede yeniden deniyordu. `build_shaders.py --check` ( `make test` hedefinin parçası), artık tüm GLSL varyantlarını glslangValidator ile derliyor.
