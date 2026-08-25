# B06 · Farbpipette — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.

## Zweck

Der Nutzer greift eine Farbe von irgendeiner Stelle des Bildschirms ab — aus einem fremden
Programm, einem Bild, einer Webseite — und hat sie als Hex-Wert in der Zwischenablage. Eine
Lupe zeigt vergrößert, welches Pixel getroffen wird.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 Bildschirmaufnahme | `bestand` | die Aufnahme des Bildschirms ist die Datenquelle |
| B02 App-Ausschluss | `bestand` | ausgeschlossene Programme dürfen auch hier nicht gelesen werden |
| B10 Tastenkombinationen | `bestand` | `⇧⌘7` |
| B15 Menüleisten-Hub | `bestand` | zeigt den Farbverlauf als Untermenü |

## User Stories

- **US-01** · Als Nutzer möchte ich eine Farbe vom Bildschirm abgreifen und als Hex-Wert
  einfügen können, ohne ein Bildbearbeitungsprogramm zu öffnen.
- **US-02** · Als Nutzer möchte ich vergrößert sehen, welches Pixel ich treffe, damit ich
  bei feinen Verläufen nicht danebengreife.
- **US-03** · Als Nutzer möchte ich die zuletzt abgegriffenen Farben wiederfinden, ohne sie
  aufzuschreiben.

## Nicht im Scope

- Farbwerte in anderen Schreibweisen einfügen (RGB, HSL) — werden angezeigt, aber nur Hex
  wird kopiert
- Farbschemata erzeugen oder Kontraste prüfen — nicht vorhanden
- Farben aus einem bereits aufgenommenen Screenshot abgreifen — nicht vorhanden

## Akzeptanzkriterien

- **AK-01** · Angenommen, `⇧⌘7` wird gedrückt oder *Pick Color* gewählt, wenn die Pipette
  startet, dann folgt dem Zeiger eine Lupe mit vergrößerter Darstellung, Fadenkreuz und
  einem Feld, das Hex-, RGB- und HSL-Wert des getroffenen Pixels zeigt.
- **AK-02** · Angenommen, die Pipette ist aktiv, wenn geklickt wird, dann liegt der
  Hex-Wert in der Zwischenablage, die Lupe verschwindet und eine Kurzmeldung „Copied
  #RRGGBB" erscheint.
- **AK-03** · Angenommen, die Pipette ist aktiv, wenn `Escape` gedrückt wird, dann bricht
  sie ohne Kopieren ab.
- **AK-04** · Angenommen, eine Farbe wurde abgegriffen, wenn das Menüleistensymbol
  angeklickt wird, dann steht sie im Untermenü *Color History* mit farbigem Punkt und
  Hex-Wert.
- **AK-05** · Angenommen, ein Eintrag im Farbverlauf wird angeklickt, wenn die Aktion
  ausgeführt ist, dann liegt dieser Hex-Wert in der Zwischenablage.
- **AK-06** · Angenommen, mehr als zehn Farben wurden abgegriffen, wenn der Verlauf
  angezeigt wird, dann enthält er nur die zehn jüngsten.
- **AK-07** · Angenommen, noch keine Farbe wurde abgegriffen, wenn das Untermenü geöffnet
  wird, dann steht dort „No colors picked yet".
- **AK-08** · Angenommen, mehrere Displays sind angeschlossen, wenn die Pipette über eines
  davon geführt wird, dann zeigt sie die Farbe des Pixels unter dem Zeiger — auf jedem
  Display, unabhängig von der Skalierung.
- **AK-09** ⚠ · Angenommen, die Pipette ist aktiv, wenn sich der Bildschirminhalt ändert —
  ein Video läuft, eine Animation spielt —, dann zeigt die Lupe **weiterhin den Stand vom
  Start der Pipette**.
  *(`ColorPickerEngine.swift:81` nimmt beim Start je Display **einen** Schnappschuss auf und
  liest danach nur noch daraus. Der Dateikommentar begründet das mit der Notwendigkeit,
  synchron zu bleiben. Zur Klärung vorgelegt: Der Nutzer greift damit eine Farbe ab, die so
  gerade nicht mehr auf dem Bildschirm steht.)*
