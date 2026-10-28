# Stüdyo hazır ayarını paylaşma

**Hazır ayarlar → Hazır ayarlarım** bölümünü açın, mevcut görünümünüze bir ad verin ve kaydedin. Kaydedilmiş bir görünümü paylaşmak için önce onu seçin, ardından **JSON olarak kopyala** (web sitesinde **Geçerli görünümü JSON olarak kopyala**) seçeneğini kullanın. JSON metnini başka bir kullanıcıya gönderin; kullanıcı bunu masaüstü veya web Stüdyosu'ndaki **JSON içe aktar** alanına yapıştırabilir.

Dışa aktarma; görsel ayarlarını içerir, ancak özel QML dosyalarını (düğme stilleri dâhil), favorileri veya otomatik günlük ayarını içermez. Özel bir QML stili kullanan görünüm için bu güvenilir dosyanın ayrıca kurulması gerekir. Tanımadığınız bir QML dosyasını zararsız bir hazır ayar olarak görmeyin.

## Herkese hazır ayar önerme

1. [Depoyu](https://github.com/Muddyblack/audio-wave-visualizer) çatallayın (fork oluşturun).
2. Dışa aktarılan JSON dosyasını kendi deponuzda `docs/preset-submissions/your-look.json` yoluna ekleyin.
3. Kısa bir açıklama, ekran görüntüsü ve katkınızda belirtilmesini istediğiniz adla bir pull request açın. Diğer kullanıcıların görünümü yeniden oluşturabilmesi için yerleşik stilleri kullanın.

Dosyayı eklemek için GitHub'ın web düzenleyicisi yeterlidir. Gönderiler incelenir; pull request açmak hazır ayarı otomatik olarak yayımlamaz veya kurmaz. Kabul edilen görünümler ilerideki bir sürümde paketlenmiş hazır ayar listesine eklenebilir.

## Günlük görünümler ve favoriler

**Hazır ayarlar → Bugünün görünümü**, yerel takvim tarihiniz için yerleşik stillerden bir varyasyon oluşturur. Stüdyoyu yeniden açmak görünümü rastgele değiştirmez. Kopyasını korumak için kaydedin veya yıldızla işaretleyin; ertesi günün önerisi bu kopyanın yerini almaz.

**Bugünün görünümünü otomatik uygula** isteğe bağlıdır ve varsayılan olarak kapalıdır. Masaüstünde etkinleştirmek için ayarlarınızı uygulayın. Çalışan widget başlangıçta ve her 30 saniyede bir tarihi kontrol eder, günlük görünümü bir kez uygular ve tarihi yeniden başlatmalar arasında hatırlar. Ses ayarları, konum ve hazır ayar kitaplıkları korunur. Elle yapılan değişiklikler ertesi güne kadar geçerli kalır. Bu seçeneği kapatmak mevcut görünümü korur. Web Stüdyosu'nda seçenek yalnızca sayfa açıkken veya sonraki ziyaretinizde o tarayıcıyı etkiler; masaüstü widget'ını değiştiremez.

Masaüstü favorileri ve kaydedilen görünümler kullanıcı hesabınız için `~/.config/audio-wave-visualizer-presets.ini` dosyasında tutulur. Aynı hesaptaki tüm Plasma widget'ları ve Hyprland Stüdyosu bunları paylaşır; widget'ı kaldırmak bu verileri silmez. Widget'ların mevcut ayrı kitaplıkları, her widget Stüdyo'yu ilk açtığında içe aktarılır. Bu ortak kitaplıkta yapılan değişiklikler **Uygula** işleminden bağımsız olarak hemen kaydedilir. Web Stüdyosu kendi tarayıcı yerel kitaplığını kullanır. Yıldız, görünümü uygulamadan işaretler; içe/dışa aktarma ile kaydedilmiş görünümler masaüstü ve web Stüdyoları arasında aktarılabilir.
