# B06 · Farbpipette — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Die Pipette arbeitet nicht auf dem lebenden Bildschirm, sondern auf einer Kopie: Beim
Start wird jedes Display **einmal** aufgenommen und die rohen Bilddaten werden im Speicher
gehalten. Jede Mausbewegung liest daraus ein Pixel — ein reiner Speicherzugriff, ohne
Wartezeit.

Das ist die tragende Entscheidung des Features und erklärt sein gesamtes Verhalten: die
flüssige Lupe (kein Rundweg zum System), den Speicherbedarf und die Tatsache, dass
bewegte Inhalte nicht mitgeführt werden.

Über den Displays liegen zwei Ebenen von Fenstern: je Display eine praktisch unsichtbare
Klickfläche, die Mausereignisse einsammelt, und darüber die Lupe.

## Komponentenstruktur

```
CaptureEngine.startColorPicker         Einstiegspunkt
├── ColorPickerEngine
│   ├── loadSnapshots(…)               je Display eine Aufnahme, ausgeschlossene Fenster gefiltert
│   ├── DisplaySnapshot                Rahmen · Bild · Rohdaten · Bytes je Pixel/Zeile · Skalierung
│   └── sampleColor(at:)               globaler Punkt → PickedColor
└── ColorLoupeController
    ├── Klickflächen                   je Display, .screenSaver, Deckkraft 0,001
    ├── Lupenfenster                   .screenSaver + 1, folgt dem Zeiger
    │   └── Lupendarstellung           8-fach, Fadenkreuz, Hex/RGB/HSL
    ├── globale Beobachter             Mausbewegung · Klick · Escape
    └── handleClick(…)                 kopieren · in den Verlauf · bei Umschalt in die Palette

ColorHistoryManager                    Verlauf (max. 10) und Palette (max. 20)
ColorPickerToast                       „Copied #RRGGBB", .floating
```

## Datenmodell

### `PickedColor` — flüchtig

| Feld | Typ | Bedeutung |
|---|---|---|
| `nsColor` | `NSColor` | die Farbe selbst, in sRGB umgerechnet |
| `hex` | `String` | `#RRGGBB`, **der einzige Wert, der kopiert wird** |
| `rgb` | `(Int, Int, Int)` | 0–255, nur zur Anzeige |
| `hsl` | `(Int, Int, Int)` | Grad und Prozent, nur zur Anzeige |

### `DisplaySnapshot` — flüchtig, solange die Pipette läuft

Rahmen des Displays, das aufgenommene Bild, dessen Rohdaten, Bytes je Pixel und je Zeile
sowie die Skalierung. Die Rohdaten sind eine **vollständige, unkomprimierte Kopie des
Bildschirminhalts**.

### Gespeichert

| Schlüssel | Typ | Grenze | Angezeigt |
|---|---|---|---|
| `colorHistory` | `[String]` | 10 | ja, im Menü |
| `colorPalette` | `[String]` | 20 | **nein — nirgends** |

Beide werden von `resetAll()` **nicht** erfasst.

## Zugriffsregeln

| Wer | Darf lesen | Erzwungen durch |
|---|---|---|
| Die Anwendung | jeden Bildschirminhalt zum Startzeitpunkt | Systemberechtigung Bildschirmaufnahme |
| — | **nicht**: ausgeschlossene Programme | Filter aus B02, angewandt beim Schnappschuss |
| — | **nicht**: eigene Fenster | zeitlich gelöst — der Schnappschuss entsteht vorher |

Bemerkenswert ist die zeitliche Lösung: Statt die eigenen Fenster zu filtern, nimmt die
Anwendung auf, **bevor** sie existieren. Das ist wirksam und einfacher als jeder Filter.

## Missbrauchsschutz

Nicht anwendbar — keine Endpunkte, keine Kosten.

Anzumerken bleibt der Speicherbedarf: Die Schnappschüsse aller Displays liegen
gleichzeitig unkomprimiert vor. Eine Obergrenze gibt es nicht.

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Einmaliger Schnappschuss statt fortlaufendem Lesen | je Mausbewegung neu lesen | ausdrücklich kommentiert: Synchronität — die Lupe muss ohne Wartezeit zeichnen. Preis: AK-09 |
| 2 | Aufnahme vor dem Aufbau der Überlagerungen | eigene Fenster filtern | einfacher und sicherer |
| 3 | Klickfläche mit Deckkraft 0,001 | völlig transparent | vollständig durchsichtige Fenster nehmen keine Mausereignisse an |
| 4 | Lupe eine Ebene höher | dieselbe Ebene | sonst verdeckt die Klickfläche die Lupe |
| 5 | Globale Ereignisbeobachter statt Fensterereignissen | Ereignisse im Panel behandeln | die Panels aktivieren die Anwendung nicht (`nonactivating`) |
| 6 | Umrechnung über `ScreenGeometry` | `NSScreen.main` | 3.4.1 behoben — anders als im Bereichspfad von B01 (dort FB-02) |
| 7 | Nur Hex wird kopiert | Auswahl anbieten | **Grund nicht erkennbar** |
| 8 | Palette getrennt vom Verlauf | nur ein Verlauf | **Zweck nicht rekonstruierbar** — es gibt keine Anzeige (FB-01) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `ColorLoupeController` + Lupendarstellung | 8-fach, Fadenkreuz, drei Werte |
| AK-02 | `handleClick` → Zwischenablage → `ColorPickerToast` | |
| AK-03 | Tastenbeobachter, Tastencode 53 | |
| AK-04 | Untermenü *Color History* | Umsetzung in B15 |
| AK-05 | Schaltfläche je Eintrag im Untermenü | |
| AK-06 | Obergrenze 10 in `addColor` | |
| AK-07 | Leerzustand des Untermenüs | |
| AK-08 | `sampleColor(at:)` über den passenden Schnappschuss | Skalierung je Display |
| AK-09 ⚠ | einmaliger Schnappschuss | bewusst, aber nicht gekennzeichnet |
| AK-10 ⚠ | `addToPalette` — **ohne Anzeige** | keine lesende Komponente |
| AK-11 | Filter aus B02 in `loadSnapshots` | |
| AK-12 | Aufnahme vor dem Aufbau der Überlagerungen | |
| AK-13 | Freigabe der Engine mit dem Controller | zu prüfen: hält niemand sonst eine Referenz |
| AK-14 | kein Protokollaufruf mit Bildbezug | |
| AK-15 ⚠ | **keine Komponente** — Schlüssel fehlen in der Rücksetzliste | |
| AK-16 ⚠ | allgemeine Zwischenablage | wie B05/AK-17 |

## Übergabe an die QA

1. **AK-10 und FB-01 zuerst** — die Palette ist im README beworben und hat keine Anzeige.
   Zu klären ist, ob die Funktion fehlt oder die Beschreibung falsch ist.
2. **AK-09 mit einem laufenden Video prüfen**: Video starten, Pipette öffnen, warten,
   Farbe abgreifen — und mit der tatsächlichen Bildschirmfarbe vergleichen.
3. **AK-13 messen**, nicht lesen: Speicherverbrauch vor, während und nach der Pipette. Eine
   nicht freigegebene Bildschirmkopie im Speicher wäre bei diesem Feature der schwerste
   denkbare Befund.
4. **AK-11 gesondert prüfen** — die Ausschlussliste greift hier über einen anderen Aufruf
   als in B01.
