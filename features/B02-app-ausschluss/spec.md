# B02 · App-Ausschluss von Aufnahmen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ beschreiben Verhalten, das
> fragwürdig aussieht, und stehen zur Klärung.

## Zweck

Der Nutzer benennt Programme, deren Fenster in keiner Aufnahme erscheinen — die
Bildschirmtastatur, ein Passwortmanager, ein Chatfenster. Was einmal ausgeschlossen ist,
bleibt es, ohne dass vor jeder Aufnahme daran gedacht werden muss.

Dies ist die **einzige Zugriffsregel der gesamten Anwendung**. Alles andere ist
Darstellung oder Verarbeitung; hier entscheidet der Nutzer, was die App nicht sehen darf.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 Bildschirmaufnahme | `bestand` | wendet die Liste an — ohne B01 wirkt sie nirgends |
| B11 Einstellungen | `bestand` | beherbergt die Auswahl im Reiter *General* |

## User Stories

- **US-01** · Als Nutzer möchte ich Programme dauerhaft von Aufnahmen ausschließen, damit
  ich nicht bei jedem Screenshot daran denken muss.
- **US-02** · Als Nutzer möchte ich sehen, wie viele Programme ausgeschlossen sind, ohne
  die Liste zu öffnen.
- **US-03** · Als Nutzer möchte ich, dass Bedienungshilfen-Überlagerungen von vornherein
  ausgeschlossen sind, damit ich es nicht selbst herausfinden muss.

## Nicht im Scope

- Ausschluss einzelner Fenster statt ganzer Programme — nicht vorhanden
- Zeitgesteuerter oder bedingter Ausschluss — nicht vorhanden
- Die Anwendung ihrer Liste gehört zu **B01**, hier wird sie nur gepflegt

## Akzeptanzkriterien

- **AK-01** · Angenommen, die Einstellungen sind offen, wenn im Reiter *General* unter
  *Privacy* auf *Choose…* geklickt wird, dann erscheint eine Liste der aufnehmbaren
  Programme mit Namen und Bundle-Kennung, alphabetisch sortiert.
- **AK-02** · Angenommen, die Liste ist offen, wenn ein Programm eingeschaltet wird, dann
  ist die Auswahl sofort gespeichert — ohne Bestätigungsschritt.
- **AK-03** · Angenommen, ein Programm ist ausgeschlossen, wenn eine Aufnahme jedweder Art
  entsteht, dann ist kein Fenster dieses Programms darin enthalten.
- **AK-04** · Angenommen, ein Programm ist ausgeschlossen, wenn die Farbpipette oder die
  Texterkennung benutzt wird, dann ist dieses Programm auch dort nicht sichtbar.