- **AK-10** ⚠ · Angenommen, mit gedrückter Umschalttaste wird geklickt, wenn die Aktion
  ausgeführt ist, dann wird die Farbe zusätzlich in eine Palette aufgenommen — **die
  nirgends angezeigt wird**. Kurzmeldung und Verhalten sind von einem gewöhnlichen Klick
  nicht unterscheidbar.
  *(`ColorLoupePanel.swift:137` ruft `addToPalette`; `ColorHistoryManager.palette` wird
  gespeichert, aber von keiner Oberfläche gelesen — das Menü zeigt ausschließlich den
  Verlauf. Der Toast lautet in beiden Fällen „Copied …". Die Funktion ist im README
  beschrieben. Zur Klärung vorgelegt.)*

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 des Katalogs ausdrücklich in Kraft. **Für ein einziges Pixel nimmt
dieses Feature den gesamten Inhalt aller Bildschirme auf** und hält ihn im Speicher.

- **AK-11** · Angenommen, die Pipette startet, wenn die Schnappschüsse entstehen, dann sind
  Fenster ausgeschlossener Programme darin nicht enthalten.
- **AK-12** · Angenommen, die Pipette startet, wenn die Schnappschüsse entstehen, dann sind
  eigene Fenster der Anwendung nicht enthalten — die Aufnahme erfolgt, **bevor** die
  Überlagerungen existieren.
- **AK-13** · Angenommen, die Pipette wird beendet oder abgebrochen, wenn aufgeräumt ist,
  dann sind die Bildschirmaufnahmen aus dem Speicher entfernt.
- **AK-14** · Angenommen, eine Farbe wird abgegriffen, wenn der Vorgang läuft, dann enthält
  kein Protokoll Bildinhalte.
- **AK-15** ⚠ · Angenommen, *Reset All Preferences* wird ausgeführt, wenn die Anwendung
  danach startet, dann sind Farbverlauf und Palette **weiterhin vorhanden**.
  *(`AppPreferences.swift:135` führt eine von Hand gepflegte Schlüsselliste; die Schlüssel
  des Farbverlaufs stehen nicht darin. Zur Klärung vorgelegt.)*
- **AK-16** ⚠ · Angenommen, ein Hex-Wert wird in die Zwischenablage gelegt, wenn die
  geräteübergreifende Zwischenablage aktiv ist, dann überträgt das System ihn an andere
  Geräte des Nutzers. *(Wie B05/AK-17; hier von geringer Tragweite, weil ein Farbwert kein
  Geheimnis ist — der Vollständigkeit halber aufgenommen.)*

*Abschnitt 4 (Rate Limits): trifft nicht zu. Abschnitt 6 (Geheimnisse): trifft nicht zu.*

## Edge Cases

- **EC-01** · Klick außerhalb aller Schnappschüsse → die Pipette bricht ohne Kopieren ab.
- **EC-02** · Display wird während laufender Pipette abgezogen → Verhalten ungeprüft.
- **EC-03** · Bildschirmaufnahme-Berechtigung fehlt → Kurzmeldung „Colour picker failed",
  keine Lupe.
- **EC-04** · Sehr viele Displays mit hoher Auflösung → alle Schnappschüsse liegen
  gleichzeitig unkomprimiert im Speicher, siehe FB-03.
- **EC-05** · Farbe wird zweimal abgegriffen → erscheint zweimal im Verlauf, es gibt keine
  Zusammenfassung gleicher Werte.

## Fehlbestand

