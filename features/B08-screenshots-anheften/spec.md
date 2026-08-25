# B08 · Screenshots anheften — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde behoben in 3.5.0**

> Beschrieben ist, **was der Code tut**. Der schwerste Befund der Kartierung saß hier:
> Angeheftete Bilder wurden geschrieben und niemals gelöscht. Alle fünf markierten
> Kriterien sind in 3.5.0 behoben.

## Zweck

Der Nutzer lässt eine Aufnahme als schwebendes Fenster über allen anderen liegen — um
etwas abzuschreiben, zu vergleichen oder im Blick zu behalten, während er in einem anderen
Programm arbeitet.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B03 Annotationseditor | `bestand` | Einstiegspunkt *Pin* in Werkzeugleiste und Fußzeile |
| B09 Verlauf | `bestand` | zweiter Einstiegspunkt über das Kontextmenü |
| B15 Menüleisten-Hub | `bestand` | Untermenü *Pinned Screenshots* |

## User Stories

- **US-01** · Als Nutzer möchte ich einen Screenshot über allen Fenstern schweben lassen,
  damit ich beim Abtippen nicht ständig umschalten muss.
- **US-02** · Als Nutzer möchte ich Größe und Durchsichtigkeit anpassen, damit er nicht
  stört.
- **US-03** · Als Nutzer möchte ich, dass angeheftete Bilder einen Neustart überstehen.

## Nicht im Scope

- Anheften mehrerer Bilder in einem Fenster — jedes Bild bekommt ein eigenes
- Anmerkungen am angehefteten Bild — dafür führt *Open in Editor* zurück in B03
- Anordnung oder Gruppierung angehefteter Fenster — nicht vorhanden

## Akzeptanzkriterien

- **AK-01** · Angenommen, der Editor ist offen, wenn *Pin* gewählt wird, dann erscheint das
  Bild als rahmenloses Fenster über allen anderen Fenstern und der Editor schließt sich.
- **AK-02** · Angenommen, ein Bild ist breiter als 400 Punkte, wenn es angeheftet wird, dann
  wird es auf 400 Punkte Breite verkleinert, unter Beibehaltung des Seitenverhältnisses.
- **AK-03** · Angenommen, ein Bild ist angeheftet, wenn es mit der Maus gezogen wird, dann
  bewegt sich das Fenster mit.
- **AK-04** · Angenommen, ein Bild ist angeheftet, wenn mit gedrückter Umschalttaste gezogen
  wird, dann ändert sich die Größe unter Beibehaltung des Seitenverhältnisses, mindestens
  jedoch 100 Punkte Breite.
- **AK-05** · Angenommen, ein Bild ist angeheftet, wenn über ihm gescrollt wird, dann ändert
  sich die Durchsichtigkeit zwischen 20 % und 100 %.
- **AK-06** · Angenommen, der Zeiger liegt über einem angehefteten Bild, wenn er dort
  verweilt, dann erscheint links oben eine Schaltfläche zum Schließen.
- **AK-07** · Angenommen, ein Bild ist angeheftet, wenn es mit der rechten Maustaste
  angeklickt wird, dann stehen *Copy Image*, *Save to Desktop*, *Open in Editor*,
  *Opacity* (Untermenü) und *Close* zur Wahl.
- **AK-08** · Angenommen, ein Bild ist angeheftet, wenn doppelt darauf geklickt wird, dann
  verschwindet es.
- **AK-09** · Angenommen, Bilder sind angeheftet, wenn das Menüleistensymbol angeklickt
  wird, dann sind sie im Untermenü *Pinned Screenshots* als „Pin 1", „Pin 2" … aufgeführt
  und über *Close All* gemeinsam schließbar.
- **AK-10** · Angenommen, Bilder waren beim Beenden angeheftet, wenn die Anwendung neu
  startet, dann erscheinen sie wieder — in Standardgröße an Standardposition, **nicht** an
  ihrem vorherigen Platz und nicht mit ihrer vorherigen Durchsichtigkeit.
- **AK-11** · Angenommen, bereits 20 Bilder sind angeheftet, wenn ein weiteres angeheftet
  werden soll, dann erscheint die Kurzmeldung „Already 20 pinned screenshots".

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 des Katalogs ausdrücklich in Kraft. **Dieses Feature schreibt
Bildschirminhalte dauerhaft an einen Ort, den der Nutzer nicht kennt.**

- **AK-12** · Angenommen, ein Bild wird angeheftet, wenn die Aktion ausgeführt ist, dann
  wird es als PNG nach `~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/`
  geschrieben — unabhängig von der Einstellung zum automatischen Sichern, weil die Datei
  die Wiederherstellung trägt und beim Schließen wieder verschwindet (siehe *Befunde*,
  BF-02).
- **AK-13** · Angenommen, ein angeheftetes Bild wird geschlossen — über die Schaltfläche,
  das Kontextmenü, den Doppelklick oder *Close All* —, wenn die Aktion ausgeführt ist, dann
  **ist auch die Datei gelöscht**.
- **AK-14** · Angenommen, mehr Dateien liegen im Ablageordner als 20, wenn die Anwendung
  startet, dann werden die **zwanzig neuesten** wiederhergestellt und die übrigen gelöscht —
  eine Datei, die ohnehin nie wieder erscheinen könnte, bleibt nicht liegen.
