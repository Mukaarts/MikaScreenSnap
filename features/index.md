# Features

Stand: 2026-09-03 · Stack-Profil: `swiftui-macos` · Artefaktpfad: `docs/` · Fassung 3.5.0

Die Einträge mit `B`-Präfix sind **Bestand**: Sie existieren im ausgelieferten Code
(Version 3.4.1) und sind nie durch die SDD-Kette gelaufen. Das Präfix hält das dauerhaft
sichtbar — bei einem Fehler in `B04` ist die Spec eine Rekonstruktion und kann selbst
falsch sein. Einträge ohne Präfix sind regulär durch die Kette gebaut.

| ID | Feature | Prio | Status | Abhängig von | Zuletzt |
|---|---|---|---|---|---|
| B01 | Bildschirmaufnahme | P0 | approved | B02, B03, B09, B10, B12 | 2026-08-25 · QA bestanden |
| B02 | App-Ausschluss von Aufnahmen | P0 | approved | B01, B11 | 2026-08-25 · QA bestanden |
| B03 | Anmerkungs-Editor | P0 | approved | B01, B04, B05, B07, B08, B09, B11 | 2026-08-25 · QA bestanden |
| B04 | Bereiche zensieren | P0 | approved | B01, B03, B09 | 2026-08-25 · QA bestanden |
| B05 | Bildschirmtext erfassen (OCR) | P1 | approved | B01, B02, B03, B10 | 2026-08-25 · QA bestanden |
| B06 | Farbpipette | P1 | approved | B01, B02, B10, B15 | 2026-08-25 · QA bestanden |
| B07 | Lineal / Bildschirm vermessen | P1 | approved | B03, B10 | 2026-08-25 · QA bestanden |
| B08 | Screenshots anheften | P1 | approved | B03, B09, B15 | 2026-08-25 · QA bestanden |
| B09 | Screenshot-Verlauf | P0 | approved | B01, B03, B08, B11 | 2026-08-25 · QA bestanden |
| B10 | Tastenkombinationen | P0 | approved | B01, B05, B06, B07, B09, B11 | 2026-08-25 · QA bestanden |
| B11 | Einstellungen | P0 | approved | B02, B09, B10, B12, B13, B14 | 2026-08-25 · QA bestanden |
| B12 | Ersteinrichtung | P1 | approved | B01, B11, B13 | 2026-08-25 · QA bestanden |
| B13 | Automatischer Start bei Login | P2 | approved | B11, B12 | 2026-08-25 · QA bestanden |
| B14 | Automatische Updates | P1 | approved | B11, B15 | 2026-08-25 · QA bestanden |
| B15 | Menüleisten-Hub & Programminfo | P0 | approved | alle | 2026-08-25 · QA bestanden |
| 16 | App-Store-Auslieferung | P1 | review | B01, B02, B08, B09, B11, B12, B14 | 2026-09-03 · 0 Befunde, 26 AK ungeprüft |

**Alle fünfzehn Bestandsfeatures sind rückerfasst und geprüft.** Je Feature liegen
`spec.md`, `design.md` und `qa-report.md` vor. Nächster Schritt ist die Auslieferung
von 3.5.0.

**16 ist das erste reguläre Feature der Kette.** Es hebt eine PRD-Entscheidung auf
(App-Store-Vertrieb stand unter *Nicht im Scope*, OF-01) und berührt sieben
Bestandsfeatures, ohne eines davon zu ersetzen. Das PRD ist noch nicht nachgeführt —
bis dahin widersprechen sich `docs/prd.md` und `features/16-app-store-auslieferung/spec.md`.

## Stand

| | Erfassung (3.4.1) | Nach Reparatur und QA (3.5.0) |
|---|---|---|
| Einträge unter *Fehlbestand* | 89 | 0 offen — 25 behoben, 15 akzeptiert (`befunde.md`) |
| Kriterien mit ⚠ | 51 | 0 |
| Offene Fragen in den Specs | 40 | 0 |
| Offene Punkte im PRD | 6 | 0 |
| Tests | keine | 59, alle grün |
| Akzeptanzkriterien geprüft | — | 269: **124 bestanden, 0 durchgefallen, 145 nicht prüfbar** |

