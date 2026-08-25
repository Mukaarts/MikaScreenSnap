# B15 · Menüleisten-Hub & Programminfo — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde bearbeitet in 3.5.0**

> Beschrieben ist, **was der Code tut**. Beide markierten Kriterien sind behoben.

## Zweck

Die Anwendung hat kein Hauptfenster und kein Dock-Symbol. Das Menüleistensymbol ist ihr
**einziger sichtbarer Anker**: Von dort ist jede Funktion erreichbar, dort erscheint der
Hinweis auf eine fehlende Berechtigung, und dort wird die Anwendung beendet.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| alle übrigen Features | `bestand` | das Menü ist ihre gemeinsame Oberfläche |

## User Stories

- **US-01** · Als Nutzer möchte ich jede Funktion erreichen, ohne Tastenkombinationen zu
  kennen.
- **US-02** · Als Nutzer möchte ich sehen, welche Kombination zu welcher Funktion gehört.
- **US-03** · Als Nutzer möchte ich erkennen, wenn eine Berechtigung fehlt.
- **US-04** · Als Nutzer möchte ich die Fassungsnummer nachschlagen können.

## Nicht im Scope

- Ein Hauptfenster — die Anwendung bleibt dauerhaft ohne Dock-Symbol
- Anpassbare Menüeinträge — nicht vorhanden

## Akzeptanzkriterien

- **AK-01** · Angenommen, die Anwendung läuft, wenn sie gestartet ist, dann erscheint ein
  Symbol in der Menüleiste, **kein** Dock-Symbol und kein Eintrag im Programmumschalter.
- **AK-02** · Angenommen, die Menüleiste ist hell oder dunkel, wenn das Symbol angezeigt
  wird, dann passt es sich an (Schablonenbild).
- **AK-03** · Angenommen, das Symbol wird angeklickt, wenn das Menü erscheint, dann sind
  vier Gruppen durch Trennlinien geschieden: Programm, Aufnahme, Zusatzfunktionen,
  Verwaltung.
- **AK-04** · Angenommen, ein Menüeintrag hat eine Tastenkombination, wenn er angezeigt
  wird, dann steht sie **im Titel** — nicht als eigene Spalte.
- **AK-05** · Angenommen, die Bildschirmaufnahme-Berechtigung fehlt, wenn das Menü geöffnet
  wird, dann erscheint zusätzlich der Eintrag „⚠ Screen Recording not granted", der in die
  Systemeinstellungen führt.
- **AK-06** · Angenommen, die Berechtigung ist erteilt, wenn das Menü geöffnet wird, dann
  fehlt dieser Eintrag.
- **AK-07** · Angenommen, angeheftete Bilder bestehen, wenn das Untermenü *Pinned
  Screenshots* geöffnet wird, dann sind sie einzeln aufgeführt und über *Close All*
  gemeinsam schließbar; sonst steht dort „No pinned screenshots".
- **AK-08** · Angenommen, Farben wurden abgegriffen, wenn *Color History* geöffnet wird,
  dann stehen sie mit farbigem Punkt und Hex-Wert da; sonst „No colors picked yet".
- **AK-09** · Angenommen, *About Mika+ScreenSnap* wird gewählt, wenn das Fenster erscheint,
  dann zeigt es Symbol, Namen und die Fassungsnummer **aus dem Programmpaket** — nicht fest
  verdrahtet.
- **AK-10** · Angenommen, *Quit* wird gewählt, wenn die Aktion ausgeführt ist, dann beendet
  sich die Anwendung.
- **AK-11** · Angenommen, alle Fenster werden geschlossen, wenn das geschehen ist, dann
  **läuft die Anwendung weiter**.
- **AK-12** · Angenommen, ein Fenster wird aus dem Menü geöffnet, wenn es erscheint, dann
  kommt es nach vorn und nimmt den Tastaturfokus — obwohl die Anwendung kein Dock-Symbol
  hat.
- **AK-13** · Angenommen, die Berechtigung fehlt, wenn das Menü geöffnet wird, dann sind
  **alle sieben Aufnahme- und Zusatzeinträge deaktiviert** und nur der Warneintrag führt
  weiter — in die Systemeinstellungen.
- **AK-14** · Angenommen, das Aktualisierungswerk ist nicht bereit, wenn *Check for
  Updates…* angezeigt wird, dann ist der Eintrag deaktiviert (siehe B14/AK-07).
