# B10 · Tastenkombinationen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde bearbeitet in 3.5.0**

> Beschrieben ist, **was der Code tut**. Der schwerste Befund dieses Features — das
> mehrfache Auslösen — ist behoben.

## Zweck

Sieben Funktionen sind systemweit über Tastenkombinationen erreichbar, ohne dass die
Anwendung im Vordergrund sein muss. Alle sieben lassen sich umbelegen.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01, B05, B06, B07, B09 | `bestand` | die ausgelösten Funktionen |
| B11 Einstellungen | `bestand` | beherbergt den Reiter *Shortcuts* |

## User Stories

- **US-01** · Als Nutzer möchte ich aus jedem Programm heraus aufnehmen können, ohne zur
  Menüleiste zu greifen.
- **US-02** · Als Nutzer möchte ich Kombinationen ändern können, wenn sie mit anderen
  Programmen kollidieren.
- **US-03** · Als Nutzer möchte ich zu den Voreinstellungen zurückkehren können.

## Nicht im Scope

- Kombinationen für Werkzeuge im Editor — die sind fest und Teil von B03
- Mehrere Kombinationen für dieselbe Funktion — nicht vorhanden
- Kombinationen ohne Zusatztaste — von der verwendeten Systemschnittstelle nicht sinnvoll
  unterstützt

## Akzeptanzkriterien

- **AK-01** · Angenommen, die Anwendung läuft, wenn eine der sieben Kombinationen gedrückt
  wird, dann wird die zugehörige Funktion ausgelöst — unabhängig davon, welches Programm
  gerade im Vordergrund ist.
- **AK-02** · Angenommen, die Anwendung startet zum ersten Mal, wenn die Kombinationen
  angemeldet werden, dann gelten: `⌃⇧⌘3` Vollbild, `⌃⇧⌘4` Bereich, `⌃⇧⌘5` vorderstes
  Fenster, `⇧⌘6` Text erfassen, `⇧⌘7` Farbpipette, `⇧⌘8` Messen, `⇧⌘H` Verlauf.
- **AK-03** · Angenommen, der Reiter *Shortcuts* ist offen, wenn eine Zeile zum Aufzeichnen
  angeklickt wird, dann wird die nächste gedrückte Kombination übernommen und in
  Symbolschreibweise angezeigt.
- **AK-04** · Angenommen, eine Kombination ist bereits einer **anderen Funktion dieser
  Anwendung** zugewiesen, wenn sie aufgezeichnet wird, dann erscheint der Hinweis „Conflict
  with <Funktion>".
- **AK-05** · Angenommen, Kombinationen wurden geändert, wenn die Anwendung neu startet,
  dann gelten die geänderten.
- **AK-06** · Angenommen, der Reiter *Shortcuts* ist offen, wenn *Restore Defaults* gewählt
  wird, dann gelten wieder die sieben Voreinstellungen.
- **AK-07** · Angenommen, eine Kombination ist bereits vom System oder einem anderen
  Programm belegt, wenn sie zugewiesen wird, dann **schlägt die Anmeldung fehl** und der
  Fehler steht in der Konsole; die Einstellung zeigt die Kombination weiterhin an.
  *(So verhält sich der Code. macOS bietet keine Abfrage, mit der sich eine fremde Belegung
  vorher feststellen ließe — Begründung unter *Befunde*, BF-03.)*
- **AK-08** · Angenommen, die Belegung wurde seit dem Start beliebig oft geändert, wenn
  danach eine Kombination gedrückt wird, dann wird die zugehörige Funktion **genau einmal**
  ausgelöst — der Ereignisbehandler wird einmal je Verwalter installiert und beim Abbau
  wieder entfernt.

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 in Kraft.

- **AK-09** · Angenommen, Kombinationen sind angemeldet, wenn Tasten gedrückt werden, dann
  erfährt die Anwendung **ausschließlich** von den sieben angemeldeten Kombinationen — die
  verwendete Systemschnittstelle liefert keine allgemeinen Tastatureingaben und die
  Anwendung fordert keine Bedienungshilfen-Berechtigung an.
- **AK-10** · Angenommen, Kombinationen werden gespeichert, wenn sie abgelegt werden, dann
  enthalten die Daten nur Tastencodes und Zusatztasten-Masken.
- **AK-11** · Angenommen, eine Kombination wird ausgelöst, wenn das geschieht, dann steht
  nichts davon in einem Protokoll; protokolliert wird nur eine **fehlgeschlagene Anmeldung**.