**Die 145 nicht prüfbaren Kriterien sind kein Nebensatz.** Sie brauchen Mausereignisse,
Fensterlebenszyklen, eine erteilte Bildschirmaufnahme-Berechtigung oder ein zweites
Display — nichts davon war hier ausführbar. Sie stehen in den Berichten ausdrücklich
**nicht** unter *bestanden*, und jeder Bericht endet mit einer benannten manuellen Auflage.

Die vier wichtigsten davon stehen in `features/befunde.md` unter *Offen*. Ohne sie ist die
Auslieferung nicht abgeschlossen — insbesondere B02/AK-03, die einzige Zugriffsregel der
Anwendung.

## Reihenfolge der Prüfung (wie durchlaufen)

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

**Auslieferung von 3.5.0 als DMG — am 2026-09-03 bestätigt und vorgezogen.** Sie hängt
nicht am App Store: 3.5.0 enthält den Fix, dass eine Zensur nicht mehr das unbearbeitete
Original im Verlaufsordner zurücklässt. Wer heute auf 3.4.1 ein Passwort verpixelt, hat es
weiterhin im Klartext auf der Platte. Die Store-Fassung kommt später als **3.6.0**,
gemeinsam mit dem DMG derselben Nummer.

**Auslieferung von 3.5.0.** Reihenfolge nach `README.md`, Abschnitt *Auto-Update*:

1. `bash build.sh` — erledigt, Bundle liegt unter `build/`
2. `bash scripts/notarize.sh` — **erledigt am 2026-09-03.** Aus dem Stand von `main`
   gebaut, nicht aus dem Feature-Branch: Der trägt zwar dieselbe Versionsnummer, enthält
   aber 604 Zeilen Feature-16-Code, deren Laufzeitverhalten nie geprüft wurde.

   | Prüfung | Ergebnis |
   |---|---|
   | Notarisierung | `status: Accepted`, Vorgang `e3f78aeb-1bb7-473a-8787-dedb0e2d139f` |
   | Ticket angeheftet | `stapler validate` — *The validate action worked!* |
   | `spctl -a -vv -t install` | **`accepted` · `source=Notarized Developer ID`** |
   | Signatur | `Developer ID Application: Michael Rodrigues (CWJM4J4HFN)` |
   | Datei | `installer/Mika+ScreenSnap-v3.5.0.dmg`, 2042057 Bytes (appcast-`length`) |

   Damit ist der Befund von der Erfassung geschlossen: Die Anwendung startet jetzt auf
   fremden Rechnern.

   ~~**ausstehend und zwingend.** Nachgewiesen: Das gebaute DMG
   ist ad-hoc signiert, und `spctl -a -vv -t install` antwortet
   `rejected — source=no usable signature`. Auf einem fremden Rechner startet die Anwendung
   damit nicht. **Korrigiert am 2026-09-03:** Das nötige Notary-Profil `MikaScreenSnap`
   liegt bereits im Schlüsselbund — `xcrun notarytool history` beantwortet damit und
   zeigt die Einreichung von 3.4.1 vom 2026-08-09. Auch das Zertifikat
   `Developer ID Application` ist vorhanden. **Es fehlt nichts; der Schritt wurde nur
   nie ausgeführt**
3. GitHub-Release mit dem beglaubigten DMG
4. `sign_update` über das **von GitHub geladene** DMG
5. `appcast.xml` ergänzen, mergen, `main:master` mitpushen

Davor: die vier manuellen Prüfungen aus `features/befunde.md`.

Danach `/sdd-erfassen abschluss` für den Auditbericht und `/sdd-betrieb` für die Nachsorge —
dessen Eingabe ist der Abschnitt *Muster* in `features/befunde.md`.
