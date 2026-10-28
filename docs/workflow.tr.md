# Widget iş akışı ve mimari

Görselleştirici üç ana katmandan oluşur: **QML arayüzü**, **veri aktarım katmanı** ve **ses arka ucu**. Plasma widget'ı ile Hyprland/Quickshell aynı temel QML çizim bileşenlerini ve ayar şemasını paylaşır; ortamlar yalnızca ana uygulamaya özgü bağlayıcılar sağlar.

## Ses verisinin akışı

1. Ses besleyicisi `cava` aracını çalıştırır ve kullanılabilir ses girişini belirler. Varsayılan olarak PipeWire, PulseAudio ve ALSA arka uçlarını dener.
2. Besleyici ses çubuklarını ve zaman damgasını dosyalara yazar. Kalp atışı, sessizlik ile durmuş bir besleyiciyi ayırt etmeye yardımcı olur.
3. `VisualizerCore.qml`, kareleri okur, ses bantlarını ve vuruş başlangıcını analiz eder, arka uç durumunu izler ve gerektiğinde besleyiciyi yeniden başlatır. Ses yakalama MPRIS oynatma durumundan bağımsızdır; tarayıcılar ve diğer uygulamalar da görselleştirilebilir.
4. `Waveform.qml`, GPU destekli ortamda gölgelendirici tabanlı çizimi kullanır; yazılım çiziminde `WaveCanvas.qml` yedeğine geçer. Basit çizim seçeneği Canvas yolunu doğrudan kullanır.

## Testler ve geliştirme

Regresyon testleri sentetik ses, besleyici yaşam döngüsü, arka uç hata kurtarma, Canvas stilleri, gölgelendirici girdileri, oynatma konumu tahmini ve ayar aktarımını denetler. GPU gerektiren çizici karşılaştırmaları, GPU sahne grafiği bulunmayan ortamlarda atlanabilir.

Gölgelendirici kaynakları değiştiğinde derlenmiş paketleri de güncelleyin. Kaynak dosyalarla derleme çıktılarının birlikte sürüm kontrolüne alınması, kullanıcıların derleme araçlarını ayrıca kurma ihtiyacını ortadan kaldırır.

## Ortak ayar stüdyosu ve web demosu

Ayar stüdyosu Qt Quick/QML ile oluşturulur. GitHub Pages'teki HTML/JavaScript demosu QML çalıştırmaz ve masaüstü ayarlarını değiştirmez; bunun yerine ayar şeması, hazır ayar kuralları, renk seçimi, Canvas görselleştiricileri, ilerleme çizimleri ve örnek sesi paylaşır. Ortak kaynaklar `package/contents/ui/studio` altında tutulur.

Masaüstü ve web sürümleri arasında görünüm aktarmak için **Hazır ayarlarım** bölümünden **JSON olarak kopyala**, diğer arayüzde ise **JSON içe aktar** seçeneklerini kullanın. JSON biçimi görünüm ayarlarını aktarır; yerleşim, yerel hazır ayar kitaplığı ve yürütülebilir özel QML dosyaları dışarıda tutulur.

Bu sayfa mimarinin Türkçe özetidir. Ayrıntılı bileşen tabloları, test komutları ve hata ayıklama notları için İngilizce [tam teknik belgeye](workflow.md) bakın.
