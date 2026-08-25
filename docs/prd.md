# Mika+ScreenSnap — Product Requirements Document

Stand: 2026-08-25 · Stufe Datenschutz: A · Stack-Profil: `swiftui-macos`
Artefaktpfad: `docs/`

> **Rückwirkend erfasst.** Dieses Dokument beschreibt, was Version 3.4.1 tut — nicht,
> was geplant war. Es entstand über `sdd-erfassen` aus Code, `CLAUDE.md`, `README.md`,
> `CHANGELOG.md` und der Marketingseite in `web/`, nicht aus einem Briefing.

## Vision

Mika+ScreenSnap nimmt den Bildschirm auf und öffnet das Ergebnis sofort in einem Editor,
statt es auf dem Schreibtisch abzulegen. Wer einen Screenshot macht, will in aller Regel
etwas daran zeigen: einen Pfeil, eine Beschriftung, ein verpixeltes Passwort. Genau
dieser Schritt liegt hier zwischen Tastendruck und Zwischenablage — nicht in einer
zweiten App.

Dazu kommen vier Werkzeuge, die dieselbe Bildschirmaufnahme für etwas anderes benutzen:
Text erkennen, Farbe abgreifen, Pixel messen, ein Bild dauerhaft im Vordergrund halten.

## Zielgruppe

| Gruppe | Situation | Was sie hier will |
|---|---|---|
| Der Autor selbst | tägliche Arbeit an macOS-Projekten, mehrmals stündlich ein Screenshot | ein Werkzeug, das genau so funktioniert, wie er es will — ohne Kompromiss an fremde Produktentscheidungen |
| Zufällige Nutzerinnen und Nutzer | fanden das Projekt auf GitHub, suchen einen Ersatz für `⇧⌘4` | eine App, die installiert einfach läuft — kein Konto, keine Cloud, keine Nachfragen |

Die zweite Gruppe ist **Nebenprodukt, nicht Auftraggeber.** Das ist eine
Produktentscheidung mit Folgen: Bei einem Zielkonflikt gewinnt der Eigenbedarf. Wer
Features für die zweite Gruppe fordert, argumentiert gegen den Zweck.

## Im Scope

- Bildschirmaufnahme in drei Formen: Vollbild, gezogener Bereich, einzelnes Fenster
- Annotationseditor, der sich nach jeder Aufnahme selbst öffnet — 11 Werkzeuge, Undo/Redo, Zoom/Pan
- Unkenntlichmachen von Bildinhalten durch Weichzeichnen und Verpixeln
- Texterkennung aus einem Bildschirmbereich, Ergebnis in der Zwischenablage
- Farbpipette mit Lupe, Farbverlauf und Palette
- Pixelmessung als Vollbild-Overlay und als Werkzeug im Editor
- Screenshots als schwebendes Fenster anheften, über Neustarts hinweg
- Automatisches Sichern jeder Aufnahme plus durchsuchbarer Verlauf
- Frei belegbare systemweite Tastenkombinationen
- Ausschlussliste: benannte Apps erscheinen in keiner Aufnahme
- Ersteinrichtung, die durch die Bildschirmaufnahme-Berechtigung führt
- Selbstaktualisierung über Sparkle, Direktvertrieb als notarisiertes DMG

## Nicht im Scope

- **Cloud und Konten** (bestätigt 2026-08-25) — keine Anmeldung, kein Backend, keine
  Synchronisation, keine Analyse des Nutzungsverhaltens. Alles bleibt auf dem Rechner.
  Das ist der Grund, warum die Datenschutzseite in `web/app/privacy/` behaupten darf, die
  App wisse nichts über ihre Nutzer — und warum jede Funktion, die das ändern würde, hier
  zuerst diskutiert werden muss.

Was **nicht** als Nicht-Ziel bestätigt ist, aber im Bestand fehlt — Bildschirmvideo,
Bildbearbeitung über Annotation hinaus, App-Store-Vertrieb —, steht unter *Offene Punkte*.
Fehlen allein ist kein Vorsatz.

## Erfolgskriterien

- **Keine Abstürze, keine Fehlerberichte.** Der Maßstab ist Stabilität, nicht Verbreitung:
  Eine App, die im Hintergrund liegt und bei jedem Tastendruck funktioniert, hat ihren
  Zweck erfüllt.
- Nachprüfbar über GitHub Issues und die Absturzberichte unter
  `~/Library/Logs/DiagnosticReports/` — beides ohne Telemetrie, passend zur Stufe A.

## Rahmenbedingungen

