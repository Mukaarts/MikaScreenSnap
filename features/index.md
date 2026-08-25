# Features

Stand: 2026-08-25 · Stack-Profil: `swiftui-macos` · Artefaktpfad: `docs/` · Fassung 3.5.0

Alle Einträge sind **Bestand**: Sie existieren im ausgelieferten Code (Version 3.4.1) und
sind nie durch die SDD-Kette gelaufen. Das `B`-Präfix hält das dauerhaft sichtbar — bei
einem Fehler in `B04` ist die Spec eine Rekonstruktion und kann selbst falsch sein.

| ID | Feature | Prio | Status | Abhängig von | Zuletzt |
|---|---|---|---|---|---|
| B01 | Bildschirmaufnahme | P0 | rekonstruiert | B02, B03, B09, B10, B12 | 2026-08-25 |
| B02 | App-Ausschluss von Aufnahmen | P0 | rekonstruiert | B01, B11 | 2026-08-25 |
| B03 | Anmerkungs-Editor | P0 | rekonstruiert | B01, B04, B05, B07, B08, B09, B11 | 2026-08-25 |
| B04 | Bereiche zensieren | P0 | rekonstruiert | B01, B03, B09 | 2026-08-25 |
| B05 | Bildschirmtext erfassen (OCR) | P1 | rekonstruiert | B01, B02, B03, B10 | 2026-08-25 |
| B06 | Farbpipette | P1 | rekonstruiert | B01, B02, B10, B15 | 2026-08-25 |
| B07 | Lineal / Bildschirm vermessen | P1 | rekonstruiert | B03, B10 | 2026-08-25 |
| B08 | Screenshots anheften | P1 | rekonstruiert | B03, B09, B15 | 2026-08-25 |
| B09 | Screenshot-Verlauf | P0 | rekonstruiert | B01, B03, B08, B11 | 2026-08-25 |
| B10 | Tastenkombinationen | P0 | rekonstruiert | B01, B05, B06, B07, B09, B11 | 2026-08-25 |
| B11 | Einstellungen | P0 | rekonstruiert | B02, B09, B10, B12, B13, B14 | 2026-08-25 |
| B12 | Ersteinrichtung | P1 | rekonstruiert | B01, B11, B13 | 2026-08-25 |
| B13 | Automatischer Start bei Login | P2 | rekonstruiert | B11, B12 | 2026-08-25 |
| B14 | Automatische Updates | P1 | rekonstruiert | B11, B15 | 2026-08-25 |
| B15 | Menüleisten-Hub & Programminfo | P0 | rekonstruiert | alle | 2026-08-25 |

**Alle fünfzehn Features sind rückerfasst.** Je Feature liegen `spec.md` und `design.md`
vor. Nächster Schritt: `/sdd-qa B01` und so fort, in der Reihenfolge unten.

## Stand der Rückerfassung

Die Specs beschreiben, **was der Code tut**. Sie sind auf 3.5.0 nachgeführt: Alle Befunde
der Erfassung sind entweder behoben oder mit Begründung und Datum akzeptiert, und alle
markierten Kriterien sind entschieden.

| | Erfassung (3.4.1) | Jetzt (3.5.0) |
|---|---|---|
| Einträge unter *Fehlbestand* | 89 | 0 offen — 23 behoben, 15 akzeptiert (zusammengefasst in `befunde.md`) |
| Kriterien mit ⚠ | 51 | 0 |
| Offene Fragen in den Specs | 40 | 0 |
| Offene Punkte im PRD | 6 | 0 |
| Tests | keine | 28 |

Die vollständige Liste mit Fundstellen, Graden und Begründungen steht in
`features/befunde.md`, einschließlich der Muster, die erst projektweit sichtbar wurden.

**Was noch aussteht: die QA.** Die Befunde stammen aus dem Lesen des Codes, nicht aus dem
Prüfen. `sdd-qa` weist jedes Kriterium einzeln nach — das ist der Schritt, der aus
„beschrieben" ein „belegt" macht.

## Prüfreihenfolge

**B01 → B02 → B04 → B09 → B05 → B06 → B08 → B14 → B12 → B03 → B10 → B11 → B13 → B07 → B15**

Nach Risiko, nicht nach Nummer. Die QA ist an einem Bestandsprojekt ein Sicherheitsaudit —
wer mit der Darstellung anfängt, prüft zuletzt, was zuerst brennen kann.

| Rang | Features | Warum hier |
|---|---|---|
| 1 | B01, B02 | lesen die Bildschirminhalte **jeder** laufenden App; B02 trägt die einzige Zugriffsregel der Anwendung |
| 2 | B04, B09 | die Frage, die nur über beide zu beantworten ist: liegt das unzensierte Original im Verlauf? |
| 3 | B05, B06 | lesen ebenfalls den gesamten Bildschirm |
| 4 | B08 | legt Bildschirminhalte dauerhaft ab und stellt sie beim Start wieder her |
| 5 | B14 | einziger Netzwerkpfad — und der einzige Weg, auf dem ausführbarer Code auf den Rechner kommt |
| 6 | B12 | steuert den Berechtigungsfluss |
| 7 | B03, B10, B11 | nehmen Eingaben entgegen und schreiben Dateien |
| 8 | B13, B07, B15 | geringstes Risiko |

## Befunde

Vollständig in `features/befunde.md`. Die drei schwersten, alle in 3.5.0 behoben:

| Befund | Feature | Grad | Kern |
|---|---|---|---|
| Auto-Save schrieb vor dem Editor, also immer das unzensierte Original | B04, B09 | hoch | wer ein Passwort verpixelte und exportierte, hatte das Original weiter im Verlaufsordner |
| Angeheftete Bilder wurden nie gelöscht, geschlossene kehrten zurück | B08 | hoch | ein unsichtbarer, unbegrenzt wachsender Ablageort |
| Ereignisbehandler wurden bei jeder Neuanmeldung erneut installiert | B10, B11 | hoch | nach *n* Änderungen der Belegung löste ein Tastendruck *n+1* Aufnahmen aus |

Das aufschlussreichste Muster: **Ein Fehler wurde einmal behoben und blieb an drei anderen
Stellen stehen.** 3.4.1 korrigierte Displaywahl und Skalierung für Fensteraufnahmen;
Vollbild, Bereich und Texterkennung behielten `displays.first` und `NSScreen.main` — obwohl
die Anwendung mit `ScreenGeometry` die richtige Umrechnung bereits besaß. Ursache waren die
fehlenden Tests: Eine Prüfung der Koordinatenrechnung hätte alle vier Stellen zugleich
erfasst. Sie existiert jetzt.

## Nächster Schritt

```
/sdd-qa B01
```

In der Prüfreihenfolge oben. Findet die QA nichts, geht das Feature auf `deployed` mit
Auditvermerk — ausgeliefert wird nichts, der Code läuft ja. Ein kritischer oder hoher
Befund unterbricht die Reihe, bis die Reparatur draußen ist.

Nach allen fünfzehn: `/sdd-erfassen abschluss` für den Auditbericht, dessen Eingabe
`features/befunde.md` ist.

**Zur Auslieferung von 3.5.0** siehe die Reihenfolge in `README.md` unter *Auto-Update* —
Version, Bau, Beglaubigung, GitHub-Release, Signatur über das geladene DMG, dann der
Appcast-Eintrag als letzter Schritt. Und `main:master` mitpushen.
