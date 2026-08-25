# B11 · Einstellungen — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Ein Fenster, das einen SwiftUI-Baum in AppKit einbettet und vier Reiter zeigt. Der Zustand
liegt vollständig in `AppPreferences` — einer beobachtbaren Klasse, deren Eigenschaften
beim Setzen unmittelbar in die Benutzereinstellungen schreiben. Es gibt kein „Übernehmen"
und keinen Zwischenstand.

Die Reiter greifen auf sechs andere Features durch: Verlauf, Tastenkombinationen,
Ausschlussliste, Anmeldestart, Aktualisierung und Ersteinrichtung. Die Einstellungen selbst
enthalten kaum eigene Logik — sie sind die Oberfläche zu Zuständen, die anderswo wirken.

**Genau daraus erklären sich die Befunde:** Ein Schalter, dessen Gegenstück im anderen
Feature fehlt, sieht hier vollständig aus und tut nichts.

## Komponentenstruktur

```
PreferencesWindowController            .titled .closable
└── PreferencesContainerView           Reiterauswahl
    ├── GeneralTabView
    │   ├── File Output                Ordner · Format · Qualität (nur bei JPEG)
    │   ├── Capture Behavior           Ton · Schwebevorschau (wirkungslos) · Auto-Sichern
    │   └── ExcludedAppsSection        → B02
    ├── ShortcutsTabView               sieben Aufzeichner + Konflikthinweis → B10
    ├── AnnotationTabView
    │   ├── Defaults                   Werkzeug · Farbe · Strichstärke (2/4/6)
    │   └── Behavior                   letztes Werkzeug merken · Beschriftungen (wirkungslos)
    └── AdvancedTabView
        ├── System                     Anmeldestart → B13 · automatische Updates → B14
        ├── Storage                    Anzahl · Größe · Ordner öffnen · Verlauf löschen → B09
        └── About                      Ersteinrichtung → B12 · Zurücksetzen · Fassung

PreferencesStyles                      Reiterdefinition mit Symbolen und Beschriftungen
AppPreferences                         der gemeinsame Zustand
```

## Datenmodell

Vollständig in `docs/datenmodell.md`, Abschnitt 1. Sechzehn Schlüssel in den
Benutzereinstellungen, davon **vier ohne Leser** (drei hier, einer in B12).

Zwei Eigenheiten:

- `defaultStrokeColorData` wird als archiviertes Farbobjekt abgelegt, nicht als Zahlenwert.
- `excludedBundleIdentifiers` ist im Speicher eine Menge, in den Einstellungen ein Feld.

## Zugriffsregeln

Keine. Alle Einstellungen gehören dem Nutzer des Rechners.

## Missbrauchsschutz

| Vorgang | Schutz |
|---|---|
| *Clear History* | Rückfrage, die die Endgültigkeit benennt |
| *Reset All Preferences* | Rückfrage |
| einzelne Einstellungen | keiner nötig |

## Externe Dienste

Keine unmittelbar; der Reiter *Advanced* steuert die Aktualisierungsprüfung aus B14.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Sofortiges Speichern beim Setzen | „Übernehmen"-Schaltfläche | entspricht dem Verhalten der Systemeinstellungen |
| 2 | Ein gemeinsamer Einstellungszustand | je Feature ein eigener | eine Stelle für alle Voreinstellungen; der Preis ist eine Klasse, die fast jedes Feature berührt |
| 3 | Bindungen mit ausdrücklichem Lesen und Schreiben | `@Bindable` | die Klasse wird als unveränderlicher Verweis übergeben |
| 4 | Vier Reiter mit Systemsymbolen | eine lange Liste | folgt den Systemeinstellungen |
| 5 | Systemeigenes Erscheinungsbild | dunkles Markenbild wie im Editor | seit `a43683a`; die Dokumentation nennt weiterhin den alten Zustand (FB-02) |
| 6 | Qualitätsregler nur bei JPEG | immer sichtbar | er wirkt bei PNG nicht |
| 7 | Rücksetzen über eine feste Schlüsselliste | gesamte Sammlung entfernen | **Grund nicht erkennbar** (FB-04) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `PreferencesWindowController` + Container | `⌘,` im Menü |
| AK-02 ⚠ | systemeigene Darstellung | Dokumentation abweichend |
| AK-03 | `NSOpenPanel` im Reiter *General* | |
| AK-04 | Regler, sichtbar bei JPEG | |
| AK-05 | dieselbe Bedingung | |
| AK-06 | `captureSoundEnabled` | gelesen in B01 |
| AK-07 | `autoSaveEnabled` | gelesen in B09 |
| AK-08 ⚠ | **kein Leser** | |
| AK-09 | `ExcludedAppsSection` | → B02 |
| AK-10 | Übernahme beim Öffnen des Editors | → B03 |
| AK-11 ⚠ | Standard 3 gegen Auswahl 2/4/6 | |
| AK-12 | `rememberLastTool` | gelesen in B03 |
| AK-13 ⚠ | **kein Leser** | |
| AK-14 | `storageUsage` + Schaltflächen | → B09 |
| AK-15 | `clearAll` nach Rückfrage | → B09 |
| AK-16 | Abschnitte *System* und *About* | → B13, B14, B12 |
| AK-17 | `resetAllPreferences` + Neuanmeldung | |
| AK-18 ⚠ | feste Schlüsselliste | Farbverlauf und Sparkle bleiben |
| AK-19 ⚠ | `reRegisterAll` ohne Entfernen des Behandlers | → B10 |
| AK-20 | nur Pfade, Zahlen, Wahrheitswerte | |
| AK-21 | nur der Pfad wird abgelegt | |
| AK-22 | Rückfrage mit Hinweis auf Endgültigkeit | |
| AK-23 ⚠ | **keine Komponente** | → B08 |

## Übergabe an die QA

1. **AK-08, AK-13 und AK-11** sind in Minuten zu prüfen und betreffen Zusagen, die die
   Oberfläche macht, ohne sie einzulösen.
2. **AK-19** hat Außenwirkung: nach *Reset All Preferences* eine Tastenkombination drücken
   und zählen, wie viele Editorfenster entstehen.
3. **AK-18** durch Farben abgreifen, zurücksetzen, Menü prüfen.
4. **AK-02** ist eine Entscheidungsfrage, keine Prüffrage — die QA sollte sie als offenen
   Punkt weiterreichen, nicht als Fehler bewerten.
