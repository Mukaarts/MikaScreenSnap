# B13 · Automatischer Start bei Login — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde behoben in 3.5.0**

> Beschrieben ist, **was der Code tut**. Das markierte Kriterium ist behoben.

## Zweck

Die Anwendung startet auf Wunsch bei der Anmeldung am Mac mit. Bei einem Werkzeug, das in
der Menüleiste wohnt und über Tastenkombinationen bedient wird, ist das die Voraussetzung
dafür, dass es überhaupt bereitsteht.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B11 Einstellungen | `bestand` | Schalter im Reiter *Advanced* |
| B12 Ersteinrichtung | `bestand` | Schalter auf der letzten Seite |

## User Stories

- **US-01** · Als Nutzer möchte ich, dass das Werkzeug nach dem Anmelden bereitsteht, ohne
  es zu starten.
- **US-02** · Als Nutzer möchte ich das jederzeit abschalten können.

## Nicht im Scope

- Verzögerter Start — nicht vorhanden
- Start ohne sichtbares Menüleistensymbol — die Anwendung ist immer sichtbar

## Akzeptanzkriterien

- **AK-01** · Angenommen, der Reiter *Advanced* ist offen, wenn der Schalter *Launch at
  Login* eingeschaltet wird, dann ist die Anwendung als Anmeldeobjekt eingetragen und
  startet bei der nächsten Anmeldung mit.
- **AK-02** · Angenommen, das Anmeldeobjekt besteht, wenn der Schalter ausgeschaltet wird,
  dann ist es entfernt.
- **AK-03** · Angenommen, der Nutzer entfernt das Anmeldeobjekt in den Systemeinstellungen,
  wenn die Einstellungen der Anwendung danach geöffnet werden, dann zeigt der Schalter
  „aus" — das System ist die Wahrheitsquelle, nicht eine eigene Ablage.
- **AK-04** · Angenommen, die Einrichtung läuft, wenn auf der letzten Seite *Done* gewählt
  wird, dann wird der Anmeldestart entsprechend dem dortigen Schalter gesetzt (siehe
  B12/AK-13 zur Voreinstellung).

### Datenschutz und Missbrauchsschutz

Stufe A.

- **AK-05** · Angenommen, der Anmeldestart wird gesetzt, wenn das geschieht, dann wird
  ausschließlich der Systemdienst für Anmeldeobjekte benutzt — es wird nichts in einen
  Startordner geschrieben und kein Hintergrunddienst eingerichtet.
- **AK-06** · Angenommen, der Anmeldestart wird gesetzt, wenn das geschieht, dann speichert
  die Anwendung selbst nichts darüber.
- **AK-07** · Angenommen, das Eintragen oder Entfernen schlägt fehl, wenn der Fehler
  auftritt, dann erscheint eine Kurzmeldung und **der Schalter zeigt den tatsächlichen
  Zustand des Systems**, nicht den gewünschten.

*Abschnitte 4 und 6 des Katalogs: treffen nicht zu.*

## Edge Cases

- **EC-01** · Anwendung liegt nicht in `/Applications` → das Eintragen kann fehlschlagen;
  siehe AK-07.
- **EC-02** · Nutzer verweigert die Systemabfrage zum Anmeldeobjekt → dito.
- **EC-03** · Anwendung wird verschoben, nachdem das Anmeldeobjekt eingetragen wurde →
  Verhalten liegt beim System.
- **EC-04** · Zwei Kopien der Anwendung auf dem Rechner → Verhalten ungeprüft.

## Behobene Befunde

- **FB-01 · Fehlschläge waren unsichtbar und der Schalter zeigte den falschen Zustand** —
  behoben 2026-08-25. Der Fehler geht über `CaptureLog`, und die Klasse ist `@Observable`
  mit einem Änderungszähler, sodass SwiftUI den Systemzustand neu liest.
- **FB-02 · Kein Abgleich beim Start** — gegenstandslos: Die Klasse führt bewusst keinen
  eigenen Zustand, es gibt also nichts abzugleichen.
- **FB-03 · Keine Tests** — akzeptiert 2026-08-25. Ein Test müsste ein Anmeldeobjekt
  eintragen; das ist eine Systemänderung, die in einem Testlauf nichts zu suchen hat.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Fehlschlag melden? | ja, als Kurzmeldung — und der Schalter folgt dem System | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie wird der Anmeldestart eingerichtet? | `SMAppService.mainApp` | ab macOS 13 der vorgesehene Weg; keine Hilfsanwendung, kein Startordner |
| 2 | Wo liegt die Wahrheit? | beim System | ausdrücklich im Dateikopf vermerkt: keine eigene Ablage, die auseinanderlaufen kann |
| 3 | Fehlerbehandlung (3.5.0) | Kurzmeldung über `CaptureLog` | ein Anmeldeobjekt, das stillschweigend nicht eingerichtet wurde, fällt erst beim nächsten Anmelden auf |
| 4 | Beobachtbarkeit (3.5.0) | `@Observable` mit Änderungszähler | ohne sie las SwiftUI den Systemzustand nach einem Fehlschlag nicht neu |
