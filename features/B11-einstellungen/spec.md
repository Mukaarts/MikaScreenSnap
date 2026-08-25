# B11 · Einstellungen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde behoben in 3.5.0**

> Beschrieben ist, **was der Code tut**. Alle sieben markierten Kriterien sind bearbeitet;
> die Dokumentation, die das Fenster falsch beschrieb, ist korrigiert.

## Zweck

Ein Fenster mit vier Reitern, in dem sich Speicherort, Format, Verhalten,
Zeichen-Standards, Tastenkombinationen und die Ausschlussliste einstellen lassen — dazu
Speicherverwaltung und Zurücksetzen.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B09 Verlauf | `bestand` | Speicherverwaltung und Ordnerwahl |
| B10 Tastenkombinationen | `bestand` | Reiter *Shortcuts* |
| B02 App-Ausschluss | `bestand` | Abschnitt *Privacy* |
| B13 Start bei Login | `bestand` | Schalter im Reiter *Advanced* |
| B14 Updates | `bestand` | Schalter und Schaltfläche im Reiter *Advanced* |
| B12 Ersteinrichtung | `bestand` | Schaltfläche *Show Again* |

## User Stories

- **US-01** · Als Nutzer möchte ich festlegen, wohin und in welchem Format Aufnahmen
  gesichert werden.
- **US-02** · Als Nutzer möchte ich sehen, wie viel Platz meine Aufnahmen belegen, und sie
  löschen können.
- **US-03** · Als Nutzer möchte ich alles auf Anfang zurücksetzen können.

## Nicht im Scope

- Ein- und Ausfuhr der Einstellungen — nicht vorhanden
- Profile oder mehrere Konfigurationen — nicht vorhanden

## Akzeptanzkriterien

### Rahmen

- **AK-01** · Angenommen, die Anwendung läuft, wenn `⌘,` gedrückt oder *Preferences…*
  gewählt wird, dann öffnet sich ein Fenster mit den vier Reitern *General*, *Shortcuts*,
  *Annotation* und *Advanced*.
