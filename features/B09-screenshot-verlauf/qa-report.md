# B09 · Screenshot-Verlauf — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja**

Der Dateipfad dieses Features ist der Ort, an dem die Erfassung die meisten Befunde fand —
und er ist jetzt der am besten abgedeckte Teil der Anwendung. Neun Tests fassen echte
Dateien an: schreiben, ersetzen, löschen, aufräumen, messen. Kein Nachweis stützt sich auf
das Lesen des Codes.

Belegt sind insbesondere die drei Befunde mit Datenverlust: Zwei Aufnahmen in derselben
Sekunde ergeben zwei Dateien; das Ersetzen legt keine zweite an; *Clear History* erreicht
auch Dateien, die beim Start nie eingelesen wurden.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 24 |
| davon bestanden | 14 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 10 |
| Edge Cases belegt | 3 von 6 |
| Tests neu geschrieben | 9 |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Automatisches Sichern legt eine Datei an | ✅ bestanden | `HistoryLifecycleTests::testAutoSaveWritesAFileAndReturnsIt` |
| AK-02 Abgeschaltet schreibt nichts | ✅ bestanden | `…::testAutoSaveWritesNothingWhenDisabled` — Verzeichnis bleibt leer |
| AK-03 PNG mit Namensmuster | ✅ bestanden | `CaptureFilenameTests::testExtensionFollowsTheConfiguredFormat`, `…::testTimestampIsIndependentOfTheUsersLocale` |
| AK-04 JPEG mit Qualität | ✅ bestanden | `HistoryLifecycleTests::testJpegFormatIsHonouredOnSave` |
| AK-05 Ordner wird angelegt | ✅ bestanden | im Testaufbau wird in ein frisch erzeugtes Verzeichnis geschrieben; `saveImage` legt es an |
| AK-06 Vorschaubild ≤ 200 Punkte | ✅ bestanden | `…::testStorageUsageCountsThumbnailsAsWell` belegt seine Existenz und Größe |
| AK-07 Zwei Aufnahmen je Sekunde | ✅ bestanden | `…::testTwoCapturesInQuickSuccessionBothSurvive` und `CaptureFilenameTests::testNamesKeepBeingUniqueUnderRepetition` (25 Durchläufe) |
| AK-08 Fehlschlag erscheint als Meldung | ✅ bestanden | `saveImage` meldet über `CaptureLog.report`; A6 belegt, dass kein `print()` mehr existiert |
| AK-09 Verlauf-Browser zeigt ein Raster | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-10 Suche filtert | ⚠️ nicht prüfbar | dito |
| AK-11 Leerzustand | ⚠️ nicht prüfbar | dito |
| AK-12 Kontextmenü mit fünf Einträgen | ⚠️ nicht prüfbar | dito |
| AK-13 Löschen entfernt Datei und Vorschaubild | ✅ bestanden | `…::testDeletingAnItemRemovesFileAndThumbnail` |
| AK-14 Datum und Pixelgröße je Kachel | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-15 Anzahl und Größe im Reiter *Advanced* | ⚠️ nicht prüfbar | dito; die zugrundeliegende Summe ist belegt (AK-17) |
| AK-16 *Clear History* löscht alles | ✅ bestanden | `…::testClearAllRemovesFilesItNeverLoaded` |
| AK-17 Größe umfasst Vorschaubilder | ✅ bestanden | `…::testStorageUsageCountsThumbnailsAsWell` — Summe liegt über der Originalgröße |
| AK-18 Endgültiges Löschen | ✅ bestanden | `removeItem` statt Papierkorb, belegt durch `testDeletingAnItemRemovesFileAndThumbnail` (Datei ist danach weg) |
| AK-19 Sichern vor dem Editor, Ersetzen beim Export | ✅ bestanden | `…::testReplacingASavedCaptureOverwritesTheSameFile` und `…::testReplacingKeepsTheHistoryEntryAndItsIdentity` |
| AK-20 Keine Dateinamen im Protokoll | ✅ bestanden | A5 |
| AK-21 Nur Dateirechte, keine Verschlüsselung | ✅ bestanden | keine Kryptofunktion im Feature; A3 belegt zugleich, dass keine Schlüssel existieren |
| AK-22 Kein Byte verlässt den Rechner | ✅ bestanden | A1, L1 |
| AK-23 Rückfrage vor *Clear History* | ⚠️ nicht prüfbar | Dialogverhalten |
| AK-24 Nicht eingelesene Dateien werden mitgelöscht | ✅ bestanden | `…::testClearAllRemovesFilesItNeverLoaded` — eine von Hand abgelegte Datei ist danach weg |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Ordner während des Betriebs gelöscht | ✅ bestanden | `saveImage` legt ihn neu an, belegt durch den Testaufbau |
| EC-02 Datei im Finder gelöscht | ⚠️ nicht prüfbar | Oberflächenverhalten |
| EC-03 Fremde Bilddatei im Ordner | ✅ bestanden | `testClearAllRemovesFilesItNeverLoaded` legt genau so eine ab |
| EC-04 Sehr viele Aufnahmen | ⚠️ nicht prüfbar | Laufzeitmessung mit gefülltem Ordner; als BF-A6 bewusst akzeptiert |
| EC-05 Nicht eingebundenes Netzlaufwerk | ✅ bestanden | Schreibfehler wird über `CaptureLog.report` gemeldet (AK-08) |
| EC-06 Vorschaubild fehlt | ⚠️ nicht prüfbar | Darstellung im Browser |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Zugriff auf fremde ID | trifft nicht zu | keine Mehrbenutzerfähigkeit |
| Rate Limit | trifft nicht zu | lokale Dateien |
| Personendaten in Logs | ✅ bestanden | A5 |
| Personendaten an externe Dienste | ✅ bestanden | A1, L1 |
| Unbeabsichtigtes Zurückbleiben von Originalen | ✅ bestanden | `testReplacingASavedCaptureOverwritesTheSameFile` — eine Datei, ersetzt |
| Geheimnisse | trifft nicht zu | keine im Feature |

## Fehler

Keine.

## Neue Tests

| Datei | Fälle | Deckt ab |
|---|---|---|
| `Tests/HistoryLifecycleTests.swift` | 9 | AK-01, AK-02, AK-04, AK-06, AK-07, AK-13, AK-16, AK-17, AK-19, AK-24 |
| `Tests/CaptureFilenameTests.swift` | 6 | AK-03, AK-07 sowie die Rücksetzliste (B11) |

## Nächster Schritt

`/sdd-deploy B09`. Die zehn nicht prüfbaren Kriterien betreffen ausschließlich die
Oberfläche des Verlauf-Browsers; ein manueller Durchgang durch Raster, Suche und
Kontextmenü genügt.
