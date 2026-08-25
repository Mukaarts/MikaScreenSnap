# B03 · Anmerkungs-Editor — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.
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
- **AK-26** ⚠ · Angenommen, `⌘S` wird gedrückt, wenn die Aktion ausgeführt wird, dann wird
  das Bild **auf den Schreibtisch** gesichert — nicht in den eingestellten Verlaufsordner —
  **und zusätzlich in die Zwischenablage gelegt**.
  *(`AnnotationEditor.swift:300-306` ruft beides. Der Speicherort ist fest der Schreibtisch
  (`ClipboardManager.swift:18`) und ignoriert die Einstellung. Zur Klärung vorgelegt.)*
- **AK-27** ⚠ · Angenommen, `⌘S` oder *Save As* werden benutzt, wenn die Datei entsteht, dann
  ist sie **immer PNG** — auch wenn in den Einstellungen JPEG gewählt ist.
  *(`ClipboardManager.swift:33` schreibt ausschließlich PNG. Der Verlauf beachtet die
  Einstellung, der Editor nicht. Zur Klärung vorgelegt.)*
- **AK-28** · Angenommen, `⇧⌘S` wird gedrückt, wenn der Dialog erscheint, dann kann Ort und
  Name frei gewählt werden.
- **AK-29** · Angenommen, keine Anmerkungen bestehen, wenn `Escape` gedrückt wird, dann wird
  das unveränderte Bild in die Zwischenablage gelegt und der Editor schließt sich.
- **AK-30** · Angenommen, Anmerkungen bestehen und sind ungesichert, wenn `Escape` gedrückt
  wird, dann erscheint die Rückfrage „Discard Changes?".
- **AK-31** ⚠ · Angenommen, zwei Bilder werden innerhalb derselben Sekunde mit `⌘S`
  gesichert, wenn beide geschrieben werden, dann **überschreibt das zweite das erste**.
  *(`ClipboardManager.swift:14` bildet den Namen mit Sekundengenauigkeit — dieselbe
  Fehlerklasse wie B09/AK-07. Zur Klärung vorgelegt.)*

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 ausdrücklich in Kraft.

- **AK-32** · Angenommen, ein Bild wird ausgegeben, wenn gerendert wird, dann enthält das
  Ergebnis alle Anmerkungen flach eingerechnet — keine Ebenen, keine wiederherstellbaren
  Originalbereiche.
- **AK-33** ⚠ · Angenommen, ein Bild wird in die Zwischenablage gelegt, wenn die
  geräteübergreifende Zwischenablage aktiv ist, dann überträgt das System **den gesamten
  Screenshot** an die anderen Geräte des Nutzers.
  *(`ClipboardManager.swift:8`, ohne Vertraulichkeitsmarkierung. Gewichtiger als bei B05,
  weil es um das vollständige Bild geht. Zur Klärung vorgelegt.)*
- **AK-34** ⚠ · Angenommen, das Sichern schlägt fehl, wenn der Fehler auftritt, dann erfährt
  der Nutzer nichts — der Editor schließt sich trotzdem.
  *(`ClipboardManager.swift:32` und `:40` schreiben in ein `print()`; `save()` ruft
  anschließend `close()` unabhängig vom Ergebnis. Zur Klärung vorgelegt — dies bedeutet
  stillen Datenverlust.)*
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

## Fehlbestand

- **FB-01 · Kein bearbeitbarer Projektstand.** Anmerkungen leben ausschließlich im
  Arbeitsspeicher (`AnnotationStore`). Folge: Ein geschlossener Editor verliert alles; ein
  exportiertes PNG ist nicht wieder bearbeitbar. *Open in Editor* aus dem Verlauf öffnet
  das Originalbild ohne die früheren Anmerkungen.
- **FB-02 · `⌘S` sichert an einen festen Ort und im festen Format.** Fundstellen:
  `ClipboardManager.swift:18` (Schreibtisch), `:33` (immer PNG). Folge: Die Einstellungen
  zu Ordner und Format gelten nur für das automatische Sichern; der Nutzer hat zwei Orte
  mit unterschiedlichem Verhalten.
- **FB-03 · `⌘S` kopiert zusätzlich in die Zwischenablage.** Fundstelle:
  `AnnotationEditor.swift:304`. Folge: Ein Sichern überschreibt unerwartet den
  Zwischenablageinhalt.
- **FB-04 · Fehlgeschlagenes Sichern bleibt unbemerkt und schließt trotzdem.** Fundstellen:
  `ClipboardManager.swift:32`, `:40`, `AnnotationEditor.swift:306`. Folge: stiller
  Datenverlust — die schwerste Ausprägung des projektweiten Befunds FB-AS-03.
- **FB-05 · Namenskollision beim Sichern auf den Schreibtisch.** Fundstelle:
  `ClipboardManager.swift:14`. Wie B09/FB-02.
- **FB-06 · `AnnotationSnapshot.data` ist untypisiert.** Fundstelle:
  `AnnotationModels.swift:104`. Folge: Fehler im Rückgängig-Pfad fallen erst zur Laufzeit
  auf, und nur wenn genau dieser Pfad läuft.
- **FB-07 · Die Zwischenablage ist nicht als vertraulich markiert.** Fundstelle:
  `ClipboardManager.swift:6-9`. Folge: siehe AK-33.
- **FB-08 · Keine Tests.** Die Koordinatenumrechnung zwischen Ansicht und Bildpixeln
  (`viewToImage`, `imageToView`) ist reine Rechnung und ideal prüfbar — sie trägt AK-23,
  von dem jede Anmerkung abhängt.

## Offene Fragen

- **OF-01** · Soll `⌘S` in den eingestellten Ordner sichern und das eingestellte Format
  benutzen? — entscheidet der Autor.
- **OF-02** · Soll `⌘S` weiterhin zusätzlich kopieren? — entscheidet der Autor.
- **OF-03** · Soll es einen bearbeitbaren Projektstand geben? — entscheidet der Autor.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie sind Anmerkungen aufgebaut? | Protokoll, jede zeichnet sich selbst | neue Werkzeuge kommen hinzu, ohne den Renderer zu ändern |
| 2 | In welchem Koordinatenraum wird gearbeitet? | in Bildpixeln, Darstellung über eine affine Abbildung | Anmerkungen bleiben unabhängig von Vergrößerung und Fenstergröße richtig platziert |
| 3 | Wie funktioniert Rückgängig? | `UndoManager` mit Momentaufnahmen je Anmerkung | Bordmittel; der Preis ist die untypisierte Ablage (FB-06) |
| 4 | Werkzeugleiste in SwiftUI, Zeichenfläche in AppKit | alles in einem | Zeichnen mit Mausereignissen ist in AppKit direkter; die Leisten sind eingebettete SwiftUI-Ansichten |
| 5 | Wie wird die Leertaste erkannt? | eigener Ereignisbeobachter | ausdrücklich kommentiert: `flagsChanged` meldet die Leertaste nicht |
| 6 | Warum schließt der Editor nach Kopieren und Sichern? | Aufnahme ist ein Durchgangsvorgang | erkennbar bewusst — der Editor ist kein Arbeitsplatz, sondern ein Zwischenschritt |
| 7 | `⌘S` auf den Schreibtisch statt in den Verlaufsordner | in den eingestellten Ordner | **Grund nicht erkennbar** (FB-02) |
