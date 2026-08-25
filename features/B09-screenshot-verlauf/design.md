# B09 · Screenshot-Verlauf — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Der Verlauf hat keinen Index und keine Datenbank: **Das Verzeichnis ist das Datenmodell.**
Beim Start liest die Anwendung den eingestellten Ordner aus, filtert auf Bilddateien und
baut daraus die Liste — bei jedem Start neu. Eine Datei, die von Hand hineingelegt wird,
erscheint; eine gelöschte verschwindet.

Das Sichern selbst hängt am Ende der Aufnahme: Bevor der Editor öffnet, ist die Datei
bereits geschrieben. Zusätzlich entsteht ein verkleinertes Vorschaubild in einem
versteckten Unterordner, damit der Browser nicht bei jedem Öffnen alle Vollbilder laden
muss.

## Komponentenstruktur

```
ScreenshotHistoryManager               Zustand und Dateizugriff
├── autoSave(_:)                       schreibt Datei + Vorschaubild, stellt Eintrag voran
├── loadHistory()                      liest das Verzeichnis, baut die Liste (im Initialisierer)
├── deleteItem(_:) / clearAll()        entfernt Dateien endgültig
├── storageUsage()                     summiert die Größe der Originale
└── generateThumbnail(for:originalURL:) verkleinert auf max. 200 Punkte, JPEG 0,7

AppPreferences.saveImage(_:)           Namensbildung, Formatwahl, Schreiben

HistoryBrowserWindowController         reguläres Fenster
└── HistoryBrowserView
    ├── Suchfeld                       filtert über Datum und Dateiname
    ├── LazyVGrid                      anpassend, mindestens 180 Punkte je Spalte
    │   └── Kachel                     Vorschaubild, Datum, Pixelgröße
    │       └── Kontextmenü            Editor · Kopieren · Anheften · Finder · Löschen
    └── Leerzustand                    „No Screenshots"
```

## Datenmodell

### Dateien

| Was | Wo | Benennung |
|---|---|---|
| Aufnahme | `<saveLocation>/` | `MikaSnap_JJJJ-MM-TT_HH-mm-ss.png` bzw. `.jpg` |
| Vorschaubild | `<saveLocation>/.thumbnails/` | **derselbe Dateiname wie das Original**, Inhalt immer JPEG |

### `HistoryItem` — flüchtig, bei jedem Start neu gebildet

| Feld | Typ | Herkunft | Anmerkung |
|---|---|---|---|
| `id` | `UUID` | beim Einlesen erzeugt | **nicht stabil über Programmstarts** |
| `url` | `URL` | Verzeichniseintrag | |
| `thumbnailURL` | `URL` | abgeleitet, sonst das Original | |
| `date` | `Date` | **Änderungsdatum der Datei** | nicht der Aufnahmezeitpunkt |
| `pixelWidth` / `pixelHeight` | `Int` | aus dem Dateikopf gelesen | je Datei ein Lesezugriff |

Beim automatischen Sichern wird der Eintrag mit `Date()` und den Maßen des Bildes im
Speicher gebildet — beim Neuladen dagegen aus der Datei. Die beiden Wege liefern also
nicht zwingend dieselben Werte.

## Zugriffsregeln

| Wer | Darf lesen | Darf schreiben | Erzwungen durch |
|---|---|---|---|
| Der Nutzer | den eingestellten Ordner | Aufnahmen anlegen und löschen | Dateirechte des Systems |
| Die Anwendung | denselben Ordner | dito | keine Sandbox, also voller Zugriff im Rahmen der Nutzerrechte |

Es gibt **keine** anwendungsseitige Zugriffsregel: keine Verschlüsselung, keine Abfrage,
keine Rechteprüfung. Wer Zugriff auf das Benutzerkonto hat, hat Zugriff auf alle
Aufnahmen. Für Stufe A ist das vertretbar und für macOS üblich — aber es ist eine
Entscheidung und keine Selbstverständlichkeit, weil der Inhalt hochsensibel sein kann.

## Missbrauchsschutz

