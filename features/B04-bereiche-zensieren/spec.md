# B04 · Bereiche zensieren — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ beschreiben Verhalten, das
> fragwürdig aussieht, und stehen zur Klärung.
>
> **Dieses Feature ist eine Datenschutzzusage, kein Zeichenwerkzeug.** Wer einen Bereich
> verpixelt, verlässt sich darauf, dass der Inhalt danach weg ist. Jede Abweichung davon
> ist ein Datenleck, nicht ein Darstellungsfehler — das ist der Maßstab für alles Folgende.

## Zweck

Der Nutzer macht Teile einer Aufnahme unkenntlich — ein Passwort, einen Namen, ein
Gesicht — bevor er sie weitergibt. Zwei Verfahren stehen bereit: Weichzeichnen und
Verpixeln.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B03 Annotationseditor | `bestand` | beherbergt die Werkzeuge, das Undo und den Export |
| B01 Bildschirmaufnahme | `bestand` | liefert das Bild |
| B09 Verlauf | `bestand` | **sichert das Original, bevor zensiert werden kann** — siehe FB-01 |

## User Stories

- **US-01** · Als Nutzer möchte ich ein Rechteck über einem Passwort aufziehen und es
  unlesbar machen, damit ich den Screenshot weitergeben kann.
- **US-02** · Als Nutzer möchte ich zwischen Weichzeichnen und Verpixeln wählen, damit ich
  das Verfahren nehmen kann, das im jeweiligen Bild besser aussieht.
- **US-03** · Als Nutzer möchte ich einen zensierten Bereich verschieben und in der Größe
  ändern können, damit ich ihn nicht neu ziehen muss.

## Nicht im Scope

- Automatisches Erkennen sensibler Inhalte (Gesichter, Kartennummern) — nicht vorhanden
- Zensieren nicht-rechteckiger Bereiche — nicht vorhanden
- Einstellbare Stärke der Zensur — nicht vorhanden, siehe AK-09
- Der Export selbst gehört zu **B03**

## Akzeptanzkriterien

- **AK-01** · Angenommen, der Editor ist offen, wenn `B` gedrückt oder das Weichzeichnen
  in der Werkzeugleiste gewählt wird, dann folgt dem Zeiger ein Fadenkreuz.
- **AK-02** · Angenommen, das Weichzeichnen ist aktiv, wenn ein Rechteck aufgezogen wird,
  dann ist der Bereich während des Ziehens durch eine gestrichelte weiße Linie
  gekennzeichnet und nach dem Loslassen weichgezeichnet.
- **AK-03** · Angenommen, das Verpixeln ist aktiv (`X`), wenn ein Rechteck aufgezogen wird,
  dann ist der Bereich nach dem Loslassen in Blöcke zerlegt.
- **AK-04** · Angenommen, ein Rechteck kleiner als 3 × 3 Bildpunkte wird gezogen, wenn
  losgelassen wird, dann entsteht **keine** Zensur.
- **AK-05** · Angenommen, ein Bereich ist zensiert, wenn `⌘Z` gedrückt wird, dann ist der
  Originalinhalt wieder sichtbar.
- **AK-06** · Angenommen, ein Bereich ist zensiert, wenn er mit dem Auswahlwerkzeug
  verschoben oder in der Größe geändert wird, dann wandert die Zensur mit und zeigt den
  Inhalt an der neuen Stelle verfremdet.
- **AK-07** · Angenommen, ein Bereich ist zensiert, wenn das Bild kopiert, gesichert oder
  angeheftet wird, dann ist der Bereich im Ergebnis unkenntlich — bei allen vier
  Ausgabewegen (`⌘C`, `⌘S`, `⇧⌘S`, Anheften).
- **AK-08** · Angenommen, ein zensierter Bereich ragt über den Bildrand hinaus, wenn
  gerendert wird, dann wird nur der Teil innerhalb des Bildes verfremdet und es entsteht
  kein Fehler.

### Wirksamkeit der Zensur

- **AK-09** ⚠ · Angenommen, ein Bereich wird zensiert, wenn er gerendert wird, dann ist die
  Stärke **fest**: Weichzeichnen mit Radius 15, Verpixeln mit Blockgröße 10 — jeweils in
  **Bildpixeln**, nicht in Bildschirmpunkten.
  *(`AnnotationModels.swift:872` und `:956`. Bei einer Retina-Aufnahme entspricht
  Blockgröße 10 nur 5 Bildschirmpunkten — die Zensur ist dort also feiner als auf einem
  nicht skalierten Bildschirm. Es gibt keine Einstellung. Zur Klärung vorgelegt: Reicht
  das, um kleine Schrift unlesbar zu machen?)*
- **AK-10** ⚠ · Angenommen, ein Bereich wird weichgezeichnet, wenn er gerendert wird, dann
  ist die Unschärfe **an den Rändern des Bereichs schwächer als in der Mitte**.
  *(`AnnotationModels.swift:895` wendet `CIGaussianBlur` auf den zugeschnittenen Ausschnitt
  an, ohne die Kanten vorher fortzusetzen (`clampedToExtent`). Der Filter mischt am Rand
  mit dem transparenten Außenraum, wodurch dort weniger Originalinformation zerstört wird.
  Zur Klärung vorgelegt: Ist Text am Rand eines weichgezeichneten Bereichs noch lesbar
  oder rekonstruierbar?)*

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 des Katalogs ausdrücklich in Kraft. Für dieses Feature ist der
Katalog **nicht** verkürzt: Es ist die einzige Stelle, an der die Anwendung dem Nutzer
eine inhaltliche Zusage über seine Daten macht.

