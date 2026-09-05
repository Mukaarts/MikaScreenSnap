# Mika+ScreenSnap — Product Requirements Document

Stand: 2026-09-03 · Stufe Datenschutz: A · Stack-Profil: `swiftui-macos` · Fassung 3.5.0
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
- Zweiter Vertriebsweg über den Mac App Store, aus derselben Quelle und mit Sandbox
  (aufgenommen 2026-09-03, Feature `16` — siehe *Nicht im Scope* unten)

## Nicht im Scope

- **Cloud und Konten** (bestätigt 2026-08-25) — keine Anmeldung, kein Backend, keine
  Synchronisation, keine Analyse des Nutzungsverhaltens. Alles bleibt auf dem Rechner.
  Das ist der Grund, warum die Datenschutzseite in `web/app/privacy/` behaupten darf, die
  App wisse nichts über ihre Nutzer — und warum jede Funktion, die das ändern würde, hier
  zuerst diskutiert werden muss.

- **Bildschirmvideo und GIF** (bestätigt 2026-08-25) — Standbilder bleiben der Umfang. Eine
  Aufzeichnung wäre ein zweites Produkt mit eigenem Editor, eigenen Formaten und eigenem
  Speicherverhalten.
- **Bildbearbeitung über Annotation hinaus** (bestätigt 2026-08-25) — keine Filter, keine
  Ebenen, kein Zuschneiden, keine Farbkorrektur. Der Editor ist ein Durchgangsschritt
  zwischen Aufnahme und Ergebnis, kein Arbeitsplatz.
- **App-Store-Vertrieb — Ausschluss aufgehoben am 2026-09-03.** Die Begründung von
  2026-08-25 lautete, die Anwendung brauche den Verzicht auf die Sandbox für
  ScreenCaptureKit über fremde Fenster und für Carbon-Tastenkombinationen. **Sie war in
  beiden Punkten falsch:** ScreenCaptureKit arbeitet im Sandbox mit
  `com.apple.security.screen-capture` — dem Entitlement, das
  `Resources/MikaScreenSnap.entitlements:7` seit jeher auf `true` setzt — und
  `RegisterEventHotKey` ist die einzige im Sandbox funktionierende Hotkey-API und
  verlangt dort gar kein Entitlement. Der Eintrag bleibt hier stehen, damit die
  Fehlannahme auffindbar bleibt. Umfang und Kriterien: `features/16-app-store-auslieferung/spec.md`.

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
| Projektform | Swift Package als Quelle · **seit 2026-09-04 zusätzlich ein erzeugtes Xcode-Projekt allein für die App-Store-Auslieferung** (`project.yml`, XcodeGen). Der Direktvertrieb wird weiterhin ausschließlich über `scripts/build.sh` gebaut |
| Backend | **keins** |
| Umgebungen | nur lokal — es gibt keine Test- oder Produktivumgebung, nur gebaute Bundles |
| Datenhaltung | `UserDefaults` für Einstellungen · `~/Pictures/MikaScreenSnap/` für Aufnahmen · `~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/` für angeheftete Bilder |
| Sandbox | **je Ausgabe verschieden** (seit 2026-09-03): DMG-Build ohne Sandbox wie bisher, Store-Build mit Sandbox und ohne Ausnahme-Entitlements. Beide aus derselben Quelle |
| Berechtigungen | Bildschirmaufnahme (Screen Recording) — ohne sie ist die App funktionslos |
| Externe Dienste | **Sparkle-Appcast** auf `raw.githubusercontent.com` — überträgt beim Update-Check das, was Sparkle standardmäßig sendet; empfängt Feed und DMG. Sonst kein Netzwerkverkehr |
| Vertrieb | **zwei Wege:** notarisiertes DMG als GitHub-Release mit Update über Sparkle-Appcast auf `main` (unverändert, OF-03 gilt unbefristet) · Mac App Store, arm64-only, ohne Sparkle, Kategorie *Utilities*, Team `CWJM4J4HFN`. **Nächste gemeinsame Fassung: 3.6.0** (beide Ausgaben tragen dieselbe Nummer, AK-37). 3.5.0 wird davor noch als DMG allein ausgeliefert |
| Sprachen | Oberfläche englisch · OCR erkennt Deutsch, Englisch, Französisch |
| Monetarisierung | keine — MIT-Lizenz, kostenlos, auch im App Store. Einzige laufende Kosten: Apple Developer Program, 99 $/Jahr |

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
- **Was der Nutzer unkenntlich macht, bleibt unkenntlich.** Ein verpixelter Bereich darf im
  Export nicht rekonstruierbar sein — und kein Nebenpfad darf das unbearbeitete Original
  ablegen. Seit 3.5.0 wird die automatisch gesicherte Datei bei jedem Export ersetzt und
  bei jeder Zensur auch dann, wenn nicht exportiert wurde.