| Thema | Entscheidung |
|---|---|
| Stack-Profil | `swiftui-macos` — Details in `~/.claude/sdd/stacks/swiftui-macos.md` |
| Sprache/Version | Swift 6.0, strict concurrency, `@MainActor`-Isolation durchgehend |
| Zielplattform | macOS 14.0 (Sonoma) aufwärts, **arm64 ausschließlich** (das ausgelieferte Binary ist nicht universal) |
| Projektform | reines Swift Package, kein Xcode-Projekt |
| Backend | **keins** |
| Umgebungen | nur lokal — es gibt keine Test- oder Produktivumgebung, nur gebaute Bundles |
| Datenhaltung | `UserDefaults` für Einstellungen · `~/Pictures/MikaScreenSnap/` für Aufnahmen · `~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/` für angeheftete Bilder |
| Sandbox | **aus** (`com.apple.security.app-sandbox = false`) — nötig für ScreenCaptureKit über Fremdfenster und Carbon-Hotkeys; schließt den App Store aus und macht Direktvertrieb zur Folge, nicht zur Wahl |
| Berechtigungen | Bildschirmaufnahme (Screen Recording) — ohne sie ist die App funktionslos |
| Externe Dienste | **Sparkle-Appcast** auf `raw.githubusercontent.com` — überträgt beim Update-Check das, was Sparkle standardmäßig sendet; empfängt Feed und DMG. Sonst kein Netzwerkverkehr |
| Vertrieb | notarisiertes DMG als GitHub-Release, Update über Sparkle-Appcast auf `main` |
| Sprachen | Oberfläche englisch · OCR erkennt Deutsch, Englisch, Französisch |
| Monetarisierung | keine — MIT-Lizenz, kostenlos |

## Datenschutz — Kurzfassung

**Stufe A, weil kein Datum den Rechner verlässt.** Die App hat keine Konten, kein
Backend, keine Analyse und keinen Netzwerkpfad außer dem Sparkle-Update-Check. OCR läuft
über Apples Vision-Framework auf dem Gerät, die Farbpipette liest lokale Pixel. Ein Grep
über `Sources/` findet kein `URLSession` und keine `URLRequest` — die Zusage der
Datenschutzseite ist im Code belegbar.

**Die Einstufung darf trotzdem nicht in Sorglosigkeit umschlagen.** Was diese App
verarbeitet, ist inhaltlich das Sensibelste, was ein Rechner hergibt: alles, was auf dem
Bildschirm steht. Ein Screenshot kann Gesundheitsdaten, Chats, Passwörter und fremde
Personendaten enthalten — Kategorien, die anderswo Stufe C auslösen würden. Stufe A gilt
hier allein deshalb, weil diese Inhalte das Gerät nie verlassen und niemand außer der
Person am Rechner sie zu Gesicht bekommt.

Daraus folgen App-weite Regeln, die in jeder Feature-Spec konkretisiert werden:

- **Kein Bildinhalt geht ins Log.** Weder Pixel, noch erkannter Text, noch Dateinamen
  mit erkennbarem Inhalt. `CaptureLog` protokolliert Fehler, keine Daten.
- **Kein Bildinhalt verlässt das Gerät — mit einer Einschränkung, die bei der
  Rückerfassung gefunden wurde.** Die Anwendung selbst baut außer dem Sparkle-Update-Check
  keine Verbindung auf. Sie legt jedoch Bilder, erkannten Text und Farbwerte in die
  allgemeine Zwischenablage, ohne sie als vertraulich zu kennzeichnen. Ist die
  geräteübergreifende Zwischenablage aktiviert, überträgt **macOS** diese Inhalte an die
  anderen Geräte des Nutzers. Das ist keine Übertragung der Anwendung, aber eine Folge ihres
  Verhaltens — und die Zusage muss so genau formuliert bleiben. Fundstellen und
  Kriterien: B03/AK-33, B05/AK-17, B06/AK-16.
- **Was der Nutzer unkenntlich macht, bleibt unkenntlich.** Ein verpixelter Bereich darf
  im Export nicht rekonstruierbar sein — und kein Nebenpfad darf das unbearbeitete
  Original ablegen, ohne dass die Person das weiß.
- **Die Ausschlussliste ist eine Zusage, keine Bequemlichkeit.** Eine dort eingetragene
  App darf in keiner Aufnahme auftauchen — auch nicht in der Farbpipette, auch nicht im OCR.
- **Lokale Ablagen sind unverschlüsselt.** Aufnahmen liegen im Klartext in
  `~/Pictures/MikaScreenSnap/`, angeheftete Bilder in `Application Support`. Das ist der
  Normalfall für macOS-Nutzdaten, aber es ist eine bewusste Entscheidung und keine
  Selbstverständlichkeit.

Der Katalog aus `~/.claude/sdd/sicherheit.md` gilt nach Stufe A verkürzt auf die
Abschnitte 4 (Missbrauch und Kosten) und 6 (Geheimnisse) — **erweitert um Abschnitt 1**,
weil die Frage „landen Daten in Logs" hier trotz Stufe A scharf gestellt werden muss.

## Feature-Roadmap

Kein Plan, sondern ein **Inventar**: Alle 15 Einträge existieren im ausgelieferten Code
und stehen auf Status `bestand`. Die Prioritäten beschreiben, was die App ohne den
jeweiligen Eintrag noch wäre.

