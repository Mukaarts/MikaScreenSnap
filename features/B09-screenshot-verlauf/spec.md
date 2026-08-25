# B09 · Screenshot-Verlauf — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.

## Zweck

Jede Aufnahme wird ohne Zutun als Datei gesichert und bleibt über einen Browser mit
Vorschaubildern auffindbar. Der Nutzer muss nicht daran denken zu speichern — und findet
den Screenshot von vorgestern wieder.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 Bildschirmaufnahme | `bestand` | ruft das automatische Sichern auf |
| B11 Einstellungen | `bestand` | liefert Ordner, Format, Qualität und die Speicherverwaltung |
| B03 Annotationseditor | `bestand` | Ziel von *Open in Editor* |
| B08 Anheften | `bestand` | Ziel von *Pin to Screen* |

## User Stories

- **US-01** · Als Nutzer möchte ich, dass jede Aufnahme automatisch gesichert wird, damit
  ich nichts verliere, wenn ich den Editor versehentlich schließe.
- **US-02** · Als Nutzer möchte ich alte Aufnahmen als Vorschaubilder durchsehen, damit
  ich die richtige finde, ohne Dateien einzeln zu öffnen.
- **US-03** · Als Nutzer möchte ich sehen, wie viel Platz die Aufnahmen belegen, und sie
  auf einen Schlag löschen können.

## Nicht im Scope

- Aufnahmen aus dem Verlauf umbenennen, verschlagworten oder ordnen — nicht vorhanden
- Automatisches Aufräumen nach Alter oder Größe — nicht vorhanden, siehe FB-05
- Synchronisation zwischen Rechnern — ausdrücklich nicht (Stufe A, `docs/prd.md`)

## Akzeptanzkriterien

### Automatisches Sichern

- **AK-01** · Angenommen, das automatische Sichern ist aktiviert (Standard), wenn eine
  Aufnahme entsteht, dann liegt sie danach als Datei im eingestellten Ordner (Standard
  `~/Pictures/MikaScreenSnap/`).
- **AK-02** · Angenommen, das automatische Sichern ist deaktiviert, wenn eine Aufnahme
  entsteht, dann wird **keine** Datei geschrieben und der Verlauf bleibt unverändert.
- **AK-03** · Angenommen, das Format steht auf PNG (Standard), wenn gesichert wird, dann
  entsteht eine `.png`-Datei mit dem Namensmuster
  `MikaSnap_JJJJ-MM-TT_HH-mm-ss.png`.
- **AK-04** · Angenommen, das Format steht auf JPEG, wenn gesichert wird, dann entsteht
  eine `.jpg`-Datei mit der eingestellten Qualität (Standard 0,85).
- **AK-05** · Angenommen, der eingestellte Ordner existiert nicht, wenn gesichert wird,
  dann wird er angelegt.
- **AK-06** · Angenommen, eine Aufnahme wird gesichert, wenn sie fertig ist, dann entsteht
  zusätzlich ein Vorschaubild von höchstens 200 Punkten Kantenlänge im Unterordner
  `.thumbnails`.
- **AK-07** ⚠ · Angenommen, zwei Aufnahmen entstehen **innerhalb derselben Sekunde**, wenn
  beide gesichert werden, dann trägt die zweite denselben Dateinamen und **überschreibt die
  erste ersatzlos**.
  *(`AppPreferences.swift:172` bildet den Namen aus einem Zeitstempel mit
  Sekundengenauigkeit; `:194` schreibt ohne Prüfung auf Vorhandensein. Das Anheften
  verwendet an vergleichbarer Stelle Millisekunden, das Sichern nicht. Zur Klärung
  vorgelegt.)*
- **AK-08** ⚠ · Angenommen, das Sichern schlägt fehl — etwa weil der Ordner nicht
  beschreibbar ist —, wenn der Fehler auftritt, dann **erfährt der Nutzer nichts davon**:
  Es erscheint keine Meldung, und die Aufnahme ist nach dem Schließen des Editors verloren.
  *(`AppPreferences.swift:196` schreibt in ein `print()`, das in einem Programm ohne
  Dock-Symbol niemanden erreicht. Zur Klärung vorgelegt.)*

### Verlauf-Browser

- **AK-09** · Angenommen, Aufnahmen existieren, wenn `⇧⌘H` gedrückt oder *Screenshot
  History* gewählt wird, dann öffnet sich ein Fenster mit einem Raster aus Vorschaubildern,
  neueste zuerst.
- **AK-10** · Angenommen, der Verlauf ist offen, wenn in das Suchfeld getippt wird, dann
  bleiben nur Einträge übrig, deren **Datum oder Dateiname** den Text enthalten.