- **AK-17** · Angenommen, Farben wurden mit gedrückter Umschalttaste abgegriffen, wenn das
  Menü geöffnet wird, dann steht neben *Color History* ein zweites Untermenü *Colour
  Palette*; beide lassen sich dort leeren.

### Datenschutz und Missbrauchsschutz

Stufe A.

- **AK-15** · Angenommen, das Menü wird geöffnet, wenn es aufgebaut wird, dann werden nur
  Zustände gelesen, die bereits im Speicher liegen — es entsteht kein Zugriff auf den
  Bildschirm und keine Datei.
- **AK-16** · Angenommen, ein Farbeintrag wird angeklickt, wenn das geschieht, dann wird
  nur der Hex-Wert in die Zwischenablage gelegt.

*Abschnitte 4 und 6 des Katalogs: treffen nicht zu.*

## Edge Cases

- **EC-01** · Menüleiste voll → das Symbol kann unsichtbar sein; die Anwendung ist dann nur
  über Tastenkombinationen erreichbar.
- **EC-02** · Menü geöffnet, während eine Auswahl läuft → die Auswahl liegt auf einer
  höheren Ebene.
- **EC-03** · Sehr viele angeheftete Bilder → das Untermenü wird lang; es gibt keine
  Begrenzung der Anzeige über die zwanzig Panels hinaus.
- **EC-04** · Berechtigung wird bei geöffnetem Menü erteilt → der Warneintrag verschwindet
  erst beim nächsten Öffnen.

## Befunde

### Behoben

- **FB-01 · Der Warnhinweis warnte, hinderte aber nicht** — behoben 2026-08-25. Die
  Aufnahmeeinträge sind ohne Berechtigung deaktiviert.
- **FB-02 · Beim Erststart wurde die Berechtigung nicht angestoßen** — behoben in B12: Die
  Ersteinrichtung fordert sie an, statt sie nur abzufragen.

### Akzeptiert

- **BF-03 · Angeheftete Bilder heißen nur „Pin 1", „Pin 2"** — akzeptiert 2026-08-25. Der
  Eintrag holt ein Fenster nach vorn, das ohnehin sichtbar ist; ein Vorschaubild im Menü
  wäre Aufwand für einen Weg, den man selten geht.
- **BF-04 · Kein Weg zur Projektseite aus der Anwendung** — akzeptiert 2026-08-25. Das
  „Über"-Fenster nennt Name und Fassung; wer ein Problem meldet, findet das Projekt über
  dieselbe Quelle, aus der er die Anwendung bezogen hat. Ein Verweis wäre eine Zeile — er
  fehlt bewusst, weil das Menü bereits fünfzehn Einträge trägt.
- **BF-05 · Keine Tests** — akzeptiert 2026-08-25. Das Menü ist eine SwiftUI-Ansicht ohne
  eigene Logik.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Aufnahmeeinträge ohne Berechtigung sperren? | ja, im Menü. Tastenkombinationen bleiben aktiv und melden den Fehlschlag | 2026-08-25 |
| OF-02 · Verweis auf das Projekt im „Über"-Fenster? | nein, siehe BF-04 | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Menüleiste statt Dock | gewöhnliche Anwendung mit Fenster | ein Aufnahmewerkzeug soll nicht im Weg stehen; `LSUIElement` gesetzt |
| 2 | Dauerhaft ohne Dock-Symbol | zwischen den Betriebsarten wechseln | 3.4.0 behoben: der Wechsel machte die Anwendung nach dem Schließen aus dem Dock unerreichbar |
| 3 | Weiterlaufen ohne Fenster | mit dem letzten Fenster beenden | eine Menüleistenanwendung, die sich beendet, wäre nicht mehr erreichbar |
| 4 | Kombinationen im Titel statt als Tastenzuordnung | echte Tastenzuordnungen | sie sind systemweit über Carbon angemeldet, nicht an das Menü gebunden |
| 5 | Leerzustände als Text statt ausgeblendeter Untermenüs | Untermenü ausblenden | ein verschwundener Eintrag sieht aus wie ein Fehler |
| 6 | Fassungsnummer aus dem Programmpaket | fest verdrahtet | seit 3.1.0; verhindert Abweichungen zwischen Anzeige und Paket |
| 7 | `Capture Window…` ohne Kombination | eigene Kombination vergeben | die interaktive Auswahl braucht ohnehin die Maus; `⌃⇧⌘5` deckt den schnellen Fall ab |
| 8 | Einträge ohne Berechtigung sperren (3.5.0) | anklickbar lassen | der Weg zur Berechtigung führte zuvor durch einen misslungenen Versuch |
