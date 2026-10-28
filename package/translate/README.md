# Çeviriler

Plasma widget'ı çalışma zamanında KDE Ki18n kataloğunu kullanır. Türkçe katalog `tr.po` dosyasında tutulur ve şu dosyaya derlenir:

`package/contents/locale/tr/LC_MESSAGES/plasma_applet_org.muddyblack.plasmaAudioVisualizer.mo`

Kataloğu şu komutla derleyin:

```sh
sh package/translate/build.sh
```

Normal `make pack` ve Nix paketleme hedefi, `.plasmoid` arşivini oluşturmadan önce kataloğu derler. Paylaşılan ayar stüdyosu Plasma dışındaki ortamlarda da kullanıldığından, KDE'nin `i18n()` işlevi bulunmadığında QML bileşenleri İngilizce yedek metinleri kullanır.

Bazı ayar etiketleri ve açıklamaları `contents/ui/studio/Schema.js` içinde veri olarak tanımlandığı için çeviri şablonu katalogla birlikte tutulur. Görünür şema metinleri eklerken veya değiştirirken hem `template.pot` hem de `tr.po` dosyalarını güncelleyin. KDE'nin Türkçe terimlerini tutarlı kullanın. KDE Türkiye yerelleştirme kılavuzu: https://tr.kde.org/localization/.
