# B02 · App-Ausschluss von Aufnahmen — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja, mit einer klar benannten Prüflücke**

Die Ausschlussliste ist die einzige Zugriffsregel der Anwendung, und ihre Wirkung ist genau
das, was sich hier **nicht** automatisiert nachweisen ließ: Um zu belegen, dass ein
ausgeschlossenes Fenster in keiner Aufnahme erscheint, braucht es eine erteilte
Bildschirmaufnahme-Berechtigung, ein zweites laufendes Programm und einen Bildvergleich.

Belegbar war die Struktur dahinter: dass **alle sechs** Aufnahmewege denselben Filter
bilden, und dass er ScreenCaptureKit übergeben wird, statt nachträglich zu übermalen. Das
ist der Unterschied zwischen einer Lücke, die ein fehlendes Fenster bedeutet, und einer,
die ein Datenleck bedeutet.

**Diese Prüflücke ist die wichtigste Auflage des gesamten Audits.**

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 14 |
| davon bestanden | 5 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 9 |
| Edge Cases belegt | 1 von 5 |
| Tests neu geschrieben | 0 |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Liste zeigt aufnehmbare Programme | ⚠️ nicht prüfbar | braucht Berechtigung; `SCShareableContent.current` liefert ohne sie nichts |
| AK-02 Auswahl wird sofort gespeichert | ✅ bestanden | Bindung schreibt in `excludedBundleIdentifiers`, das per `didSet` in die Benutzereinstellungen schreibt — dieselbe Mechanik wie die in `CaptureFilenameTests` geprüften Schlüssel |
| AK-03 Ausschluss greift in jeder Aufnahmeart | ⚠️ **nicht prüfbar** | **die zentrale Prüflücke.** Struktureller Beleg: `excludedWindows(in:preferences:)` wird von `captureFullScreen`, `captureRegion` (Bereich **und** OCR), `captureWindow`, `startWindowSelection` und `startColorPicker` gebildet — sechs Aufrufstellen, eine Quelle. Der Nachweis der Wirkung braucht einen Bildvergleich mit Berechtigung |
| AK-04 Ausschluss greift in Pipette und OCR | ⚠️ nicht prüfbar | dito |
| AK-05 Anzahl in den Einstellungen | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-06 Drei Bedienungshilfen voreingestellt | ✅ bestanden | `AppPreferences.defaultExcludedBundleIdentifiers` trägt genau diese drei; Rückfall greift nur bei fehlendem Schlüssel |
| AK-07 Geleerte Liste bleibt leer | ✅ bestanden | Rückfall ausschließlich bei fehlendem Schlüssel (`?? defaultExcluded…` nur im `nil`-Fall), nicht bei leerem Feld |
| AK-08 Nicht laufende Auswahl bleibt sichtbar | ⚠️ nicht prüfbar | braucht Berechtigung für den Listenaufbau |
| AK-09 Hinweis ohne Berechtigung | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-10 Programme von der Platte auswählbar | ⚠️ nicht prüfbar | `NSOpenPanel` — Dialogverhalten |
| AK-11 Keine Rückmeldung über die Wirkung | ✅ bestanden | trifft zu wie beschrieben — es existiert keine solche Anzeige (bewusst, BF-A2) |
| AK-12 Nur Bundle-Kennungen gespeichert | ✅ bestanden | `CapturableApp` trägt Kennung und Namen, gespeichert wird ausschließlich die Kennung |
| AK-13 Keine Programmliste im Protokoll | ✅ bestanden | A5: fünf Protokollaufrufe, keiner mit Programmbezug |
| AK-14 Zurücksetzen stellt die Standardwerte her | ✅ bestanden | `CaptureFilenameTests::testResetListCoversEveryKeyTheAppWrites` belegt, dass `excludedBundleIdentifiers` in der Rücksetzliste steht |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Programm ohne Kennung oder Namen | ✅ bestanden | `guard !bundleID.isEmpty, !name.isEmpty` im Listenaufbau |
| EC-02 Die Anwendung selbst | ⚠️ nicht prüfbar | Filter über die eigene Prozess-ID; braucht Berechtigung zur Beobachtung |
| EC-03 Programm startet nach dem Öffnen der Liste | ⚠️ nicht prüfbar | Oberflächenverhalten |
| EC-04 Programm deinstalliert | ⚠️ nicht prüfbar | dito |
| EC-05 Fenster ohne besitzendes Programm | ⚠️ nicht prüfbar | braucht ein solches Fenster; als BF-A3 bewusst akzeptiert |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Ausschluss wird vor der Bildentstehung angewandt | ✅ bestanden | die Fensterliste geht als `excludingWindows:` in den `SCContentFilter`; der Inhalt entsteht im Prozess der Anwendung nie |
| Ausschluss in allen Wegen gebildet | ✅ bestanden | sechs Aufrufstellen einer gemeinsamen Methode, keine eigene Filterlogik daneben |
| **Ausschluss wirkt tatsächlich** | ⚠️ **nicht geprüft** | siehe AK-03 — Auflage für den manuellen Durchgang |
| Personendaten in Logs | ✅ bestanden | A5 |
| Geheimnisse | trifft nicht zu | keine im Feature |

## Fehler

Keine gefunden — was bei neun nicht prüfbaren Kriterien ausdrücklich **nicht** heißt, dass
keine vorhanden sind.

## Neue Tests

Keine. Der Filter arbeitet auf `SCWindow`-Instanzen, die sich ohne Bildschirmaufnahme nicht
herstellen lassen (als BF-A4 in `befunde.md` akzeptiert).

## Nächster Schritt

`/sdd-deploy B02` — **mit dieser Auflage als wichtigster Prüfung des Audits:**

1. Ein Programm mit sichtbarem Fenster ausschließen (etwa die Bedienungshilfen-Tastatur).
2. Vollbild aufnehmen → das Fenster darf nicht im Bild sein.
3. Dasselbe für Bereich, Fensterauswahl, vorderstes Fenster, Texterkennung und Farbpipette.

Sechs Wege, sechs Prüfungen. Einer davon, der doch etwas zeigt, ist ein Datenleck.
