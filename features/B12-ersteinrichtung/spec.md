# B12 · Ersteinrichtung — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde bearbeitet in 3.5.0**

> Beschrieben ist, **was der Code tut**. Vier der fünf markierten Kriterien sind behoben,
> darunter der Grund für misslungene Erststarts.

## Zweck

Beim ersten Start führt die Anwendung durch drei Bildschirme: Begrüßung, die
Bildschirmaufnahme-Berechtigung, eine Übersicht der Tastenkombinationen. Danach ist sie
einsatzbereit — oder der Nutzer weiß zumindest, was ihm fehlt.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 Bildschirmaufnahme | `bestand` | die Berechtigung, um die es geht |
| B13 Start bei Login | `bestand` | Schalter auf dem letzten Bildschirm |
| B11 Einstellungen | `bestand` | einziger Weg, den Ablauf erneut zu öffnen |

## User Stories

- **US-01** · Als neuer Nutzer möchte ich erfahren, welche Berechtigung gebraucht wird und
  warum, bevor mich das System danach fragt.
- **US-02** · Als neuer Nutzer möchte ich die Tastenkombinationen einmal gesehen haben.
- **US-03** · Als neuer Nutzer möchte ich den Ablauf überspringen können.

## Nicht im Scope

- Einrichtung von Speicherort oder Format — bleibt den Einstellungen überlassen
- Erklärung einzelner Werkzeuge — nicht vorhanden
- Erneutes Anzeigen nach einem Update — der Ablauf erscheint nur einmal

## Akzeptanzkriterien

- **AK-01** · Angenommen, die Anwendung wurde noch nie abgeschlossen eingerichtet, wenn sie
  startet, dann öffnet sich das Einrichtungsfenster (480 × 560) mit dunklem Farbverlauf.
- **AK-02** · Angenommen, die Berechtigung fehlt, wenn der Ablauf aufgebaut wird, dann hat
  er **drei** Seiten; ist sie erteilt, hat er **zwei** — der Berechtigungsschritt entfällt.
- **AK-03** · Angenommen, der Ablauf läuft, wenn er angezeigt wird, dann zeigen Punkte am
  unteren Rand die Zahl der Seiten und die aktuelle Position.
- **AK-04** · Angenommen, die Begrüßungsseite ist sichtbar, wenn *Weiter* gewählt wird, dann
  erscheint die nächste Seite mit einer Übergangsbewegung.
- **AK-05** · Angenommen, die Berechtigungsseite ist sichtbar und die Berechtigung fehlt,
  wenn *Open System Settings* gewählt wird, dann öffnet sich die Systemeinstellung für die
  Bildschirmaufnahme.
- **AK-06** · Angenommen, die Berechtigungsseite ist sichtbar, wenn die Berechtigung
  **während** der Anzeige erteilt wird, dann wechselt die Darstellung binnen einer Sekunde
  auf ein grünes Häkchen und blättert nach einer weiteren Sekunde selbsttätig weiter.
- **AK-07** · Angenommen, die Berechtigungsseite ist sichtbar, wenn *Skip for now* gewählt
  wird, dann geht es ohne Berechtigung weiter.
- **AK-08** · Angenommen, die letzte Seite ist sichtbar, wenn sie angezeigt wird, dann stehen
  dort alle sieben Tastenkombinationen und ein Schalter *Launch Mika+ScreenSnap at login*.
- **AK-09** · Angenommen, die letzte Seite ist sichtbar, wenn *Done* gewählt wird, dann wird
  der Anmeldestart entsprechend dem Schalter gesetzt und das Fenster schließt sich.
- **AK-10** · Angenommen, das Einrichtungsfenster schließt sich — gleich auf welchem Weg —,
  wenn es geschlossen ist, dann gilt die Einrichtung als abgeschlossen und erscheint beim
  nächsten Start nicht mehr.
- **AK-11** · Angenommen, die Einrichtung ist abgeschlossen, wenn in den Einstellungen
  *Show Onboarding Again* gewählt wird, dann erscheint sie erneut.
- **AK-12** · Angenommen, der Ablauf ist auf der ersten Seite, wenn `Escape` gedrückt
  wird, dann schließt er sich und gilt als **abgeschlossen** — der Nutzer sieht ihn nicht
  wieder, ohne die Einstellungen zu öffnen.
  *(So verhält sich der Code, und das bleibt so — Begründung unter *Befunde*, BF-03.)*
- **AK-13** · Angenommen, die letzte Seite wird angezeigt, wenn der Schalter für den
  Anmeldestart erscheint, dann zeigt er den **tatsächlichen Zustand des Systems** — er ist
  nicht vorangekreuzt.
- **AK-14** · Angenommen, der Ablauf wird vor der letzten Seite abgebrochen, wenn er
  schließt, dann bleibt der Anmeldestart so, wie er war — angezeigter und tatsächlicher
  Zustand stimmen überein.

### Berechtigung

- **AK-15** · Angenommen, die Berechtigung fehlt, wenn auf der Berechtigungsseite *Grant
  Access* gewählt wird, dann **fordert die Anwendung sie beim System an**; erst wenn das
  Ansuchen abschlägig bleibt, öffnet sich die Systemeinstellung. Damit ist die Anwendung
  dort in jedem Fall gelistet.

