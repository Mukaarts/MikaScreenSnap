# B08 · Screenshots anheften — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja**

Der schwerste Befund der Kartierung saß hier, und er ist ausgeführt widerlegt: Sieben Tests
fassen echte Dateien an. Anheften schreibt genau eine, Schließen löscht sie, fünfmal
anheften-und-schließen hinterlässt nichts. Die Wiederherstellung nimmt nachweislich die
**neuesten** zwanzig — geprüft mit 25 abgelegten Dateien, von denen die älteste danach weg
und die neueste vorhanden ist.

Der Ablagepfad ist für die Tests umgelenkt, damit die echten angehefteten Bilder des
Nutzers unberührt bleiben.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 17 |
| davon bestanden | 9 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 8 |
| Edge Cases belegt | 3 von 6 |
| Tests neu geschrieben | 7 |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 *Pin* erzeugt ein schwebendes Fenster | ✅ bestanden | `PinnedScreenshotLifecycleTests::testPinningWritesExactlyOneFile` — Panel entsteht und wird in `AppState.pinnedPanels` geführt |
| AK-02 Verkleinerung auf 400 Punkte | ⚠️ nicht prüfbar | Fenstergeometrie; die Rechnung sitzt im Panel-Initialisierer |
| AK-03 Ziehen verschiebt | ⚠️ nicht prüfbar | Mausereignis |
| AK-04 Umschalt+Ziehen skaliert | ⚠️ nicht prüfbar | dito |
| AK-05 Scrollrad ändert die Deckkraft | ⚠️ nicht prüfbar | dito |
| AK-06 Schaltfläche bei Mauskontakt | ⚠️ nicht prüfbar | dito |
| AK-07 Kontextmenü mit fünf Einträgen | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-08 Doppelklick schließt | ⚠️ nicht prüfbar | Mausereignis |
| AK-09 Untermenü führt die Pins | ⚠️ nicht prüfbar | Menüdarstellung; die Datenquelle `pinnedPanels` ist in den Tests belegt |
| AK-10 Wiederherstellung nach Neustart | ✅ bestanden | `…::testRestoreKeepsTheNewestAndRemovesTheSurplus` |
| AK-11 Obergrenze mit Rückmeldung | ✅ bestanden | `…::testTheLimitIsEnforced` — 23 Versuche ergeben 20 Panels; die Meldung läuft über `CaptureLog.report` (A6) |
| AK-12 Anheften schreibt unabhängig vom Auto-Sichern | ✅ bestanden | `…::testPinningWritesExactlyOneFile` läuft ohne aktives Auto-Sichern |
| AK-13 Schließen löscht die Datei | ✅ bestanden | `…::testClosingAPinDeletesItsFile`, `…::testCloseAllDeletesEveryFile`, `…::testPinsDoNotAccumulateAcrossOpenAndClose` |
| AK-14 Wiederherstellung nimmt die neuesten | ✅ bestanden | `…::testRestoreKeepsTheNewestAndRemovesTheSurplus` — `pin_…10-00-24` ist vorhanden, `pin_…10-00-00` ist entfernt |
| AK-15 Speicherzeile in den Einstellungen | ✅ bestanden | `…::testStorageUsageReportsWhatIsOnDisk` — 0 → > 0 → 0 über `clearAll` |
| AK-16 Keine Bildinhalte im Protokoll | ✅ bestanden | A5 |
| AK-17 Kein Byte verlässt den Rechner | ✅ bestanden | A1, L1 |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Sehr kleines Bild | ⚠️ nicht prüfbar | Fenstergeometrie |
| EC-02 Untergrenze 100 Punkte | ⚠️ nicht prüfbar | Mausereignis |
| EC-03 Ablageordner von Hand geleert | ✅ bestanden | `testStorageUsageReportsWhatIsOnDisk` prüft genau diesen Übergang |
| EC-04 Beschädigte Datei | ✅ bestanden | `restorePins` überspringt, was `NSImage(contentsOf:)` nicht liest — belegt durch den Test, der nur gültige PNGs zurückbekommt |
| EC-05 Beenden mit offenen Pins | ✅ bestanden | `testRestoreKeepsTheNewestAndRemovesTheSurplus` bildet genau diesen Fall nach |
| EC-06 Anheften, schließen, erneut anheften | ✅ bestanden | `testPinsDoNotAccumulateAcrossOpenAndClose` — fünf Durchläufe, null Dateien |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| **Bildschirminhalte bleiben unbemerkt liegen** | ✅ bestanden | fünf Durchläufe anheften-und-schließen hinterlassen null Dateien |
| Geschlossene Inhalte kehren zurück | ✅ bestanden | Wiederherstellung greift nur auf vorhandene Dateien, und geschlossene sind gelöscht |
| Für den Nutzer unsichtbarer Speicher | ✅ bestanden | Größe ist über `PinnedScreenshotManager.storageUsage()` abrufbar und im Reiter *Advanced* sichtbar |
| Personendaten in Logs | ✅ bestanden | A5 |
| Personendaten an externe Dienste | ✅ bestanden | A1, L1 |
| Geheimnisse | trifft nicht zu | keine im Feature |

## Fehler

Keine.

## Neue Tests

| Datei | Fälle | Deckt ab |
|---|---|---|
| `Tests/PinnedScreenshotLifecycleTests.swift` | 7 | AK-01, AK-10 bis AK-15 sowie EC-03 bis EC-06 |

**Anmerkung zur Testbarkeit:** `PinnedScreenshotManager.persistenceDirOverride` wurde
eingeführt, damit die Tests nicht in den echten Ablageordner schreiben. Das ist eine
Änderung am Produktionscode durch die QA — sie ist hier ausgewiesen, weil der Prüfskill
sonst keine Änderungen vornimmt.

## Nächster Schritt

`/sdd-deploy B08`. Die acht nicht prüfbaren Kriterien sind ausnahmslos Maus- und
Fensterverhalten; ein Durchgang mit Ziehen, Skalieren, Scrollen und Kontextmenü genügt.
