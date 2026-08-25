# B07 · Lineal / Bildschirm vermessen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde bearbeitet in 3.5.0**

> Beschrieben ist, **was der Code tut**. Das markierte Kriterium ist behoben.

## Zweck

Der Nutzer misst Abstände und Flächen — entweder direkt auf dem Bildschirm über ein
Vollbild-Overlay oder innerhalb einer bereits geöffneten Aufnahme im Editor. Messungen sind
Hilfslinien, keine Anmerkungen: Sie erscheinen in keinem Export.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B03 Annotationseditor | `bestand` | beherbergt die zweite Ausprägung als Werkzeug `M` |
| B10 Tastenkombinationen | `bestand` | `⇧⌘8` für das Overlay |

## User Stories

- **US-01** · Als Nutzer möchte ich den Abstand zweier Punkte auf dem Bildschirm messen,
  ohne einen Screenshot zu machen.
- **US-02** · Als Nutzer möchte ich die Größe eines Bereichs in Pixeln kennen.
- **US-03** · Als Nutzer möchte ich zwischen Pixeln und Punkten umschalten.

## Nicht im Scope

- Messungen speichern oder exportieren — ausdrücklich nicht, siehe AK-09
- Winkelmessung — nicht vorhanden
- Kalibrierung auf andere Einheiten (Millimeter, Zoll) — nicht vorhanden

## Akzeptanzkriterien

### Vollbild-Overlay (`⇧⌘8`)

- **AK-01** · Angenommen, `⇧⌘8` wird gedrückt oder *Measure* gewählt, wenn das Overlay
  erscheint, dann liegt es über dem Bildschirm und der Zeiger wird von Hilfslinien
  begleitet.
- **AK-02** · Angenommen, das Overlay ist aktiv, wenn nacheinander zwei Punkte angeklickt
  werden, dann erscheinen beide Punkte, die Verbindungslinie und der Abstand als Zahl.
- **AK-03** · Angenommen, das Overlay ist aktiv, wenn mit gedrückter Maustaste gezogen wird,
  dann wird ein Rechteck gemessen und Breite, Höhe und Maße werden angezeigt.
- **AK-04** · Angenommen, das Overlay ist aktiv, wenn die Leertaste gedrückt wird, dann
  wechselt die Anzeige zwischen Pixeln und Punkten.
- **AK-05** · Angenommen, das Overlay ist aktiv, wenn `Escape` gedrückt wird, dann
  verschwindet es.
- **AK-06** · Angenommen, das Overlay ist aktiv, wenn es angezeigt wird, dann steht in einer
  Informationsfläche, in welcher Einheit gemessen wird.

### Werkzeug im Editor (`M`)

- **AK-07** · Angenommen, der Editor ist offen, wenn `M` gedrückt wird, dann misst ein Klick
  oder ein Ziehen im Bild — mit denselben zwei Betriebsarten.
- **AK-08** · Angenommen, im Editor wird gemessen, wenn die Vergrößerung verändert wird,
  dann bleiben die gemessenen Werte auf das Bild bezogen und ändern sich nicht.
- **AK-09** · Angenommen, eine Messung liegt im Editor vor, wenn das Bild kopiert, gesichert
  oder angeheftet wird, dann ist die Messung im Ergebnis **nicht** enthalten.
- **AK-10** · Angenommen, das Messwerkzeug ist im Editor aktiv, wenn `U` gedrückt wird, dann
  wechselt die Einheit zwischen Pixeln und Punkten. Die Leertaste bleibt dem Verschieben
  vorbehalten; im Vollbild-Overlay, wo es kein Verschieben gibt, schaltet weiterhin die
  Leertaste um.

### Datenschutz und Missbrauchsschutz

Stufe A. Dieses Feature ist das einzige mit Bildschirmbezug, das **keine Bildinhalte
liest**: Das Overlay zeichnet nur darüber.

- **AK-11** · Angenommen, das Overlay ist aktiv, wenn gemessen wird, dann wird **kein**
  Bildschirminhalt aufgenommen, gelesen oder gespeichert.
- **AK-12** · Angenommen, eine Messung wird durchgeführt, wenn sie beendet ist, dann bleibt
  nichts davon zurück — weder Datei noch Einstellung noch Protokolleintrag.

*Abschnitte 4 und 6 des Katalogs: treffen nicht zu.*

## Edge Cases

- **EC-01** · Zwei Klicks auf denselben Punkt → Abstand 0.
- **EC-02** · Messung über Displaygrenzen hinweg → Verhalten ungeprüft; das Overlay wird je
  Display angelegt.
- **EC-03** · Overlay aktiv, während eine Aufnahme ausgelöst wird → das Overlay liegt auf
  derselben Ebene wie die Bereichsauswahl; Verhalten ungeprüft.
- **EC-04** · Messwerkzeug im Editor, dann Werkzeugwechsel → die Messung verschwindet.

## Befunde

### Behoben

- **FB-01 · Die Leertaste war doppelt belegt** — behoben 2026-08-25. Im Editor wechselt `U`
  die Einheit; die Leertaste verschiebt.
- **FB-02 · `startMeasurement(appState:)` benutzte seinen Parameter nicht** — behoben
  2026-08-25. Der Parameter ist entfernt.
- **FB-03 · Der Controller wurde gehalten, aber nie freigegeben** — behoben 2026-08-25.
  `start(onDismiss:)` meldet das Ende, und die Aufnahme-Engine gibt den Verweis frei — wie
  bei der Farbpipette.

### Akzeptiert

- **BF-04 · Zwei getrennte Implementierungen** — akzeptiert 2026-08-25. Overlay und
  Editorwerkzeug arbeiten in verschiedenen Koordinatenräumen und mit verschiedenen
  Ereignisquellen; ein gemeinsamer Kern brächte eine Abstraktion, die mehr kostet als die
  Dopplung. Eine Zusammenführung wäre ein eigenes Feature.
- **BF-05 · Keine Tests** — akzeptiert 2026-08-25. Die Abstandsberechnung ist eine Zeile
  Pythagoras innerhalb einer Zeichenroutine; ein Test darüber prüfte die Standardbibliothek.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Leertaste im Messwerkzeug? | nein — sie bleibt das Verschieben; die Einheit wechselt `U` | 2026-08-25 |
| OF-02 · Die beiden Ausprägungen zusammenführen? | nein, siehe BF-04 | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Messungen als Anmerkung oder als Hilfslinie? | Hilfslinie, nicht exportiert | eine Messung ist ein Arbeitsmittel, kein Bildinhalt — ausdrücklich im Dateikopf vermerkt |
| 2 | Zwei Ausprägungen | nur das Overlay | auf dem Bildschirm messen und im Bild messen sind verschiedene Vorgänge |
| 3 | Einheitenwechsel: Leertaste im Overlay, `U` im Editor (3.5.0) | überall dieselbe Taste | im Overlay gibt es kein Verschieben, im Editor schon — dieselbe Taste hätte dort beides ausgelöst |
| 4 | Overlay ohne Bildaufnahme | Bildschirm aufnehmen und darauf messen | braucht keine Bildschirmaufnahme-Berechtigung für diesen Weg |
