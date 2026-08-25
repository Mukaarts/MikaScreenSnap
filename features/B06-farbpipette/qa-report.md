# B06 · Farbpipette — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja**

Die Farbumrechnung — der Teil, der stillschweigend falsche Werte liefern kann — ist durch
fünf Tests abgedeckt, einschließlich eines Hin-und-Rück-Durchlaufs über die Markenfarbe und
der Prüfung auf führende Nullen im Hex-Wert.

Der auffälligste Befund der Erfassung (eine Palette, die befüllt und nirgends angezeigt
wurde) ist behoben; Verlauf und Palette sind jetzt beide sichtbar und leerbar, und beide
werden vom Zurücksetzen erfasst — Letzteres ist getestet.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 17 |
| davon bestanden | 6 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 11 |
| Edge Cases belegt | 0 von 5 |
| Tests neu geschrieben | 5 |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Lupe mit Fadenkreuz und Werten | ⚠️ nicht prüfbar | braucht Berechtigung und Zeigerbewegung |
| AK-02 Klick kopiert und meldet | ⚠️ nicht prüfbar | Mausereignis |
| AK-03 Escape bricht ab | ⚠️ nicht prüfbar | dito |
| AK-04 Farbverlauf im Menü | ⚠️ nicht prüfbar | Menüdarstellung |
| AK-05 Klick auf einen Eintrag kopiert | ⚠️ nicht prüfbar | dito |
| AK-06 Höchstens zehn Farben | ✅ bestanden | Obergrenze in `addColor` (`prefix(10)`); die Werte werden über die in `ColorConversionTests` geprüfte Umrechnung gebildet |
| AK-07 Leerzustand | ⚠️ nicht prüfbar | Menüdarstellung |
| AK-08 Farbe des Pixels unter dem Zeiger | ⚠️ nicht prüfbar | braucht Berechtigung; die Umrechnung Punkt → Farbe ist in `ColorConversionTests` abgedeckt |
| AK-09 Lupe zeigt den Stand vom Start | ⚠️ nicht prüfbar | Laufzeitverhalten; als BF-A5 bewusst akzeptiert |
| AK-10 Palette im Menü sichtbar | ✅ bestanden | Untermenü *Colour Palette* liest `colorHistory.palette` — die Eigenschaft hat jetzt einen Leser (Gegenprobe zum Erfassungsbefund) |
| AK-11 Ausgeschlossene Programme nicht im Schnappschuss | ⚠️ nicht prüfbar | siehe B02/AK-03 |
| AK-12 Eigene Fenster nicht im Schnappschuss | ⚠️ nicht prüfbar | braucht Berechtigung |
| AK-13 Speicher wird freigegeben | ⚠️ nicht prüfbar | Speichermessung zur Laufzeit |
| AK-14 Keine Bildinhalte im Protokoll | ✅ bestanden | A5 |
| AK-15 Zurücksetzen leert Verlauf und Palette | ✅ bestanden | `CaptureFilenameTests::testResetListCoversEveryKeyTheAppWrites` — beide Schlüssel stehen in `ownedDefaultsKeys` |
| AK-16 Hex ohne Vertraulichkeitskennzeichnung | ✅ bestanden | `copyToClipboard(text:concealed: false)` an beiden Aufrufstellen |
| AK-17 Verlauf und Palette leerbar | ✅ bestanden | `clearHistory()` und `clearPalette()` existieren und werden vom Menü aufgerufen |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Klick außerhalb der Schnappschüsse | ⚠️ nicht prüfbar | braucht Berechtigung |
| EC-02 Display während der Pipette abgezogen | ⚠️ nicht prüfbar | Hardwarewechsel |
| EC-03 Fehlende Berechtigung | ⚠️ nicht prüfbar | Oberflächenverhalten |
| EC-04 Viele große Displays | ⚠️ nicht prüfbar | Speichermessung |
| EC-05 Farbe zweimal abgegriffen | ⚠️ nicht prüfbar | `addColor` entfernt Doppelte vor dem Voranstellen — Mausereignis nötig |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Bildschirmkopie im Speicher | ⚠️ nicht geprüft | braucht Speichermessung; als BF-A3 akzeptiert |
| Personendaten in Logs | ✅ bestanden | A5 |
| Personendaten an externe Dienste | ✅ bestanden | A1, L1 |
| Farbwerte überleben das Zurücksetzen | ✅ bestanden | Test über `ownedDefaultsKeys` |
| Geheimnisse | trifft nicht zu | keine im Feature |

## Fehler

Keine.

## Neue Tests

| Datei | Fälle | Deckt ab |
|---|---|---|
| `Tests/ColorConversionTests.swift` | 5 | Hex, RGB, HSL, führende Nullen, Hin-und-Rück über die Markenfarbe |

## Nächster Schritt

`/sdd-deploy B06`. Für AK-13 empfiehlt sich im manuellen Durchgang ein Blick auf den
Speicherverbrauch vor, während und nach der Pipette.
