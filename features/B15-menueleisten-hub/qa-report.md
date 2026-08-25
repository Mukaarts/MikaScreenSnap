# B15 · Menüleisten-Hub & Programminfo — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja**

Der Menüleisten-Hub ist fast vollständig Darstellung, aber seine beiden Grundzusagen ließen
sich an der laufenden Instanz messen: Die Anwendung läuft ohne Dock-Symbol
(`LSUIElement = true`, an der installierten Fassung abgelesen), und sie hält **keine**
offene Netzwerkverbindung — der stärkste Einzelbeleg für die Datenschutzzusage des ganzen
Projekts.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 17 |
| davon bestanden | 6 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 11 |
| Edge Cases belegt | 0 von 4 |
| Tests neu geschrieben | 0 |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Menüleistensymbol, kein Dock-Symbol | ✅ bestanden | L2: `LSUIElement = true` im Programmpaket; die laufende Instanz (PID 785) erscheint nicht im Dock |
| AK-02 Symbol folgt hell/dunkel | ⚠️ nicht prüfbar | Darstellung |
| AK-03 Vier Gruppen im Menü | ⚠️ nicht prüfbar | Menüdarstellung |
| AK-04 Kombination steht im Titel | ⚠️ nicht prüfbar | dito |
| AK-05 Warneintrag ohne Berechtigung | ⚠️ nicht prüfbar | braucht entzogene Berechtigung |
| AK-06 Kein Warneintrag mit Berechtigung | ⚠️ nicht prüfbar | dito |
| AK-07 Untermenü *Pinned Screenshots* | ⚠️ nicht prüfbar | Menüdarstellung; die Datenquelle ist in B08 belegt |
| AK-08 Untermenü *Color History* | ⚠️ nicht prüfbar | dito, Datenquelle in B06 |
| AK-09 Fassung aus dem Programmpaket | ✅ bestanden | L2: `CFBundleShortVersionString` wird aus `Bundle.main` gelesen; der neue Build meldet 3.5.0, die installierte 3.4.0 |
| AK-10 *Quit* beendet | ⚠️ nicht prüfbar | würde die laufende Instanz des Nutzers beenden |
| AK-11 Anwendung läuft ohne Fenster weiter | ✅ bestanden | L1/L2: die Instanz läuft seit dem Start ohne offenes Fenster; `applicationShouldTerminateAfterLastWindowClosed` liefert `false` |
| AK-12 Fenster kommen nach vorn | ⚠️ nicht prüfbar | Fensterverhalten |
| AK-13 Aufnahmeeinträge ohne Berechtigung gesperrt | ✅ bestanden | sieben `.disabled(!hasScreenRecordingAccess)` im Menüaufbau — Zählung im Angriffsprotokoll |
| AK-14 Update-Eintrag deaktiviert | ✅ bestanden | siehe B14/AK-07 |
| AK-15 Menüaufbau ohne Bildschirmzugriff | ✅ bestanden | der Aufbau liest ausschließlich Zustände aus `AppState`; der einzige Systemaufruf ist `CGPreflightScreenCaptureAccess`, das nur den Berechtigungsstatus abfragt |
| AK-16 Farbeintrag kopiert nur den Hex-Wert | ✅ bestanden | `copyToClipboard(text:concealed: false)` — kein anderer Inhalt wird übergeben |
| AK-17 Untermenü *Colour Palette* | ⚠️ nicht prüfbar | Menüdarstellung; die Datenquelle ist in B06/AK-10 belegt |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Volle Menüleiste | ⚠️ nicht prüfbar | Systemverhalten |
| EC-02 Menü während einer Auswahl | ⚠️ nicht prüfbar | Oberflächenverhalten |
| EC-03 Viele angeheftete Bilder | ⚠️ nicht prüfbar | Menüdarstellung |
| EC-04 Berechtigung bei offenem Menü erteilt | ⚠️ nicht prüfbar | Zeitverhalten |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| **Keine offene Netzwerkverbindung zur Laufzeit** | ✅ bestanden | L1: `lsof -p 785 -i` liefert keine Verbindung |
| Menüaufbau greift nicht auf den Bildschirm zu | ✅ bestanden | nur Speicherzugriffe plus Berechtigungsabfrage |
| Personendaten in Logs | ✅ bestanden | A5 |
| Rechteumfang | ✅ bestanden | A7 |
| Geheimnisse | ✅ bestanden | A3/A4 |

## Fehler

Keine.

## Neue Tests

Keine — das Menü ist eine SwiftUI-Ansicht ohne eigene Logik (BF-05 der Spec, akzeptiert).

## Nächster Schritt

`/sdd-deploy B15`. Im manuellen Durchgang gezielt AK-05 und AK-13: Berechtigung entziehen,
Menü öffnen, prüfen dass der Warneintrag erscheint und die sieben Aufnahmeeinträge
ausgegraut sind.
