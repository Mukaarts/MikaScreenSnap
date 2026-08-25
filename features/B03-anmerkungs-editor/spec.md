# B03 · Anmerkungs-Editor — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde bearbeitet in 3.5.0**

> Beschrieben ist, **was der Code tut**. Von den fünf markierten Kriterien sind vier
> behoben, eines liegt außerhalb der Anwendung und ist entschärft.
>
> Zensieren (Weichzeichnen, Verpixeln) ist als **B04** gesondert erfasst, das Lineal als
> **B07**. Hier stehen der Rahmen, die neun übrigen Werkzeuge, Zoom, Auswahl und Ausgabe.

## Zweck

Nach jeder Aufnahme öffnet sich ein Fenster, in dem der Nutzer das Bild beschriften kann —
Pfeile, Rahmen, Text, Hervorhebungen — und aus dem heraus er es kopiert, sichert oder
anheftet. Der Editor ist der Weg jeder Aufnahme nach draußen.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 Bildschirmaufnahme | `bestand` | liefert das Bild und öffnet den Editor |
| B04 Zensieren | `bestand` | zwei der elf Werkzeuge |
| B07 Lineal | `bestand` | ein weiteres Werkzeug |
| B05 Texterkennung | `bestand` | Schaltfläche *Extract Text* |
| B08 Anheften | `bestand` | Schaltfläche *Pin* |
| B09 Verlauf | `bestand` | zweiter Einstiegsweg über *Open in Editor* |
| B11 Einstellungen | `bestand` | Standardwerkzeug, -farbe, -strichstärke |

## User Stories

- **US-01** · Als Nutzer möchte ich direkt nach der Aufnahme zeichnen können, ohne eine
  zweite Anwendung zu öffnen.
- **US-02** · Als Nutzer möchte ich Gezeichnetes nachträglich auswählen, verschieben,
  skalieren und löschen.
- US-03 · Als Nutzer möchte ich jeden Schritt rückgängig machen können.
- **US-04** · Als Nutzer möchte ich in ein Bild hineinzoomen, um genau zu treffen.
- **US-05** · Als Nutzer möchte ich das Ergebnis mit einem Tastendruck in der
  Zwischenablage haben.

## Nicht im Scope

- Ebenen, Gruppierung, Ausrichtungshilfen — nicht vorhanden
- Speichern eines bearbeitbaren Projektstands — nicht vorhanden, siehe FB-01
- Zuschneiden oder Drehen des Bildes — nicht vorhanden
- Farbkorrektur, Filter — nicht vorhanden

## Akzeptanzkriterien

### Rahmen

- **AK-01** · Angenommen, eine Aufnahme ist entstanden, wenn sie fertig ist, dann öffnet
  sich der Editor mit dem Bild, höchstens 80 % der Bildschirmgröße einnehmend.
- **AK-02** · Angenommen, der Editor ist offen, wenn er angezeigt wird, dann liegt oben eine
  Werkzeugleiste, in der Mitte die Zeichenfläche und unten eine Leiste mit Zoomstufe,
  Bildmaßen und Ausgabeschaltflächen.
- **AK-03** · Angenommen, der Editor öffnet sich, wenn Standardwerte eingestellt sind, dann
  sind Werkzeug, Farbe und Strichstärke daraus übernommen.
- **AK-04** · Angenommen, *Remember last tool* ist eingeschaltet (Standard), wenn der Editor
  geschlossen wird, dann wird das zuletzt benutzte Werkzeug zum neuen Standard.

### Werkzeuge

- **AK-05** · Angenommen, der Editor ist offen, wenn eine der Tasten `V A R E L F T H B X M`
  gedrückt wird, dann wechselt das Werkzeug entsprechend (Auswahl, Pfeil, Rechteck, Ellipse,
  Linie, Freihand, Text, Hervorheben, Weichzeichnen, Verpixeln, Messen).
