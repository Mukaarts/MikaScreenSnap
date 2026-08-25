# Features

Stand: 2026-08-25 · Stack-Profil: `swiftui-macos` · Artefaktpfad: `docs/`

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

## Was `rekonstruiert` hier bedeutet — und was noch fehlt

Die Specs beschreiben, **was der Code tut**, nicht was er tun sollte. Wo das Verhalten
fragwürdig aussieht, steht es trotzdem als Kriterium da, mit ⚠ markiert — damit `sdd-qa` es
reproduziert statt es zu übersehen.

**Der Bestätigungsschritt steht aus.** Nach dem Verfahren wird jedes ⚠-Kriterium einzeln
vorgelegt mit der Frage: *„Das tut der Code heute — soll er das?"* Diese Frage kann kein
Agent beantworten, weil die Absicht nirgends im Code steht. Bis sie beantwortet ist, gilt:

| Antwort | Folge |
|---|---|
| „ja, so gewollt" | Marker entfällt, bleibt reguläres Kriterium |
| „nein, das ist ein Fehler" | wandert aus den Kriterien in den *Fehlbestand* |
| „unklar" | bleibt als offene Frage stehen |

**51 Kriterien** tragen den Marker. Sie sind konservativ gesetzt: im Zweifel markiert statt
stillschweigend durchgewunken.

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

## Befunde aus der Rückerfassung

**89 Einträge unter *Fehlbestand*** über alle Specs, jeder mit Fundstelle und Folge. Hier
stehen nur die, die über ein einzelnes Feature hinausreichen oder Daten betreffen. Die
Grade sind **vorläufig** — gesetzt beim Lesen, nicht beim Prüfen. `sdd-qa` bewertet neu und
schreibt nach `features/befunde.md` fort.

### Datenverlust und Datenverbleib

| Befund | Feature | Grad (vorläufig) | Kern |
|---|---|---|---|
| Auto-Save schreibt **vor** dem Editor, also immer das unzensierte Original | B04, B09 | **hoch** | wer ein Passwort verpixelt und exportiert, hat das Original weiter in `~/Pictures/MikaScreenSnap/` |
| Angeheftete Bilder werden nie gelöscht, geschlossene kehren zurück | B08 | **hoch** | unsichtbarer, unbegrenzt wachsender Ablageort, in der Anwendung nicht leerbar |
| Dateiname mit Sekundengenauigkeit, Schreiben ohne Prüfung | B03, B09 | mittel | zwei Aufnahmen in derselben Sekunde → eine Datei |
| Fehlgeschlagenes Sichern schließt den Editor trotzdem und meldet nichts | B03, B09 | mittel | stiller Datenverlust |
| Anheften ignoriert die Einstellung zum automatischen Sichern | B08 | mittel | eine ausdrückliche Nutzerentscheidung wird übergangen |

### Zusagen, die nicht eingelöst werden

| Befund | Feature | Grad | Kern |
|---|---|---|---|
| Zwischenablage ohne Vertraulichkeitskennzeichnung | B03, B05, B06 | mittel | bei geräteübergreifender Zwischenablage trägt **macOS** Bild und erkannten Text zu anderen Geräten — die einzige Einschränkung der Zusage „kein Byte verlässt den Rechner" |
| Zensurstärke fest und nicht auflösungsbezogen; Weichzeichnen ohne Kantenfortsetzung | B04 | mittel | am Rand eines weichgezeichneten Bereichs bleibt mehr Originalinformation stehen |
| Palette wird befüllt und nirgends angezeigt | B06 | mittel | im README beworben, aus Nutzersicht wirkungslos |
| Ausschlussliste nicht nachprüfbar, nur laufende Programme wählbar | B02 | mittel | eine Zusage ohne Kontrollmöglichkeit; Passwortmanager nicht vorbeugend ausschließbar |
| Vier Einstellungsschlüssel ohne jeden Leser | B11, B12 | mittel | `floatingPreviewEnabled`, `previewDismissDuration`, `showToolbarLabels`, `permissionSkipped` |
| README und CHANGELOG beschreiben die Einstellungen als dunkel und markenfarben | B11 | mittel | der Code ist seit `a43683a` systemnativ |
| CHANGELOG 3.3.1 sagt, die Update-Schaltfläche werde deaktiviert | B14 | niedrig | `canCheckForUpdates` ist toter Code |

### Fehlverhalten mit Außenwirkung

| Befund | Feature | Grad | Kern |
|---|---|---|---|
| Ereignisbehandler werden bei jeder Neuanmeldung erneut installiert | B10, B11 | **hoch** | nach *n* Änderungen der Belegung löst ein Tastendruck *n+1* Aufnahmen aus; *Reset All Preferences* nimmt denselben Weg |
| Vollbild und Bereich rechnen immer gegen `displays.first` | B01 | mittel | auf Mehrschirm-Arbeitsplätzen falscher Bildschirm und falscher Ausschnitt — obwohl `ScreenGeometry` die Lösung enthält und der Fensterpfad sie benutzt |
| Vollbild multipliziert die Pixelgröße fest mit 2 | B01 | mittel | falsche Auflösung bei Skalierung ≠ 2 |
| Berechtigung wird nie angefordert, beim Erststart nicht einmal angestoßen | B12, B15, B01 | mittel | der Nutzer wird in eine Systemliste geschickt, in der die Anwendung noch nicht steht |
| Leertaste doppelt belegt (Einheitenwechsel und Verschieben) | B07, B03 | niedrig | Messen und Verschieben lösen gleichzeitig aus |
| Leeres OCR-Ergebnis bleibt stumm; die beiden OCR-Wege verhalten sich unterschiedlich | B05 | niedrig | Fehlschlag und Nichtstun sind nicht unterscheidbar |
| Lupe zeigt einen eingefrorenen Bildschirm | B06 | niedrig | bewusste Entscheidung, aber nicht gekennzeichnet |

### Projektweit

| Befund | Grad | Kern |
|---|---|---|
| **Keine Tests** (`Tests/` fehlt) | mittel | betrifft alle 15 Features. Genau die Fehlerklasse, die 3.4.1 im Fensterpfad behoben hat, ist im Bereichs- und Vollbildpfad unbemerkt geblieben — sie wäre testbar gewesen |
| Sechs `print()` in Fehlerpfaden | mittel | erreichen in einem Programm ohne Dock-Symbol niemanden |
| Keine Schemaversion in den Benutzereinstellungen | niedrig | ein Formatwechsel verliert die Konfiguration unbemerkt |
| Rücksetzliste von Hand gepflegt | niedrig | Farbverlauf, Palette und Sparkles Schlüssel überstehen *Reset All Preferences* |
| Kein Weg zur Projektseite aus der Anwendung | niedrig | bei „keine Fehlerberichte" als Erfolgskriterium bemerkenswert |

## Nächster Schritt

```
/sdd-qa B01
```

Findet die QA nichts, geht das Feature auf `deployed` mit Auditvermerk — ausgeliefert wird
nichts, der Code läuft ja. Ein kritischer oder hoher Befund **unterbricht** die Reihe, bis
die Reparatur draußen ist; mittlere und niedrige sammeln sich in `features/befunde.md`.

Nach allen fünfzehn: `/sdd-erfassen abschluss` für den Auditbericht.