| Vorgang | Limit | Anmerkung |
|---|---|---|
| automatisches Sichern | **keins** | jede Aufnahme schreibt; keine Obergrenze für Anzahl, Alter oder Gesamtgröße (FB-05) |
| Löschen | Bestätigungsdialog vor *Clear History* | einzelne Einträge werden ohne Rückfrage gelöscht |

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Verzeichnis statt Index | Datenbank oder Indexdatei | keine Datenhaltung, die mit der Wirklichkeit auseinanderlaufen kann; der Preis ist FB-04 |
| 2 | Sichern vor dem Öffnen des Editors | beim Schließen des Editors | **Grund nicht dokumentiert.** Erkennbar: nichts soll verloren gehen — Folge ist FB-01 |
| 3 | Vorschaubilder in `.thumbnails` neben den Originalen | in *Application Support* | bleiben beim Bestand, auch wenn der Ordner verschoben wird |
| 4 | Vorschaubilder als JPEG bei Qualität 0,7 | verlustfrei | Größe; Vorschau braucht keine Genauigkeit |
| 5 | Vorschaubild trägt den Namen des Originals | eigene Endung `.jpg` | **Grund nicht erkennbar** — vermutlich Bequemlichkeit beim Zuordnen (FB-06) |
| 6 | Endgültiges Löschen statt Papierkorb | `NSWorkspace.recycle` | **Grund nicht erkennbar** (FB-08, AK-18) |
| 7 | Zeitstempel auf die Sekunde | mit Millisekunden | **Grund nicht erkennbar**; an anderer Stelle im Projekt wird feiner aufgelöst (FB-02) |
| 8 | Suche über Datum und Dateiname | Volltextsuche über die Texterkennung | einfach; die vorhandene Texterkennung wird nicht genutzt |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `postCapture` → `autoSave` → `saveImage` | |
| AK-02 | Prüfung von `autoSaveEnabled` in `autoSave` | |
| AK-03 | Namensbildung in `saveImage` | |
| AK-04 | Formatzweig mit Qualitätsfaktor | |
| AK-05 | Verzeichnis wird vor dem Schreiben angelegt | |
| AK-06 | `generateThumbnail` | Obergrenze 200 Punkte |
| AK-07 ⚠ | **keine Komponente** — es gibt keine Kollisionsprüfung | |
| AK-08 ⚠ | `print()` in `saveImage` | erreicht niemanden |
| AK-09 | `HistoryBrowserWindowController` + `LazyVGrid` | neueste zuerst durch Voranstellen |
| AK-10 | `filteredItems` | Datum **oder** Dateiname |
| AK-11 | `ContentUnavailableView` | |
| AK-12 | Kontextmenü der Kachel | fünf Einträge |
| AK-13 | `deleteItem` | löscht beide Dateien |
| AK-14 | Kachelbeschriftung | |
| AK-15 | `storageUsage` + `formatBytes`, Reiter *Advanced* | |
| AK-16 | `clearAll` | löscht auch den Vorschauordner |
| AK-17 ⚠ | `storageUsage` summiert nur Originale | |
| AK-18 ⚠ | `removeItem` statt Papierkorb | |
| AK-19 ⚠ | Aufrufreihenfolge in `postCapture` | Gegenstück zu B04/AK-12 |
| AK-20 | kein Protokollaufruf mit Dateibezug | |
| AK-21 | keine Verschlüsselung im Feature | bewusst, siehe *Zugriffsregeln* |
| AK-22 | kein Netzwerkaufruf im Feature | |

## Übergabe an die QA

1. **AK-19 zusammen mit B04 prüfen.** Das ist derselbe Befund von zwei Seiten und der
   Grund, warum beide Features in der Erfassungsreihenfolge nebeneinanderstehen.
2. **AK-07 ist reproduzierbar**: zweimal in derselben Sekunde aufnehmen — am ehesten über
   `⌃⇧⌘5`, das ohne Interaktion auskommt. Danach zählen, wie viele Dateien entstanden sind.
3. **AK-08** durch einen schreibgeschützten Zielordner erzwingen und beobachten, ob der
   Nutzer irgendetwas davon mitbekommt.
4. **FB-04** mit einem gefüllten Ordner messen (etwa 2.000 Dateien) und die Startzeit
   vergleichen.
