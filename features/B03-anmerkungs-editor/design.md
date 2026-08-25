# B03 · Anmerkungs-Editor — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Der Editor besteht aus drei Teilen: zwei SwiftUI-Leisten (oben, unten) und dazwischen einer
AppKit-Zeichenfläche. Die Zeichenfläche ist der Kern; sie hält eine affine Abbildung
zwischen **Bildpixeln** und **Ansichtspunkten** und rechnet jedes Mausereignis in
Bildkoordinaten um, bevor es an das aktive Werkzeug geht.

Daraus folgt die zentrale Eigenschaft: **Werkzeuge und Anmerkungen kennen nur Bildpixel.**
Vergrößerung und Verschiebung sind allein Sache der Abbildung — ein Werkzeug muss davon
nichts wissen.

Anmerkungen zeichnen sich selbst. Der Renderer legt das Originalbild an und lässt jede
Anmerkung nach Reihenfolge darüberzeichnen; dieselbe Vorschrift gilt für die Bildschirm-
darstellung und den Export, weshalb beide zwangsläufig übereinstimmen.

## Komponentenstruktur

```
AnnotationEditorWindowController      .titled .closable .resizable .miniaturizable
├── AnnotationToolbar (SwiftUI)       Werkzeuge · 6 Farben + freie Wahl · 3 Stärken
│                                     · Extract Text (B05) · Pin (B08)
├── AnnotationCanvasView (AppKit)     der Kern
│   ├── tools[DrawingToolType]        11 Werkzeuge, in setupTools() angemeldet
│   ├── imageTransform                Bildpixel ↔ Ansichtspunkte
│   ├── viewToImage / imageToView     Umrechnung je Ereignis
│   ├── Beobachter für die Leertaste  Verschiebemodus
│   ├── Schachbrett                   hinter transparenten Bildern
│   └── draw(_:)                      Bild · Anmerkungen (nach zIndex) · Werkzeugvorschau
├── AnnotationBottomBar (SwiftUI)     Zoomstufe · Bildmaße · Kopieren/Sichern/Anheften
└── Tastaturbeobachter                Kürzel, sofern kein Textfeld aktiv ist

AnnotationStore                       Anmerkungen · Auswahl · Farbe · Stärke · Zoom
                                      · Verschiebung · UndoManager
AnnotationRenderer                    flaches Rendern in voller Auflösung
```

Die elf Werkzeuge erfüllen dasselbe Protokoll: Maus gedrückt, gezogen, losgelassen, plus
eine Vorschau. Die Zeichenfläche verteilt nur; sie kennt kein Werkzeug im Einzelnen.

## Datenmodell

Ausführlich in `docs/datenmodell.md`, Abschnitt 3. Kurz:

`AnnotationStore` hält Anmerkungen, Auswahl, aktuelle Farbe und Stärke, aktives Werkzeug,
Vergrößerung, Verschiebung, einen Änderungsvermerk und den Rückgängig-Verwalter.
**Nichts davon wird gespeichert.**

Neun Anmerkungsarten erfüllen ein gemeinsames Protokoll mit Identität, Art, Umriss, Farbe,
Strichstärke, Auswahlzustand und Reihenfolge, dazu Treffertest, Zeichnen, Verschieben,
Skalieren sowie Momentaufnahme und Wiederherstellung für das Rückgängigmachen.

## Zugriffsregeln

Keine Rollen. Bemerkenswert ist allein der Umgang mit dem Bild:

| Zustand | Wo liegt das Bild |
|---|---|
| während der Bearbeitung | im Arbeitsspeicher, unverändert; Anmerkungen liegen daneben |
| beim Export | einmalig flach gerendert, das Ergebnis geht nach draußen |
| nach dem Schließen | Anmerkungen verworfen; die Originaldatei aus B09 bleibt |

## Missbrauchsschutz

Nicht anwendbar — keine Endpunkte, keine Kosten.

## Externe Dienste