*Abschnitt 4 (Rate Limits) und Abschnitt 6 (Geheimnisse): treffen nicht zu.*

## Edge Cases

- **EC-01** · Kombination bereits vom System belegt (etwa `⌘Leertaste`) → siehe AK-07.
- **EC-02** · Aufzeichnung mit `Escape` → Verhalten ungeprüft.
- **EC-03** · Kombination ohne Zusatztaste → wird angenommen, fängt danach aber
  gewöhnliche Tasteneingaben systemweit ab.
- **EC-04** · Gespeicherte Belegung ist beschädigt → Rückfall auf die Voreinstellungen, weil
  die Dekodierung fehlschlägt.
- **EC-05** · Zwei Funktionen auf derselben Kombination trotz Warnung → die zuletzt
  angemeldete gewinnt; die andere schlägt still fehl.
- **EC-06** · Kombination wird gedrückt, während bereits eine Auswahl läuft → die alte wird
  verworfen (B01/EC-07).

## Befunde

### Behoben

- **FB-01 · Ereignisbehandler wurden bei jeder Neuanmeldung erneut installiert** — behoben
  2026-08-25. `installEventHandlerIfNeeded()` läuft genau einmal, die Kennung wird
  aufbewahrt und in `deinit` über `RemoveEventHandler` freigegeben. **Dies war der
  schwerste Befund dieses Features** und betraf auch *Reset All Preferences*, das denselben
  Weg nimmt.
- **FB-05 · Keine Tests** — behoben 2026-08-25. Sechs Tests in
  `Tests/HotkeyBindingTests.swift` über Kodierung, Eindeutigkeit der Voreinstellungen und
  Symbolschreibweise.

### Akzeptiert

- **BF-02 · Fehlgeschlagene Anmeldungen bleiben in der Oberfläche unsichtbar** — akzeptiert
  2026-08-25. Eine Meldung im Augenblick des Zuweisens wäre möglich, träfe aber die falsche
  Aussage: Die Anmeldung kann auch später scheitern, wenn ein anderes Programm die
  Kombination beansprucht. Der Fehler steht in der Konsole; die verlässliche Prüfung ist,
  die Kombination zu drücken.
- **BF-03 · Die Konflikterkennung kennt nur die eigene Anwendung** — akzeptiert
  2026-08-25. macOS stellt keine Schnittstelle bereit, über die sich fremde
  Tastenkombinationen abfragen ließen; jede Anzeige wäre geraten.
- **BF-04 · Keine Prüfung auf Kombinationen ohne Zusatztaste** — akzeptiert 2026-08-25. Wer
  eine solche Kombination bewusst zuweist, hat einen Grund; die Voreinstellungen tragen alle
  mindestens zwei Zusatztasten.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Ereignisbehandler einmalig anmelden? | ja — das mehrfache Auslösen war ein echter Fehler mit sichtbarer Wirkung | 2026-08-25 |
| OF-02 · Fehlgeschlagene Anmeldung in der Oberfläche zeigen? | nein, siehe BF-02 | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Welche Schnittstelle für systemweite Kombinationen? | Carbon `RegisterEventHotKey` | die einzige, die ohne Bedienungshilfen-Berechtigung auskommt — ein Ereignisabgriff bräuchte weitreichende Rechte |
| 2 | Wie findet der Rückruf zur Instanz? | statischer Verweis, `nonisolated(unsafe)` | Carbon-Rückrufe sind C-Funktionszeiger ohne Zustand; in `CLAUDE.md` als Muster festgehalten |
| 3 | Signatur `0x4D534E53` | beliebiger Wert | „MSNS" als Kennzeichnung der Anwendung |
| 4 | Wie werden Belegungen gespeichert? | JSON in den Benutzereinstellungen | Tastencode und Maske sind Zahlen; es gibt keine Schemaversion (siehe `docs/datenmodell.md`, FB-DM-06) |
| 5 | Rückfall bei fehlerhaften Daten | Voreinstellungen | besser als keine Kombinationen |
| 6 | Konflikterkennung nur intern | auch gegen das System prüfen | macOS bietet dafür keine Abfrage; geprüft wird, was prüfbar ist |
| 7 | Behandler einmal installieren (3.5.0) | bei jeder Anmeldung neu | jede Neuanmeldung stapelte einen weiteren Behandler, ohne dass je einer entfernt wurde |