- **AK-02** · Angenommen, das Fenster ist offen, wenn es angezeigt wird, dann erscheint es
  im **systemeigenen Erscheinungsbild** und folgt der Hell-/Dunkel-Einstellung des Systems.
  *(Die Beschreibung in `README.md` ist am 2026-08-25 daran angeglichen worden — sie nannte
  das Fenster seit `a43683a` fälschlich „dark-themed".)*

### Reiter *General*

- **AK-03** · Angenommen, der Reiter ist offen, wenn *Change…* gewählt wird, dann lässt sich
  ein Ordner wählen, in den künftig gesichert wird.
- **AK-04** · Angenommen, das Format steht auf JPEG, wenn der Reiter angezeigt wird, dann
  erscheint zusätzlich ein Schieberegler für die Qualität mit Prozentanzeige.
- **AK-05** · Angenommen, das Format steht auf PNG, wenn der Reiter angezeigt wird, dann ist
  der Qualitätsregler **nicht** sichtbar.
- **AK-06** · Angenommen, der Schalter *Capture sound* wird umgelegt, wenn danach aufgenommen
  wird, dann erklingt der Ton entsprechend.
- **AK-07** · Angenommen, der Schalter *Auto-save screenshots* wird ausgeschaltet, wenn danach
  aufgenommen wird, dann entsteht keine Datei im Verlaufsordner.
- **AK-08** · Angenommen, der Reiter *General* ist offen, wenn er angezeigt wird, dann gibt
  es **keinen Schalter für eine schwebende Vorschau** mehr — er wurde entfernt, weil die
  Funktion nie gebaut wurde.
- **AK-09** · Angenommen, der Abschnitt *Privacy* ist sichtbar, wenn er angezeigt wird, dann
  steht dort die Zahl der ausgeschlossenen Programme und eine Schaltfläche zur Auswahl
  (Umsetzung in B02).

### Reiter *Annotation*

- **AK-10** · Angenommen, ein Standardwerkzeug, eine Standardfarbe und eine Strichstärke sind
  gewählt, wenn der Editor öffnet, dann sind sie voreingestellt.
- **AK-11** · Angenommen, die Anwendung wurde nie eingestellt, wenn der Reiter zum ersten
  Mal geöffnet wird, dann steht die Strichstärke auf „Medium" (4) — der Standardwert ist
  einer der drei angebotenen.
- **AK-12** · Angenommen, *Remember last used tool* ist eingeschaltet (Standard), wenn der
  Editor geschlossen wird, dann wird das zuletzt benutzte Werkzeug zum Standard.
- **AK-13** · Angenommen, der Schalter *Show toolbar labels* wird eingeschaltet, wenn der
  Editor **danach** geöffnet wird, dann steht unter jedem Werkzeugsymbol seine Bezeichnung
  und die Leiste ist entsprechend höher.

### Reiter *Advanced*

- **AK-14** · Angenommen, der Reiter ist offen, wenn er angezeigt wird, dann stehen dort
  Anzahl und Gesamtgröße der Aufnahmen sowie Schaltflächen zum Öffnen des Ordners und zum
  Löschen des Verlaufs.
- **AK-15** · Angenommen, *Clear History* wird gewählt, wenn die Rückfrage bestätigt wird,
  dann werden alle Aufnahmen und Vorschaubilder endgültig gelöscht.
- **AK-16** · Angenommen, der Reiter ist offen, wenn er angezeigt wird, dann stehen dort
  Schalter für den Anmeldestart und die automatische Aktualisierung, eine Schaltfläche zum
  Prüfen mit dem Zeitpunkt der letzten Prüfung, sowie Fassungsnummer und Erstellungsnummer.
- **AK-17** · Angenommen, *Reset All Preferences* wird bestätigt, wenn die Aktion läuft, dann
  stehen alle Einstellungen wieder auf ihren Voreinstellungen und die Tastenkombinationen
  werden neu angemeldet.
- **AK-18** · Angenommen, *Reset All Preferences* wird ausgeführt, wenn danach nachgesehen
  wird, dann sind **Farbverlauf und Palette geleert**; die von Sparkle geführten
  Einstellungen bleiben bestehen.
  *(Sparkles Schlüssel gehören dem Rahmenwerk, nicht dieser Anwendung — Begründung unter
  *Befunde*, BF-04.)*
- **AK-19** · Angenommen, *Reset All Preferences* wird ausgeführt, wenn danach eine
  Tastenkombination gedrückt wird, dann wird die zugehörige Funktion **genau einmal**
  ausgelöst.

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 in Kraft.

- **AK-20** · Angenommen, Einstellungen werden geändert, wenn sie gespeichert werden, dann
  enthalten sie keine Nutzerinhalte — nur Pfade, Formate, Zahlen und Wahrheitswerte.
- **AK-21** · Angenommen, ein Ordner wird über *Change…* gewählt, wenn das geschieht, dann
  wird nur der Pfad gespeichert.
- **AK-22** · Angenommen, *Clear History* wird ausgeführt, wenn gelöscht wird, dann erscheint
  vorher eine Rückfrage, die die Endgültigkeit benennt.
- **AK-23** · Angenommen, der Reiter *Advanced* ist offen, wenn der Abschnitt *Storage*
  angezeigt wird, dann stehen dort **zwei Zeilen**: Aufnahmen mit Vorschaubildern und
  angeheftete Bilder, jede mit Größe und eigener Löschmöglichkeit.

*Abschnitte 4 und 6 des Katalogs: treffen nicht zu.*

## Edge Cases

- **EC-01** · Gewählter Ordner nicht beschreibbar → fällt erst beim Sichern auf, dort
  unsichtbar (B09/AK-08).
- **EC-02** · Gewählter Ordner wird gelöscht → wird beim nächsten Sichern neu angelegt.
- **EC-03** · Einstellungen offen, während der Verlauf sich ändert → Speicheranzeige wird
  nicht laufend aktualisiert.
- **EC-04** · *Reset* bei geöffnetem Editor → der Editor arbeitet mit den bereits
  übernommenen Werten weiter.

## Befunde

### Behoben

- **FB-01 · Drei Einstellungen ohne Wirkung** — behoben 2026-08-25. *Show toolbar labels*
  wirkt jetzt; *Floating preview* und die zugehörige Dauer sind samt Schlüsseln entfernt,
  weil die Funktion dahinter nie gebaut wurde. Eine schwebende Vorschau bleibt möglich —
  als eigenes Feature mit eigener Nummer, nicht als Schalter ohne Gegenstück.
- **FB-02 · Die Dokumentation beschrieb das Fenster falsch** — behoben 2026-08-25.
  `README.md` nennt es jetzt „native System Settings layout".
- **FB-03 · Standard-Strichstärke stand nicht zur Auswahl** — behoben 2026-08-25. Der
  Standard ist 4; ein Test hält fest, dass er einer der angebotenen Werte ist.
- **FB-04 · Die Rücksetzliste war unvollständig** — behoben 2026-08-25.
  `AppPreferences.ownedDefaultsKeys` steht neben den Eigenschaften, die sie schreiben, und
  enthält die Schlüssel des Farbverlaufs; ein Test prüft das.
- **FB-05 · Die Speicherverwaltung kannte nur einen Ablageort** — behoben 2026-08-25.
- **FB-06 · Zurücksetzen verdoppelte die Tastenkombinationen** — behoben in B10.
- **FB-08 · Keine Tests** — behoben 2026-08-25 für Rücksetzliste und Standardwerte.

### Akzeptiert

- **BF-04 · Sparkles Einstellungen bleiben beim Zurücksetzen bestehen** — akzeptiert
  2026-08-25. Sie gehören dem Rahmenwerk, nicht dieser Anwendung; sie zu entfernen hieße,
  in fremde Schlüssel zu greifen, deren Namen sich mit einer neuen Fassung ändern können.
- **BF-07 · Keine Rückmeldung nach dem Zurücksetzen** — akzeptiert 2026-08-25. Die
  Änderungen sind unmittelbar in denselben Feldern sichtbar, in denen der Nutzer die Aktion
  ausgelöst hat.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Wirkungslose Einstellungen umsetzen oder entfernen? | *Show toolbar labels* umgesetzt, *Floating preview* entfernt — eine Vorschau ist ein Feature, kein Schalter | 2026-08-25 |
| OF-02 · Ist das Fenster falsch oder die Dokumentation? | die Dokumentation; das native Erscheinungsbild bleibt | 2026-08-25 |
| OF-03 · Speicherverwaltung um Pins erweitern? | ja, als eigene Zeile mit Größe und Leeren | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie sind die Einstellungen aufgeteilt? | vier Reiter | folgt dem Aufbau der macOS-Systemeinstellungen |
| 2 | Wann wird gespeichert? | sofort bei jeder Änderung | kein „Übernehmen"; jede Eigenschaft schreibt beim Setzen |
| 3 | Wo liegen die Werte? | Benutzereinstellungen, gebündelt in einer Klasse | eine Stelle für alle Voreinstellungen |
| 4 | Erscheinungsbild | systemeigen, seit `a43683a` | zuvor dunkel im Markenbild; die Dokumentation nennt weiterhin den alten Zustand (FB-02) |
| 5 | Zurücksetzen über eine gepflegte Schlüsselliste (3.5.0) | die gesamte Sammlung entfernen | die Liste steht neben den Eigenschaften und ist getestet; ein pauschales Leeren würde auch Sparkles Schlüssel treffen (BF-04) |
| 6 | Endgültiges Löschen mit Rückfrage | Papierkorb ohne Rückfrage | die Rückfrage ist da, der Papierkorb nicht (B09/AK-18) |