- **Der Store-Vertrieb bringt einen Empfänger, den es vorher nicht gab: Apple.** Die
  Anwendung selbst erhebt weiterhin nichts. Bei Installation über den App Store erhält
  Apple jedoch eigene Absturz- und Nutzungsdaten, sofern der Nutzer das in den
  Systemeinstellungen erlaubt hat — sichtbar für den Autor in App Store Connect. Das ist
  keine Erhebung der Anwendung, aber wie bei der Zwischenablage eine Folge ihres
  Vertriebswegs. `web/app/privacy/page.tsx:10` sagt heute „collects nothing" und muss
  vor der Einreichung präzisiert werden (Feature `16`, AK-46). Im Store-Eintrag wird
  „keine Daten erfasst" deklariert, weil sich das auf die Anwendung bezieht (AK-47).
- **Die Ausschlussliste ist eine Zusage, keine Bequemlichkeit.** Eine dort eingetragene
  App darf in keiner Aufnahme auftauchen — auch nicht in der Farbpipette, auch nicht im OCR.
- **Lokale Ablagen sind unverschlüsselt und haben ein Gegenstück.** Aufnahmen liegen im
  Klartext in `~/Pictures/MikaScreenSnap/`, angeheftete Bilder in `Application Support`.
  Beide sind in den Einstellungen sichtbar und leerbar, und jeder Schreibpfad hat einen
  Löschpfad — ein angehefteter Screenshot verschwindet mit seinem Fenster.

Der Katalog aus `~/.claude/sdd/sicherheit.md` gilt nach Stufe A verkürzt auf die
Abschnitte 4 (Missbrauch und Kosten) und 6 (Geheimnisse) — **erweitert um Abschnitt 1**,
weil die Frage „landen Daten in Logs" hier trotz Stufe A scharf gestellt werden muss.

## Feature-Roadmap

Die fünfzehn `B`-Einträge sind kein Plan, sondern ein **Inventar**: Sie existieren im
ausgelieferten Code. Die Prioritäten beschreiben, was die App ohne den jeweiligen Eintrag
noch wäre. Ab `16` ist es wieder eine Roadmap — reguläre Features, die vor dem Bauen
spezifiziert werden.

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
| 16 | App-Store-Auslieferung | P1 | zweite Ausgabe mit Sandbox, ohne Sparkle, mit Ordnerwahl und Umzug — bis zur Einreichung | B01, B02, B08, B09, B11, B12, B14 |

**Erfassungsreihenfolge:** B01 → B02 → B04 → B09 → B05 → B06 → B08 → B14 → B12 → B03 → B10 → B11 → B13 → B07 → B15

Begründung steht unter der Tabelle in `features/index.md` — sie folgt dem Risiko, nicht
der Nummer.

## Offene Punkte

Die sechs Punkte der Erfassung sind am 2026-08-25 entschieden (OF-01 und OF-02 am
2026-09-03 fortgeschrieben). **Die drei Punkte aus Feature `16` sind am 2026-09-03
ebenfalls entschieden** — offen ist davon nur noch eine Beschaffung, keine Frage:

| # | Frage | Stand |
|---|---|---|
| OF-07 | Welches Konto trägt den Store-Eintrag? | **Entschieden am 2026-09-03: Team `CWJM4J4HFN`** — dasselbe, das den Direktvertrieb signiert. **Offen bleibt die Beschaffung:** App-ID unter dieser Team-ID registrieren, `Apple Distribution` und `3rd Party Mac Developer Installer` erzeugen. Im Schlüsselbund liegt heute nur `Developer ID Application` |
| OF-08 | Welche Store-Kategorie und Alterseinstufung? | **Entschieden am 2026-09-03: *Utilities*, 4+.** Dort suchen Nutzer Screenshot-Werkzeuge; 4+, weil die Anwendung keine fremden Inhalte anzeigt |
| OF-09 | Die MIT-Lizenz erlaubt jedem, dasselbe Binary unter eigenem Namen einzureichen — bleibt es dabei? | **Entschieden am 2026-09-03: MIT bleibt.** Kein Umsatz zu schützen; Apple prüft bei der Einreichung Rechte an Name und Symbol, nicht die Codelizenz |
| OF-10 | Was geschieht mit dem zweiten Update-Repository `Mukaarts/MikaScreenSnap`? | **Entschieden am 2026-09-03: auslaufen lassen.** Beide `appcast.xml` sind heute byte-identisch. **Die Entscheidung hat eine Vorbedingung, ohne die sie das Gegenteil bewirkt:** Sparkle bevorzugt `SUFeedURL` aus `UserDefaults` gegenüber `Info.plist`, und die Anwendung löscht diesen Schlüssel nirgends. Wer nur aufhört, nach `Mukaarts` zu pushen, schneidet diese Installationen ab, statt sie umzuleiten. Nötig ist **zuerst** ein Update über `Mukaarts`, das den Schlüssel entfernt — erst danach greift `Info.plist` mit `daumedia`. Gehört zu B14, nicht zu Feature 16 |

Die entschiedenen Punkte der Erfassung:

| # | Frage | Entscheidung |
|---|---|---|
| OF-01 | Sind Bildschirmvideo, weitergehende Bildbearbeitung und App-Store-Vertrieb bewusste Nicht-Ziele? | **Video und Bildbearbeitung ja** — sie würden aus einem Aufnahmewerkzeug ein zweites Produkt machen. **App Store nein, korrigiert am 2026-09-03:** Die Antwort von 2026-08-25 beruhte auf einer falschen technischen Annahme (Begründung unter *Nicht im Scope*). Der Store ist seither Feature `16` |
| OF-02 | Ist Intel-Unterstützung aufgegeben? | **Nicht beabsichtigt gewesen.** Das Programmpaket ist arm64-only, die Website sagt das ehrlich. Ein Universal-Build wäre möglich, hat aber keinen bekannten Adressaten. **Am 2026-09-03 erneut gestellt und bestätigt:** Der Store schafft zwar erstmals sichtbare Intel-Nutzer, aber keine der 269 Bestandsprüfungen wäre auf Intel nachweisbar — es gibt kein Testgerät. Der Store blendet die App dort aus |
| OF-03 | Bis wann muss `main:master` mitgepusht werden? | **Unbefristet.** Die Feed-Adresse älterer Installationen ist einkompiliert; ein Ende wäre nur über eine Zählung begründbar, und die soll es nicht geben. Der Schritt steht in `README.md`. **Präzisiert am 2026-09-03:** Das gilt für `main:master` innerhalb von `daumedia`. Für das zweite Repository `Mukaarts/MikaScreenSnap` gilt es **nicht** — siehe OF-10 |
| OF-04 | Soll `swift test` etabliert werden? | **Ja, geschehen.** 28 Tests decken ab, was rechnet: Mehrschirm-Koordinaten, Tastenkombinationen, Farbumrechnung, Zensurstärke, Namenskollisionen. UI-Verhalten bleibt manuell nachzuweisen, wie im Stack-Profil vorgesehen |
| OF-05 | Zwischenablage als vertraulich kennzeichnen? | **Für Text ja** (erledigt in 3.5.0), für Bilder nicht möglich — macOS kennt dafür keine Kennzeichnung. Als Einschränkung oben unter *Datenschutz* ausgewiesen |
| OF-06 | Berechtigung anfordern statt nur abfragen? | **Ja, erledigt in 3.5.0.** Die Ersteinrichtung ruft `CGRequestScreenCaptureAccess`, und die Aufnahmeeinträge sind ohne Berechtigung gesperrt |
