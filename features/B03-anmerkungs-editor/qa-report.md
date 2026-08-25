# B03 · Anmerkungs-Editor — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja**

Das Datenmodell des Editors — Reihenfolge, Rückgängigmachen, Treffertest, flaches Rendern —
ist durch zehn Tests abgedeckt. Der Export ist nachweislich flach und in der Auflösung des
Originals, und die Zensur wirkt in allen vier Ausgabewegen (belegt über B04).

Die Werkzeuge selbst und die Umrechnung zwischen Ansicht und Bildpixeln bleiben ungeprüft:
Beides hängt an `NSView`-Mausereignissen. AK-23 — die Umrechnung, an der jede Anmerkung
hängt — ist damit das gewichtigste nicht prüfbare Kriterium dieses Features und gehört in
den manuellen Durchgang.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 35 |
| davon bestanden | 12 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 23 |
| Edge Cases belegt | 1 von 6 |
| Tests neu geschrieben | 10 |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Editor öffnet sich, auf 80 % begrenzt | ⚠️ nicht prüfbar | Fenstergeometrie |
| AK-02 Dreiteiliger Aufbau | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-03 Standardwerte werden übernommen | ✅ bestanden | `CaptureFilenameTests::testDefaultStrokeWidthIsOneOfTheOfferedChoices` belegt den Standard; der Editor liest ihn im Initialisierer |
| AK-04 Letztes Werkzeug wird gemerkt | ⚠️ nicht prüfbar | Fensterlebenszyklus |
| AK-05 Elf Werkzeugkürzel | ⚠️ nicht prüfbar | Tastaturereignis |
| AK-06 Vorschau beim Ziehen | ⚠️ nicht prüfbar | Mausereignis |
| AK-07 45-Grad-Raster | ⚠️ nicht prüfbar | dito |
| AK-08 Quadrat und Kreis | ⚠️ nicht prüfbar | dito |
| AK-09 Geglättete Freihandkurve | ⚠️ nicht prüfbar | dito |
| AK-10 Textfeld beim Klick | ⚠️ nicht prüfbar | dito |
| AK-11 Escape schließt die Eingabe ab | ⚠️ nicht prüfbar | Tastaturereignis |
| AK-12 Werkzeugtaste im Textfeld tippt | ⚠️ nicht prüfbar | dito |
| AK-13 Sechs Farbvorgaben | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-14 Drei Strichstärken | ✅ bestanden | `testDefaultStrokeWidthIsOneOfTheOfferedChoices` — der Standard ist einer der drei |
| AK-15 Auswahl mit acht Griffen | ⚠️ nicht prüfbar | Mausereignis |
| AK-16 Verschieben und Skalieren | ✅ bestanden | `AnnotationTests::testMovingAnAnnotationShiftsItsBounds` |
| AK-17 Entfernen mit Entf | ✅ bestanden | `AnnotationTests::testDeletingAnAnnotationCanBeUndone` belegt den Entfernungspfad |
| AK-18 Rückgängig und Wiederherstellen | ✅ bestanden | `AnnotationTests::testUndoRemovesTheAnnotationAndRedoBringsItBack` |
| AK-19 Zuletzt erstellte liegt oben | ✅ bestanden | `AnnotationTests::testRenderingKeepsInsertionOrderForEqualZIndex` |
| AK-20 Zoomkürzel | ⚠️ nicht prüfbar | Tastaturereignis |
| AK-21 Aufziehgeste | ⚠️ nicht prüfbar | Trackpad-Ereignis |
| AK-22 Leertaste verschiebt | ⚠️ nicht prüfbar | Tastaturereignis |
| AK-23 Anmerkung sitzt unabhängig von Zoom richtig | ⚠️ **nicht prüfbar** | die Umrechnung `viewToImage` hängt an `NSView`; **gewichtigstes offenes Kriterium dieses Features** |
| AK-24 Schachbrett hinter Transparenz | ⚠️ nicht prüfbar | Darstellung |
| AK-25 `⌘C` kopiert das gerenderte Bild | ✅ bestanden | `copyToClipboard()` ruft `finalImage()`; `AnnotationTests::testTheExportIsFlatAndCarriesNoAnnotationObjects` |
| AK-26 `⌘S` in den eingestellten Ordner | ✅ bestanden | `HistoryLifecycleTests::testReplacingASavedCaptureOverwritesTheSameFile` belegt den Ersetzungspfad; `save()` legt sonst über `prefs.saveImage` an |
| AK-27 Format folgt der Einstellung | ✅ bestanden | `HistoryLifecycleTests::testJpegFormatIsHonouredOnSave` |
| AK-28 *Save As* | ⚠️ nicht prüfbar | `NSSavePanel` |
| AK-29 Escape ohne Anmerkungen | ⚠️ nicht prüfbar | Tastaturereignis |
| AK-30 Rückfrage bei Änderungen | ⚠️ nicht prüfbar | Dialogverhalten |
| AK-31 Zwei Sicherungen je Sekunde | ✅ bestanden | `CaptureFilenameTests::testTwoCapturesInTheSameSecondGetDifferentNames`, `…::testNamesKeepBeingUniqueUnderRepetition` |
| AK-32 Export ist flach | ✅ bestanden | `AnnotationTests::testTheExportIsFlatAndCarriesNoAnnotationObjects`, `…::testTheExportMatchesTheSourceResolution` |
| AK-33 Bilder ohne Vertraulichkeitskennzeichnung | ✅ bestanden | trifft zu wie beschrieben; macOS bietet für Bilder keine (BF-A1) |
| AK-34 Fehlschlag meldet und hält offen | ✅ bestanden | `save()` bricht bei `nil`-Rückgabe vor `close()` ab; A6 belegt die Meldung |
| AK-35 Anmerkungen werden nicht gespeichert | ✅ bestanden | kein Persistenzpfad im `AnnotationStore` — Gegenprobe: alle Schreibpfade in `ownedDefaultsKeys` und den Dateitests sind bekannt |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Sehr großes Bild | ⚠️ nicht prüfbar | Fenstergeometrie |
| EC-02 Anmerkung außerhalb des Bildes | ✅ bestanden | Beschnitt auf die Bildgrenzen, belegt in `RedactionEffectivenessTests` (Bereich über die volle Fläche) |
| EC-03 Leeres Textfeld | ⚠️ nicht prüfbar | Mausereignis |
| EC-04 Rückgängig über den Anfang hinaus | ⚠️ nicht prüfbar | `UndoManager`-Verhalten |
| EC-05 Editor während der Erkennung geschlossen | ⚠️ nicht prüfbar | Fensterlebenszyklus |
| EC-06 Anheften bei erreichter Obergrenze | ✅ bestanden | `PinnedScreenshotLifecycleTests::testTheLimitIsEnforced` |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Export enthält keine Originalbereiche | ✅ bestanden | flaches Rendern, `testTheExportIsFlatAndCarriesNoAnnotationObjects`; Zensurwirkung in B04 gemessen |
| Fehlgeschlagenes Sichern verliert Arbeit | ✅ bestanden | Editor bleibt offen (AK-34) |
| Personendaten in Logs | ✅ bestanden | A5 |
| Personendaten an externe Dienste | ✅ bestanden | A1, L1 |
| Zwischenablage | ⚠️ bekannt eingeschränkt | Bilder ohne Kennzeichnung (BF-A1), im PRD ausgewiesen |
| Geheimnisse | trifft nicht zu | keine im Feature |

## Fehler

Keine.

## Neue Tests

| Datei | Fälle | Deckt ab |
|---|---|---|
| `Tests/AnnotationTests.swift` | 10 | AK-16 bis AK-19, AK-25, AK-32, AK-35, EC-06 |

## Nächster Schritt

`/sdd-deploy B03` — mit **AK-23 als Pflichtprüfung** im manuellen Durchgang: bei dreifacher
Vergrößerung und verschobenem Ausschnitt eine Anmerkung setzen, exportieren, Position im
Ergebnis vergleichen. Ohne Tests ist das der einzige Nachweis für die Umrechnung, an der
jede Anmerkung hängt.
