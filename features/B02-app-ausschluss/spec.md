# B02 · App-Ausschluss von Aufnahmen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde bearbeitet in 3.5.0**

> Beschrieben ist, **was der Code tut**. Von den beiden markierten Kriterien der ersten
> Fassung ist eines behoben, eines bewusst akzeptiert — beides unter *Befunde* mit Begründung.

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
- **AK-10** · Angenommen, ein Programm läuft nicht und stand nie auf der Liste, wenn in der
  Auswahl *Add App…* gewählt wird, dann lässt es sich aus dem Programmordner auswählen und
  ist danach ausgeschlossen — auch solange es geschlossen bleibt.
- **AK-11** · Angenommen, die Auswahl wird geändert, wenn danach eine Aufnahme entsteht,
  dann gibt es **keine Rückmeldung darüber, dass der Ausschluss gegriffen hat** — das ist
  eine bewusste Entscheidung, Begründung unter *Befunde*, BF-02.

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

## Befunde

### Behoben

- **FB-01 · Nur laufende Programme waren auswählbar** — behoben 2026-08-25.
  `ExcludedAppsManager.add(applicationAt:selected:)` nimmt ein Programmbündel von der
  Platte auf; die Auswahl ist über *Add App…* erreichbar und öffnet im Programmordner.

### Akzeptiert

Bewusst nicht behoben, mit Begründung und Datum.

- **BF-02 · Der Ausschluss ist nicht nachprüfbar** — akzeptiert 2026-08-25. Eine Anzeige
  „hier wurde etwas ausgelassen" wäre irreführender als ihr Fehlen: Ein Fenster kann auch
  deshalb fehlen, weil es nicht offen war oder verdeckt lag. Der Ausschluss wird
  stattdessen dort abgesichert, wo er wirkt — er wird ScreenCaptureKit als Filter
  übergeben, sodass der Inhalt im Prozess der Anwendung nie entsteht.
- **BF-03 · Kein Ausschluss für Fenster ohne besitzendes Programm** — akzeptiert
  2026-08-25. Die Liste ordnet über Bundle-Kennungen zu; ein Fenster ohne Programm hat
  keine. Für den einzigen bekannten Fall dieser Art — den Bedienungshilfen-Zeiger — gibt
  es die gesonderte Erkennung in B01.
- **BF-04 · Keine Tests für die Filterlogik** — akzeptiert 2026-08-25. Der Filter arbeitet
  auf `SCWindow`-Instanzen, die sich nicht ohne Bildschirmaufnahme herstellen lassen.
  Nachweis bleibt manuell, wie im Stack-Profil für UI-Verhalten vorgesehen.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Auch nicht laufende Programme ausschließbar? | ja, über *Add App…* aus dem Programmordner | 2026-08-25 |
| OF-02 · Sichtbar machen, dass ein Ausschluss griff? | nein, siehe BF-02 | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Ausschluss nach Programm oder Fenster? | nach Programm (Bundle-Kennung) | überlebt Neustarts des Programms; Fenster-IDs tun das nicht |
| 2 | Was ist voreingestellt? | drei Bedienungshilfen-Dienste | sie liegen über allem und landeten sonst in jeder Aufnahme |
| 3 | Was passiert bei einer leer geräumten Liste? | sie bleibt leer | ausdrücklich im Code vermerkt: nur ein **fehlender** Schlüssel fällt auf die Standardwerte zurück — sonst käme das Weggenommene bei jedem Start zurück |
| 4 | Woher kommt die Auswahlliste? | aus den laufenden Programmen | **Grund nicht erkennbar**; naheliegend ist, dass ScreenCaptureKit ohnehin gefragt werden muss (siehe FB-01) |
| 5 | Wie wird eine nicht laufende Auswahl dargestellt? | eingemischt, Name über `NSWorkspace` | ausdrücklich kommentiert: eine bestehende Auswahl soll nicht unbemerkt aus der Liste fallen |
| 6 | Wie kommt ein geschlossenes Programm auf die Liste? (3.5.0) | Auswahl aus dem Programmordner | genau der Fall, für den die Liste gedacht ist — ein Passwortmanager ist selten offen, wenn man daran denkt |
