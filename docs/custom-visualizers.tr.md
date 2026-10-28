# Özel QML görselleştiricileri, ilerleme çubukları ve oynatma düğmeleri

**Ayarlar → Görselleştirici → Özel görselleştiriciler → Yönet…** bölümünü açın, **QML içe aktar…** seçeneğini belirleyin ve güvendiğiniz yerel bir `.qml` dosyası seçin. Canlı önizlemede örnek ses kullanılır; gerçek sesle kullanmak için ayarları uygulayın. **Örneği dene**, paketteki Pulse Bars stilini yükler. Yerleşik görselleştiriciye dönmek için **Yerleşik görselleştirici** seçeneğini veya yerleşik stil kutucuklarından birini seçin. **Kaldır**, dosyaları silmeden stili listeden çıkarır.

[AsciiSpectrum.qml](../package/contents/examples/AsciiSpectrum.qml) ikinci bir örnektir: terminal/ASCII sistem izleyicilerini andıran, eğik çizgilerle çizilmiş tek aralıklı bir spektrum. **Örneği dene** seçeneğine bağlı değildir; **QML içe aktar…** ile elle içe aktarın.

İçe aktarma dosyanın konumunu kaydeder; dosyaları kopyalamaz veya yüklemez. QML dosyasını ve ona eşlik eden varlıkları kalıcı bir dizinde tutun. Stili paylaşmak için bu dizini (isteğe bağlı olarak ZIP biçiminde) gönderin; alıcı arşivi açıp ana QML dosyasını içe aktarabilir. Birden fazla dosya içe aktarıp açılır listeden aralarında geçiş yapabilirsiniz. Görünen adlar dosya adlarından alınır.

Özel görselleştirici stilleri hem Plasma hem Hyprland'de mevcut düzenlerin içindeki dalga biçiminin yerini alır. Orbit, yalnızca şarkı sözleri düzenleri ve kapsülün küçük EQ göstergesi ayrı çiziciler kullanır. Kapsülde özel stil göstermek için dalga seçeneğini belirleyin. Tam kart düzeni eklentileri ve ZIP üzerinden kurulum bu arayüzün parçası değildir.

## Özel ilerleme çubukları

**Ayarlar → Görünüm → İlerleme → Özel ilerleme çubukları → Yönet…** bölümünü açıp bir QML dosyası içe aktarın veya paketteki gradyan çubuğu için **Örneği dene** seçeneğini kullanın. Bu seçici, görselleştirici seçicisiyle aynı şekilde çalışır ancak ayrı bir kayıtlı liste tutar. Yerleşik bir ilerleme çubuğu seçildiğinde o stile dönülür.

Özel ilerleme çubukları kartın içindeki çubuğun ve süre etiketlerinin yerini alır; yerleşik kapak halkasına da öncelik verir. Kapsülün ayrı ince ilerleme göstergesini değiştirmez ve ilerleme çubuğu bulunmayan düzenlere çubuk eklemez.

## Özel oynatma düğmeleri

**Ayarlar → Görünüm → Düğmeler → Özel düğme stilleri → Yönet…** bölümünü açıp güvendiğiniz yerel bir `.qml` dosyasını içe aktarın. **Örneği dene**, [MinimalButtons.qml](../package/contents/examples/MinimalButtons.qml) dosyasını yükler. Seçici ayrı bir düğme stili kitaplığı tutar ve seçili dosyayı önizler. Yerleşik stil kutucuğu veya **Yerleşik düğmeler** seçeneği önceki görünüme döndürür. Özel stil, Plasma ve Hyprland'deki tüm kart düzenlerinde oynatma denetimlerinin yerini alır. Panel kapsülleri kendi kompakt denetimlerini kullanır.

Kök öğe `Item` sınıfından türemeli, `readonly property int apiVersion: 1` ve `required property var buttons` bildirmelidir. Yüksekliği 26 piksel olan denetim alanını doldurur. `implicitWidth` değerini 60–220 piksel arasında ayarlayın; ana uygulama bunu düzen boyutlandırmasında kullanır. Stil kendi işaretçi hedeflerini çizer ve yönetir. Oynatma için sağlanan yöntemleri kullanın; bunlar oynatıcının yeteneklerini denetler ve her iki ortamda çalışır.

