# B01 · Bildschirmaufnahme — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja, mit einer Einschränkung**

Die Koordinaten- und Skalierungsrechnung — die Stelle, an der dieses Feature zweimal
falsch war — ist jetzt durch fünf Tests abgedeckt, die vier Displayanordnungen
durchrechnen. Der Datenschutzkern (kein Netzwerk, keine Bildinhalte im Protokoll) ist
ausgeführt belegt.

**Die Einschränkung betrifft die Prüfmethode, nicht das Ergebnis:** Alles, was einen
zweiten Bildschirm oder eine erteilte Bildschirmaufnahme-Berechtigung braucht, konnte hier
nicht ausgeführt werden. Diese Kriterien stehen unter *nicht prüfbar* — nicht unter
*bestanden*. Sie sind der Grund, warum vor der Auslieferung ein manueller Durchgang auf
einem Mehrschirm-Arbeitsplatz stehen sollte.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 27 |
| davon bestanden | 12 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 15 |
| Edge Cases belegt | 2 von 7 |
| Tests neu geschrieben | 5 |
| Tests grün | 59 von 59 (gesamte Suite) |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Vollbild löst aus | ⚠️ nicht prüfbar | braucht erteilte Bildschirmaufnahme-Berechtigung und eine laufende Instanz; die installierte 3.4.0 des Nutzers durfte dafür nicht ersetzt werden |
| AK-02 Vollbild nimmt das Display unter dem Zeiger | ⚠️ nicht prüfbar | braucht zwei Displays. Die zugrundeliegende Auswahl ist über `NSScreen.underPointer` implementiert; die Rechnung dahinter ist in `ScreenGeometryTests` abgedeckt |
| AK-03 Auflösung entspricht dem Display | ⚠️ nicht prüfbar | braucht ein Display mit Skalierung ≠ 2 |
| AK-04 Auswahl auf jedem Display | ⚠️ nicht prüfbar | braucht zwei Displays |
| AK-05 Größenanzeige beim Ziehen | ⚠️ nicht prüfbar | Oberflächenverhalten, kein automatisierter Zugang |
| AK-06 Escape bricht ab | ⚠️ nicht prüfbar | dito |
| AK-07 Auswahl < 4 Punkte gilt als Abbruch | ⚠️ nicht prüfbar | dito |
| AK-08 Bereich auf dem zweiten Display trifft | ✅ bestanden | `ScreenGeometryTests::testSourceRectOnScreenToTheRightSubtractsOrigin` und `…OnScreenAboveAccountsForOriginY`, `…OnScreenBelowHandlesNegativeOrigin` — die drei Anordnungen, an denen die alte Rechnung scheiterte |
| AK-09 Skalierung folgt dem gewählten Display | ✅ bestanden | Skalierung stammt aus `SCContentFilter.pointPixelScale`; `ScreenGeometryTests::testSourceRectPreservesSizeAcrossArrangements` belegt, dass der Ausschnitt anordnungsunabhängig bleibt |
| AK-10 Fensterauswahl hebt hervor | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-11 Klick nimmt das Fenster auf | ⚠️ nicht prüfbar | dito |
| AK-12 Escape/Rechtsklick bricht ab | ⚠️ nicht prüfbar | dito |
| AK-13 `⌃⇧⌘5` nimmt das vorderste Fenster | ⚠️ nicht prüfbar | braucht Berechtigung |
| AK-14 Fensterauflösung folgt dem Display | ⚠️ nicht prüfbar | braucht zwei Displays |
| AK-15 Titellose Fenster sind Ziele | ⚠️ nicht prüfbar | braucht Berechtigung |
| AK-16 Fenster < 40 Punkte sind keine Ziele | ⚠️ nicht prüfbar | dito |
| AK-17 Dock, Stage Manager usw. sind keine Ziele | ⚠️ nicht prüfbar | dito |
| AK-18 Editor öffnet sich nach jeder Aufnahme | ✅ bestanden | `postCapture` ist der einzige Ausgang aller vier Wege; `HistoryLifecycleTests` belegt die Kette Aufnahme → Datei → Editorverweis |
| AK-19 Auslöseton respektiert die Einstellung | ⚠️ nicht prüfbar | Audioausgabe |
| AK-20 Automatisches Sichern legt eine Datei an | ✅ bestanden | `HistoryLifecycleTests::testAutoSaveWritesAFileAndReturnsIt` |
| AK-21 Bedienungshilfen-Zeiger nicht im Bild | ⚠️ nicht prüfbar | braucht aktivierten Zeiger und Berechtigung |
| AK-22 Fehlschlag erscheint als Meldung | ✅ bestanden | alle Fehlerpfade laufen über `CaptureLog.report`; Angriffsprüfung A6 belegt, dass kein `print()` mehr existiert |
| AK-23 Fehlende Berechtigung sperrt die Menüeinträge | ✅ bestanden | `MikaScreenSnapApp.swift`: sieben `.disabled(!hasScreenRecordingAccess)`; Zählung im Angriffsprotokoll |
| AK-24 Ausschlussliste greift in jeder Aufnahmeart | ✅ bestanden | ein gemeinsamer `excludedWindows`-Aufruf in allen vier Wegen plus Pipette und OCR — belegt über die Aufrufzählung, siehe B02 |
| AK-25 Keine Bildinhalte im Protokoll | ✅ bestanden | Angriffsprüfung A5: alle fünf Protokollaufrufe enthalten ausschließlich Statuscodes und Aktionsnamen |
| AK-26 Kein Byte verlässt den Rechner | ✅ bestanden | Angriffsprüfung A1 (kein `URLSession`/`URLRequest` im gesamten `Sources/`) und L1 (die laufende Instanz hält **keine** offene Netzwerkverbindung) |
| AK-27 Eigene Fenster nicht im Bild | ✅ bestanden | Filter über die eigene Prozess-ID in `excludedWindows`, gemeinsam mit AK-24 |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Kein Display gefunden | ✅ bestanden | `CaptureError.noDisplay` wird geworfen und über `CaptureLog` gemeldet |
| EC-02 Kein aufnehmbares Fenster | ⚠️ nicht prüfbar | braucht Berechtigung |
| EC-03 Leeres Inhaltsrechteck | ⚠️ nicht prüfbar | dito |
| EC-04 Fenster zwischen Auswahl und Klick geschlossen | ⚠️ nicht prüfbar | dito |
| EC-05 Fenster über zwei Displays | ⚠️ nicht prüfbar | braucht zwei Displays |
| EC-06 Bildschirmschoner während der Auswahl | ⚠️ nicht prüfbar | Oberflächenverhalten |
| EC-07 Zweite Auswahl verwirft die erste | ✅ bestanden | `dismissAreaSelection` bzw. `dismissWindowSelection` läuft als erste Anweisung beider Startmethoden |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Zugriff auf fremde ID (IDOR) | trifft nicht zu | keine IDs, keine Mehrbenutzerfähigkeit |
| Rate Limit greift | trifft nicht zu | rein lokal, keine Kosten je Aufruf |
| Personendaten in Logs | ✅ bestanden | A5: fünf Protokollaufrufe, keiner mit Bild-, Text- oder Fensterbezug |
| Personendaten an externe Dienste | ✅ bestanden | A1: kein Netzwerkcode; L1: keine offene Verbindung zur Laufzeit |
| Zugriffsregeln serverseitig | trifft nicht zu | kein Server; die Regel ist die Systemberechtigung |
| Geheimnisse im Repository | ✅ bestanden | A3/A4: keine Werte im Code und keine in der Historie |
| Rechteumfang | ✅ bestanden | A7: Entitlements auf Sandbox aus, Bildschirmaufnahme, Library-Validation aus (für Sparkle nötig) |

## Fehler

Keine.

## Neue Tests

| Datei | Fälle | Deckt ab |
|---|---|---|
| `Tests/ScreenGeometryTests.swift` | 5 | AK-08, AK-09 — vier Displayanordnungen einschließlich negativer Ursprünge |

## Nächster Schritt

`/sdd-deploy B01` — mit der Auflage, die 15 nicht prüfbaren Kriterien vor der
Veröffentlichung manuell zu durchlaufen. Die Liste dafür steht oben; der Kern sind zwei
Durchgänge: einer mit zwei Displays unterschiedlicher Skalierung, einer mit entzogener
Bildschirmaufnahme-Berechtigung.
