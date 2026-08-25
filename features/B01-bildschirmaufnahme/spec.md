# B01 · Bildschirmaufnahme — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut** — nicht, was sie tun sollte. Kriterien mit ⚠
> beschreiben Verhalten, das fragwürdig aussieht; sie sind bewusst als Kriterium
> aufgenommen, damit `sdd-qa` sie reproduziert, und stehen zur Klärung.

## Zweck

Der Nutzer nimmt den Bildschirminhalt auf — ganz, als gezogenen Bereich oder als
einzelnes Fenster — ohne die Anwendung zu wechseln, in der er gerade arbeitet. Jede
Aufnahme landet unmittelbar im Annotationseditor.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B02 App-Ausschluss | `bestand` | liefert die Liste der Fenster, die nie erscheinen dürfen |
| B10 Tastenkombinationen | `bestand` | löst drei der vier Aufnahmearten aus |
| B12 Ersteinrichtung | `bestand` | führt zur Bildschirmaufnahme-Berechtigung, ohne die nichts geht |
| B03 Annotationseditor | `bestand` | ist das Ziel jeder Aufnahme |
| B09 Verlauf | `bestand` | sichert jede Aufnahme automatisch |

## User Stories

- **US-01** · Als Nutzer möchte ich den ganzen Bildschirm aufnehmen, ohne vorher etwas
  auszuwählen, damit ein Tastendruck genügt.
- **US-02** · Als Nutzer möchte ich einen Bereich aufziehen und dabei sehen, wie groß er
  in Pixeln ist, damit ich genau den Ausschnitt bekomme, den ich brauche.
- **US-03** · Als Nutzer möchte ich ein einzelnes Fenster aufnehmen, ohne den Hintergrund
  mitzunehmen, damit das Ergebnis ohne Nachbearbeitung brauchbar ist.
- **US-04** · Als Nutzer möchte ich beim Fenstermodus sehen, welches Fenster ich treffe,
  bevor ich klicke, damit ich nicht das falsche erwische.
- **US-05** · Als Nutzer möchte ich erkennen, wenn eine Aufnahme fehlschlägt, damit ich
  nicht auf ein Bild warte, das nie kommt.

## Nicht im Scope

- Bildschirmvideo und GIF — nicht vorhanden; ob bewusst, ist offen (`docs/prd.md`, OF-01)
- Zeitverzögerte Aufnahme — nicht vorhanden
- Scrollende Aufnahme ganzer Seiten — nicht vorhanden
- Die Ausschlussliste selbst gehört zu **B02**, hier wird sie nur angewandt

## Akzeptanzkriterien

### Vollbild

- **AK-01** · Angenommen, die Bildschirmaufnahme-Berechtigung ist erteilt, wenn `⌃⇧⌘3`
  gedrückt oder *Capture Full Screen* im Menü gewählt wird, dann wird der Bildschirm ohne
  weitere Rückfrage aufgenommen und der Annotationseditor öffnet sich mit dem Ergebnis.
- **AK-02** ⚠ · Angenommen, zwei Displays sind angeschlossen, wenn eine Vollbildaufnahme
  ausgelöst wird, dann wird **immer das von ScreenCaptureKit zuerst gelieferte Display**
  aufgenommen — unabhängig davon, wo der Mauszeiger steht oder welches Fenster aktiv ist.
  *(`CaptureEngine.swift:120` nimmt `content.displays.first`. Es gibt keine Auswahl und
  keinen Hinweis. Zur Klärung vorgelegt.)*
- **AK-03** ⚠ · Angenommen, das aufgenommene Display hat keinen Retina-Faktor 2, wenn eine
  Vollbildaufnahme ausgelöst wird, dann entsteht ein Bild mit der doppelten Pixelzahl der
  tatsächlichen Auflösung.
  *(`CaptureEngine.swift:130` multipliziert die Displaygröße fest mit 2, statt
  `pointPixelScale` des Filters zu benutzen — dieselbe Fehlerklasse, die 3.4.1 für
  Fensteraufnahmen behoben hat. Zur Klärung vorgelegt.)*

### Bereich

- **AK-04** · Angenommen, `⌃⇧⌘4` wird gedrückt, wenn die Auswahl erscheint, dann liegt
  über **jedem** angeschlossenen Display eine abgedunkelte Fläche mit Fadenkreuz-Zeiger.
