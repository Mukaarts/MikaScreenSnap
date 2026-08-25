# B15 · Menüleisten-Hub & Programminfo — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Die Anwendung ist eine SwiftUI-App, deren gesamte Oberfläche aus einem `MenuBarExtra`
besteht. Daneben steht ein Programmdelegat, der beim Start drei Dinge tut: die
Ersteinrichtung oder die Berechtigungsprüfung anstoßen, angeheftete Bilder wiederherstellen
und die sieben Tastenkombinationen anmelden.

Der gemeinsame Zustand liegt in einem Halter, der alle Verwalter und Fenstercontroller
führt. Fenstercontroller werden beim ersten Bedarf erzeugt und danach wiederverwendet.

Der vollständige Menüaufbau steht in `docs/app-shell.md`.

## Komponentenstruktur

```
MikaScreenSnapApp                      @main
├── AppDelegate
│   ├── applicationDidFinishLaunching
│   │   ├── Ersteinrichtung **oder** Berechtigungsprüfung   ← siehe FB-02
│   │   ├── restorePins(appState:)     → B08
│   │   └── HotkeyManager(…)           sieben Rückrufe → B10
│   ├── applicationShouldTerminateAfterLastWindowClosed → false
│   ├── showOnboarding()               → B12
│   └── checkScreenCapturePermission() ruft SCShareableContent — nur im else-Zweig
├── AppState                           gemeinsamer Halter
│   ├── Verwalter                      Aufnahme · Verlauf · Farben · Aktualisierung · Anmeldestart
│   ├── Fenstercontroller              Editor · Verlauf · Einstellungen · Über · Einrichtung
│   ├── pinnedPanels                   Grundlage des Untermenüs
│   └── lastCapture
└── MenuBarExtra                       Schablonensymbol
    ├── Programm                       Über · Updates · Berechtigungswarnung
    ├── Aufnahme                       vier Einträge
    ├── Zusatzfunktionen               Text · Farbe · Messen
    ├── Verwaltung                     Pins ▸ · Farben ▸ · Verlauf
    └── Abschluss                      Einstellungen ⌘, · Beenden ⌘Q

AboutWindowController                  Symbol · Name · Fassung aus dem Paket
```

## Datenmodell

Kein eigenes. `AppState` hält Verweise, keine Daten.

Bemerkenswert ist die Reihenfolge beim Start: Angeheftete Bilder werden **vor** der
Anmeldung der Tastenkombinationen wiederhergestellt und **unabhängig davon**, ob die
Ersteinrichtung läuft. Beim allerersten Start können also bereits Fenster erscheinen,
während die Einrichtung noch offen ist — sofern der Ablageordner Dateien enthält.

## Zugriffsregeln

Keine. Das Menü zeigt Zustände, die andere Features führen.

## Missbrauchsschutz

Nicht anwendbar.

## Externe Dienste

Keine. Der Deeplink in die Systemeinstellungen überträgt nichts.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | `MenuBarExtra` statt eines eigenen Statuselements | `NSStatusItem` von Hand | SwiftUI-Bordmittel; das Menü ist eine Ansicht |
| 2 | Schablonenbild als Symbol | farbiges Symbol | folgt hell und dunkel automatisch |
| 3 | Fenstercontroller träge erzeugt und behalten | jedes Mal neu | Zustand und Position bleiben innerhalb einer Sitzung erhalten |
| 4 | Dauerhaft ohne Dock-Symbol, Fenster über ausdrückliche Aktivierung | Betriebsart wechseln | in 3.4.0 behoben; in `CLAUDE.md` als Konvention festgehalten |
| 5 | Berechtigungsprüfung im `else`-Zweig der Ersteinrichtung | in beiden Zweigen | **Grund nicht erkennbar** — Ursache von FB-02 |
| 6 | Angeheftete Bilder vor den Kombinationen wiederherstellen | danach oder verzögert | **Grund nicht erkennbar**; ohne Wirkung, solange nichts fehlschlägt |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `LSUIElement` im Programmpaket + `MenuBarExtra` | |
| AK-02 | Schablonenbild | |
| AK-03 | Trennlinien im Menü | |
| AK-04 | Kombination im Titel | siehe Entscheidung 4 |
| AK-05 | Abfrage beim Aufbau des Menüs | |
| AK-06 | dieselbe Abfrage | |
| AK-07 | Untermenü über `pinnedPanels` | → B08 |
| AK-08 | Untermenü über den Farbverlauf | → B06 |
| AK-09 | `AboutWindowController`, Fassung aus dem Paket | |
| AK-10 | `NSApplication.terminate` | |
| AK-11 | `applicationShouldTerminateAfterLastWindowClosed` → false | |
| AK-12 | ausdrückliche Aktivierung in den Controllern | |
| AK-13 ⚠ | **keine Komponente** — nichts wird deaktiviert | |
| AK-14 ⚠ | **keine Komponente** | → B14 |
| AK-15 | nur Speicherzugriffe beim Aufbau | |
| AK-16 | Schreiben des Hex-Werts im Untermenü | |

## Übergabe an die QA

1. **FB-02 ist die wichtigste Feststellung dieses Features** und erklärt B12/FB-01: Die
   Berechtigungsprüfung, die die Anwendung in die Systemliste einträgt, läuft beim
   Erststart nicht. Mit einem frischen Benutzerkonto zu prüfen.
2. **AK-01 und AK-11** sind die Grundzusagen der Anwendungsform — nach dem Schließen aller
   Fenster muss das Menüleistensymbol bleiben (der Fehler aus 3.4.0 darf nicht
   zurückkehren).
3. **AK-13** gemeinsam mit B01 prüfen.
