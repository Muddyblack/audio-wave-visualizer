# Stüdyo duvar kâğıtları

QML ayar stüdyosu ve HTML demosu için temel önizleme görselleri.

- `pine-lake.png`: yerel `/mnt/projects/nixos-config` kurulumundaki `assets/wallpapers/desktop.png` dosyasının değiştirilmemiş kopyası; depo sahibinin isteğiyle seçilmiştir.
- `afterglow.png`: aynı kurulumdaki `assets/wallpapers/lockscreen.png` dosyasının değiştirilmemiş kopyası.
- `midnight-marina.svg`: [Muddyblack'ın Midnight Marina](https://marketplace.visualstudio.com/items?itemName=Muddyblack.midnight-marina) temasından esinlenen özgün vektör sahnesi: gece denizi, turkuaz, elektrik mavisi, su üzerindeki akuamarin yansımaları ve uzaktaki marina ışıkları.
- `aurora-sound.svg`, `moss-mist.svg`, `silver-tide.svg`: bu renk paletini kuzey ışıkları, orman ve aydınlık gündüz temalarına taşıyan özgün vektör sahneleri.

Adlar, sabit kimlikler, dosya adları ve yedek renkler `../StudioCatalog.js` içinde bulunur. Değişikliklerden sonra depo kök dizininden `python3 tools/sync_studio_assets.py` komutunu çalıştırın. `docs/website/assets/studio` altındaki dosyalar yok sayılan derleme çıktılarıdır; yerel ortamda `make docs`, Pages iş akışında ise otomatik olarak oluşturulurlar. Yalnızca özgün kaynaklar sürüm kontrolünde tutulur. Bunlar önizleme arka planlarıdır; kullanıcının masaüstü duvar kâğıdını değiştirmez.