- **AK-06** · Angenommen, ein Zeichenwerkzeug ist aktiv, wenn gezogen wird, dann erscheint
  während des Ziehens eine Vorschau und beim Loslassen die fertige Anmerkung.
- **AK-07** · Angenommen, Pfeil oder Linie sind aktiv, wenn mit gedrückter Umschalttaste
  gezogen wird, dann rastet der Winkel in 45-Grad-Schritten ein.
- **AK-08** · Angenommen, Rechteck oder Ellipse sind aktiv, wenn mit gedrückter
  Umschalttaste gezogen wird, dann entstehen Quadrat beziehungsweise Kreis.
- **AK-09** · Angenommen, das Freihandwerkzeug ist aktiv, wenn gezogen wird, dann entsteht
  eine geglättete Kurve statt eines Streckenzugs.
- **AK-10** · Angenommen, das Textwerkzeug ist aktiv, wenn in das Bild geklickt wird, dann
  erscheint ein Eingabefeld; der eingegebene Text bleibt mit farblich hinterlegter Fläche
  stehen.
- **AK-11** · Angenommen, ein Textfeld ist in Bearbeitung, wenn `Escape` gedrückt wird, dann
  wird die Eingabe abgeschlossen — der Editor schließt sich **nicht**.
- **AK-12** · Angenommen, ein Textfeld ist in Bearbeitung, wenn eine Werkzeugtaste gedrückt
  wird, dann wird sie als Text eingegeben und wechselt das Werkzeug nicht.
- **AK-13** · Angenommen, sechs Farbvorgaben und eine freie Farbwahl stehen bereit, wenn
  eine davon gewählt wird, dann zeichnen alle folgenden Anmerkungen in dieser Farbe.
- **AK-14** · Angenommen, drei Strichstärken (2, 4, 6 Punkte) stehen bereit, wenn eine
  gewählt wird, dann gilt sie für alle folgenden Anmerkungen.

### Auswahl und Bearbeitung

- **AK-15** · Angenommen, das Auswahlwerkzeug ist aktiv, wenn auf eine Anmerkung geklickt
  wird, dann ist sie ausgewählt und von acht Griffen umgeben.
- **AK-16** · Angenommen, eine Anmerkung ist ausgewählt, wenn sie gezogen wird, dann wird sie
  verschoben; wenn ein Griff gezogen wird, wird sie skaliert.
- **AK-17** · Angenommen, eine Anmerkung ist ausgewählt, wenn `Entf` oder `Rückschritt`
  gedrückt wird, dann wird sie entfernt.
- **AK-18** · Angenommen, Anmerkungen wurden erstellt, wenn `⌘Z` gedrückt wird, dann wird der
  jeweils letzte Schritt rückgängig gemacht; `⇧⌘Z` stellt ihn wieder her.
- **AK-19** · Angenommen, mehrere Anmerkungen überlappen, wenn gezeichnet wird, dann liegt
  die zuletzt erstellte oben.

### Zoom und Verschieben

- **AK-20** · Angenommen, der Editor ist offen, wenn `⌘+` oder `⌘-` gedrückt wird, dann
  ändert sich die Vergrößerung; `⌘0` stellt die Einpassung wieder her.
- **AK-21** · Angenommen, ein Trackpad ist vorhanden, wenn darauf aufgezogen wird, dann
  ändert sich die Vergrößerung stufenlos.
- **AK-22** · Angenommen, die Leertaste wird gehalten, wenn gezogen wird, dann verschiebt
  sich der Bildausschnitt statt zu zeichnen.
- **AK-23** · Angenommen, die Vergrößerung ist verändert, wenn gezeichnet wird, dann liegt
  die Anmerkung an der Stelle des Bildes, auf die geklickt wurde — unabhängig von
  Vergrößerung und Verschiebung.
- **AK-24** · Angenommen, ein Bild mit Transparenz ist geöffnet, wenn es angezeigt wird,
  dann liegt ein Schachbrettmuster dahinter.

### Ausgabe

