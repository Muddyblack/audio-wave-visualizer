# Çeviriler

Türkçe metinler `tr.po` dosyasında tutulur. Üç parçadan oluşur:

- **`Messages.sh`** — QML ve JS kaynaklarındaki `i18n("…")` ve `N_("…")` çağrılarını `template.pot` dosyasına çıkarır, ardından `tr.po` ile birleştirir (artık kullanılmayan metinler kaldırılır). Yeni bir metin eklediğinizde veya değiştirdiğinizde bunu çalıştırın. Ayrıca paylaşılan stüdyo için `ui/studio/TranslationCatalog.js` dosyasını üretir.
- **`build.sh`** — `tr.po` dosyasını Plasma'nın yüklediği `contents/locale/tr/LC_MESSAGES/plasma_applet_<Id>.mo` dosyasına derler. `make pack` ve `test_install.sh` bunu otomatik çalıştırır.
- **`ui/studio/I18n.js`** — tek çeviri yardımcısı. Her QML dosyası `I18n.i18n("…")` çağırır. Metinler `TranslationCatalog.js` içinden okunur; bu dosya modülle birlikte yüklendiği için çeviri, arayüz oluşturulurken hazırdır. Plasma'da KDE'nin `i18n()` işlevi verilirse onu kullanır.

Kontroller:

```sh
sh package/translate/Messages.sh        # şablon ve çalışma zamanı kataloğunu güncelle
sh package/translate/build.sh <paket>   # .mo derle
python3 tests/test_translations.py      # kapsama, yer tutucular ve derleme
```

Tutarlı Türkçe terimler için KDE Türkiye yerelleştirme kılavuzunu kullanın: https://tr.kde.org/localization/.
