# Stüdyo hazır ayarını paylaşma

**Hazır ayarlar → Hazır ayarlarım** bölümünü açın, mevcut görünümünüze bir ad verin ve kaydedin. Kaydedilmiş bir görünümü paylaşmak için seçin ve **JSON olarak kopyala** (web sitesinde **Geçerli görünümü JSON olarak kopyala**) seçeneğini kullanın. JSON metnini başka bir kullanıcıya gönderin; kullanıcı bunu masaüstü veya web Stüdyosu'ndaki **JSON içe aktar** alanına yapıştırabilir.

Dışa aktarma görsel ayarlarını içerir; özel QML dosyalarını, favorileri veya otomatik günlük ayarını içermez. Özel bir QML stili kullanan görünüm için güvenilir dosyanın ayrıca kurulması gerekir. Tanımadığınız QML dosyalarını içe aktarmayın; bunlar yürütülebilir koddur.

## Herkese hazır ayar önerme

1. [Depoyu](https://github.com/Muddyblack/audio-wave-visualizer) çatallayın.
2. JSON dosyasını kendi deponuzda `docs/preset-submissions/your-look.json` yoluna ekleyin.
3. Kısa açıklama, ekran görüntüsü ve katkınızda belirtilmesini istediğiniz adla bir pull request açın. Diğer kullanıcıların görünümü yeniden oluşturabilmesi için yerleşik stilleri kullanın.

Gönderiler incelenir; pull request açmak hazır ayarı otomatik olarak yayımlamaz veya kurmaz. Kabul edilen görünümler ilerideki bir sürümde hazır ayar listesine eklenebilir.

## Günlük görünümler ve favoriler

**Hazır ayarlar → Bugünün görünümü**, yerel takvim tarihiniz için yerleşik stillerden bir varyasyon oluşturur. Stüdyoyu yeniden açmak görünümü değiştirmez. Kopyasını korumak için kaydedin veya yıldızla işaretleyin; ertesi günün önerisi bu kopyanın yerini almaz.

**Bugünün görünümünü otomatik uygula** isteğe bağlıdır ve varsayılan olarak kapalıdır. Masaüstü widget'ı başlangıçta ve her 30 saniyede bir tarihi kontrol eder, günlük görünümü bir kez uygular ve tarihi yeniden başlatmalar arasında hatırlar. Ses ayarları, konum ve hazır ayar kitaplıkları korunur. Elle yapılan değişiklikler ertesi güne kadar geçerli kalır. Web Stüdyosu'ndaki seçenek yalnızca o tarayıcıyı etkiler; masaüstü widget'ını değiştiremez.

Masaüstü favorileri ve kayıtlı görünümler `~/.config/audio-wave-visualizer-presets.ini` dosyasında tutulur. Aynı hesaptaki Plasma widget'ları ve Hyprland Stüdyosu bunları paylaşır; widget'ı kaldırmak bu verileri silmez. Web Stüdyosu kendi tarayıcı yerel kitaplığını kullanır. Yıldız, görünümü uygulamadan işaretler; içe/dışa aktarma ile kayıtlı görünümler masaüstü ve web Stüdyoları arasında aktarılabilir.