- **AK-15** · Angenommen, der Nutzer öffnet die Speicherverwaltung in den Einstellungen,
  wenn sie angezeigt wird, dann steht dort eine eigene Zeile *Pinned screenshots* mit
  Größe und einer Schaltfläche, die diesen Speicher leert.
- **AK-16** · Angenommen, ein Bild wird angeheftet, wenn es gespeichert wird, dann enthält
  kein Protokoll seinen Inhalt.
- **AK-17** · Angenommen, ein Bild ist angeheftet, wenn es sichtbar ist, dann verlässt es
  den Rechner nicht.

*Abschnitt 4 (Rate Limits): trifft nicht zu. Abschnitt 6 (Geheimnisse): trifft nicht zu.*

## Edge Cases

- **EC-01** · Sehr kleines Bild wird angeheftet → keine Vergrößerung, es bleibt klein.
- **EC-02** · Angeheftetes Bild wird auf 100 Punkte verkleinert → Untergrenze greift.
- **EC-03** · Ablageordner wird von Hand geleert → beim nächsten Start erscheinen keine
  Bilder; laufende Fenster bleiben unberührt.
- **EC-04** · Datei im Ablageordner ist beschädigt → wird beim Wiederherstellen
  übersprungen, ohne Meldung.
- **EC-05** · Anwendung wird beendet, während Bilder angeheftet sind → die Fenster
  verschwinden, die Dateien bleiben und kehren beim Start zurück.
- **EC-06** · Bild wird angeheftet, geschlossen, erneut angeheftet → **zwei** Dateien im
  Ablageordner.

## Befunde

### Behoben

- **FB-01 · Angeheftete Bilder wurden nie gelöscht** — behoben 2026-08-25. Jedes Panel
  kennt seine Datei (`PinnedScreenshotPanel.persistedURL`); `unpinPanel`, `unpinAll` und
  das Schließen im Panel löschen sie. **Dies war der schwerste Befund der Kartierung.**
- **FB-03 · Nur das Bild wurde gesichert, nicht die Anordnung** — bewusst beibehalten,
  siehe BF-03; die Beschreibung im README ist entsprechend genauer gefasst.
- **FB-04 · Das Erreichen der Obergrenze war unsichtbar** — behoben 2026-08-25.
  `CaptureLog.report` zeigt eine Kurzmeldung.
- **FB-05 · Wiederherstellung sortierte nach Dateinamen aufsteigend** — behoben
  2026-08-25. Sie ist umgekehrt und räumt überzählige Dateien ab.

### Akzeptiert

- **BF-02 · Anheften folgt nicht der Einstellung zum automatischen Sichern** — akzeptiert
  2026-08-25. Die Datei ist kein Archiv, sondern der Träger der Wiederherstellung, und sie
  verschwindet mit dem Fenster (FB-01). Wer beides nicht will, schließt den Pin.
- **BF-03 · Position, Größe und Deckkraft überleben keinen Neustart** — akzeptiert
  2026-08-25. Ein angehefteter Screenshot ist ein Arbeitsmittel für den Moment; die
  Anordnung mitzuführen wäre eine eigene Funktion mit eigener Spec.
- **BF-06 · Keine Tests** — akzeptiert 2026-08-25. Der Lebenszyklus hängt an
  `NSPanel`-Fenstern und lässt sich ohne Oberfläche nicht sinnvoll prüfen; der Nachweis
  bleibt manuell (siehe *Übergabe an die QA* in `design.md`).

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Löscht das Schließen die Datei? | ja — das war die Kernfrage des Features und ist der Befund, der die Reparatur ausgelöst hat | 2026-08-25 |
| OF-02 · Anordnung mitsichern? | nein, siehe BF-03 | 2026-08-25 |
| OF-03 · Speicherverwaltung erweitern? | ja — eigene Zeile mit Größe und Leeren im Reiter *Advanced* | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie schwebt das Fenster? | rahmenloses, nicht aktivierendes Panel auf `.floating` | bleibt oben, ohne die Anwendung in den Vordergrund zu holen |
| 2 | Wie wird gesichert? | PNG je Bild in *Application Support* | dort gehören Programmdaten hin, die der Nutzer nicht selbst verwaltet |
| 3 | Dateiname mit Millisekunden | wie beim Verlauf auf die Sekunde | verhindert Kollisionen bei schnellem Anheften — im Verlauf fehlt genau das (B09/FB-02) |
| 4 | Obergrenze 20 | unbegrenzt | Schutz gegen zugestellten Bildschirm |
| 5 | Anzeigegröße höchstens 400 Punkte breit | Originalgröße | ein Vollbild-Screenshot als schwebendes Fenster wäre unbrauchbar |
| 6 | Durchsichtigkeit über das Scrollrad | nur über das Kontextmenü | schnell erreichbar, ohne Menü |
| 7 | Schließen löscht die Datei (3.5.0) | Datei behalten | ein geschlossener Pin ist erledigt; alles andere sammelt Bildschirminhalte an einem Ort, den der Nutzer nicht sieht |
| 8 | Wiederherstellung neueste zuerst (3.5.0) | alphabetisch aufsteigend | bei Zeitstempel-Namen holte die alte Sortierung die ältesten zwanzig zurück |
