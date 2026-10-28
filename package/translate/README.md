# Translations

The Plasma widget uses KDE's Ki18n catalog at runtime. The Turkish catalog is
stored in `tr.po` and compiled into:

`package/contents/locale/tr/LC_MESSAGES/plasma_applet_org.muddyblack.plasmaAudioVisualizer.mo`

Build the catalog with:

```sh
sh package/translate/build.sh
```

The normal `make pack` and Nix packaging target build the catalog before
creating the .plasmoid archive. The shared settings studio is also used by
non-Plasma hosts, so its QML components keep an English fallback when KDE's
`i18n()` function is not available.

Because some setting labels and descriptions are defined as data in
`contents/ui/studio/Schema.js`, the translation template is maintained
alongside the catalog. When adding or changing visible schema strings, update
both `template.pot` and `tr.po`. Use KDE's Turkish terminology consistently;
the KDE Türkiye localization guide is at https://tr.kde.org/localization/.
