# B08 · Screenshots anheften — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.
>
> **Hier sitzt der schwerste Einzelbefund der Kartierung** (FB-01): Angeheftete Bilder
> werden auf die Festplatte geschrieben und niemals gelöscht.

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
- **AK-11** ⚠ · Angenommen, bereits 20 Bilder sind angeheftet, wenn ein weiteres angeheftet
  werden soll, dann **geschieht nichts** — ohne jede Rückmeldung.
  *(`PinnedScreenshotManager.swift:21` schreibt in ein `print()` und gibt `nil` zurück. Der
  Nutzer wählt *Pin*, der Editor schließt sich womöglich, und kein Fenster erscheint. Zur
  Klärung vorgelegt.)*

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 des Katalogs ausdrücklich in Kraft. **Dieses Feature schreibt
Bildschirminhalte dauerhaft an einen Ort, den der Nutzer nicht kennt.**

- **AK-12** ⚠ · Angenommen, ein Bild wird angeheftet, wenn die Aktion ausgeführt ist, dann
  wird es als PNG nach `~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/`
  geschrieben — **auch dann, wenn das automatische Sichern in den Einstellungen abgeschaltet
  ist**.
  *(`PinnedScreenshotManager.swift:30` ruft `savePinnedImage` ohne Prüfung von
  `autoSaveEnabled`. Wer das automatische Sichern bewusst abgeschaltet hat, legt hier
  trotzdem Dateien an. Zur Klärung vorgelegt.)*
- **AK-13** ⚠ · Angenommen, ein angeheftetes Bild wird geschlossen — über die Schaltfläche,
  das Kontextmenü, den Doppelklick oder *Close All* —, wenn die Aktion ausgeführt ist, dann
  **bleibt die Datei auf der Festplatte**.
  *(Im gesamten Feature existiert kein einziger Löschaufruf. `unpinPanel`, `unpinAll` und
  `closePanel` entfernen nur das Fenster. Zur Klärung vorgelegt.)*
- **AK-14** ⚠ · Angenommen, mehr Dateien liegen im Ablageordner als 20, wenn die Anwendung
  startet, dann werden die **alphabetisch ersten zwanzig** wiederhergestellt — bei
  Zeitstempel-Dateinamen also die **ältesten**. Ein bewusst geschlossenes Bild kann dabei
  zurückkehren, während ein neueres ausbleibt.
  *(`PinnedScreenshotManager.swift:62-64` sortiert nach Dateinamen aufsteigend und nimmt
  die ersten `maxPins`. Zur Klärung vorgelegt.)*
- **AK-15** ⚠ · Angenommen, der Nutzer öffnet die Speicherverwaltung in den Einstellungen,
  wenn die Größe angezeigt wird, dann sind die angehefteten Bilder **nicht enthalten**; und
  *Clear History* löscht sie nicht.
  *(`AdvancedTabView.swift:85` und `:157` arbeiten ausschließlich über den Verlaufsverwalter,
  der nur den Bilderordner kennt. Zur Klärung vorgelegt.)*
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

## Fehlbestand

- **FB-01 · Angeheftete Bilder werden nie gelöscht.** Fundstellen:
  `PinnedScreenshotManager.swift:37-46` (`unpinPanel`, `unpinAll` — nur `orderOut`),
  `PinnedScreenshotPanel.swift:125` (`closePanel` — nur `orderOut`), sowie das Fehlen jedes
  `removeItem` im Feature. Folge, in vier Stufen:
  1. Bildschirminhalte sammeln sich **unbegrenzt** in `Application Support` an.
  2. Die Obergrenze von 20 gilt für gleichzeitig offene Fenster, nicht für Dateien.
  3. Geschlossene Bilder kehren beim Neustart zurück (AK-14).
  4. Der Nutzer sieht diesen Speicher nirgends und kann ihn in der Anwendung nicht leeren
     (AK-15) — nur über den Finder, wenn er den Ort kennt.
  Gemessen an der Datenschutzregel des PRD („lokale Ablagen sind eine bewusste
  Entscheidung") ist das der schwerste Befund der Erfassung.
- **FB-02 · Das Anheften ignoriert die Einstellung zum automatischen Sichern.** Fundstelle:
  `PinnedScreenshotManager.swift:30`. Folge: Eine ausdrückliche Entscheidung des Nutzers,
  nichts auf die Festplatte zu schreiben, wird an dieser Stelle übergangen.
- **FB-03 · Nur das Bild wird gesichert, nicht seine Anordnung.** Fundstelle:
  `savePinnedImage` speichert ein PNG, sonst nichts. Folge: Das im README beschriebene
  „persistent across app restarts" gilt für den Inhalt, nicht für die Anordnung — Position,
  Größe und Durchsichtigkeit gehen verloren.
- **FB-04 · Das Erreichen der Obergrenze ist unsichtbar.** Fundstelle:
  `PinnedScreenshotManager.swift:21`. Folge: *Pin* tut scheinbar nichts.
- **FB-05 · Die Wiederherstellung sortiert nach Dateinamen, nicht nach Aktualität.**
  Fundstelle: `PinnedScreenshotManager.swift:62`. Folge: siehe AK-14.
- **FB-06 · Keine Tests.**

## Offene Fragen

- **OF-01** · Soll das Schließen eines angehefteten Bildes seine Datei löschen? —
  entscheidet der Autor. Dies ist die Kernfrage des Features.
- **OF-02** · Soll die Anordnung mitgesichert werden? — entscheidet der Autor.
- **OF-03** · Soll die Speicherverwaltung in den Einstellungen diesen Ordner einbeziehen? —
  entscheidet der Autor. Betrifft B11.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie schwebt das Fenster? | rahmenloses, nicht aktivierendes Panel auf `.floating` | bleibt oben, ohne die Anwendung in den Vordergrund zu holen |
| 2 | Wie wird gesichert? | PNG je Bild in *Application Support* | dort gehören Programmdaten hin, die der Nutzer nicht selbst verwaltet |
| 3 | Dateiname mit Millisekunden | wie beim Verlauf auf die Sekunde | verhindert Kollisionen bei schnellem Anheften — im Verlauf fehlt genau das (B09/FB-02) |
| 4 | Obergrenze 20 | unbegrenzt | Schutz gegen zugestellten Bildschirm |
| 5 | Anzeigegröße höchstens 400 Punkte breit | Originalgröße | ein Vollbild-Screenshot als schwebendes Fenster wäre unbrauchbar |
| 6 | Durchsichtigkeit über das Scrollrad | nur über das Kontextmenü | schnell erreichbar, ohne Menü |
| 7 | Kein Löschen beim Schließen | Datei mit entfernen | **Grund nicht erkennbar.** Erkennbar ist nur, dass Wiederherstellung gewollt war — dass sie auch geschlossene Bilder erfasst, wirkt unbeabsichtigt (FB-01) |
