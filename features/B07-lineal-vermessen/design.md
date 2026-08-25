# B07 · Lineal / Bildschirm vermessen — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Das Feature existiert **zweimal**, in zwei getrennten Implementierungen: als
Vollbild-Overlay, das über den Bildschirm gelegt wird, und als Werkzeug innerhalb des
Editors. Beide bieten dieselben zwei Betriebsarten — Punkt zu Punkt und Rechteck — und
denselben Einheitenwechsel, teilen aber keinen Code.

Das Overlay ist das einzige bildschirmbezogene Feature der Anwendung, das **keine
Bildschirmaufnahme benötigt**: Es zeichnet nur darüber und misst Koordinaten.

## Komponentenstruktur

```
Ausprägung 1 — Overlay (⇧⌘8)
CaptureEngine.startMeasurement          Parameter appState wird nicht benutzt
└── MeasurementOverlayController
    ├── MeasurementPanel                je Display, borderless, .screenSaver
    ├── Tastenbeobachter                Escape schließt · Leertaste wechselt die Einheit
    └── Messansicht
        ├── Punkt-zu-Punkt              Klick A → Klick B
        ├── Rechteck                    ziehen
        ├── Hilfslinien                 waagerecht und senkrecht am Zeiger
        └── Informationsfläche          aktuelle Einheit

Ausprägung 2 — Werkzeug im Editor (M)
MeasurementTool                          erfüllt DrawingTool
├── mouseDown/Dragged/Up                 dieselben zwei Betriebsarten
├── keyDown                              Leertaste wechselt die Einheit (Konflikt, FB-01)
└── drawPreview                          **nur Vorschau** — nie im Export
```

Der entscheidende Unterschied zu allen anderen Werkzeugen: `MeasurementTool` legt **keine
Annotation** an. Es zeichnet ausschließlich in die Vorschau, die der Renderer nicht kennt —
deshalb ist die Nichtexportierbarkeit (AK-09) keine Prüfung, sondern eine Eigenschaft des
Aufbaus.

## Datenmodell

Keine Persistenz, keine Annotation. Beide Ausprägungen halten zwei Punkte, eine Betriebsart
und einen Wahrheitswert für die Einheit — alles nur, solange gemessen wird.

## Zugriffsregeln

| Wer | Darf | Erzwungen durch |
|---|---|---|
| Das Overlay | Mauskoordinaten lesen | keine Berechtigung nötig |
| Das Overlay | **keine** Bildinhalte lesen | es nimmt schlicht nichts auf |

Bemerkenswert: Dieses Feature läuft auch dann, wenn die Bildschirmaufnahme-Berechtigung
fehlt.

## Missbrauchsschutz

Nicht anwendbar.

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Messungen werden nie exportiert | als Anmerkung behandeln | im Dateikopf ausdrücklich vermerkt: ein Arbeitsmittel, kein Bildinhalt |
| 2 | Umsetzung über die Vorschau statt über eine Annotation | Annotation mit Ausschluss beim Export | die Nichtexportierbarkeit ergibt sich aus dem Aufbau und kann nicht versehentlich verloren gehen |
| 3 | Ein Panel je Display | ein Panel über alle | folgt dem Muster der Bereichsauswahl |
| 4 | Overlay ohne Bildschirmaufnahme | Bildschirm aufnehmen | keine Berechtigung nötig |
| 5 | Zwei getrennte Implementierungen | gemeinsamer Kern | **Grund nicht erkennbar** (FB-04) |
| 6 | Controller wird gehalten, ohne Rückruf zum Freigeben | wie bei der Farbpipette | **Grund nicht erkennbar** (FB-03) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `MeasurementOverlayController` + Panels | |
| AK-02 | Punkt-zu-Punkt-Betriebsart | |
| AK-03 | Rechteck-Betriebsart | |
| AK-04 | Tastenbeobachter, Tastencode 49 | |
| AK-05 | Tastenbeobachter, Tastencode 53 | |
| AK-06 | Informationsfläche | |
| AK-07 | `MeasurementTool` | |
| AK-08 | Werkzeug rechnet in Bildpixeln | Umrechnung aus B03 |
| AK-09 | nur Vorschau, keine Annotation | Eigenschaft des Aufbaus |
| AK-10 ⚠ | zwei Behandler für dieselbe Taste | |
| AK-11 | keine Aufnahme im Overlay | |
| AK-12 | kein Speicherpfad, kein Protokollaufruf | |

## Übergabe an die QA

1. **AK-09 in allen vier Ausgabewegen prüfen** — Kopieren, Sichern, Sichern unter,
   Anheften. Eine sichtbare Messung im Export wäre ein Fehler mit Außenwirkung.
2. **AK-10** reproduzieren: `M` drücken, messen, Leertaste, dann ziehen.
3. **AK-11** ist die datenschutzrelevante Zusage: prüfen, dass das Overlay auch ohne
   erteilte Bildschirmaufnahme-Berechtigung funktioniert. Tut es das nicht, liest es doch
   Bildinhalte.
