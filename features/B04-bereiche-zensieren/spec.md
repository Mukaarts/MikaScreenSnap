# B04 · Bereiche zensieren — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde behoben in 3.5.0**

> Beschrieben ist, **was der Code tut**. Alle drei ⚠-Kriterien der ersten Fassung sind in
> 3.5.0 behoben — darunter der schwerste Befund der ganzen Erfassung (AK-12).
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

- **AK-09** · Angenommen, ein Bereich wird zensiert, wenn er gerendert wird, dann richtet
  sich die Stärke nach der **kürzeren Seite des Bereichs**: Weichzeichnen mit einem Viertel
  davon (mindestens 15), Verpixeln mit etwa einem Achtel (mindestens 10). Eine größere
  Aufnahme wird damit ebenso wirksam zensiert wie eine kleine.
- **AK-10** · Angenommen, ein Bereich wird weichgezeichnet, wenn er gerendert wird, dann ist
  die Unschärfe **am Rand so stark wie in der Mitte**: Die Kanten werden vor dem Filtern
  fortgesetzt, sodass nicht mit dem transparenten Außenraum gemischt wird.
- **AK-14** · Angenommen, ein zensierter Bereich wird nachträglich vergrößert, wenn er
  gerendert wird, dann wächst die Zensurstärke mit — eine aufgezogene Zensur bleibt nicht
  auf der Stärke ihrer ursprünglichen Größe stehen.

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 des Katalogs ausdrücklich in Kraft. Für dieses Feature ist der
Katalog **nicht** verkürzt: Es ist die einzige Stelle, an der die Anwendung dem Nutzer
eine inhaltliche Zusage über seine Daten macht.

- **AK-11** · Angenommen, ein Bereich ist zensiert, wenn das Ergebnis exportiert wird, dann
  enthält die Ausgabedatei die Originalpixel des Bereichs **nicht mehr** — auch nicht in
  Metadaten, Ebenen oder Vorschaubildern.
- **AK-12** · Angenommen, der Nutzer zensiert einen Bereich und exportiert das Bild, wenn
  danach der Verlaufsordner geöffnet wird, dann liegt dort **die zensierte Fassung** — die
  automatisch gesicherte Originaldatei wird beim Export ersetzt.
- **AK-15** · Angenommen, der Nutzer zensiert einen Bereich und schließt den Editor **ohne**
  zu exportieren, wenn danach der Verlaufsordner geöffnet wird, dann liegt auch dort die
  zensierte Fassung. Eine Zensur wird beim Schließen immer angewandt, weil sie eine Zusage
  über den Inhalt ist und nicht eine Gestaltungsentscheidung.
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

## Behobene Befunde

Alle fünf Einträge sind in 3.5.0 behoben.

- **FB-01 · Die unzensierte Originalaufnahme blieb auf der Festplatte** — behoben
  2026-08-25. Der Editor merkt sich die von `autoSave` geschriebene Datei
  (`AnnotationEditorWindowController.autoSavedURL`) und ersetzt sie bei jedem Export sowie
  beim Schließen, sobald eine Zensur vorliegt. **Dies war der schwerste Befund der
  Erfassung.**
- **FB-02 · Weichzeichnen ohne Kantenfortsetzung** — behoben 2026-08-25. Der Ausschnitt
  wird vor dem Filtern fortgesetzt (`clampedToExtent()`), danach auf die ursprüngliche
  Ausdehnung zurückgeschnitten.
- **FB-03 · Zensurstärke nicht auflösungsbezogen** — behoben 2026-08-25.
  `BlurAnnotation.radius(for:)` und `PixelateAnnotation.blockSize(for:)` leiten die Stärke
  aus der kürzeren Seite des Bereichs ab und ziehen beim Skalieren nach. Sechs Tests in
  `Tests/RedactionStrengthTests.swift`.
- **FB-04 · Keine Warnung vor unwirksamer Zensur** — gegenstandslos seit FB-01 und FB-03:
  Das Original bleibt nicht mehr liegen, und die Stärke passt sich an. Eine Prüfung auf
  Restkontrast wäre eine Scheinsicherheit.
- **FB-05 · Keine Tests** — behoben 2026-08-25. Die Stärkeberechnung ist abgedeckt; die
  Wirksamkeit selbst bleibt in der QA über die Texterkennung nachzuweisen.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Wann wird automatisch gesichert? | weiterhin sofort — als Sicherheitsnetz gegen einen Absturz. Die Datei wird jedoch beim Export und bei jeder Zensur ersetzt, womit der Grund für die ursprüngliche Frage entfällt | 2026-08-25 |
| OF-02 · Zensurstärke einstellbar? | nein — sie richtet sich nach der Bereichsgröße. Eine Einstellung würde nahelegen, dass eine schwächere Stufe vertretbar ist | 2026-08-25 |
| OF-03 · Weichzeichnen als Verfahren zulassen? | ja, mit Kantenfortsetzung und größenbezogener Stärke. Verpixeln bleibt die Alternative; die Wahl trifft der Nutzer nach dem Bild, nicht nach der Sicherheit | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Zensur als Annotation oder als Bildänderung? | als Annotation | umkehrbar über das gewöhnliche Undo; das Original bleibt bis zum Export erhalten |
| 2 | Woher kommt der Inhalt des zensierten Bereichs? | aus dem Originalbild, bei jedem Zeichnen neu | erlaubt Verschieben und Skalieren ohne Qualitätsverlust — hat aber zur Folge, dass sich überlappende Zensuren nicht verstärken (EC-03) |
| 3 | Welche Filter? | `CIGaussianBlur` und `CIPixellate` | Systemfilter, keine eigene Implementierung |
| 4 | Feste Stärke | Radius 15 · Blockgröße 10 | **Grund nicht erkennbar** — keine Herleitung im Code, keine Einstellung |
| 5 | Kantenfortsetzung vor dem Weichzeichnen (3.5.0) | `clampedToExtent()` | ohne sie mischt der Filter den Rand mit dem transparenten Außenraum — genau dort, wo ein zensiertes Wort enden kann |
| 6 | Stärke aus der Bereichsgröße (3.5.0) | kürzere Seite als Bezug | die kürzere Seite entspricht der Texthöhe; die längere sagt nichts darüber, wie fein der Inhalt ist |
