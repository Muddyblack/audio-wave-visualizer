# Windows desteği

Windows sürümü, Plasma widget'ı ve Hyprland paneliyle aynı QML çizim ağacını kullanır. `windows/app.py` uygulama penceresini barındırır; `windows/audio_capture.py`, `cava` yerine WASAPI döngü yakalamayı kullanır; `windows/media_session.py` ise MPRIS yerine Windows medya oturumlarından parça adı, sanatçı, kapak, süre, konum ve oynatma denetimlerini alır. Sistem tepsisi menüsündeki **Settings…** ortak ayar stüdyosunu açar.

## Doğrulama durumu

- QML çizim ağacı ve ayar stüdyosu Quickshell/Plasma dışında açılabiliyor; CI'da Linux ve Windows üzerinde öz sınama çalıştırılıyor.
- Sentetik ses yakalama, FFT, `frame.ini`, sessizlik, kapanma ve aygıt kaybı testleri otomatikleştirilmiştir.
- Windows 11 sanal makinesinde medya oturumundan parça bilgileri ve denetimler doğrulanmıştır.
- Ses yakalamanın `frame.ini` üzerinden görselleştiriciye ulaşması Linux'ta doğrulanmıştır.
- DPI ölçekleme, çoklu monitör ve gerçek Windows WASAPI döngü yakalama henüz doğrulanmamıştır. Test sanal makinesinde ses aygıtı bulunmamıştır.

## Çalıştırma ve paketleme

Windows geliştirme ve paketleme adımları depo içindeki Windows iş akışında tanımlıdır. Derlemeler PyInstaller ve Inno Setup kullanır; Scoop ve WinGet bildirimleri sürüm çıktılarından hazırlanır. Microsoft Store dağıtımı için ayrıca MSIX paketi ve Partner Center yayıncı kimliği gerekir.

## Bilinen sınırlamalar

Windows'ta henüz Linux tarafındaki tüm özellikler taşınmış değildir. Şarkı sözleri, favicon ve ek medya üst verisi aramaları ile tanılama düğmesi Windows sürümüne aktarılmamıştır. Pencerenin diğer tüm pencerelerin arkasında kalması ve çoklu ekran davranışı gerçek donanımda ayrıca sınanmalıdır. Bu nedenle Windows desteğini tüm özellikleri doğrulanmış kararlı bir sürüm olarak değerlendirmeyin.

Ayrıntılı uygulama ve test notları için İngilizce [Windows teknik belgesine](windows.md) bakın.