- **AK-05** · Angenommen, Programme sind ausgeschlossen, wenn die Einstellungen geöffnet
  werden, dann steht neben *Exclude apps from capture* deren Anzahl („None", „1 app",
  „<n> apps").
- **AK-06** · Angenommen, die Anwendung wird zum ersten Mal gestartet, wenn die
  Ausschlussliste gelesen wird, dann sind die Bedienungshilfen-Tastatur, die
  Verweilsteuerung und der Zoom-Darstellungsdienst bereits ausgeschlossen.
- **AK-07** · Angenommen, der Nutzer entfernt **alle** Einträge aus der Liste, wenn die
  Anwendung neu startet, dann bleibt die Liste leer — die Standardwerte kehren nicht
  zurück.
- **AK-08** · Angenommen, ein ausgeschlossenes Programm läuft gerade nicht, wenn die Liste
  geöffnet wird, dann erscheint es trotzdem und bleibt ausgewählt.
- **AK-09** · Angenommen, die Bildschirmaufnahme-Berechtigung fehlt, wenn die Liste
  geöffnet wird, dann erscheint der Hinweis „No capturable apps found. Grant Screen
  Recording permission and try again."
- **AK-10** ⚠ · Angenommen, ein Programm läuft nicht und stand nie auf der Liste, wenn die
  Auswahl geöffnet wird, dann ist es **nicht auswählbar**.
  *(`ExcludedAppsManager.swift:33` baut die Liste aus `SCShareableContent.current`, also
  aus laufenden Programmen. Ein Passwortmanager lässt sich nicht vorbeugend ausschließen,
  solange er geschlossen ist. Zur Klärung vorgelegt.)*
- **AK-11** ⚠ · Angenommen, die Auswahl wird geändert, wenn danach eine Aufnahme entsteht,
  dann gibt es **keine Rückmeldung darüber, dass der Ausschluss gegriffen hat**.
  *(Der Nutzer sieht nur das fertige Bild. Ob ein Fenster fehlt, weil es ausgeschlossen war
  oder weil es nicht offen war, ist nicht unterscheidbar. Zur Klärung vorgelegt.)*

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 des Katalogs ausdrücklich in Kraft.

- **AK-12** · Angenommen, die Ausschlussliste wird geändert, wenn gespeichert wird, dann
  enthält sie ausschließlich Bundle-Kennungen — keine Fenstertitel, keine Inhalte.
- **AK-13** · Angenommen, die Liste wird aufgebaut, wenn die laufenden Programme gelesen
  werden, dann landet nichts davon in einem Protokoll.
- **AK-14** · Angenommen, *Reset All Preferences* wird ausgeführt, wenn die Anwendung
  danach liest, dann steht die Ausschlussliste wieder auf den drei Standardwerten.

*Abschnitt 4 (Rate Limits) und Abschnitt 6 (Geheimnisse): treffen nicht zu — keine
Kosten, kein fremder Dienst, keine Schlüssel.*

## Edge Cases

- **EC-01** · Programm ohne Bundle-Kennung oder ohne Namen → erscheint nicht in der Liste.
- **EC-02** · Die Anwendung selbst → erscheint nie in der Liste (eigene Prozess-ID gefiltert).
- **EC-03** · Ausgeschlossenes Programm startet nach dem Öffnen der Liste → erscheint erst
  nach *Refresh*.
- **EC-04** · Ausgeschlossenes Programm wird deinstalliert → bleibt als Bundle-Kennung in
  der Liste, der Name fällt auf die Kennung zurück.
- **EC-05** · Fenster ohne besitzendes Programm (WindowServer) → vom Ausschluss **nicht**
  erfasst; nur die gesonderte Zeiger-Erkennung in B01 greift.

## Fehlbestand

- **FB-01 · Nur laufende Programme sind auswählbar.**
  `ExcludedAppsManager.swift:33` liest `SCShareableContent.current`. Folge: Vorbeugender
  Ausschluss ist unmöglich — genau bei einem Passwortmanager, den man selten offen hat,
  ist das die falsche Einschränkung. Ein Auswahldialog über `/Applications` gibt es nicht.
- **FB-02 · Der Ausschluss ist nicht nachprüfbar.** Es gibt keine Anzeige, keine Markierung
  am Ergebnis und keinen Testweg. Folge: Eine Zusage, auf die sich der Nutzer verlässt,
  ohne sie überprüfen zu können — und ohne Tests (siehe FB-04) auch ohne automatischen
  Nachweis.
- **FB-03 · Der Ausschluss greift nicht bei Fenstern ohne besitzendes Programm.**
  `CaptureEngine.swift:19` bricht mit `guard let app = window.owningApplication` ab.
  Folge: Systemüberlagerungen, die WindowServer ohne Programmbezug zeichnet, sind über
  diese Liste nicht ausschließbar. Für den Zeiger gibt es eine Sonderbehandlung, für alles
  Übrige nicht.
- **FB-04 · Keine Tests.** Die Filterlogik ist reine Mengenoperation und damit gut prüfbar;
  geprüft wird sie nicht. Folge: Die einzige Zugriffsregel der Anwendung hat keinen
  automatischen Nachweis.

## Offene Fragen

- **OF-01** · Soll ein Programm auch dann ausschließbar sein, wenn es nicht läuft? —
  entscheidet der Autor.
- **OF-02** · Soll die Anwendung sichtbar machen, dass ein Ausschluss gegriffen hat? —
  entscheidet der Autor.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Ausschluss nach Programm oder Fenster? | nach Programm (Bundle-Kennung) | überlebt Neustarts des Programms; Fenster-IDs tun das nicht |
| 2 | Was ist voreingestellt? | drei Bedienungshilfen-Dienste | sie liegen über allem und landeten sonst in jeder Aufnahme |
| 3 | Was passiert bei einer leer geräumten Liste? | sie bleibt leer | ausdrücklich im Code vermerkt: nur ein **fehlender** Schlüssel fällt auf die Standardwerte zurück — sonst käme das Weggenommene bei jedem Start zurück |
| 4 | Woher kommt die Auswahlliste? | aus den laufenden Programmen | **Grund nicht erkennbar**; naheliegend ist, dass ScreenCaptureKit ohnehin gefragt werden muss (siehe FB-01) |
| 5 | Wie wird eine nicht laufende Auswahl dargestellt? | eingemischt, Name über `NSWorkspace` | ausdrücklich kommentiert: eine bestehende Auswahl soll nicht unbemerkt aus der Liste fallen |
