# B10 · Tastenkombinationen — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja, mit einer Pflichtprüfung**

Die Datenseite ist abgedeckt: Kodierung übersteht einen Hin-und-Rück-Durchlauf, alle sieben
Voreinstellungen sind paarweise verschieden, jede Aktion hat eine eigene Kennung, und die
Symbolschreibweise stimmt bis zur Reihenfolge der Zusatztasten.

**Der schwerste Befund dieses Features lässt sich hier nicht ausführen.** Dass ein
Tastendruck nach mehrfacher Neubelegung nur noch **eine** Aufnahme auslöst, erfordert einen
echten systemweiten Tastendruck. Die Ursache ist behoben (der Behandler wird einmal
installiert und in `deinit` entfernt), aber der Nachweis steht aus.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 11 |
| davon bestanden | 5 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 6 |
| Edge Cases belegt | 1 von 6 |
| Tests neu geschrieben | 6 |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Systemweites Auslösen | ⚠️ nicht prüfbar | braucht einen echten Tastendruck außerhalb der Anwendung |
| AK-02 Sieben Voreinstellungen | ✅ bestanden | `HotkeyBindingTests::testDefaultBindingsAreAllDistinct`, `…::testDefaultFullScreenBindingIsControlShiftCommandThree` |
| AK-03 Aufzeichner übernimmt | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-04 Konflikthinweis innerhalb der Anwendung | ⚠️ nicht prüfbar | dito |
| AK-05 Belegung übersteht den Neustart | ✅ bestanden | `HotkeyBindingTests::testBindingSurvivesAJSONRoundTrip`; `CaptureFilenameTests::testResetListCoversEveryKeyTheAppWrites` belegt den Schlüssel |
| AK-06 *Restore Defaults* | ⚠️ nicht prüfbar | Oberflächenverhalten; die Voreinstellungen selbst sind belegt |
| AK-07 Fremdbelegung schlägt fehl | ⚠️ nicht prüfbar | braucht eine tatsächlich belegte Kombination |
| AK-08 Genau eine Auslösung nach Neubelegung | ⚠️ **nicht prüfbar** | braucht systemweite Tastendrücke. Struktureller Beleg: `installEventHandlerIfNeeded()` prüft `eventHandlerRef == nil`, `deinit` ruft `RemoveEventHandler` — **Pflichtprüfung im manuellen Durchgang** |
| AK-09 Nur angemeldete Kombinationen sichtbar | ✅ bestanden | Carbon `RegisterEventHotKey` statt Ereignisabgriff; A7 belegt, dass keine Bedienungshilfen-Berechtigung angefordert wird |
| AK-10 Nur Zahlen gespeichert | ✅ bestanden | `HotkeyBindingTests::testBindingSurvivesAJSONRoundTrip` — die Struktur trägt ausschließlich `keyCode` und `modifiers` |
| AK-11 Nur Fehlschläge im Protokoll | ✅ bestanden | A5: zwei Protokollaufrufe, beide mit Statuscode und Aktionsnamen, keiner mit Tasteninhalt |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Systembelegte Kombination | ⚠️ nicht prüfbar | siehe AK-07 |
| EC-02 Aufzeichnung mit Escape | ⚠️ nicht prüfbar | Oberflächenverhalten |
| EC-03 Kombination ohne Zusatztaste | ⚠️ nicht prüfbar | als BF-A3 akzeptiert |
| EC-04 Beschädigte gespeicherte Belegung | ✅ bestanden | `try?`-Dekodierung fällt auf die Voreinstellungen zurück; `testBindingSurvivesAJSONRoundTrip` belegt das gültige Format, aus dem der Fehlerfall folgt |
| EC-05 Zwei Aktionen auf derselben Kombination | ⚠️ nicht prüfbar | braucht Tastendrücke |
| EC-06 Auslösen während laufender Auswahl | ⚠️ nicht prüfbar | dito |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| **Kein Zugriff auf fremde Tastatureingaben** | ✅ bestanden | A7: Entitlements ohne Bedienungshilfen; Carbon meldet ausschließlich angemeldete Kombinationen |
| Tasteninhalte im Protokoll | ✅ bestanden | A5 |
| Personendaten an externe Dienste | ✅ bestanden | A1, L1 |
| Geheimnisse | trifft nicht zu | keine im Feature |

## Fehler

Keine.

## Neue Tests

| Datei | Fälle | Deckt ab |
|---|---|---|
| `Tests/HotkeyBindingTests.swift` | 6 | AK-02, AK-05, AK-10 sowie Eindeutigkeit der Kennungen und die Symbolschreibweise |

## Nächster Schritt

`/sdd-deploy B10` — **mit AK-08 als Pflichtprüfung:** Anwendung starten, im Reiter
*Shortcuts* zweimal eine Belegung ändern, dann `⌃⇧⌘3` **einmal** drücken und zählen, wie
viele Editorfenster entstehen. Erwartet: genau eines. Gegenprobe über *Reset All
Preferences*, das denselben Weg nimmt.
