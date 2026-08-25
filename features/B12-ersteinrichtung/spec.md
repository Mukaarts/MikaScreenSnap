# B12 · Ersteinrichtung — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.

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
- **AK-12** ⚠ · Angenommen, der Ablauf ist auf der ersten Seite, wenn `Escape` gedrückt
  wird, dann schließt er sich und gilt als **abgeschlossen** — der Nutzer sieht ihn nicht
  wieder, ohne die Einstellungen zu öffnen.
  *(`OnboardingView.swift:74` behandelt `Escape` als Abschluss;
  `OnboardingWindow.swift:58` setzt beim Schließen `hasCompletedOnboarding = true`,
  unabhängig davon, wie weit der Nutzer gekommen ist. Zur Klärung vorgelegt.)*
- **AK-13** ⚠ · Angenommen, die letzte Seite wird zum ersten Mal angezeigt, wenn der Nutzer
  nichts ändert, dann ist der Schalter für den Anmeldestart **bereits eingeschaltet** — ein
  Klick auf *Done* richtet ein Anmeldeobjekt ein, ohne dass der Nutzer es ausdrücklich
  gewählt hat.
  *(`ShortcutsScreen.swift:14` setzt den Anfangswert auf `true`. Zur Klärung vorgelegt.)*
- **AK-14** ⚠ · Angenommen, der Ablauf wird vor der letzten Seite abgebrochen, wenn er
  schließt, dann wird der Anmeldestart **nicht** gesetzt — obwohl der Schalter „ein" zeigte.
  *(`ShortcutsScreen.swift:63` ruft `setEnabled` ausschließlich in der *Done*-Aktion.
  Zusammen mit AK-13 heißt das: Der angezeigte Zustand und der tatsächliche gehen
  auseinander. Zur Klärung vorgelegt.)*

### Berechtigung

- **AK-15** ⚠ · Angenommen, die Berechtigung fehlt, wenn der Ablauf sie behandelt, dann wird
  sie **nie beim System angefordert** — es wird nur abgefragt und in die Systemeinstellungen
  verwiesen.
  *(Im gesamten Quelltext gibt es fünf Aufrufe von `CGPreflightScreenCaptureAccess()` und
  **keinen einzigen** von `CGRequestScreenCaptureAccess()`. Der einzige Aufruf, der die
  Anwendung in die Systemliste einträgt — `SCShareableContent.current` in
  `MikaScreenSnapApp.swift:112` — steht in einem Zweig, der beim Erststart **nicht** läuft
  (`:44-48`). Folge: Der Systemdialog erscheint nicht, und die Anwendung wird erst beim
  zweiten Start oder beim ersten Aufnahmeversuch eingetragen. Ein Nutzer, der im
  Einrichtungsablauf auf *Open System Settings* klickt, steht dort vor einer Liste, in der
  die Anwendung noch gar nicht auftaucht. Zur Klärung vorgelegt.)*

### Datenschutz und Missbrauchsschutz

Stufe A.

- **AK-16** · Angenommen, die Berechtigungsseite wird angezeigt, wenn der Nutzer sie liest,
  dann nennt sie den Zweck und stellt fest, dass die Daten auf dem Rechner bleiben.
- **AK-17** · Angenommen, der Ablauf läuft, wenn er abgeschlossen wird, dann werden
  ausschließlich zwei Wahrheitswerte gespeichert (`hasCompletedOnboarding`,
  `permissionSkipped`) — keine Nutzerdaten.
- **AK-18** ⚠ · Angenommen, der Nutzer wählt *Skip for now*, wenn das vermerkt wird, dann
  bleibt dieser Vermerk **wirkungslos**: `permissionSkipped` wird gespeichert und von
  **niemandem** gelesen.
  *(Einzige Fundstelle außerhalb der Einstellungsklasse: `PermissionScreen.swift:63`. Zur
  Klärung vorgelegt.)*

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

## Fehlbestand

- **FB-01 · Die Berechtigung wird nie angefordert — und beim Erststart nicht einmal
  angestoßen.** Fundstellen: kein Aufruf von `CGRequestScreenCaptureAccess()` im gesamten
  Quelltext; zusätzlich `MikaScreenSnapApp.swift:44-48`. Dort steht die Prüfung, die über
  `SCShareableContent.current` die Anwendung überhaupt erst in die Systemliste einträgt und
  den Systemdialog auslösen kann — sie läuft aber **nur im `else`-Zweig**, also erst wenn
  die Ersteinrichtung bereits abgeschlossen ist. Genau beim ersten Start übernimmt die
  Ersteinrichtung, die ausschließlich abfragt. Folge: Der Nutzer klickt im Onboarding auf
  *Open System Settings* und steht dort vor einer Liste, in der die Anwendung noch nicht
  auftaucht — sie wird erst beim zweiten Start oder beim ersten Aufnahmeversuch eingetragen.
  Das ist die wahrscheinlichste Ursache für einen misslungenen ersten Start.
- **FB-02 · `permissionSkipped` ist wirkungslos.** Fundstelle: `PermissionScreen.swift:63`,
  ohne Leser. Folge: Der vierte Einstellungsschlüssel ohne Wirkung — die Anwendung könnte
  darauf aufbauend später erinnern, tut es aber nicht.
- **FB-03 · Der Abschluss wird durch jedes Schließen ausgelöst.** Fundstelle:
  `OnboardingWindow.swift:58`. Folge: Ein versehentliches `Escape` auf der ersten Seite
  beendet die Einrichtung dauerhaft.
- **FB-04 · Anzeigezustand und Wirkung des Anmeldestarts gehen auseinander.** Fundstellen:
  `ShortcutsScreen.swift:14` (voreingestellt ein), `:63` (nur bei *Done* gesetzt). Folge:
  Wer abbricht, hat einen Schalter gesehen, der „ein" zeigte, ohne dass etwas geschah — wer
  *Done* drückt, richtet ein Anmeldeobjekt ein, ohne es gewählt zu haben.
- **FB-05 · Kein Weg zurück im Ablauf.** Es gibt nur Vorwärtsnavigation; die Punkte am
  unteren Rand sind Anzeige, nicht bedienbar.
- **FB-06 · Keine Tests.**

## Offene Fragen

- **OF-01** · Soll `CGRequestScreenCaptureAccess()` aufgerufen werden, damit der
  Systemdialog erscheint? — entscheidet der Autor. Betrifft B01.
- **OF-02** · Soll ein Abbruch vor der letzten Seite als „abgeschlossen" gelten? —
  entscheidet der Autor.
- **OF-03** · Soll der Anmeldestart voreingestellt eingeschaltet sein? — entscheidet der
  Autor.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie viele Seiten? | drei, oder zwei bei erteilter Berechtigung | keine Seite ohne Zweck zeigen |
| 2 | Wie wird die Berechtigung erkannt? | Abfrage im Sekundentakt | ohne Delegate merkt die Anwendung sonst nicht, dass der Nutzer sie in den Systemeinstellungen erteilt hat |
| 3 | Selbsttätiges Weiterblättern nach Erteilung | auf einen Klick warten | der Nutzer kommt gerade aus den Systemeinstellungen zurück und soll nicht suchen |
| 4 | Anmeldestart im Ablauf statt in den Einstellungen | nur in den Einstellungen | die naheliegende Stelle für eine Entscheidung, die man einmal trifft |
| 5 | Abschluss beim Schließen des Fensters | erst nach der letzten Seite | **Grund nicht erkennbar** (FB-03) |
| 6 | Nur abfragen, nie anfordern | `CGRequestScreenCaptureAccess()` aufrufen | **Grund nicht erkennbar** (FB-01) |
