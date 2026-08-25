# B04 · Bereiche zensieren — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja**

Dies ist das einzige Feature, dessen Kernzusage sich messen statt begutachten lässt — und
sie wurde gemessen. Ein Kennwort wird ins Bild gerendert, zensiert und anschließend Apples
Texterkennung darauf angesetzt. Sie findet es nicht: weder bei Weichzeichnen noch bei
Verpixeln, weder in der Mitte noch am Rand des Bereichs, weder bei kleiner noch bei
doppelter Schriftgröße.

Ein Kontrolltest weist zuvor nach, dass die Erkennung das Kennwort **vor** der Zensur
liest. Ohne ihn wäre der Rest wertlos: Eine Erkennung, die ohnehin nichts findet, belegt
keine Zensur.

Ebenso belegt ist der schwerste Befund der Erfassung: Die automatisch gesicherte Datei wird
beim Export durch die zensierte Fassung **ersetzt**, nicht ergänzt.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 15 |
| davon bestanden | 11 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 4 |
| Edge Cases belegt | 3 von 5 |
| Tests neu geschrieben | 11 (5 Wirksamkeit, 6 Stärke) |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Fadenkreuz beim Weichzeichnen | ⚠️ nicht prüfbar | Zeigerdarstellung, kein automatisierter Zugang |
| AK-02 Rechteck wird weichgezeichnet | ✅ bestanden | `RedactionEffectivenessTests::testBlurMakesTheSecretUnreadable` |
| AK-03 Rechteck wird verpixelt | ✅ bestanden | `RedactionEffectivenessTests::testPixelateMakesTheSecretUnreadable` |
| AK-04 Rechteck < 3 Punkte erzeugt nichts | ⚠️ nicht prüfbar | Mausereignisfolge im Werkzeug |
| AK-05 `⌘Z` stellt den Originalinhalt her | ✅ bestanden | `AnnotationTests::testUndoRemovesTheAnnotationAndRedoBringsItBack` |
| AK-06 Verschieben und Skalieren | ✅ bestanden | `AnnotationTests::testMovingAnAnnotationShiftsItsBounds`, `RedactionStrengthTests::testResizingARedactionRecomputesItsStrength` |
| AK-07 Zensur wirkt in allen vier Ausgabewegen | ✅ bestanden | alle vier rufen `finalImage()`, das über `AnnotationRenderer.renderFinalImage` geht; `AnnotationTests::testTheExportIsFlatAndCarriesNoAnnotationObjects` belegt das Ergebnis |
| AK-08 Zensur über den Bildrand hinaus | ✅ bestanden | Schnittmenge mit den Bildgrenzen vor dem Filtern; `RedactionEffectivenessTests` deckt einen Bereich über die gesamte Bildfläche ab |
| AK-09 Stärke richtet sich nach der Bereichsgröße | ✅ bestanden | `RedactionStrengthTests` — 6 Fälle, darunter `testBlurRadiusFollowsTheShorterSide` und `testALargeRegionIsRedactedAsEffectivelyAsASmallOne` |
| AK-10 Rand so stark wie die Mitte | ✅ bestanden | `RedactionEffectivenessTests::testTextAtTheEdgeOfTheRegionIsAlsoUnreadable` — der Bereich endet knapp hinter der Grundlinie, sodass die Glyphen die Kante berühren |
| AK-11 Export enthält keine Originalpixel | ✅ bestanden | `AnnotationTests::testTheExportIsFlatAndCarriesNoAnnotationObjects` und `…MatchesTheSourceResolution` |
| AK-12 Verlauf enthält die zensierte Fassung | ✅ bestanden | `HistoryLifecycleTests::testReplacingASavedCaptureOverwritesTheSameFile` — die Datei trägt danach die neue Bildfarbe, und es entsteht **keine zweite** |
| AK-13 Zwischenablage enthält nur das gerenderte Bild | ✅ bestanden | `copyToClipboard()` ruft `finalImage()` vor der Übergabe |
| AK-14 Stärke wächst beim Vergrößern mit | ✅ bestanden | `RedactionStrengthTests::testResizingARedactionRecomputesItsStrength` |
| AK-15 Zensur wirkt auch ohne Export | ⚠️ nicht prüfbar | `close()` ersetzt die Datei bei vorhandener Zensur; der Pfad ist implementiert, konnte aber ohne Fensterlebenszyklus nicht ausgeführt werden |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Zensur außerhalb des Bildes | ✅ bestanden | `guard !clampedRect.isNull` vor dem Zeichnen; kein Fehler bei leerer Schnittmenge |
| EC-02 Zensur über die ganze Bildfläche | ✅ bestanden | genau dieser Fall in `RedactionEffectivenessTests` |
| EC-03 Überlappende Zensuren verstärken sich nicht | ✅ bestanden | jede Annotation liest aus `baseImage`, belegt durch die Signatur `draw(in:baseImage:)` und das Renderverhalten in `AnnotationTests` |
| EC-04 Skalierung auf null | ⚠️ nicht prüfbar | Mausereignisfolge |
| EC-05 Undo, Redo, dann Export | ⚠️ nicht prüfbar | braucht den Editor-Fensterlebenszyklus |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| **Zensur maschinell angegriffen** | ✅ bestanden | Vision auf das zensierte Ergebnis angesetzt — findet das Kennwort in keinem der vier Fälle. Kontrolltest belegt, dass sie es vorher las |
| Original bleibt nach Zensur liegen | ✅ bestanden | `testReplacingASavedCaptureOverwritesTheSameFile`: eine Datei, neuer Inhalt |
| Personendaten in Logs | ✅ bestanden | A5: keine Bildinhalte in Protokollaufrufen |
| Personendaten an externe Dienste | ✅ bestanden | A1/L1: CoreImage arbeitet lokal, kein Netzwerkpfad |
| Rate Limit / Kosten | trifft nicht zu | lokale Filter |
| Geheimnisse | trifft nicht zu | keine Schlüssel im Feature |

## Fehler

Keine.

## Neue Tests

| Datei | Fälle | Deckt ab |
|---|---|---|
| `Tests/RedactionEffectivenessTests.swift` | 5 | AK-02, AK-03, AK-09, AK-10 — Wirksamkeit gegen Texterkennung, inkl. Kontrolle |
| `Tests/RedactionStrengthTests.swift` | 6 | AK-09, AK-14 — Stärke folgt der Bereichsgröße und dem Skalieren |

## Nächster Schritt

`/sdd-deploy B04`. Die vier nicht prüfbaren Kriterien betreffen ausschließlich
Mausereignisse und den Fensterlebenszyklus; AK-15 sollte im manuellen Durchgang gezielt
angesehen werden: zensieren, Editor **ohne** Export schließen, Verlaufsordner prüfen.
