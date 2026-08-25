# B09 · Screenshot-Verlauf — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde bearbeitet in 3.5.0**

> Beschrieben ist, **was der Code tut**. Von den fünf markierten Kriterien der ersten
> Fassung sind vier behoben, eines bewusst beibehalten.

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
- **AK-07** · Angenommen, zwei Aufnahmen entstehen **innerhalb derselben Sekunde**, wenn
  beide gesichert werden, dann entstehen **zwei Dateien**: Der Zeitstempel trägt
  Millisekunden, und bei gleichem Namen wird eine Zählnummer angehängt.
- **AK-08** · Angenommen, das Sichern schlägt fehl — etwa weil der Ordner nicht
  beschreibbar ist —, wenn der Fehler auftritt, dann erscheint eine Kurzmeldung am
  Bildschirm und der Fehler steht in der Konsole.

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
- **AK-17** · Angenommen, die Speichergröße wird angezeigt, wenn sie berechnet wird, dann
  umfasst sie Aufnahmen **und** Vorschaubilder; angeheftete Bilder stehen als eigene Zeile
  daneben.
- **AK-18** · Angenommen, Aufnahmen werden gelöscht, wenn die Aktion läuft, dann werden sie
  **endgültig entfernt**, nicht in den Papierkorb gelegt — bewusst beibehalten, Begründung
  unter *Befunde*, BF-05.
- **AK-24** · Angenommen, Dateien liegen im Verlaufsordner, die beim Start nicht eingelesen
  wurden, wenn *Clear History* ausgeführt wird, dann werden auch sie gelöscht.

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 des Katalogs ausdrücklich in Kraft. Dieses Feature legt
Bildschirminhalte **dauerhaft und unverschlüsselt** auf der Festplatte ab — es ist die
Stelle, an der aus einem flüchtigen Bild eine Datei wird.

- **AK-19** · Angenommen, eine Aufnahme entsteht, wenn sie gesichert wird, dann geschieht
  das **vor** dem Öffnen des Editors — als Sicherheitsnetz gegen einen Absturz. Sobald der
  Nutzer exportiert oder etwas zensiert, wird **dieselbe Datei durch das bearbeitete Bild
  ersetzt**, statt eine zweite anzulegen. Gegenstück zu B04/AK-12 und B04/AK-15.
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

## Befunde

### Behoben

- **FB-01 · Das automatisch Gesicherte war immer das Original** — behoben 2026-08-25.
  `autoSave` gibt die geschriebene Datei zurück, `replaceSaved(at:with:)` ersetzt sie, und
  der Editor ruft das bei jedem Export sowie beim Schließen mit Zensur.
- **FB-02 · Namenskollision innerhalb einer Sekunde** — behoben 2026-08-25.
  `uniqueCaptureURL(in:)` bildet den Namen mit Millisekunden und hängt eine Zählnummer an,
  falls die Datei doch existiert. Abgedeckt in `Tests/CaptureFilenameTests.swift`.
- **FB-03 · Fehlgeschlagenes Sichern blieb unbemerkt** — behoben 2026-08-25. Alle Pfade
  melden über `CaptureLog`, das protokolliert **und** eine Kurzmeldung zeigt.
- **FB-04 · Der Verlauf wurde synchron beim Start eingelesen** — teilweise entschärft, im
  Kern akzeptiert, siehe BF-04.
- **FB-06 · Vorschaubilder mit der Endung des Originals** — akzeptiert, siehe BF-06.
- **FB-08 · `clearAll()` löschte nur Geladenes** — behoben 2026-08-25. Es räumt jetzt das
  Verzeichnis selbst ab, nicht die Liste im Speicher.
- **FB-09 · Keine Tests** — behoben 2026-08-25 für Namensbildung und Rücksetzliste.

### Akzeptiert

- **BF-04 · Der Verlauf wird beim Start vollständig eingelesen** — akzeptiert 2026-08-25.
  Das Verzeichnis **ist** das Datenmodell; ein Index müsste gepflegt werden und könnte von
  der Wirklichkeit abweichen. Erst wenn ein spürbar langsamer Start gemeldet wird, lohnt
  ein Zwischenspeicher — und der wäre ein eigenes Feature mit eigener Nummer.
- **BF-05 · Endgültiges Löschen statt Papierkorb** — akzeptiert 2026-08-25. *Clear History*
  fragt vorher und benennt die Endgültigkeit; einzelne Einträge löscht der Nutzer bewusst.
  Ein Papierkorbweg würde die Daten an einem zweiten Ort weiterleben lassen, was dem Zweck
  der Aktion widerspricht.
- **BF-06 · Vorschaubilder tragen die Endung des Originals** — akzeptiert 2026-08-25. Der
  gleiche Name ist die Zuordnung zwischen Original und Vorschau; macOS liest das Format aus
  dem Inhalt. Eine Umbenennung würde bestehende Vorschauordner verwaisen lassen.
- **BF-07 · `HistoryItem.id` ist bei jedem Start neu, `date` ist das Änderungsdatum** —
  akzeptiert 2026-08-25. Beides folgt daraus, dass das Verzeichnis die Wahrheit ist. Die
  Kennung wird nur zur Darstellung benutzt; das dokumentiert `design.md`.
- **BF-05a · Kein Aufräumen, keine Obergrenze** (vormals FB-05) — akzeptiert 2026-08-25.
  Eine automatische Löschung würde Aufnahmen entfernen, die der Nutzer noch braucht; die
  Speicheranzeige und *Clear History* machen den Verbrauch sichtbar und beherrschbar.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Erst beim Schließen sichern? | nein — sofort sichern bleibt das Sicherheitsnetz. Die Datei wird bei Export und Zensur ersetzt, womit der Datenschutzgrund für die Frage entfällt | 2026-08-25 |
| OF-02 · Gelöschtes in den Papierkorb? | nein, siehe BF-05 | 2026-08-25 |
| OF-03 · Obergrenze oder automatisches Aufräumen? | nein, siehe BF-05a | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wo liegt der Verlauf? | im Dateisystem, kein Index | das Verzeichnis **ist** das Datenmodell — robust gegenüber fremden Änderungen |
| 2 | Wann wird gesichert? | sofort nach der Aufnahme | **Grund nicht dokumentiert.** Erkennbar: nichts soll verloren gehen, auch wenn der Editor abstürzt — der Preis ist FB-01 |
| 3 | Vorschaubilder als JPEG mit Qualität 0,7 | PNG wie das Original | kleiner; Vorschaubilder brauchen keine Verlustfreiheit |
| 4 | Vorschaubilder in einem versteckten Unterordner | eigener Ort in *Application Support* | sie bleiben beim Original, ohne im Finder aufzufallen |
| 5 | Suche über Datum und Dateiname | Inhaltssuche über die Texterkennung | einfach zu bauen; die Texterkennung ist zwar vorhanden (B05), wird hier aber nicht genutzt |
| 6 | Zeitstempel mit Millisekunden und Zählnummer (3.5.0) | auf die Sekunde | zwei Aufnahmen in derselben Sekunde sind über `⌃⇧⌘5` mühelos zu erzeugen |
| 7 | Bearbeitetes ersetzt das Original (3.5.0) | zweite Datei anlegen | ein Verlauf mit Original *und* Bearbeitung nebeneinander würde bei einer Zensur genau das Bild behalten, das verschwinden soll |
