# B11 · Einstellungen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.

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
- **AK-02** ⚠ · Angenommen, das Fenster ist offen, wenn es angezeigt wird, dann erscheint es
  im **systemeigenen Erscheinungsbild** und folgt der Hell-/Dunkel-Einstellung des Systems.
  *(`README.md` und `CHANGELOG.md` (3.4.0) beschreiben es als „dark-themed" im „Mika+ brand
  aesthetic"; `Sources/Preferences/` enthält **keinen einzigen** Verweis auf die
  Markenpalette, und der Dateikopf von `PreferencesStyles.swift` lautet „native macOS
  style". Commit `a43683a` hat das Erscheinungsbild geändert, ohne die Dokumentation
  nachzuziehen. Zur Klärung vorgelegt: Welche Seite ist falsch?)*

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
- **AK-08** ⚠ · Angenommen, der Schalter *Floating preview* wird eingeschaltet und eine
  Dauer gewählt, wenn danach aufgenommen wird, dann **geschieht nichts anderes als vorher**.
  *(`floatingPreviewEnabled` und `previewDismissDuration` werden gespeichert, geladen,
  zurückgesetzt und angeboten — aber von keinem Feature gelesen. Zur Klärung vorgelegt.)*
- **AK-09** · Angenommen, der Abschnitt *Privacy* ist sichtbar, wenn er angezeigt wird, dann
  steht dort die Zahl der ausgeschlossenen Programme und eine Schaltfläche zur Auswahl
  (Umsetzung in B02).

### Reiter *Annotation*

- **AK-10** · Angenommen, ein Standardwerkzeug, eine Standardfarbe und eine Strichstärke sind
  gewählt, wenn der Editor öffnet, dann sind sie voreingestellt.