- **AK-05** · Angenommen, die Bereichsauswahl ist aktiv, wenn mit gedrückter Maustaste
  gezogen wird, dann ist der gewählte Bereich unverdunkelt, von einer gestrichelten weißen
  Linie umgeben, und daneben steht laufend die Größe im Format `<Breite> × <Höhe> px`.
- **AK-06** · Angenommen, die Bereichsauswahl ist aktiv, wenn `Escape` gedrückt wird, dann
  verschwindet die Auswahl ohne Aufnahme.
- **AK-07** · Angenommen, die Bereichsauswahl ist aktiv, wenn ein Bereich kleiner als
  4 × 4 Punkte gezogen wird, dann gilt das als Abbruch und es entsteht keine Aufnahme.
- **AK-08** ⚠ · Angenommen, zwei Displays sind angeschlossen, wenn ein Bereich auf dem
  **zweiten** Display gezogen wird, dann entsteht **nicht** der gewählte Ausschnitt: Die
  Auswahl wird gegen das erste Display gerechnet.
  *(`CaptureEngine.swift:150-160` filtert auf `displays.first` und rechnet den y-Versatz
  gegen dessen Höhe, während die Auswahl globale AppKit-Koordinaten über alle Displays
  liefert. Die Anwendung besitzt in `ScreenGeometry.swift` genau die Umrechnung, die hier
  fehlt — sie wird an dieser Stelle nicht benutzt. Zur Klärung vorgelegt.)*
- **AK-09** ⚠ · Angenommen, das Display, auf dem gewählt wurde, hat einen anderen
  Skalierungsfaktor als das Display mit dem Tastaturfokus, wenn die Aufnahme entsteht,
  dann hat sie die falsche Auflösung.
  *(`CaptureEngine.swift:162` benutzt `NSScreen.main?.backingScaleFactor`. `NSScreen.main`
  folgt dem Schlüsselfenster, nicht der Maus — der Dateikommentar in
  `ScreenGeometry.swift:12` benennt genau dieses Problem. Zur Klärung vorgelegt.)*

### Fenster

- **AK-10** · Angenommen, mehrere Fenster sind offen, wenn *Capture Window…* im Menü
  gewählt wird, dann wird das Fenster unter dem Mauszeiger hervorgehoben und mit Symbol,
  Programmname und Pixelgröße beschriftet.
- **AK-11** · Angenommen, die Fensterauswahl ist aktiv, wenn auf ein hervorgehobenes
  Fenster geklickt wird, dann wird genau dieses Fenster aufgenommen — ohne Hintergrund
  und ohne die Auswahl-Oberfläche.
- **AK-12** · Angenommen, die Fensterauswahl ist aktiv, wenn `Escape` oder die rechte
  Maustaste betätigt wird, dann bricht die Auswahl ohne Aufnahme ab.
- **AK-13** · Angenommen, `⌃⇧⌘5` wird gedrückt, wenn ein anderes Programm im Vordergrund
  ist, dann wird dessen vorderstes Fenster ohne Rückfrage aufgenommen.
- **AK-14** · Angenommen, ein Fenster liegt auf einem Display mit anderem
  Skalierungsfaktor, wenn es aufgenommen wird, dann entspricht die Auflösung dem Display,
  auf dem es tatsächlich liegt.
  *(Seit 3.4.1 über `SCContentFilter.contentRect` und `.pointPixelScale` — im Fensterpfad
  korrekt gelöst, anders als in AK-03 und AK-09.)*
- **AK-15** · Angenommen, ein Fenster hat keinen Titel, wenn die Fensterauswahl aufgebaut
  wird, dann erscheint es trotzdem als wählbares Ziel.
- **AK-16** · Angenommen, ein Fenster ist schmaler oder niedriger als 40 Punkte, wenn die
  Fensterauswahl aufgebaut wird, dann erscheint es **nicht** als Ziel.
- **AK-17** · Angenommen, Dock, Stage Manager, Schreibtischhintergrund, Mitteilungszentrale
  oder Kontrollzentrum sind sichtbar, wenn die Fensterauswahl aufgebaut wird, dann sind sie
  **keine** wählbaren Ziele.

### Alle Aufnahmearten

