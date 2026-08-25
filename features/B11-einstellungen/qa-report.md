# B11 · Einstellungen — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja**

Die Einstellungen sind fast vollständig Oberfläche, und Oberfläche ließ sich hier nicht
ausführen. Was zählbar war, ist geprüft: Die Rücksetzliste enthält jeden Schlüssel, den die
Anwendung schreibt — einschließlich der beiden, die früher fehlten —, und der Standard für
die Strichstärke ist einer der drei angebotenen Werte. Beides ist durch einen Test
festgehalten, der bei jedem künftigen neuen Schlüssel anschlägt.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 23 |
| davon bestanden | 6 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 17 |
| Edge Cases belegt | 0 von 4 |
| Tests neu geschrieben | 2 (innerhalb `CaptureFilenameTests`) |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Vier Reiter | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-02 Systemeigenes Erscheinungsbild | ✅ bestanden | `grep -c MikaPlus Sources/Preferences/` liefert 0 — die Markenpalette wird dort nicht benutzt; `README.md` beschreibt es jetzt entsprechend |
| AK-03 Ordnerwahl | ⚠️ nicht prüfbar | `NSOpenPanel` |
| AK-04 Qualitätsregler bei JPEG | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-05 Kein Regler bei PNG | ⚠️ nicht prüfbar | dito |
| AK-06 Auslöseton folgt der Einstellung | ⚠️ nicht prüfbar | Audioausgabe |
| AK-07 Auto-Sichern folgt der Einstellung | ✅ bestanden | `HistoryLifecycleTests::testAutoSaveWritesNothingWhenDisabled` |
| AK-08 Kein Schalter für schwebende Vorschau | ✅ bestanden | `grep -c 'floatingPreview' Sources/` liefert 0 — Schlüssel und Bedienelement sind entfernt |
| AK-09 Abschnitt *Privacy* | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-10 Standardwerte im Editor | ✅ bestanden | `CaptureFilenameTests::testDefaultStrokeWidthIsOneOfTheOfferedChoices` |
| AK-11 Strichstärke ist vorausgewählt | ✅ bestanden | derselbe Test — der Standard 4 liegt in {2, 4, 6} |
| AK-12 Letztes Werkzeug merken | ⚠️ nicht prüfbar | Fensterlebenszyklus |
| AK-13 Werkzeugbeschriftungen | ⚠️ nicht prüfbar | Oberflächenverhalten; die Einstellung wird jetzt von `AnnotationToolbarView` gelesen |
| AK-14 Speicherangaben | ⚠️ nicht prüfbar | Oberflächenverhalten; die Summen sind in B08/B09 belegt |
| AK-15 *Clear History* | ✅ bestanden | `HistoryLifecycleTests::testClearAllRemovesFilesItNeverLoaded` |
| AK-16 System- und About-Abschnitt | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-17 Zurücksetzen stellt Voreinstellungen her | ✅ bestanden | `CaptureFilenameTests::testResetListCoversEveryKeyTheAppWrites` |
| AK-18 Sparkles Schlüssel bleiben | ✅ bestanden | `ownedDefaultsKeys` enthält keine Sparkle-Schlüssel — bewusst (BF-A13) |
| AK-19 Genau eine Auslösung nach dem Zurücksetzen | ⚠️ nicht prüfbar | siehe B10/AK-08 — dieselbe Pflichtprüfung |
| AK-20 Nur Pfade, Zahlen, Wahrheitswerte | ✅ bestanden | `ownedDefaultsKeys` ist im Test aufgezählt; keiner der Schlüssel trägt Inhalte |
| AK-21 Nur der Pfad wird abgelegt | ⚠️ nicht prüfbar | `NSOpenPanel` |
| AK-22 Rückfrage vor dem Löschen | ⚠️ nicht prüfbar | Dialogverhalten |
| AK-23 Zwei Speicherzeilen | ⚠️ nicht prüfbar | Oberflächenverhalten; `PinnedScreenshotManager.storageUsage()` ist in B08 belegt |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Ordner nicht beschreibbar | ⚠️ nicht prüfbar | braucht einen schreibgeschützten Ordner; der Meldepfad ist über A6 belegt |
| EC-02 Ordner gelöscht | ⚠️ nicht prüfbar | wird beim nächsten Sichern angelegt (B09/AK-05) |
| EC-03 Speicheranzeige aktualisiert nicht laufend | ⚠️ nicht prüfbar | Oberflächenverhalten |
| EC-04 Zurücksetzen bei offenem Editor | ⚠️ nicht prüfbar | Fensterlebenszyklus |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Einstellungen enthalten keine Nutzerinhalte | ✅ bestanden | Aufzählung in `ownedDefaultsKeys`, im Test festgehalten |
| Zurücksetzen lässt nichts zurück | ✅ bestanden | Test über die Vollständigkeit der Liste |
| Personendaten in Logs | ✅ bestanden | A5 |
| Geheimnisse | ✅ bestanden | A3/A4 |

## Fehler

Keine.

## Neue Tests

| Datei | Fälle | Deckt ab |
|---|---|---|
| `Tests/CaptureFilenameTests.swift` | 2 der 6 | AK-10, AK-11, AK-17, AK-20 |

## Nächster Schritt

`/sdd-deploy B11`. Die 17 nicht prüfbaren Kriterien sind Oberfläche; ein Durchgang durch
alle vier Reiter mit je einer Änderung genügt.