- **AK-11** · Angenommen, ein Bereich ist zensiert, wenn das Ergebnis exportiert wird, dann
  enthält die Ausgabedatei die Originalpixel des Bereichs **nicht mehr** — auch nicht in
  Metadaten, Ebenen oder Vorschaubildern.
- **AK-12** ⚠ · Angenommen, der Nutzer zensiert einen Bereich und exportiert das Bild, wenn
  danach der Verlaufsordner geöffnet wird, dann liegt dort **die unzensierte
  Originalaufnahme**.
  *(`CaptureEngine.swift:427` ruft `historyManager.autoSave(image)` mit dem Originalbild,
  **bevor** der Editor überhaupt öffnet. Kein Pfad ersetzt oder löscht diese Datei später.
  Das exportierte Bild ist zensiert, die automatisch gesicherte Datei nicht. Zur Klärung
  vorgelegt — dies ist der schwerwiegendste Einzelbefund der gesamten Erfassung.)*
- **AK-13** · Angenommen, ein Bereich ist zensiert, wenn das Bild in die Zwischenablage
  kopiert wird, dann enthält die Zwischenablage nur das gerenderte, zensierte Bild.

## Edge Cases

- **EC-01** · Zensur vollständig außerhalb des Bildes → wird nicht gezeichnet, kein Fehler.
- **EC-02** · Zensur über die gesamte Bildfläche → funktioniert, das ganze Bild wird
  verfremdet.
- **EC-03** · Mehrere überlappende Zensuren → jede zeichnet aus dem **Original**, nicht aus
  dem Ergebnis der vorherigen; überlappende Bereiche werden also nicht doppelt verfremdet.
- **EC-04** · Zensur wird auf null Breite oder Höhe skaliert → wird nicht gezeichnet.
- **EC-05** · Zensur und danach `⌘Z`, `⇧⌘Z`, dann Export → das Wiederherstellen muss die
  Zensur wieder wirksam machen.

## Fehlbestand

- **FB-01 · Die unzensierte Originalaufnahme bleibt dauerhaft auf der Festplatte.**
  Fundstelle: `CaptureEngine.swift:427` (`postCapture` sichert vor dem Öffnen des Editors),
  `AppPreferences.swift:168` (`saveImage`). Folge: **Die Zensur schützt das Weitergegebene,
  nicht das Gespeicherte.** Wer ein Passwort verpixelt und den Screenshot verschickt, hat
  das unverpixelte Bild weiterhin in `~/Pictures/MikaScreenSnap/` liegen — sichtbar für
  jeden mit Zugriff auf den Rechner, in jedem Backup, in jeder Cloud-Synchronisation dieses
  Ordners. Der Nutzer wird darauf an keiner Stelle hingewiesen.
- **FB-02 · Weichzeichnen ohne Kantenfortsetzung.** Fundstelle:
  `AnnotationModels.swift:891-899`. Folge: Am Rand des Bereichs ist die Unschärfe
  schwächer; ein Wort, das genau an der Kante liegt, kann teilweise lesbar bleiben. Der
  übliche Weg — die Kanten vor dem Filtern fortzusetzen — wird nicht gegangen.
- **FB-03 · Die Zensurstärke ist nicht einstellbar und nicht auflösungsbezogen.**
  Fundstelle: `AnnotationModels.swift:872`, `:956`. Folge: Bei hoher Auflösung ist die
  Zensur relativ schwächer, ohne dass der Nutzer gegensteuern kann.
- **FB-04 · Keine Warnung vor unwirksamer Zensur.** Es gibt keine Prüfung, ob der zensierte
  Bereich noch Kontrastkanten enthält, und keinen Hinweis auf FB-01. Folge: Der Nutzer hat
  keinen Anlass zu misstrauen.
- **FB-05 · Keine Tests.** Die Wirksamkeit einer Zensur ist maschinell prüfbar — etwa indem
  Text ins Bild gerendert, zensiert und anschließend die Texterkennung darauf angesetzt
  wird. Die Anwendung hat die Texterkennung bereits an Bord (B05). Geprüft wird nichts.

## Offene Fragen

- **OF-01** · Soll das automatische Sichern erst **nach** dem Schließen des Editors
  geschehen, oder soll die Originaldatei beim Export ersetzt werden? — entscheidet der
  Autor. Betrifft B09 unmittelbar.
- **OF-02** · Soll die Zensurstärke einstellbar sein? — entscheidet der Autor.
- **OF-03** · Ist Weichzeichnen als Zensurverfahren überhaupt zulässig, oder sollte nur
  Verpixeln angeboten werden? — entscheidet der Autor. Weichzeichnen gilt allgemein als
  das schwächere Verfahren.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Zensur als Annotation oder als Bildänderung? | als Annotation | umkehrbar über das gewöhnliche Undo; das Original bleibt bis zum Export erhalten |
| 2 | Woher kommt der Inhalt des zensierten Bereichs? | aus dem Originalbild, bei jedem Zeichnen neu | erlaubt Verschieben und Skalieren ohne Qualitätsverlust — hat aber zur Folge, dass sich überlappende Zensuren nicht verstärken (EC-03) |
| 3 | Welche Filter? | `CIGaussianBlur` und `CIPixellate` | Systemfilter, keine eigene Implementierung |
| 4 | Feste Stärke | Radius 15 · Blockgröße 10 | **Grund nicht erkennbar** — keine Herleitung im Code, keine Einstellung |
| 5 | Warum kein `clampedToExtent` vor dem Weichzeichnen? | — | **Grund nicht erkennbar**; erkennbar ist nur, dass auf die Originalausdehnung zurückgeschnitten wird (siehe FB-02) |