- **AK-18** · Angenommen, eine Aufnahme ist entstanden, wenn sie fertig ist, dann öffnet
  sich der Annotationseditor mit dem Bild — bei jeder Aufnahmeart, ausnahmslos.
- **AK-19** · Angenommen, der Auslöseton ist aktiviert (Standard), wenn eine Aufnahme
  entsteht, dann erklingt der Systemton „Tink".
- **AK-20** · Angenommen, das automatische Sichern ist aktiviert (Standard), wenn eine
  Aufnahme entsteht, dann liegt sie danach als Datei im eingestellten Ordner.
- **AK-21** · Angenommen, ein vergrößerter oder eingefärbter Mauszeiger ist in den
  Bedienungshilfen aktiviert, wenn eine Aufnahme entsteht, dann ist der Zeiger **nicht**
  im Bild.
- **AK-22** · Angenommen, die Aufnahme schlägt fehl, wenn der Fehler auftritt, dann
  erscheint eine Kurzmeldung am Bildschirm und der Fehler steht unter dem Subsystem
  `com.mika.mikaplusscreensnap` in der Konsole.
- **AK-23** · Angenommen, die Bildschirmaufnahme-Berechtigung fehlt, wenn eine Aufnahme
  ausgelöst wird, dann erscheint die Meldung „Screen Recording permission required".

### Datenschutz und Missbrauchsschutz

Katalog: `~/.claude/sdd/sicherheit.md`, Stufe A (`docs/prd.md`) — Abschnitte 4 und 6
verkürzt, Abschnitt 1 (Logs) ausdrücklich in Kraft.

- **AK-24** · Angenommen, eine App steht auf der Ausschlussliste, wenn eine Aufnahme
  jedweder Art entsteht, dann ist kein Fenster dieser App darin enthalten.
- **AK-25** · Angenommen, eine Aufnahme entsteht, wenn sie fertig ist, dann enthalten die
  Protokolle weder Bildinhalte noch erkannten Text noch den Namen des aufgenommenen
  Fensters.
- **AK-26** · Angenommen, eine Aufnahme entsteht, wenn sie fertig ist, dann verlässt kein
  Byte davon den Rechner.
- **AK-27** · Angenommen, die Anwendung nimmt auf, wenn die Aufnahme entsteht, dann sind
  eigene Fenster der Anwendung (Auswahl-Overlays, Editor, Panels) nicht enthalten.

*Zu Abschnitt 4 des Katalogs (Rate Limits): trifft nicht zu — die Aufnahme kostet kein
Geld, ruft keinen fremden Dienst und ist rein lokal. Zu Abschnitt 6 (Geheimnisse):
trifft nicht zu — dieses Feature braucht keine Schlüssel.*

## Edge Cases

- **EC-01** · Kein Display gefunden → Meldung „No display available", keine Aufnahme.
- **EC-02** · Kein aufnehmbares Fenster vorhanden → Meldung „No window to capture".
- **EC-03** · Fenster mit leerem Inhaltsrechteck → Meldung „Window has no capturable
  content", keine Aufnahme.
- **EC-04** · Fenster wird zwischen Auswahl und Klick geschlossen → die Aufnahme schlägt
  fehl und meldet sich als Kurzmeldung.
- **EC-05** · Fenster liegt über zwei Displays → wird als **ein** Ziel behandelt und
  vollständig aufgenommen.
- **EC-06** · Bereichsauswahl aktiv, während der Bildschirmschoner startet → Panels liegen
  auf `.screenSaver`-Ebene; Verhalten ungeprüft.
- **EC-07** · Aufnahme wird ausgelöst, während bereits eine Auswahl läuft → die alte
  Auswahl wird verworfen (`dismissAreaSelection` bzw. `dismissWindowSelection` zuerst).

## Fehlbestand

Nicht vorhanden, aus dem Code belegt. **Kein Kriterium** — `sdd-qa` prüft nichts davon als
bestanden, sondern nimmt es als Suchliste.

- **FB-01 · Kein Display-Bezug bei Vollbild und Bereich.** `CaptureEngine.swift:120` und
  `:150` verwenden `content.displays.first`. Es gibt keinen Weg, ein anderes Display zu
  wählen, und keinen Hinweis darauf, dass nur eines aufgenommen wird. Folge: Auf
  Mehrschirm-Arbeitsplätzen nimmt die App regelmäßig den falschen Bildschirm auf, und die
  Bereichsauswahl liefert einen falschen Ausschnitt (AK-08).
