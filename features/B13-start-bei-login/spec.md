# B13 · Automatischer Start bei Login — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.

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
- **AK-07** ⚠ · Angenommen, das Eintragen oder Entfernen schlägt fehl, wenn der Fehler
  auftritt, dann erfährt der Nutzer nichts davon, und **der Schalter zeigt weiterhin den
  gewünschten statt den tatsächlichen Zustand** — bis die Ansicht neu aufgebaut wird.
  *(`LaunchAtLoginManager.swift:24` schreibt in ein `print()`. Die Klasse ist **nicht**
  `@Observable`, weshalb eine fehlgeschlagene Änderung kein Neuzeichnen auslöst. Zur
  Klärung vorgelegt.)*

*Abschnitte 4 und 6 des Katalogs: treffen nicht zu.*

## Edge Cases

- **EC-01** · Anwendung liegt nicht in `/Applications` → das Eintragen kann fehlschlagen;
  siehe AK-07.
- **EC-02** · Nutzer verweigert die Systemabfrage zum Anmeldeobjekt → dito.
- **EC-03** · Anwendung wird verschoben, nachdem das Anmeldeobjekt eingetragen wurde →
  Verhalten liegt beim System.
- **EC-04** · Zwei Kopien der Anwendung auf dem Rechner → Verhalten ungeprüft.

## Fehlbestand

- **FB-01 · Fehlschläge sind unsichtbar und der Schalter lügt.** Fundstelle:
  `LaunchAtLoginManager.swift:24`. Folge: Der Nutzer glaubt, der Anmeldestart sei
  eingerichtet, und wundert sich beim nächsten Anmelden. Zwei Ursachen wirken zusammen: das
  wirkungslose `print()` und die fehlende Beobachtbarkeit der Klasse.
- **FB-02 · Kein Abgleich beim Start.** Die Anwendung fragt den Zustand nur ab, wenn eine
  Ansicht ihn anzeigt. Folge: keine unmittelbare — vermerkt, weil die Klasse damit als
  einzige im Projekt ohne eigenen Zustand auskommt, was ausdrücklich so gewollt ist.
- **FB-03 · Keine Tests.**

## Offene Fragen

- **OF-01** · Soll ein Fehlschlag gemeldet werden? — entscheidet der Autor.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie wird der Anmeldestart eingerichtet? | `SMAppService.mainApp` | ab macOS 13 der vorgesehene Weg; keine Hilfsanwendung, kein Startordner |
| 2 | Wo liegt die Wahrheit? | beim System | ausdrücklich im Dateikopf vermerkt: keine eigene Ablage, die auseinanderlaufen kann |
| 3 | Fehlerbehandlung | `print()` | **Grund nicht erkennbar** (FB-01) |