### Datenschutz und Missbrauchsschutz

Stufe A.

- **AK-16** · Angenommen, die Berechtigungsseite wird angezeigt, wenn der Nutzer sie liest,
  dann nennt sie den Zweck und stellt fest, dass die Daten auf dem Rechner bleiben.
- **AK-17** · Angenommen, der Ablauf läuft, wenn er abgeschlossen wird, dann wird
  ausschließlich ein Wahrheitswert gespeichert (`hasCompletedOnboarding`) — keine
  Nutzerdaten.
- **AK-18** · Angenommen, der Nutzer wählt *Skip for now*, wenn das geschieht, dann geht es
  ohne Berechtigung weiter und **es wird nichts gespeichert** — der wirkungslose Vermerk
  `permissionSkipped` ist entfernt. Dass die Berechtigung fehlt, zeigt stattdessen dauerhaft
  das Menüleistenmenü.

*Abschnitt 4 (Rate Limits) und Abschnitt 6 (Geheimnisse): treffen nicht zu.*

## Edge Cases

- **EC-01** · Berechtigung wird erteilt, während die Begrüßungsseite sichtbar ist → der
  Seitenaufbau bleibt dreiseitig, weil er beim Aufbau festgelegt wurde.
- **EC-02** · Berechtigung wird während der Berechtigungsseite entzogen → die Anzeige
  wechselt nicht zurück; `granted` kennt nur den Weg vom Fehlen zum Vorhandensein.
- **EC-03** · Systemeinstellungen lassen sich nicht öffnen → keine Rückmeldung.
- **EC-04** · Fenster wird über die rote Schaltfläche geschlossen → gilt als abgeschlossen
  (AK-12).
- **EC-05** · *Show Onboarding Again* bei erteilter Berechtigung → zweiseitiger Ablauf.

## Befunde

### Behoben

- **FB-01 · Die Berechtigung wurde nie angefordert** — behoben 2026-08-25.
  `CGRequestScreenCaptureAccess()` wird über *Grant Access* aufgerufen; die
  Systemeinstellung öffnet sich nur, wenn das Ansuchen nicht zum Ziel führt. **Dies war die
  wahrscheinlichste Ursache für einen misslungenen ersten Start.**
- **FB-02 · `permissionSkipped` war wirkungslos** — behoben 2026-08-25 durch Entfernen.
- **FB-04 · Anzeigezustand und Wirkung des Anmeldestarts gingen auseinander** — behoben
  2026-08-25. Der Schalter wird aus `SMAppService` vorbelegt.

### Akzeptiert

- **BF-03 · Jedes Schließen gilt als Abschluss** — akzeptiert 2026-08-25. Ein Ablauf, der
  nach `Escape` beim nächsten Start wiederkommt, ist aufdringlich; wer ihn wiedersehen will,
  findet ihn unter *Preferences → Advanced → Onboarding*. Der eigentliche Schutz ist nicht
  der Ablauf, sondern der dauerhafte Hinweis im Menü und die jetzt gesperrten
  Aufnahmeeinträge (B15).
- **BF-05 · Kein Weg zurück im Ablauf** — akzeptiert 2026-08-25. Drei Seiten ohne
  Eingaben, die man verlieren könnte; ein Zurück wäre Zierrat.
- **BF-06 · Keine Tests** — akzeptiert 2026-08-25. Der Ablauf besteht aus
  Berechtigungsabfragen und Systemänderungen, die in einem Testlauf nichts zu suchen haben.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Berechtigung anfordern? | ja — und die Systemeinstellung erst danach öffnen | 2026-08-25 |
| OF-02 · Abbruch als „abgeschlossen" werten? | ja, siehe BF-03 | 2026-08-25 |
| OF-03 · Anmeldestart voreingestellt an? | nein — der Schalter zeigt den Systemzustand | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie viele Seiten? | drei, oder zwei bei erteilter Berechtigung | keine Seite ohne Zweck zeigen |
| 2 | Wie wird die Berechtigung erkannt? | Abfrage im Sekundentakt | ohne Delegate merkt die Anwendung sonst nicht, dass der Nutzer sie in den Systemeinstellungen erteilt hat |
| 3 | Selbsttätiges Weiterblättern nach Erteilung | auf einen Klick warten | der Nutzer kommt gerade aus den Systemeinstellungen zurück und soll nicht suchen |
| 4 | Anmeldestart im Ablauf statt in den Einstellungen | nur in den Einstellungen | die naheliegende Stelle für eine Entscheidung, die man einmal trifft |
| 5 | Abschluss beim Schließen des Fensters | erst nach der letzten Seite | **Grund nicht erkennbar** (FB-03) |
| 6 | Berechtigung anfordern (3.5.0) | nur abfragen und verweisen | ohne Ansuchen trägt macOS die Anwendung nicht in die Liste ein — der Nutzer wurde in eine Liste geschickt, in der sie fehlte |
| 7 | Anmeldestart aus dem System vorbelegt (3.5.0) | fest auf „ein" | ein vorangekreuztes Kästchen richtet eine Systemänderung ein, die niemand gewählt hat |
