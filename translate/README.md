# Translations

One gettext catalog per language, `translate/<lang>.po`, translates everything
a user reads, on every platform. QML calls `I18n.i18n("…")`, or `I18n.i18np("%1
bar", "%1 bars", n)` for counts and `I18n.i18nc("context", "…")` to tell apart
two meanings of a word. Text stored as data and translated when it is drawn is
marked `noop("…")` in JS and `I18n.noop("…")` in QML.

- `Messages.sh` extracts the strings into `template.pot` and merges it into
  every `.po`. Run it after changing a string; the pre-commit hook does.
- Every host reads the `.po` at runtime (`package/contents/ui/text/I18n.qml`,
  parsed by `ui/studio/I18n.js`), so Settings → Comfort & power can switch the
  language without a restart.
- `build.sh` copies each `.po` into the package and compiles the `.mo` Plasma
  reads for the store description.

## Translating

```bash
make new-language CODE=de      # starts translate/de.po from the template
# edit translate/de.po (Poedit, Lokalize, or any text editor)
make translations              # re-extract and merge, keeps your work
make check-translations        # every catalog must compile
```

The language setting offers every catalog it finds, so nothing else needs
changing.

Placeholders are `%1`, `%2`, … and may be reordered. Lines starting with `#.`
in the catalog are notes for translators; add one in the source with a
`// TRANSLATORS: …` comment on the line before the string.

`complete-languages` lists the languages CI requires to stay 100% translated;
any other language may be partial and shows English for the rest.