- **AK-11** ⚠ · Angenommen, die Anwendung wurde nie eingestellt, wenn der Reiter zum ersten
  Mal geöffnet wird, dann zeigt die Auswahl der Strichstärke **keinen** ausgewählten Wert:
  Der Standard ist 3, zur Wahl stehen 2 („Thin"), 4 („Medium") und 6 („Thick").
  *(`AppPreferences.swift:114` und `:162` setzen 3,0; `AnnotationTabView.swift:64-66` bietet
  2, 4 und 6 an. Zur Klärung vorgelegt.)*
- **AK-12** · Angenommen, *Remember last used tool* ist eingeschaltet (Standard), wenn der
  Editor geschlossen wird, dann wird das zuletzt benutzte Werkzeug zum Standard.
- **AK-13** ⚠ · Angenommen, der Schalter *Show toolbar labels* wird eingeschaltet, wenn der
  Editor geöffnet wird, dann **erscheinen keine Beschriftungen**.
  *(`showToolbarLabels` wird von der Werkzeugleiste nicht gelesen. Zur Klärung vorgelegt.)*

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
- **AK-18** ⚠ · Angenommen, *Reset All Preferences* wird ausgeführt, wenn danach nachgesehen
  wird, dann bleiben **Farbverlauf und Palette erhalten** und die von Sparkle geführten
  Einstellungen ebenso.
  *(`AppPreferences.swift:135` führt eine von Hand gepflegte Schlüsselliste ohne
  `colorHistory`, `colorPalette` und ohne Sparkles eigene Schlüssel. Zur Klärung vorgelegt.)*
- **AK-19** ⚠ · Angenommen, *Reset All Preferences* wird ausgeführt, wenn danach eine
  Tastenkombination gedrückt wird, dann wird die zugehörige Funktion **doppelt** ausgelöst.
  *(`AdvancedTabView.swift:170` ruft `reRegisterAll`, das einen zusätzlichen
  Ereignisbehandler installiert — siehe B10/AK-08. Zur Klärung vorgelegt.)*

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 in Kraft.

- **AK-20** · Angenommen, Einstellungen werden geändert, wenn sie gespeichert werden, dann
  enthalten sie keine Nutzerinhalte — nur Pfade, Formate, Zahlen und Wahrheitswerte.
- **AK-21** · Angenommen, ein Ordner wird über *Change…* gewählt, wenn das geschieht, dann
  wird nur der Pfad gespeichert.
- **AK-22** · Angenommen, *Clear History* wird ausgeführt, wenn gelöscht wird, dann erscheint
  vorher eine Rückfrage, die die Endgültigkeit benennt.
- **AK-23** ⚠ · Angenommen, *Clear History* wird ausgeführt, wenn gelöscht wird, dann bleiben
  die **angehefteten Bilder** in *Application Support* unberührt und ungenannt.
  *(Siehe B08/AK-15. Zur Klärung vorgelegt.)*

*Abschnitte 4 und 6 des Katalogs: treffen nicht zu.*

## Edge Cases

- **EC-01** · Gewählter Ordner nicht beschreibbar → fällt erst beim Sichern auf, dort
  unsichtbar (B09/AK-08).
- **EC-02** · Gewählter Ordner wird gelöscht → wird beim nächsten Sichern neu angelegt.
- **EC-03** · Einstellungen offen, während der Verlauf sich ändert → Speicheranzeige wird
  nicht laufend aktualisiert.
- **EC-04** · *Reset* bei geöffnetem Editor → der Editor arbeitet mit den bereits
  übernommenen Werten weiter.

## Fehlbestand

- **FB-01 · Drei Einstellungen ohne jede Wirkung.** `floatingPreviewEnabled`,
  `previewDismissDuration` (`GeneralTabView.swift:95-121`) und `showToolbarLabels`
  (`AnnotationTabView.swift:97`). Gegenprobe: `captureSoundEnabled`, `rememberLastTool` und
  `defaultAnnotationTool` werden sehr wohl gelesen. Folge: Der Nutzer stellt etwas ein, das
  nichts tut — und hat keinen Anhaltspunkt dafür.
  *(Zusammen mit `permissionSkipped` aus B12 sind es vier tote Schlüssel im Projekt.)*
- **FB-02 · Die Dokumentation beschreibt das Fenster falsch.** `README.md`, `CHANGELOG.md`
  (3.4.0) gegen `Sources/Preferences/`. Folge: siehe AK-02.
- **FB-03 · Standard-Strichstärke steht nicht zur Auswahl.** Fundstellen:
  `AppPreferences.swift:114`, `:162` gegen `AnnotationTabView.swift:64-66`. Folge: leere
  Auswahl beim ersten Öffnen.
- **FB-04 · Die Rücksetzliste ist von Hand gepflegt.** Fundstelle:
  `AppPreferences.swift:135`. Folge: Wer einen Schlüssel hinzufügt, muss daran denken, ihn
  einzutragen — bei `colorHistory` und `colorPalette` ist genau das unterblieben. Eine
  vollständige Rücknahme über die Sammlung der Anwendungseinstellungen wäre unabhängig
  davon.
- **FB-05 · Die Speicherverwaltung kennt nur einen von zwei Ablageorten.** Fundstelle:
  `AdvancedTabView.swift:85`, `:157`. Folge: siehe AK-23 und B08/FB-01.
- **FB-06 · Zurücksetzen verdoppelt die Tastenkombinationen.** Fundstelle:
  `AdvancedTabView.swift:170`. Folge: siehe AK-19.
- **FB-07 · Keine Rückmeldung nach dem Zurücksetzen.** Es gibt keinen Hinweis, dass die
  Aktion ausgeführt wurde; sichtbar wird es nur an den geänderten Feldern.
- **FB-08 · Keine Tests.**

## Offene Fragen

- **OF-01** · Sollen die drei wirkungslosen Einstellungen umgesetzt oder entfernt werden? —
  entscheidet der Autor.
- **OF-02** · Ist das Fenster falsch oder die Dokumentation? — entscheidet der Autor.
- **OF-03** · Soll die Speicherverwaltung beide Ablageorte umfassen? — entscheidet der
  Autor. Betrifft B08.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie sind die Einstellungen aufgeteilt? | vier Reiter | folgt dem Aufbau der macOS-Systemeinstellungen |
| 2 | Wann wird gespeichert? | sofort bei jeder Änderung | kein „Übernehmen"; jede Eigenschaft schreibt beim Setzen |
| 3 | Wo liegen die Werte? | Benutzereinstellungen, gebündelt in einer Klasse | eine Stelle für alle Voreinstellungen |
| 4 | Erscheinungsbild | systemeigen, seit `a43683a` | zuvor dunkel im Markenbild; die Dokumentation nennt weiterhin den alten Zustand (FB-02) |
| 5 | Zurücksetzen über eine feste Schlüsselliste | die gesamte Sammlung entfernen | **Grund nicht erkennbar** — die Folge ist FB-04 |
| 6 | Endgültiges Löschen mit Rückfrage | Papierkorb ohne Rückfrage | die Rückfrage ist da, der Papierkorb nicht (B09/AK-18) |