- **FB-02 · `ScreenGeometry` wird im Aufnahmepfad nicht benutzt.**
  `ScreenGeometry.swift:11-19` existiert genau für die korrekte Umrechnung über mehrere
  Displays und warnt im Kommentar ausdrücklich vor `NSScreen.main`.
  `CaptureEngine.swift:162` und `:335` benutzen trotzdem
  `NSScreen.main?.backingScaleFactor`. Folge: Die vorhandene Lösung greift an der Stelle
  nicht, für die sie geschrieben wurde.
- **FB-03 · Erkennt keine fehlende Berechtigung, bevor es zu spät ist.** Die
  Aufnahmebefehle sind auch ohne Berechtigung auslösbar; der Fehlschlag wird erst danach
  gemeldet. `MikaScreenSnapApp.swift:159` zeigt zwar einen Warneintrag im Menü, blockiert
  aber nichts. Folge: Der Weg zur Berechtigung führt durch einen misslungenen Versuch.
- **FB-04 · Keine Tests.** Es existiert kein `Tests/`-Verzeichnis. Die Koordinaten- und
  Skalierungslogik in `CaptureEngine` und `ScreenGeometry` ist reine Rechnung ohne UI und
  damit gut testbar — geprüft wird sie nirgends. Folge: Genau die Fehlerklasse, die 3.4.1
  im Fensterpfad behoben hat, ist im Bereichs- und Vollbildpfad unbemerkt geblieben.
- **FB-05 · `startMeasurement(appState:)` ignoriert seinen Parameter.**
  `CaptureEngine.swift:395` nimmt `appState` entgegen und benutzt es nicht. Folge: keine
  unmittelbare, aber die Ausschlussliste greift dadurch in B07 nicht.

## Offene Fragen

- **OF-01** · Soll die Vollbildaufnahme das Display unter dem Mauszeiger nehmen, alle
  Displays zu einem Bild verbinden, oder weiterhin nur das erste? — entscheidet der Autor.
- **OF-02** · Soll die Bereichsauswahl über Displaygrenzen hinweg funktionieren, oder
  reicht es, sie auf das Display zu beschränken, auf dem gezogen wurde? — entscheidet der
  Autor.
- **OF-03** · Sollen Aufnahmebefehle bei fehlender Berechtigung deaktiviert sein, statt
  fehlzuschlagen? — entscheidet der Autor, betrifft auch B12.

## Decision Log

Rekonstruiert aus Code und `CHANGELOG.md`; wo die Absicht nicht belegbar ist, steht das so.

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie wird aufgenommen? | ScreenCaptureKit statt `CGWindowListCreateImage` | 3.4.1 hat den letzten Rest der veralteten API ersetzt; SCK ist ab macOS 14 der einzige unterstützte Weg |
| 2 | Wie wird das vorderste Fenster gefunden? | `NSWorkspace.frontmostApplication`, sonst das vorderste der Liste | Die App aktiviert sich nie (`.accessory`), also bleibt beim Hotkey die vorherige App vorn |
| 3 | Welche Fenster sind Ziele? | Ebenen 0–19, mindestens 40 × 40 Punkte, ohne Dock/Stage Manager/Wallpaper | 3.4.1 hat den vorherigen Filter ersetzt, der die hinterste statt der vordersten Ebene wählte und titellose Fenster ausschloss |
| 4 | Wie wird der Zeiger unterdrückt? | `showsCursor = false` plus eigene Erkennung des „Cursor"-Fensters | `showsCursor` unterdrückt nur den Hardware-Zeiger; Bedienungshilfen-Zeiger sind gewöhnliche Fenster |
| 5 | Warum 100 ms Verzögerung vor der Aufnahme? | fest verdrahtete Pause nach dem Schließen der Overlays | Grund nicht dokumentiert, erkennbar: die eigenen Panels sollen verschwunden sein, bevor aufgenommen wird |
| 6 | Warum `shouldBeOpaque = false` nur bei Fenstern? | Fenster behalten ihre Transparenz, Vollbild und Bereich nicht | Erkennbar bewusst: ein Fenster mit runden Ecken soll keinen schwarzen Rand bekommen |