- **AK-11** · Angenommen, der Verlauf ist leer, wenn er geöffnet wird, dann erscheint der
  Hinweis „No Screenshots — Take a screenshot to see it here."
- **AK-12** · Angenommen, ein Eintrag ist sichtbar, wenn er mit der rechten Maustaste
  angeklickt wird, dann stehen *Open in Editor*, *Copy*, *Pin to Screen*, *Show in Finder*
  und *Delete* zur Wahl.
- **AK-13** · Angenommen, ein Eintrag wird gelöscht, wenn die Aktion ausgeführt ist, dann
  sind Originaldatei **und** Vorschaubild entfernt und der Eintrag verschwindet aus dem
  Raster.
- **AK-14** · Angenommen, ein Eintrag ist sichtbar, wenn er angezeigt wird, dann stehen
  darunter Datum und Pixelgröße.

### Speicherverwaltung

- **AK-15** · Angenommen, die Einstellungen sind offen, wenn der Reiter *Advanced* gewählt
  wird, dann stehen dort Anzahl und Gesamtgröße der Aufnahmen.
- **AK-16** · Angenommen, *Clear History* wird bestätigt, wenn die Aktion läuft, dann sind
  alle Aufnahmen und der gesamte `.thumbnails`-Ordner gelöscht.
- **AK-17** ⚠ · Angenommen, die Speichergröße wird angezeigt, wenn sie berechnet wird, dann
  zählt sie **nur die Originaldateien** — die Vorschaubilder fehlen in der Summe.
  *(`ScreenshotHistoryManager.swift:110` summiert über `items`, also über Originale. Zur
  Klärung vorgelegt.)*
- **AK-18** ⚠ · Angenommen, Aufnahmen werden gelöscht, wenn die Aktion läuft, dann werden
  sie **endgültig entfernt**, nicht in den Papierkorb gelegt.
  *(`ScreenshotHistoryManager.swift:92` und `:101` benutzen `removeItem`. Zur Klärung
  vorgelegt.)*

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 des Katalogs ausdrücklich in Kraft. Dieses Feature legt
Bildschirminhalte **dauerhaft und unverschlüsselt** auf der Festplatte ab — es ist die
Stelle, an der aus einem flüchtigen Bild eine Datei wird.

- **AK-19** ⚠ · Angenommen, eine Aufnahme entsteht, wenn sie gesichert wird, dann geschieht
  das **vor** dem Öffnen des Editors — also mit dem **unbearbeiteten Original**. Zensiert
  der Nutzer anschließend einen Bereich, bleibt die unzensierte Datei bestehen.
  *(`CaptureEngine.swift:427`. Gegenstück zu B04/AK-12. Zur Klärung vorgelegt — dies ist
  der schwerwiegendste Einzelbefund der Erfassung.)*
- **AK-20** · Angenommen, eine Aufnahme wird gesichert, wenn die Datei entsteht, dann
  enthält kein Protokoll ihren Inhalt oder ihren Dateinamen.
- **AK-21** · Angenommen, Aufnahmen liegen im Verlaufsordner, wenn darauf zugegriffen wird,
  dann gelten ausschließlich die Dateirechte des Systems — die Anwendung verschlüsselt
  nichts und fragt nichts ab.
- **AK-22** · Angenommen, Aufnahmen existieren, wenn die Anwendung sie sichert, dann
  verlässt keine davon den Rechner.

*Abschnitt 4 (Rate Limits): trifft nicht zu. Abschnitt 6 (Geheimnisse): trifft nicht zu.*

## Edge Cases

- **EC-01** · Verlaufsordner wird während des Betriebs gelöscht → beim nächsten Sichern neu
  angelegt; der angezeigte Verlauf zeigt bis zum Neustart Einträge ohne Datei.
- **EC-02** · Datei wird im Finder gelöscht, während der Verlauf offen ist → der Eintrag
  bleibt sichtbar, die Aktionen schlagen still fehl.
- **EC-03** · Fremde Bilddatei wird in den Ordner gelegt → erscheint beim nächsten Start im
  Verlauf, ohne Vorschaubild.
- **EC-04** · Sehr viele Aufnahmen im Ordner → siehe FB-04, der Start verzögert sich.
- **EC-05** · Ordner auf einem nicht eingebundenen Netzlaufwerk → Sichern schlägt fehl,
  siehe AK-08.
- **EC-06** · Vorschaubild fehlt → der Eintrag verweist ersatzweise auf das Original.

## Fehlbestand