- **AK-25** · Angenommen, Anmerkungen bestehen, wenn `⌘C` gedrückt wird, dann liegt das
  fertig gerenderte Bild in der Zwischenablage und der Editor schließt sich.
- **AK-26** · Angenommen, `⌘S` wird gedrückt, wenn die Aktion ausgeführt wird, dann wird das
  Bild **in den eingestellten Ordner** gesichert und die Zwischenablage bleibt unberührt.
  Hat das automatische Sichern die Aufnahme bereits abgelegt, wird **diese Datei ersetzt**,
  statt eine zweite anzulegen.
- **AK-27** · Angenommen, `⌘S` wird benutzt, wenn die Datei entsteht, dann trägt sie das in
  den Einstellungen gewählte Format. *Save As* schreibt weiterhin PNG, weil der Nutzer dort
  Ort und Namen ohnehin selbst bestimmt.
- **AK-28** · Angenommen, `⇧⌘S` wird gedrückt, wenn der Dialog erscheint, dann kann Ort und
  Name frei gewählt werden.
- **AK-29** · Angenommen, keine Anmerkungen bestehen, wenn `Escape` gedrückt wird, dann wird
  das unveränderte Bild in die Zwischenablage gelegt und der Editor schließt sich.
- **AK-30** · Angenommen, Anmerkungen bestehen und sind ungesichert, wenn `Escape` gedrückt
  wird, dann erscheint die Rückfrage „Discard Changes?".
- **AK-31** · Angenommen, zwei Bilder werden innerhalb derselben Sekunde mit `⌘S`
  gesichert, wenn beide geschrieben werden, dann entstehen **zwei Dateien** — der Name trägt
  Millisekunden und weicht bei Gleichstand über eine Zählnummer aus.

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 ausdrücklich in Kraft.

- **AK-32** · Angenommen, ein Bild wird ausgegeben, wenn gerendert wird, dann enthält das
  Ergebnis alle Anmerkungen flach eingerechnet — keine Ebenen, keine wiederherstellbaren
  Originalbereiche.
- **AK-33** · Angenommen, ein Bild wird in die Zwischenablage gelegt, wenn die
  geräteübergreifende Zwischenablage aktiv ist, dann überträgt **das System** den Screenshot
  an die anderen Geräte des Nutzers. Für Bilder kennt macOS keine
  Vertraulichkeitskennzeichnung, mit der sich das unterbinden ließe — anders als für Text
  (B05/AK-17). Bewusst so belassen, Begründung unter *Befunde*, BF-07; im PRD als
  Einschränkung der Datenschutzzusage ausgewiesen.
- **AK-34** · Angenommen, das Sichern schlägt fehl, wenn der Fehler auftritt, dann erscheint
  eine Kurzmeldung und **der Editor bleibt offen**, damit die Arbeit nicht verloren geht.
- **AK-35** · Angenommen, Anmerkungen bestehen, wenn der Editor geschlossen wird, dann
  werden sie nirgends gespeichert.

## Edge Cases

- **EC-01** · Sehr großes Bild → Fenster auf 80 % der Bildschirmgröße begrenzt.
- **EC-02** · Anmerkung außerhalb des Bildes gezeichnet → wird gezeichnet, aber beim Export
  auf die Bildfläche beschnitten.
- **EC-03** · Leeres Textfeld bestätigt → es entsteht keine Anmerkung.
- **EC-04** · Rückgängig über den Anfang hinaus → keine Wirkung.
- **EC-05** · Editor geschlossen, während die Texterkennung läuft → das Ergebnisfenster
  erscheint dennoch.
- **EC-06** · Anheften bei erreichter Obergrenze → der Editor schließt sich, kein Fenster
  erscheint (B08/AK-11).

## Befunde

### Behoben

- **FB-02 · `⌘S` sicherte an einen festen Ort und im festen Format** — behoben 2026-08-25.
  Es folgt den Einstellungen und ersetzt die automatisch gesicherte Datei.
