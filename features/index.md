# Features

Stand: 2026-08-25 · Stack-Profil: `swiftui-macos` · Artefaktpfad: `docs/`

Alle Einträge sind **Bestand**: Sie existieren im ausgelieferten Code (Version 3.4.1) und
sind nie durch die SDD-Kette gelaufen. Das `B`-Präfix hält das dauerhaft sichtbar — bei
einem Fehler in `B04` ist die Spec eine Rekonstruktion und kann selbst falsch sein.

| ID | Feature | Prio | Status | Abhängig von | Zuletzt |
|---|---|---|---|---|---|
| B01 | Bildschirmaufnahme | P0 | bestand | — | — |
| B02 | App-Ausschluss von Aufnahmen | P0 | bestand | B01 | — |
| B03 | Anmerkungs-Editor | P0 | bestand | B01 | — |
| B04 | Bereiche zensieren | P0 | bestand | B03 | — |
| B05 | Bildschirmtext erfassen (OCR) | P1 | bestand | B01, B02 | — |
| B06 | Farbpipette | P1 | bestand | B01, B02 | — |
| B07 | Lineal / Bildschirm vermessen | P1 | bestand | B03 | — |
| B08 | Screenshots anheften | P1 | bestand | B01, B03 | — |
| B09 | Screenshot-Verlauf | P0 | bestand | B01 | — |
| B10 | Tastenkombinationen | P0 | bestand | B01 | — |
| B11 | Einstellungen | P0 | bestand | B01, B09, B10 | — |
| B12 | Ersteinrichtung | P1 | bestand | B01, B13 | — |
| B13 | Automatischer Start bei Login | P2 | bestand | — | — |
| B14 | Automatische Updates | P1 | bestand | — | — |
| B15 | Menüleisten-Hub & Programminfo | P0 | bestand | alle | — |

## Erfassungsreihenfolge

**B01 → B02 → B04 → B09 → B05 → B06 → B08 → B14 → B12 → B03 → B10 → B11 → B13 → B07 → B15**

Nach Risiko, nicht nach Nummer. Die Rückerfassung ist die Eintrittskarte für `sdd-qa`,
und die QA ist an einem Bestandsprojekt ein Sicherheitsaudit — wer mit der Darstellung
anfängt, prüft zuletzt, was zuerst brennen kann.

| Rang | Features | Warum hier |
|---|---|---|
| 1 | B01, B02 | lesen über ScreenCaptureKit die Bildschirminhalte **jeder** laufenden App. B02 trägt die einzige Zugriffsregel der Anwendung: Was ausgeschlossen ist, darf nirgends auftauchen — auch nicht in B05 und B06 |
| 2 | B04, B09 | zusammen, weil die entscheidende Frage nur über beide zu beantworten ist: **Liegt das unverpixelte Original im Verlauf, nachdem der Nutzer etwas zensiert hat?** Wer beide getrennt prüft, findet das nie |
| 3 | B05, B06 | lesen ebenfalls den gesamten Bildschirm — OCR erkennt Text, den es nicht erkennen sollte; die Pipette snapshottet alle Displays für ein einziges Pixel |
| 4 | B08 | legt Bildschirminhalte dauerhaft ab und stellt sie beim Start wieder her. Der schwerste Befund der Kartierung sitzt hier (FB-DM-01) |
| 5 | B14 | einziger Netzwerkpfad der App — und Sparkle installiert ausführbaren Code. Ein Fehler in der Signaturprüfung wiegt schwerer als jeder Darstellungsfehler |
| 6 | B12 | steuert den Berechtigungsfluss: Was hier schiefgeht, entscheidet, ob B01 überhaupt darf |
| 7 | B03, B10, B11 | nehmen Eingaben entgegen und schreiben Dateien, lesen aber nichts von fremden Fenstern |
| 8 | B13, B07, B15 | Systemdienst, Messung und Navigation — geringstes Risiko |

B03 steht bewusst **hinter** B04, obwohl es dessen Vorstufe ist: Der Editor als Ganzes ist
Werkzeug, das Zensieren ist eine Datenschutzzusage. Für die Rückerfassung von B04 reicht
das Wissen über den Editor aus dem Code; umgekehrt gilt das nicht.

## Umfang

Fünfzehn Features, fünfzehn Sitzungen. Das ist kein Argument dagegen, aber es sollte
niemand überrascht sein. Jede Sitzung wird einzeln aufgerufen:

```
/sdd-erfassen B01
```

Danach `/sdd-qa B01`. Was die QA findet, entscheidet über den weiteren Weg — ein
kritischer oder hoher Befund unterbricht die Erfassung, bis die Reparatur ausgeliefert
ist, weil er Code betrifft, der in diesem Moment läuft.

## Bereits bekannte Befunde

Aus der Kartierung, jeweils verifiziert und dem Feature zugeordnet, in dessen Spec sie
unter *Fehlbestand* gehören. Sie sind **keine** Akzeptanzkriterien.

| Befund | Feature | Grad (vorläufig) | Kurz |
|---|---|---|---|
| FB-DM-01 | B08 | hoch | angeheftete Bilder werden nie gelöscht, sammeln sich unsichtbar an, geschlossene Pins kehren zurück |
| FB-AS-03 | B03, B05, B08, B09, B13 | mittel | sechs `print()` in Fehlerpfaden — der Nutzer erfährt nicht, wenn das Sichern fehlschlägt |
| FB-DM-03 | B06 | mittel | `resetAll()` löscht Farbverlauf und Palette nicht |
| FB-DS-01 | B11 | mittel | README und CHANGELOG beschreiben die Einstellungen als dunkel; der Code ist systemnativ |
| FB-DM-02 | B11 | mittel | drei Einstellungen ohne jede Wirkung |
| FB-AS-02 | B01, B12 | mittel | fehlende Berechtigung wird angezeigt, blockiert aber nichts — der Weg führt durch einen Fehlversuch |
| FB-DM-04 | B09 | niedrig | `HistoryItem.id` bei jedem Start neu, `date` ist das Änderungsdatum |
| FB-DM-05 | B03 | niedrig | `AnnotationSnapshot.data` untypisiert, Fehler fallen erst zur Laufzeit auf |
| FB-DM-06 | projektweit | niedrig | keine Schemaversion in `UserDefaults`, kein Migrationspfad |
| FB-DS-02 bis -05 | B11, projektweit | niedrig | Markenpalette nur teilweise angewandt, keine Tokens, kein Hell-Modus, Kontrast ungeprüft |
| FB-AS-01, FB-AS-04 | B12, projektweit | niedrig | Onboarding schwer wiederauffindbar, keine Fensterwiederherstellung |

Die Grade sind **vorläufig** — gesetzt beim Lesen, nicht beim Prüfen. `sdd-qa` bewertet
sie neu und schreibt sie nach `features/befunde.md` fort.