- **FB-01 · Die Palette hat keine Anzeige.** Fundstellen: `ColorHistoryManager.swift:16`
  (gespeichert, höchstens 20), `ColorLoupePanel.swift:137` (befüllt),
  `MikaScreenSnapApp.swift:219` (das Menü zeigt nur den Verlauf). Folge: Eine im README
  beworbene Funktion („Shift+Click adds to palette") ist ohne Wirkung für den Nutzer — die
  Daten sammeln sich, ohne je sichtbar zu werden.
- **FB-02 · Die Lupe zeigt einen eingefrorenen Bildschirm.** Fundstelle:
  `ColorPickerEngine.swift:81`. Folge: Bei bewegten Inhalten wird die falsche Farbe
  abgegriffen, ohne Hinweis. Die Entscheidung ist begründet (Synchronität), die fehlende
  Kennzeichnung nicht.
- **FB-03 · Der gesamte Bildschirminhalt liegt unkomprimiert im Speicher.** Fundstelle:
  `ColorPickerEngine.swift:96` hält je Display die rohen Bilddaten. Folge: Bei mehreren
  großen Displays erheblicher Speicherbedarf, solange die Pipette aktiv ist — und eine
  vollständige Kopie fremder Bildschirminhalte im Prozessspeicher.
- **FB-04 · Farbverlauf und Palette überstehen das Zurücksetzen.** Fundstelle:
  `AppPreferences.swift:135`. Folge: „Alle Einstellungen zurücksetzen" tut nicht, was es
  sagt; abgegriffene Farben bleiben nachvollziehbar.
- **FB-05 · Kein Weg, den Farbverlauf zu leeren.** Weder Menü noch Einstellungen bieten
  das an; `clearPalette` existiert im Verwalter, wird aber von niemandem aufgerufen. Folge:
  Der Verlauf lässt sich nur durch zehn neue Farben verdrängen.
- **FB-06 · RGB und HSL werden berechnet und angezeigt, aber nie kopiert.** Fundstelle:
  `ColorPickerEngine.swift:13-14`. Folge: Wer den RGB-Wert braucht, muss ihn abschreiben.
- **FB-07 · Keine Tests.** Die Farbumrechnung (Hex, RGB, HSL) ist reine Rechnung und ideal
  prüfbar; geprüft wird sie nicht.

## Offene Fragen

- **OF-01** · Soll die Palette eine Anzeige bekommen — oder soll Shift+Klick entfallen? —
  entscheidet der Autor.
- **OF-02** · Soll der Farbverlauf leerbar sein und vom Zurücksetzen erfasst werden? —
  entscheidet der Autor.
- **OF-03** · Soll die Lupe den Bildschirm fortlaufend neu lesen? — entscheidet der Autor;
  die jetzige Lösung ist bewusst gewählt, die Folge (AK-09) aber unsichtbar.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie wird ein Pixel gelesen? | einmaliger Schnappschuss je Display, danach nur Speicherzugriff | ausdrücklich kommentiert: die Lupe zeichnet bei jeder Mausbewegung neu, ein Rundweg zum System je Abtastung würde ruckeln |
| 2 | Wann wird der Schnappschuss genommen? | **bevor** die eigenen Überlagerungen existieren | sonst läge die eigene Lupe unter der Lupe |
| 3 | Wie werden Koordinaten umgerechnet? | über `ScreenGeometry` | 3.4.1: zuvor wurde gegen das Fenster mit dem Tastaturfokus gespiegelt, was auf mehreren Displays falsch war |
| 4 | Womit wird aufgenommen? | ScreenCaptureKit | 3.4.1: ersetzte `CGWindowListCreateImage` |
| 5 | Wie wird die Klickfläche unsichtbar gemacht? | Deckkraft 0,001 statt völliger Transparenz | ein vollständig durchsichtiges Fenster nimmt keine Mausereignisse entgegen |
| 6 | Welche Ebene hat die Lupe? | eine über den Klickflächen | sonst verdeckte die eigene Klickfläche die Lupe |
| 7 | Was wird kopiert? | nur Hex | **Grund nicht erkennbar** (FB-06) |
| 8 | Wofür die Palette? | dauerhafte Sammlung neben dem Verlauf | **Zweck nicht rekonstruierbar** — es gibt keine Anzeige dazu (FB-01) |