Keine. Mittelbar berührt: die geräteübergreifende Zwischenablage des Systems (AK-33).

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Werkzeuge arbeiten in Bildpixeln | in Ansichtspunkten | Anmerkungen bleiben bei jeder Vergrößerung an Ort und Stelle; die Umrechnung liegt an einer Stelle |
| 2 | Anmerkungen zeichnen sich selbst | ein Renderer mit Fallunterscheidung | Bildschirm und Export benutzen zwangsläufig dieselbe Vorschrift |
| 3 | Reihenfolge über `zIndex`, stabil sortiert | Reihenfolge im Feld | gleiche Werte behalten die Einfügereihenfolge |
| 4 | Zeichenfläche in AppKit, Leisten in SwiftUI | alles in SwiftUI | Mausereignisse und Zeichenkontext sind in AppKit unmittelbar zugänglich |
| 5 | Eigener Beobachter für die Leertaste | `flagsChanged` | ausdrücklich kommentiert: `flagsChanged` meldet die Leertaste nicht |
| 6 | Tastaturkürzel werden bei aktivem Textfeld nicht abgefangen | immer abfangen | sonst ließe sich der Buchstabe „b" nicht tippen |
| 7 | Editor schließt nach Kopieren und Sichern | offen lassen | der Editor ist ein Durchgangsschritt |
| 8 | `⌘S` sichert auf den Schreibtisch und kopiert zusätzlich | in den eingestellten Ordner sichern | **Grund nicht erkennbar** (FB-02, FB-03) |
| 9 | Export immer PNG | Format aus den Einstellungen | **Grund nicht erkennbar** (FB-02) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | Fenstergröße aus dem Bild, auf 80 % begrenzt | |
| AK-02 | Toolbar · Canvas · BottomBar | |
| AK-03 | Übernahme der Standardwerte beim Aufbau | Umsetzung in B11 |
| AK-04 | Rückschreiben beim Schließen, sofern eingeschaltet | |
| AK-05 | Zuordnungstabelle im Tastaturbeobachter | 11 Werkzeuge |
| AK-06 | Werkzeugvorschau + Anlegen beim Loslassen | |
| AK-07 | Winkelraster in Pfeil- und Linienwerkzeug | |
| AK-08 | Umschalt-Zwang in Rechteck und Ellipse | |
| AK-09 | Catmull-Rom-Glättung im Freihandwerkzeug | |
| AK-10 | Textwerkzeug + eingebettetes Textfeld | |
| AK-11 | Sonderbehandlung, wenn ein Textfeld aktiv ist | |
| AK-12 | dieselbe Sonderbehandlung | |
| AK-13 | sechs Systemfarben + freie Wahl | siehe `docs/design-system.md` |
| AK-14 | drei Stärken (2/4/6) | |
| AK-15 | Auswahlwerkzeug mit acht Griffen | |
| AK-16 | `moved(by:)` und `resized(from:to:)` je Anmerkung | |
| AK-17 | Tastencodes 51 und 117 | |
| AK-18 | `UndoManager` mit Momentaufnahmen | |
| AK-19 | Sortierung nach `zIndex` | |
| AK-20 | `zoomIn` · `zoomOut` · `zoomToFit` | |
| AK-21 | Aufziehgeste auf der Zeichenfläche | |
| AK-22 | Leertastenbeobachter + Verschiebemodus | |
| AK-23 | `viewToImage` je Ereignis | **das tragende Kriterium des Features** |
| AK-24 | Schachbrett hinter dem Bild | |
| AK-25 | `renderFinalImage` → Zwischenablage → schließen | |
| AK-26 ⚠ | `save()` — Schreibtisch **und** Zwischenablage | |
| AK-27 ⚠ | `saveToFile` schreibt immer PNG | |
| AK-28 | `NSSavePanel` | |
| AK-29 | Schnellweg bei leerem Anmerkungsstand | |
| AK-30 | Rückfrage bei ungesicherten Änderungen | |
| AK-31 ⚠ | Zeitstempel auf die Sekunde | |
| AK-32 | flaches Rendern | |
| AK-33 ⚠ | allgemeine Zwischenablage ohne Markierung | ganzes Bild |
| AK-34 ⚠ | `print()` + bedingungsloses Schließen | stiller Datenverlust |
| AK-35 | kein Speicherpfad für Anmerkungen | bewusst (FB-01) |

## Übergabe an die QA

1. **AK-34 zuerst** — es ist der einzige Punkt in diesem Feature, der Daten verliert:
   Zielordner unzugänglich machen (etwa den Schreibtisch schreibgeschützt), `⌘S` drücken,
   beobachten. Erwartung nach Aktenlage: Der Editor schließt sich, die Datei existiert
   nicht, es erscheint keine Meldung.
2. **AK-23 systematisch prüfen.** Bei dreifacher Vergrößerung und verschobenem Ausschnitt
   eine Anmerkung setzen, dann exportieren und die Position im Ergebnis vergleichen. Ohne
   Tests (FB-08) ist das der einzige Nachweis für die Umrechnung, an der alles hängt.
3. **AK-26, AK-27 und AK-31** beschreiben zusammen, dass das Sichern im Editor anderen
   Regeln folgt als das automatische Sichern. Zu klären ist, ob das gewollt ist.
4. **AK-33** gemeinsam mit B05/AK-17 prüfen — hier geht das vollständige Bild über den
   Systemdienst hinaus.
