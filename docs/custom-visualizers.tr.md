# Özel görselleştiriciler ve denetimler

## Özel QML görselleştiricileri

**Ayarlar → Görselleştirici → Özel görselleştiriciler → Yönet…** bölümünü açın, **QML içe aktar…** seçeneğini belirleyin ve güvendiğiniz yerel bir `.qml` dosyası seçin. Canlı önizlemede örnek ses kullanılır; gerçek sesle kullanmak için ayarları uygulayın. **Örneği dene**, paketteki Pulse Bars stilini yükler. Yerleşik görselleştiriciye dönmek için yerleşik bir stil seçin.

İçe aktarma dosyanın konumunu kaydeder; dosyaları kopyalamaz veya yüklemez. QML dosyasını ve ona eşlik eden varlıkları kalıcı bir dizinde tutun. Stili paylaşmak için bu dizini gönderin; alıcı ana QML dosyasını içe aktarabilir. Dosya adları görünen adları belirler.

Özel görselleştirici stilleri Plasma ve Hyprland'de mevcut düzenlerin içindeki dalga biçiminin yerini alır. Orbit, yalnızca şarkı sözleri düzenleri ve panel kapsülünün küçük EQ göstergesi ayrı çiziciler kullanır. Tam kart düzeni eklentileri ve ZIP üzerinden kurulum bu arayüzün parçası değildir.

## Özel ilerleme çubukları

**Ayarlar → Görünüm → İlerleme → Özel ilerleme çubukları → Yönet…** bölümünden bir QML dosyası içe aktarın veya örnek gradyan çubuğunu deneyin. Özel ilerleme çubukları kartın içindeki çubuğun ve süre etiketlerinin yerini alır; yerleşik kapak halkasına da öncelik verir. Panel kapsülünün ayrı ince ilerleme göstergesini değiştirmez.

## Özel oynatma düğmeleri

**Ayarlar → Görünüm → Düğmeler → Özel düğme stilleri → Yönet…** bölümünden güvendiğiniz yerel bir `.qml` dosyasını içe aktarın. Örnek olarak paketteki MinimalButtons stili kullanılabilir. Özel stil, Plasma ve Hyprland'deki kart düzenlerinde oynatma denetimlerinin yerini alır; panel kapsülleri kendi kompakt denetimlerini kullanır.

## Güvenlik ve sorun giderme

QML, Plasma veya Quickshell ana uygulamasında çalışan yürütülebilir koddur; **korumalı bir tema biçimi değildir**. Yalnızca güvendiğiniz stilleri içe aktarın. Kötü yazılmış kod uygulamayı dondurabilir veya çökertebilir; dosya seçildiğinde önizleme için hemen çalıştırılır.

Dosya eksikse, QML yüklenemezse veya API sürümü desteklenmiyorsa seçili yerleşik stile dönülür. Özel stil önizlemesi hatayı gösterir; ana uygulama günlüğünde QML tanıları bulunur. Bir eklentiyi devre dışı bırakmak için yerleşik stil seçin. Ana uygulama başlatılamıyorsa yapılandırmadaki `customVisualizer`, `customProgressBar` ve `customButtons` değerlerini temizleyin.

Tarayıcı Stüdyosu yerel QML kodunu çalıştırmaz; yalnızca seçiciyi ve bu belge bağlantısını gösterir. JSON görünüm aktarımı özel QML dosyalarını içermez; bu dosyaları ayrıca paylaşın.

API özellikleri ve örnekler için İngilizce [ayrıntılı teknik belgeye](custom-visualizers.md) bakın.