| Özellik / yöntem | Açıklama |
| --- | --- |
| `apiVersion` | Arayüz sürümü; şu anda `1` |
| `isPlaying`, `active` | Oynatma durumu ve denetimlerin görünür olup olmadığı |
| `canTogglePlaying`, `canGoPrevious`, `canGoNext` | Kullanılabilir oynatıcı eylemleri |
| `canShuffle`, `canRepeat`, `shuffleOn`, `repeatOn`, `repeatTrack` | Ek denetim yetenekleri ve durumları |
| `showSkipButtons`, `showShuffleRepeat` | Kullanıcının görünürlük tercihleri |
| `iconColor`, `accentColor`, `reducedMotion` | Geçerli renkler ve hareket tercihi |
| `previous()`, `togglePlaying()`, `next()` | Oynatma eylemleri; eylemin kullanılabilir olup olmadığını döndürür |
| `toggleShuffle()`, `cycleRepeat()` | İsteğe bağlı oynatıcı eylemleri; kullanılabilirlik sonucunu döndürür |

Özel QML yalnızca masaüstü ortamlarında çalıştırılır. Tarayıcı Stüdyosu, ortak ayar şemasından seçiciyi listeler ve bu belgeye bağlantı verir; yerel QML kodunu çalıştırmaz. Şema, katalog, varsayılanlar ve tarayıcı varlıkları QML kaynaklarından `python3 tools/sync_studio_assets.py` komutuyla yayımlanır.

## Güvenlik ve hatalar

QML, Plasma veya Quickshell ana uygulamasında çalışan yürütülebilir koddur; **korumalı bir tema biçimi değildir**. Yalnızca güvendiğiniz stilleri içe aktarın. Bir stil, ana uygulamanın erişebildiği içe aktarmaları ve API'leri kullanabilir; kötü yazılmış kod uygulamayı dondurabilir veya çökertir. Dosya seçildiğinde önizleme için hemen çalıştırılır.

Dosya eksikse, QML yüklenemezse veya API sürümü desteklenmiyorsa seçili yerleşik stile dönülür. Özel stil önizlemesi hatayı gösterir; ana uygulama günlüğünde QML tanıları bulunur. Çalışma zamanı betik hataları ve performans sorunları yükleyici tarafından güvenilir biçimde yakalanamaz. Bir eklentiyi devre dışı bırakmak için yerleşik stil seçin. Ana uygulama başlatılamıyorsa yapılandırmasındaki `customVisualizer`, `customProgressBar` ve `customButtons` değerlerini temizleyin.

Yerel kayıtlı görünümler özel bir stili hatırlayabilir. Taşınabilir JSON dışa/içe aktarma, özel dosya seçimlerini ve kitaplıklarını içermez; böylece sıradan bir görünümün aktarılması yürütülebilir QML'yi etkinleştirmez. Özel dosyaları ayrıca paylaşın.

## Görselleştirici API sürüm 1

[PulseBars.qml](../package/contents/examples/PulseBars.qml) ile başlayın. Kök `Item` olmalı ve aşağıdaki özellikleri bildirmelidir:

```qml
import QtQuick

Item {
    id: root
    readonly property int apiVersion: 1
    required property var visualizer

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height * root.visualizer.energy
        color: root.visualizer.waveColor
    }
}
```

Ana uygulama kök öğeyi dalga alanına göre boyutlandırır ve çizimi bu alanla sınırlar. İç widget nesnelerine bağımlı olmak yerine sağlanan `visualizer` nesnesine bağlanın. Arayüz özellikleri salt okunurdur ve ana uygulamayla birlikte güncellenir.