- **FB-03 · `⌘S` kopierte zusätzlich in die Zwischenablage** — behoben 2026-08-25.
- **FB-04 · Fehlgeschlagenes Sichern blieb unbemerkt und schloss trotzdem** — behoben
  2026-08-25. `CaptureLog` meldet, und der Editor bleibt offen.
- **FB-05 · Namenskollision beim Sichern** — behoben 2026-08-25 über
  `AppPreferences.uniqueCaptureURL(in:)`.
- **FB-08 · Keine Tests** — teilweise behoben 2026-08-25: Die Umrechnung zwischen Ansicht
  und Bildpixeln bleibt an `NSView` gebunden und damit manuell zu prüfen, die Zensurstärke
  und die Namensbildung sind abgedeckt.

### Akzeptiert

- **BF-01 · Kein bearbeitbarer Projektstand** — akzeptiert 2026-08-25. Der Editor ist ein
  Durchgangsschritt zwischen Aufnahme und Ergebnis; ein eigenes Dateiformat wäre ein
  Produkt für sich und gehört als neues Feature durch die volle Kette.
- **BF-06 · `AnnotationSnapshot.data` ist untypisiert** — akzeptiert 2026-08-25. Eine
  typisierte Momentaufnahme je Annotationsart wäre neun zusätzliche Typen für einen Pfad,
  der ausschließlich innerhalb einer Annotation gelesen und geschrieben wird.
- **BF-07 · Die Zwischenablage trägt keine Vertraulichkeitskennzeichnung für Bilder** —
  akzeptiert 2026-08-25. Für Text gibt es die Kennzeichnung und sie wird gesetzt (B05); für
  Bilder kennt macOS keine, und die geräteübergreifende Zwischenablage lässt sich von einer
  Anwendung nicht abwählen. Im PRD als Einschränkung der Datenschutzzusage ausgewiesen.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · `⌘S` in den eingestellten Ordner? | ja, mit dem eingestellten Format — und es ersetzt die automatisch gesicherte Datei | 2026-08-25 |
| OF-02 · `⌘S` weiterhin zusätzlich kopieren? | nein — Sichern und Kopieren sind zwei Absichten, und die stille Übernahme der Zwischenablage war überraschend | 2026-08-25 |
| OF-03 · Bearbeitbarer Projektstand? | nein, siehe BF-01 | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie sind Anmerkungen aufgebaut? | Protokoll, jede zeichnet sich selbst | neue Werkzeuge kommen hinzu, ohne den Renderer zu ändern |
| 2 | In welchem Koordinatenraum wird gearbeitet? | in Bildpixeln, Darstellung über eine affine Abbildung | Anmerkungen bleiben unabhängig von Vergrößerung und Fenstergröße richtig platziert |
| 3 | Wie funktioniert Rückgängig? | `UndoManager` mit Momentaufnahmen je Anmerkung | Bordmittel; der Preis ist die untypisierte Ablage (FB-06) |
| 4 | Werkzeugleiste in SwiftUI, Zeichenfläche in AppKit | alles in einem | Zeichnen mit Mausereignissen ist in AppKit direkter; die Leisten sind eingebettete SwiftUI-Ansichten |
| 5 | Wie wird die Leertaste erkannt? | eigener Ereignisbeobachter | ausdrücklich kommentiert: `flagsChanged` meldet die Leertaste nicht |
| 6 | Warum schließt der Editor nach Kopieren und Sichern? | Aufnahme ist ein Durchgangsvorgang | erkennbar bewusst — der Editor ist kein Arbeitsplatz, sondern ein Zwischenschritt |
| 7 | `⌘S` in den eingestellten Ordner (3.5.0) | auf den Schreibtisch | zwei Speicherorte mit verschiedenen Regeln waren nicht erklärbar; die Einstellung gab es bereits |
| 8 | Fehlschlag hält den Editor offen (3.5.0) | trotzdem schließen | ein geschlossener Editor ohne Datei bedeutet Datenverlust ohne Rettungsweg |
