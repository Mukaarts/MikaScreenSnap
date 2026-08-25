# B06 · Farbpipette — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde bearbeitet in 3.5.0**

> Beschrieben ist, **was der Code tut**. Von den vier markierten Kriterien sind drei
> behoben, eines ist eine bewusste Entscheidung.

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
- **AK-09** · Angenommen, die Pipette ist aktiv, wenn sich der Bildschirminhalt ändert — ein
  Video läuft, eine Animation spielt —, dann zeigt die Lupe **weiterhin den Stand vom Start
  der Pipette**. Das ist eine bewusste Entscheidung, Begründung unter *Befunde*, BF-02.
- **AK-10** · Angenommen, mit gedrückter Umschalttaste wird geklickt, wenn die Aktion
  ausgeführt ist, dann wird die Farbe zusätzlich in eine Palette aufgenommen, die im
  Menüleistenmenü unter *Colour Palette* steht und dort auch geleert werden kann.

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
- **AK-15** · Angenommen, *Reset All Preferences* wird ausgeführt, wenn die Anwendung danach
  startet, dann sind Farbverlauf und Palette **geleert** — beide Schlüssel stehen in der
  Rücksetzliste.
- **AK-16** · Angenommen, ein Hex-Wert wird in die Zwischenablage gelegt, wenn die
  geräteübergreifende Zwischenablage aktiv ist, dann überträgt das System ihn an andere
  Geräte des Nutzers. Anders als bei erkanntem Text (B05) wird hier **keine**
  Vertraulichkeitskennzeichnung gesetzt: Ein Farbwert ist kein Geheimnis, und die
  Kennzeichnung würde Zwischenablage-Verwaltungen daran hindern, ihn aufzubewahren.
- **AK-17** · Angenommen, Farben stehen im Verlauf, wenn im Untermenü *Clear History*
  gewählt wird, dann ist der Verlauf leer; dasselbe gilt für *Clear Palette*.

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

## Befunde

### Behoben

- **FB-01 · Die Palette hatte keine Anzeige** — behoben 2026-08-25. Untermenü *Colour
  Palette* mit farbigem Punkt, Hex-Wert und *Clear Palette*.
- **FB-04 · Farbverlauf und Palette überstanden das Zurücksetzen** — behoben 2026-08-25.
  `ColorHistoryManager.historyDefaultsKey` und `.paletteDefaultsKey` sind öffentlich und
  stehen in `AppPreferences.ownedDefaultsKeys`; ein Test hält das fest.
- **FB-05 · Kein Weg, den Farbverlauf zu leeren** — behoben 2026-08-25 über *Clear
  History* und *Clear Palette* im Menü. *(Die erste Fassung behauptete, `clearPalette`
  existiere bereits im Verwalter — das war falsch; die Methode gab es nicht und wurde
  angelegt.)*

### Akzeptiert

- **BF-02 · Die Lupe zeigt einen eingefrorenen Bildschirm** — akzeptiert 2026-08-25. Die
  Lupe zeichnet bei jeder Mausbewegung neu; ein Rundweg zum System je Abtastung würde
  ruckeln, und ein regelmäßiges Neulesen hieße, den gesamten Bildschirminhalt fortlaufend
  im Speicher zu erneuern. Für den Zweck — eine Farbe aus einer stehenden Oberfläche
  greifen — ist der Schnappschuss richtig.
- **BF-03 · Der Bildschirminhalt liegt unkomprimiert im Speicher** — akzeptiert
  2026-08-25. Folge von BF-02; der Speicher wird mit dem Controller freigegeben, sobald die
  Pipette endet.
- **BF-06 · RGB und HSL werden angezeigt, aber nie kopiert** — akzeptiert 2026-08-25. Hex
  ist das Format, das in Code und Werkzeugen eingefügt wird; eine Auswahl beim Klicken
  würde den einen Handgriff verdoppeln, um den es geht.

### Behoben (Tests)

- **FB-07 · Keine Tests** — behoben 2026-08-25. Fünf Tests über Hex-, RGB- und
  HSL-Umrechnung in `Tests/ColorConversionTests.swift`.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Palette anzeigen oder Shift+Klick entfernen? | anzeigen — als eigenes Untermenü neben dem Verlauf | 2026-08-25 |
| OF-02 · Verlauf leerbar und vom Zurücksetzen erfasst? | beides ja | 2026-08-25 |
| OF-03 · Lupe fortlaufend neu lesen? | nein, siehe BF-02 | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie wird ein Pixel gelesen? | einmaliger Schnappschuss je Display, danach nur Speicherzugriff | ausdrücklich kommentiert: die Lupe zeichnet bei jeder Mausbewegung neu, ein Rundweg zum System je Abtastung würde ruckeln |
| 2 | Wann wird der Schnappschuss genommen? | **bevor** die eigenen Überlagerungen existieren | sonst läge die eigene Lupe unter der Lupe |
| 3 | Wie werden Koordinaten umgerechnet? | über `ScreenGeometry` | 3.4.1: zuvor wurde gegen das Fenster mit dem Tastaturfokus gespiegelt, was auf mehreren Displays falsch war |
| 4 | Womit wird aufgenommen? | ScreenCaptureKit | 3.4.1: ersetzte `CGWindowListCreateImage` |
| 5 | Wie wird die Klickfläche unsichtbar gemacht? | Deckkraft 0,001 statt völliger Transparenz | ein vollständig durchsichtiges Fenster nimmt keine Mausereignisse entgegen |
| 6 | Welche Ebene hat die Lupe? | eine über den Klickflächen | sonst verdeckte die eigene Klickfläche die Lupe |
| 7 | Was wird kopiert? | nur Hex | **Grund nicht erkennbar** (FB-06) |
| 8 | Wofür die Palette? | dauerhafte Sammlung neben dem Verlauf, seit 3.5.0 im Menü sichtbar | der Verlauf verdrängt nach zehn Farben; die Palette hält, was bleiben soll |
