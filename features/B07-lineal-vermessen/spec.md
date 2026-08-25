# B07 · Lineal / Bildschirm vermessen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.

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
- **AK-10** ⚠ · Angenommen, das Messwerkzeug ist im Editor aktiv, wenn die Leertaste gedrückt
  wird, dann schaltet die Anzeige die Einheit um **und** der Editor wechselt gleichzeitig in
  den Verschiebemodus.
  *(`AnnotationCanvasView.swift:70` beobachtet die Leertaste über einen lokalen
  Ereignisbeobachter, der das Ereignis weiterreicht; `MeasurementTool.swift:54` behandelt
  dieselbe Taste. Ein anschließendes Ziehen verschiebt den Ausschnitt, statt zu messen. Zur
  Klärung vorgelegt.)*

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

## Fehlbestand

- **FB-01 · Die Leertaste ist doppelt belegt.** Fundstellen:
  `AnnotationCanvasView.swift:70`, `Tools/MeasurementTool.swift:54`. Folge: siehe AK-10.
- **FB-02 · `startMeasurement(appState:)` benutzt seinen Parameter nicht.** Fundstelle:
  `CaptureEngine.swift:395`. Folge: keine unmittelbare — das Overlay braucht keinen
  Anwendungszustand. Der Parameter täuscht eine Abhängigkeit vor, die es nicht gibt.
- **FB-03 · Der Controller des Overlays wird gehalten, aber nie freigegeben.** Fundstelle:
  `CaptureEngine.swift:396` weist `measurementController` zu; anders als bei der Farbpipette
  gibt es keinen Rückruf, der die Zuweisung nach dem Schließen zurücknimmt. Folge: Der
  zuletzt benutzte Controller bleibt bis zum nächsten Messvorgang im Speicher — geringe
  Menge, aber ein Muster, das bei der Farbpipette bewusst anders gelöst ist.
- **FB-04 · Zwei getrennte Implementierungen derselben Sache.** `MeasurementOverlay.swift`
  (362 Zeilen) und `Tools/MeasurementTool.swift` (160 Zeilen) berechnen und zeichnen
  dasselbe auf verschiedene Weise. Folge: Eine Änderung an der Darstellung muss an zwei
  Stellen erfolgen; Abweichungen fallen nicht auf.
- **FB-05 · Keine Tests.** Abstandsberechnung und Einheitenumrechnung sind reine Rechnung.

## Offene Fragen

- **OF-01** · Soll die Leertaste im Messwerkzeug die Einheit umschalten oder verschieben? —
  entscheidet der Autor.
- **OF-02** · Sollen die beiden Ausprägungen zusammengeführt werden? — entscheidet der
  Autor; das wäre ein eigenes Feature mit eigener Nummer, kein Nachtrag hier.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Messungen als Anmerkung oder als Hilfslinie? | Hilfslinie, nicht exportiert | eine Messung ist ein Arbeitsmittel, kein Bildinhalt — ausdrücklich im Dateikopf vermerkt |
| 2 | Zwei Ausprägungen | nur das Overlay | auf dem Bildschirm messen und im Bild messen sind verschiedene Vorgänge |
| 3 | Leertaste für den Einheitenwechsel | eine Buchstabentaste | im Overlay naheliegend — im Editor kollidiert sie (FB-01) |
| 4 | Overlay ohne Bildaufnahme | Bildschirm aufnehmen und darauf messen | braucht keine Bildschirmaufnahme-Berechtigung für diesen Weg |