| Özellik | Açıklama |
| --- | --- |
| `apiVersion` | Arayüz sürümü; şu anda `1` |
| `bars`, `numBars`, `maxRange` | Yumuşatılmış spektrum değerleri, çubuk sayısı ve genlik üst sınırı; normalleştirmek için her çubuğu `maxRange` değerine bölün |
| `bass`, `mid`, `high` | Kaynak frekans bantlarının 0–1 aralığındaki seviyeleri |
| `energy` | Gösterilen çubukların normalleştirilmiş ortalama genliği, 0–1 |
| `attack` | Ses başlangıcı göstergesi |
| `hasAudio`, `backendFailed` | Ses ve arka uç durumu |
| `active` | Görünür, ses alıyor ve arka uç sağlıklı |
| `frameTimeMs` | Paylaşılan ses kare saati (ms); animasyon için farkları kullanın |
| `reducedMotion` | Dekoratif animasyonu azaltma tercihi |
| `softwareRendering` | Yerleşik çizicinin yazılım yedeğini kullanıp kullanmayacağı |
| `waveColor`, `textColor` | Geçerli görselleştirici ve metin renkleri |
| `coverColor1`, `coverColor2` | Kapak görselinden alınan palet renkleri |
| `lineWidth`, `fillWave`, `glowWave` | Çizim tercihleri; pil tasarrufunda parıltı kapatılır |
| `direction` | `"up"` veya `"down"` |

Ayrı bir hızlı zamanlayıcı yerine paylaşılan kare saatini kullanın. `active` değeri yanlışken dekoratif işlemleri durdurun ve `reducedMotion` tercihine uyun. Gizli stiller kaldırılır ve yeniden görünür olduklarında oluşturulur; animasyon durumunun korunacağına güvenmeyin. Ana saat, yapılandırılmış kare hızını ve pil sınırlarını izler; ses sessizleşip kararlı hâle geldiğinde ilerlemez.

Canvas tabanlı stiller, `visualizer` hedefli `Connections` kullanıp çubuk, renk veya boyut değişiminde `requestPaint()` çağırabilir. Basit Qt Quick şekilleri GPU ve yazılım çiziminde çalışır. Gölgelendirici kullanan stiller kendi yazılım yedeklerini sağlamalıdır. Yüklenmiş bir QML dosyasını düzenledikten sonra ana uygulamayı yeniden başlatın; QML motoru dosyayı önbelleğe alabilir.

## İlerleme çubuğu API sürüm 1

[GradientProgress.qml](../package/contents/examples/GradientProgress.qml) ile başlayın. Kök `Item` üzerinde `readonly property int apiVersion: 1` ve `required property var progressBar` bildirin. Ana uygulama genişlik ve yüksekliği sağlar; mevcut kart düzenlerine uyması için `implicitHeight` değeri 9–28 mantıksal piksel aralığında kullanılır. `implicitHeight` değerini sağlanan yüksekliğe bağlamayın. Çizim ve işaretçi yönetimi stile aittir.

| Özellik / yöntem | Açıklama |
| --- | --- |
| `apiVersion` | Arayüz sürümü; şu anda `1` |
| `progress` | Geçerli oran, 0–1 |
| `position`, `duration` | Her iki ortamda da saniye cinsinden oynatma konumu ve süresi |
| `elapsedText`, `totalText`, `remainingText` | Biçimlendirilmiş süre etiketleri |
| `isPlaying`, `hasAudio`, `active` | Oynatma, ses ve görünürlük/ana uygulama etkinliği |
| `canSeek` | Geçerli oynatıcının ileri/geri sarma desteği |
| `seekToFraction(fraction)` | Oynatıcının yerel birimlerini kullanarak 0–1 aralığında konum değiştirir; başarıyı döndürür ve yetenekleri yeniden denetler |
| `showTimes`, `timeFormat`, `centerTimes` | Etiket tercihleri; biçim `"total"` veya `"remaining"` |
| `textColor`, `startColor`, `endColor`, `waveColor` | Geçerli renkler |
| `track`, `artist` | Geçerli parçanın üst verileri |
| `reducedMotion`, `frameTimeMs` | Hareket tercihi ve paylaşılan ses kare saati |

Ana uygulama mevcut oynatma saatini ve konum değiştirme adaptörünü yeniden kullanır; eklentilerin kendi zamanlayıcılarına, MPRIS bağlantılarına veya saniye/mikrosaniye dönüşümüne ihtiyacı yoktur. Ortak yükleyici gizli stilleri kaldırır ve yükleme hatasında yerleşik çubuğu geri getirir. Görselleştirici dosyası, ilgili arayüzü uygulamadan ilerleme çubuğu olarak kullanılamaz.
