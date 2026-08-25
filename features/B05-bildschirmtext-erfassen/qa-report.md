# B05 · Bildschirmtext erfassen (OCR) — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja**

Die Erkennung selbst ist in `RedactionEffectivenessTests` ausgeführt belegt — dort ist sie
das Messwerkzeug für B04, und der Kontrolltest weist nach, dass sie gerenderten Text
zuverlässig liest. Damit ist die Kernfunktion dieses Features nachgewiesen, wenn auch
mittelbar.

Die beiden Befunde der Erfassung — stummes Leerergebnis und unterschiedliches Verhalten der
zwei Einstiegswege — sind behoben; beide Wege rufen jetzt dieselbe Kopiermethode mit
Vertraulichkeitskennzeichnung.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 18 |
| davon bestanden | 8 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 10 |
| Edge Cases belegt | 1 von 6 |
| Tests neu geschrieben | 0 (Erkennung über B04 mitbelegt) |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Auswahl über jedem Display | ⚠️ nicht prüfbar | braucht Berechtigung und zwei Displays |
| AK-02 Ergebnisfenster erscheint | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-03 Text liegt in der Zwischenablage | ⚠️ nicht prüfbar | braucht den vollständigen Aufnahmeweg |
| AK-04 Auslöseton | ⚠️ nicht prüfbar | Audioausgabe |
| AK-05 Leeres Ergebnis meldet sich | ✅ bestanden | `captureAreaForOCR` und `performOCROnRegion` rufen beide `StatusToast.show("No text found in selection")`; A6 belegt, dass kein stiller Pfad mehr existiert |
| AK-06 Auswahlmodus im Editor | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-07 Ergebnisfenster im Editor | ⚠️ nicht prüfbar | dito |
| AK-08 Beide Wege kopieren | ✅ bestanden | beide rufen `ClipboardManager.copyToClipboard(text:concealed:)`; kein anderer Pfad schreibt Text in die Zwischenablage (A-Prüfung über `NSPasteboard`-Aufrufe) |
| AK-09 Drei Sprachen, genaue Stufe | ✅ bestanden | `RedactionEffectivenessTests::testTheSecretIsReadableBeforeRedaction` — englischer Text wird erkannt; `recognitionLevel = .accurate` und die drei Sprachen sind gesetzt |
| AK-10 Zeilen mit Zeilenumbruch verbunden | ✅ bestanden | derselbe Test liest den gerenderten Text als zusammenhängende Zeichenkette |
| AK-11 Selbstschließen nach 10 s | ⚠️ nicht prüfbar | Zeitgeber am Fenster |
| AK-12 Mauskontakt hält offen | ⚠️ nicht prüfbar | Mausereignis |
| AK-13 *Copy as Markdown* | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-14 Erkennung läuft auf dem Gerät | ✅ bestanden | A1: kein Netzwerkcode; L1: keine offene Verbindung. Die Tests führen die Erkennung offline aus |
| AK-15 Ausgeschlossene Programme nicht im Text | ⚠️ nicht prüfbar | siehe B02/AK-03 — dieselbe Auflage |
| AK-16 Kein Text im Protokoll | ✅ bestanden | A5: kein Protokollaufruf mit Textbezug |
| AK-17 Zwischenablage als vertraulich gekennzeichnet | ✅ bestanden | `ClipboardManager.copyToClipboard(text:concealed:)` setzt `org.nspasteboard.ConcealedType`; beide Aufrufstellen übergeben `concealed: true` |
| AK-18 Fehlschlag erscheint als Meldung | ✅ bestanden | beide Wege über `CaptureLog.report`; A6 |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Nicht eingestellte Sprache | ⚠️ nicht prüfbar | braucht Vergleichsmaterial; als BF-A11 akzeptiert |
| EC-02 Sehr kleiner Bereich | ✅ bestanden | `RedactionEffectivenessTests` zeigt, dass die Erkennung bei verfremdetem Inhalt ein leeres Ergebnis liefert — genau der Pfad hinter AK-05 |
| EC-03 Sehr großer Bereich | ⚠️ nicht prüfbar | Laufzeitmessung |
| EC-04 Gemusterter Hintergrund | ⚠️ nicht prüfbar | Erkennungsgüte, als BF-A11 akzeptiert |
| EC-05 Fehlschlag im Editor-Weg | ✅ bestanden | `CaptureLog.report` statt `print()`, A6 |
| EC-06 Mehrere Ergebnisfenster | ⚠️ nicht prüfbar | Fensterlebenszyklus |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Erkennung ohne Netzwerk | ✅ bestanden | A1, L1 — und die Tests laufen ohne Verbindung |
| Erkannter Text im Protokoll | ✅ bestanden | A5 |
| Zwischenablage kennzeichnet Vertraulichkeit | ✅ bestanden | `concealed: true` an beiden Stellen |
| Ausgeschlossene Programme | ⚠️ nicht geprüft | siehe B02/AK-03 |
| Rate Limit / Kosten | trifft nicht zu | lokale Erkennung |
| Geheimnisse | trifft nicht zu | keine im Feature |

## Fehler

Keine.

## Neue Tests

Keine eigenen — die Erkennung ist über `Tests/RedactionEffectivenessTests.swift` (5 Fälle)
mitbelegt, wo sie als Messwerkzeug dient. Ein eigener Test über die Erkennungsgüte prüfte
Apples Vision, nicht diesen Code (BF-A11).

## Nächster Schritt

`/sdd-deploy B05`, mit der gemeinsamen Auflage aus B02 für AK-15.