| ID | Feature | Prio | Kurzbeschreibung | Abhängig von |
|---|---|---|---|---|
| B01 | Bildschirmaufnahme | P0 | Vollbild, gezogener Bereich oder einzelnes Fenster über ScreenCaptureKit | — |
| B02 | App-Ausschluss von Aufnahmen | P0 | benannte Apps erscheinen in keiner Aufnahme | B01 |
| B03 | Anmerkungs-Editor | P0 | Pfeil, Rechteck, Ellipse, Linie, Freihand, Text, Hervorheben, Auswahl; Undo/Redo, Zoom/Pan | B01 |
| B04 | Bereiche zensieren | P0 | Weichzeichnen und Verpixeln sensibler Bildstellen | B03 |
| B05 | Bildschirmtext erfassen (OCR) | P1 | Text aus einem Bereich erkennen und in die Zwischenablage legen | B01, B02 |
| B06 | Farbpipette | P1 | Pixelfarbe mit Lupe abgreifen, HEX kopieren, Verlauf und Palette | B01, B02 |
| B07 | Lineal / Bildschirm vermessen | P1 | Pixelabstände messen — als Overlay und als Editorwerkzeug | B03 |
| B08 | Screenshots anheften | P1 | Bild als schwebendes Fenster halten, über Neustarts hinweg | B01, B03 |
| B09 | Screenshot-Verlauf | P0 | jede Aufnahme automatisch sichern, durchsuchbar anzeigen | B01 |
| B10 | Tastenkombinationen | P0 | sieben systemweite Hotkeys über Carbon, frei belegbar | B01 |
| B11 | Einstellungen | P0 | vier Tabs: Speicherort, Format, Ton, Zeichen-Standards, Speicherplatz, Zurücksetzen | B01, B09, B10 |
| B12 | Ersteinrichtung | P1 | dreistufiger Erststart mit Berechtigungsanfrage und Shortcut-Übersicht | B01, B13 |
| B13 | Automatischer Start bei Login | P2 | Anmeldeobjekt über `SMAppService` | — |
| B14 | Automatische Updates | P1 | Sparkle prüft den Appcast und installiert neue Versionen | — |
| B15 | Menüleisten-Hub & Programminfo | P0 | Statusleistensymbol als einziger Einstiegspunkt, „Über"-Fenster | alle |

**Erfassungsreihenfolge:** B01 → B02 → B04 → B09 → B05 → B06 → B08 → B14 → B12 → B03 → B10 → B11 → B13 → B07 → B15

Begründung steht unter der Tabelle in `features/index.md` — sie folgt dem Risiko, nicht
der Nummer.

## Offene Punkte

- **OF-01** (2026-08-25) — Sind Bildschirmvideo/GIF, weitergehende Bildbearbeitung und
  App-Store-Vertrieb bewusste Nicht-Ziele oder nur bisher nicht gebaut? Der Bestand sagt
  darüber nichts. Bis zur Klärung stehen sie **nicht** unter *Nicht im Scope* — eine Lücke
  ist ein Befund, kein Vorsatz.
- **OF-02** (2026-08-25) — Das ausgelieferte Binary ist arm64-only, die Website sagt das
  ehrlich („Apple silicon"). Ist Intel-Unterstützung aufgegeben oder nie beabsichtigt gewesen?
- **OF-03** (2026-08-25) — Der Sparkle-Feed zeigt seit `db55d1f` auf `main`; Installationen
  bis einschließlich 3.4.1 haben `master` fest einkompiliert. Bis der letzte dieser
  Installationen aktualisiert ist, muss `main:master` mitgepusht werden. Wann darf das enden?
- **OF-04** (2026-08-25) — Es existieren **keine Tests** (`Tests/` fehlt). Für die
  Rückerfassung heißt das: Jedes Akzeptanzkriterium braucht in der QA einen manuellen
  Nachweis oder einen neu geschriebenen Test. Soll `swift test` als Ziel etabliert werden?
- **OF-05** (2026-08-25, aus der Rückerfassung) — Soll die Zwischenablage als vertraulich
  gekennzeichnet werden, damit erkannter Text und Screenshots nicht über die
  geräteübergreifende Zwischenablage weitergereicht werden? Das ist die einzige Stelle, an
  der Nutzerinhalte den Rechner verlassen können. Betrifft B03, B05 und B06.
- **OF-06** (2026-08-25, aus der Rückerfassung) — Die Anwendung fordert die
  Bildschirmaufnahme-Berechtigung nie an (`CGRequestScreenCaptureAccess` kommt nirgends
  vor), und der Aufruf, der sie in die Systemliste einträgt, läuft beim Erststart nicht.
  Soll das geändert werden? Betrifft B01, B12 und B15 und ist der wahrscheinlichste Grund
  für einen misslungenen ersten Start.
