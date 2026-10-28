# Şarkı sözleri ve karaoke

Okuma görünümü için **Şarkı sözleri → Yalnızca şarkı sözleri**, eşzamanlanan tek satır için **Kartta satır** seçeneğini etkinleştirin. Widget önce yerel dosyaları, ardından çevrim içi önbelleği ve LRCLIB'yi kontrol eder. Yerel arama için oynatıcının MPRIS `xesam:url` alanı yerel bir `file:` URI'sini göstermelidir; akış URL'leri yerel dosya olarak açılmaz.

`Song.mp3` için arama sırası:

1. Ses dosyasının dizinindeki `Song.lrc`, `Song.mp3.lrc` veya `Song.LRC`.
2. Gömülü ID3 `SYLT` (milisaniye zaman damgaları), ardından `USLT`.
3. Önbelleğe alınmış LRCLIB sözleri, ardından başlık, sanatçı, albüm ve süreyle çevrim içi arama.

Qt HTTPS bağlantısı başarısız olursa arama, sertifika doğrulaması yapan Python HTTPS istemcisine geçer. Geçici hatalarda iki kez yeniden denenir; başarısız istekler sözlerin bulunmadığı şeklinde önbelleğe alınmaz. Eşzamanlanmış sözler yoksa çevrim içi düz metin yalnızca **Yalnızca şarkı sözleri** görünümünde gösterilir.

UTF-8 ve BOM işaretli UTF-16 yan dosyaları desteklenir. Düz USLT sözleri zaman uydurulmadan gösterilir. MPEG kare sayıları kullanan SYLT atlanır; bu değerler milisaniye değildir. Gömülü ID3 desteği Python **mutagen** kitaplığını kullanır; yan dosyaları aramak için Python 3 yeterlidir. Diğer kurulumlarda `mutagen` kurun.

Gelişmiş LRC, sözcük veya hece dolgu animasyonunu destekler. Bir sözcük bir sonraki zaman işaretinde sona erer. Kapanış işaretçisi yoksa sonraki satırda biter; son sözcük için iki saniyelik varsayılan süre kullanılır. GPU çizimi yumuşak parıltılı geçiş, yazılım çizimi ise kırpılmış dolgu kullanır. Azaltılmış hareket ayarında dolgu canlandırılmaz. Normal LRC satırların tamamını vurgular. İleri/geri sarma ve duraklatma oynatma saatini izler.

**− / +** düğmeleri zamanlama kaymasını 100 ms adımlarla, ±10 saniyeye kadar değiştirir. Pozitif değerler sözlerin daha erken görünmesini sağlar. Sıfırlamak için değere tıklayın. Söz görünümüne odaklanıp klavyede **− / +** (veya **=**) tuşlarını da kullanabilirsiniz. Kayma tüm söz görünümlerine ve parçalara uygulanır. LRC içindeki `[offset:milliseconds]` etiketi de geçerlidir.

## Çeviriler ve telaffuz

Ses dosyasının yanına zaman damgaları eşleştirilmiş ek dosyalar ekleyin:

- `Song.translation.lrc`: Çevrilmiş altyazılar.
- `Song.romaji.lrc`: Romaji veya Pinyin dâhil telaffuz altyazıları.
- `Song.reading.lrc`: Japonca kana okunuşları.

Ek dosyalar orijinalin ayarlanmış zaman damgalarıyla 20 ms içinde eşleşir. Tek LRC dosyasında aynı zaman damgasına sahip iki satır orijinal + çeviri olarak gösterilir. Şarkı sözü metinleri düz metin olarak çizilir; gömülü HTML yorumlanmaz.

**Okuma dili**, Otomatik, Japonca veya Çince seçeneklerini sunar. Otomatik mod Japonca kana karakterlerini algılar. Yalnızca Han karakterlerinden oluşan sözler için Japonca veya Çince'yi açıkça seçin. Python **pykakasi**, Romaji ve kana; **pypinyin** ise ton işaretli Pinyin sağlar. Bu isteğe bağlı kitaplıklar yerel çalışır; eksik olsalar da sözler gizlenmez. Otomatik telaffuz kusurlu olabilir; ek dosyalar bu sonucu geçersiz kılar. **Telaffuz altyazısı**, Romaji/Pinyin, kana veya kapalı seçeneklerini sunar.

Çeviriler yerel olarak sağlanmalı veya söz metnine eklenmelidir: [LRCLIB API'sinde](https://lrclib.net/docs) çeviri uç noktası yoktur. Otomatik çeviri hizmeti kullanılmaz.