- **FB-01 · Das automatisch Gesicherte ist immer das Original, nie das Bearbeitete.**
  Fundstelle: `CaptureEngine.swift:427`. Folge: siehe B04/FB-01 — die Zensur schützt nur
  das Weitergegebene. Zusätzlich: Annotationen gehen verloren, wenn der Nutzer den Editor
  schließt, ohne zu exportieren; im Verlauf liegt dann nur die rohe Aufnahme.
- **FB-02 · Namenskollision innerhalb einer Sekunde führt zu Datenverlust.** Fundstelle:
  `AppPreferences.swift:172` (Format ohne Millisekunden), `:194` (Schreiben ohne Prüfung).
  Folge: Zwei schnell aufeinanderfolgende Aufnahmen hinterlassen nur eine Datei — ohne
  Meldung. Dass `PinnedScreenshotManager.swift:79` an gleicher Stelle Millisekunden
  verwendet, zeigt, dass das Problem an anderer Stelle erkannt wurde.
- **FB-03 · Fehlgeschlagenes Sichern bleibt unbemerkt.** Fundstelle:
  `AppPreferences.swift:196`. Folge: Datenverlust ohne Hinweis — die schwerste Ausprägung
  des projektweiten Befunds FB-AS-03.
- **FB-04 · Der Verlauf wird beim Start vollständig und synchron eingelesen.** Fundstelle:
  `ScreenshotHistoryManager.swift:26` (`loadHistory()` im Initialisierer), `:75`
  (`imageSize(at:)` öffnet **jede** Datei einzeln). Folge: Der Programmstart wird mit
  wachsendem Verlauf spürbar langsamer, weil für jede Datei die Bildgröße aus dem Dateikopf
  gelesen wird — auf dem Hauptthread.
- **FB-05 · Kein Aufräumen, keine Obergrenze.** Es gibt weder Höchstzahl noch Höchstalter
  noch Höchstgröße. Folge: Der Ordner wächst unbegrenzt; die einzige Bereinigung ist
  „alles löschen".
- **FB-06 · Vorschaubilder tragen die Endung des Originals.** Fundstelle:
  `ScreenshotHistoryManager.swift:134` — der Name wird vom Original übernommen, der Inhalt
  ist immer JPEG. Folge: Ein Vorschaubild heißt `….png` und enthält JPEG-Daten. Funktioniert
  unter macOS, ist aber irreführend.
- **FB-07 · `HistoryItem.id` und `date` bedeuten nicht, wonach sie aussehen.** Die Kennung
  wird bei jedem Start neu vergeben, das Datum ist das Änderungsdatum der Datei. Folge:
  Kennungen dürfen nie über einen Programmstart hinweg verwendet werden; ein Kopiervorgang
  ändert das angezeigte Datum.
- **FB-08 · `clearAll()` löscht nur, was geladen wurde.** Fundstelle:
  `ScreenshotHistoryManager.swift:99`. Folge: Dateien im Ordner, die beim Start nicht
  eingelesen wurden, bleiben liegen, obwohl der Nutzer „alles löschen" gewählt hat.
- **FB-09 · Keine Tests.**

## Offene Fragen

- **OF-01** · Soll das automatische Sichern erst beim Schließen des Editors geschehen — mit
  dem bearbeiteten Bild? — entscheidet der Autor. Betrifft B04 unmittelbar.
- **OF-02** · Sollen gelöschte Aufnahmen in den Papierkorb wandern? — entscheidet der Autor.
- **OF-03** · Soll es eine Obergrenze oder automatisches Aufräumen geben? — entscheidet der
  Autor.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wo liegt der Verlauf? | im Dateisystem, kein Index | das Verzeichnis **ist** das Datenmodell — robust gegenüber fremden Änderungen |
| 2 | Wann wird gesichert? | sofort nach der Aufnahme | **Grund nicht dokumentiert.** Erkennbar: nichts soll verloren gehen, auch wenn der Editor abstürzt — der Preis ist FB-01 |
| 3 | Vorschaubilder als JPEG mit Qualität 0,7 | PNG wie das Original | kleiner; Vorschaubilder brauchen keine Verlustfreiheit |
| 4 | Vorschaubilder in einem versteckten Unterordner | eigener Ort in *Application Support* | sie bleiben beim Original, ohne im Finder aufzufallen |
| 5 | Suche über Datum und Dateiname | Inhaltssuche über die Texterkennung | einfach zu bauen; die Texterkennung ist zwar vorhanden (B05), wird hier aber nicht genutzt |
| 6 | Zeitstempel ohne Millisekunden | mit Millisekunden wie beim Anheften | **Grund nicht erkennbar** — siehe FB-02 |
