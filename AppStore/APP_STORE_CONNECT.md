# App Store Connect — Feld für Feld

Version 3.6.0 · Bundle-ID `lu.daumedia.screensnap` · Stand 2026-09-04

Die Texte stehen in `metadata/en-US/` und sind zum Kopieren gedacht. Hier steht alles,
was **nicht** in einer Textdatei liegt: Grunddaten, Kategorien und die Antworten der
Fragebögen.

Aufgebaut wie die Pakete von Mika+Grid und Mika+FileScope, damit die drei Projekte gleich
funktionieren. Wo etwas abweicht, steht der Grund dabei.

## Grunddaten

| Feld | Wert |
|---|---|
| Name | Mika+ScreenSnap |
| Bundle-ID | `lu.daumedia.screensnap` |
| SKU | `screensnap-mac` |
| Primäre Kategorie | Dienstprogramme / Utilities |
| Sekundäre Kategorie | *(leer lassen)* |
| Preis | Kostenlos |
| Altersfreigabe | 4+ (siehe [ALTERSFREIGABEN.md](ALTERSFREIGABEN.md)) |
| Copyright | © 2026 Michael Ferreira · daumedia.lu · MIT-Lizenz |
| Plattform | macOS 14 Sonoma oder neuer |

**Die Kategorie muss zu `LSApplicationCategoryType` in `Resources/Info.plist` passen** —
dort steht `public.app-category.utilities`. Weichen beide voneinander ab, weist der
Upload mit Fehler 90242 ab. `swift test --filter StoreAssetTests` prüft, dass Bundle und
diese Datei denselben Wert nennen; ob er zur Auswahl in App Store Connect passt, kann nur
ein Mensch beurteilen.

*Dienstprogramme* und nicht *Fotografie*: Die Anwendung erzeugt keine Fotos und verwaltet
keine Mediathek, sie nimmt den Bildschirm auf und bearbeitet das Ergebnis. Entschieden am
2026-09-03 als OF-02 in `features/16-app-store-auslieferung/spec.md`.

## Zwei Fassungen, eine Kennung

Mika+ScreenSnap erscheint in zwei Fassungen aus derselben Quelle: dem notarisierten
DMG mit eingebautem Updater und der sandboxed Store-Fassung ohne. Beide tragen **dieselbe**
Bundle-Kennung `lu.daumedia.screensnap`, damit eine Installation die andere ersetzt statt
neben ihr zu laufen. In App Store Connect gibt es deshalb nur diesen einen Datensatz.

Für den Store zählt allein: Das hochgeladene Paket enthält **kein** Sparkle und keinen
Update-Feed. `scripts/build-appstore.sh` bricht ab, wenn es doch eines von beiden findet —
das ist eine von zehn Selbstprüfungen, die dort bei jedem Bau laufen.

## App Privacy — das „Nutrition Label"

Die Antwort ist durchgehend dieselbe:

> **Data Not Collected** — für jede einzelne Kategorie.

Begründung, falls die Prüfung nachfragt: Die Anwendung führt keine Konten, sendet nichts
und speichert nur technische Einstellungen (Tastenkürzel, Zeichenvorgaben, Ausschlussliste,
Speicherort, Start bei der Anmeldung) in den lokalen `UserDefaults`. Die Bildschirmfotos
selbst liegen als Dateien in dem Ordner, den der Nutzer gewählt hat. Nichts davon verlässt
das Gerät.

Die Store-Fassung macht **überhaupt keinen** Netzverkehr — sie enthält nicht einmal einen
Update-Kanal, der einen aufbauen könnte. Belegbar über den öffentlichen Quelltext:

```bash
grep -rn "URLSession\|WKWebView\|NSURLConnection" Sources/   # leer
```

Auch die Texterkennung läuft örtlich: `Vision` erkennt auf dem Gerät, es gibt keinen
Dienst dahinter.

`swift test --filter StoreAssetTests` prüft genau das bei jedem Lauf mit.

**Was Apple selbst erhebt, steht auf der Datenschutzseite.** Wer über den Store
installiert, schickt Absturz- und Nutzungsdaten an Apple, sofern er das unter
*Systemeinstellungen › Datenschutz & Sicherheit › Analyse & Verbesserungen* erlaubt hat.
Das ist Apples Erhebung, nicht die der Anwendung; `web/app/privacy/` sagt es ausdrücklich
(AK-46).

## Altersfreigaben

Der Fragebogen hat 24 Kategorien; jede einzelne wird mit „Nein" bzw. „Nie" beantwortet.
Das Ergebnis ist **4+**. Die Antworten stehen samt Beleg in
[ALTERSFREIGABEN.md](ALTERSFREIGABEN.md).

## Prüfungshinweise für Apple (App Review Information)

**Dieser Block ist hier keine Höflichkeit, sondern der wichtigste Text des Eintrags.**
Ein Prüfer startet die Anwendung und sieht nichts: kein Dock-Symbol, kein Fenster, kein
Menü. Wer nicht weiß, dass sie in der Menüleiste sitzt, hält sie für kaputt und lehnt
nach Guideline 2.1 ab. Dazu kommt, dass die Bildschirmaufnahme sich nicht vorab erteilen
lässt — ohne sie liefert jede Aufnahme ein leeres Bild.

```
The app requires no sign-in of any kind.

Mika+ScreenSnap has no Dock icon and no window of its own: it is a menu bar app. After
launching, look for its icon in the menu bar at the top right of the screen. Clicking it
opens the menu with every capture mode.

First launch opens a short setup window with two steps that cannot be skipped:

1. Screen Recording permission. Taking a screenshot means reading the contents of the
   screen, which macOS gates behind System Settings > Privacy & Security > Screen &
   System Audio Recording. This consent cannot be granted in advance, and macOS requires
   the app to be relaunched after it is given. Until then every capture returns an empty
   image. The setup screen links straight to the correct settings pane.

2. A folder for the screenshots. The app is sandboxed, so it has no path to the Pictures
   folder it could take on its own; the setup step opens a standard open panel and the
   choice is remembered through a security-scoped bookmark. It can be changed later in
   Settings.

To review, after those two steps: press Control-Shift-Command-4 and drag a rectangle over
anything on screen. The annotation editor opens on the capture. Press A for the arrow
tool, B for blur, then Command-C to copy and close. Shift-Command-6 extracts text from a
dragged region, Shift-Command-7 opens the colour loupe.

The app makes no network connections at all and contains no updater — updates come from
the App Store. Everything it captures stays in the folder chosen during setup.
```

## Berechtigungen

Die Store-Fassung läuft in der Sandbox (`Resources/MikaScreenSnap-AppStore.entitlements`):

| Entitlement | Wofür |
|---|---|
| `com.apple.security.app-sandbox` | Pflicht im Store |
| `com.apple.security.files.user-selected.read-write` | der Ordner, den der Nutzer in der Ersteinrichtung wählt |
| `com.apple.security.files.bookmarks.app-scope` | lässt diese Erlaubnis einen Neustart überleben — Ordner einmal wählen, nicht täglich |

Kein `com.apple.security.network.client` — die Anwendung stellt keine Verbindungen her.
Die Beschreibung sagt „makes no network connection at all"; ein Netz-Entitlement würde
diese Zusage im selben Bundle widerlegen. Ein Test hält das fest.

**Kein `com.apple.security.screen-capture`.** Die Direktfassung trägt diesen
undokumentierten Schlüssel; er hat dort nie etwas bewirkt. Die Bildschirmaufnahme ist eine
TCC-Entscheidung des Nutzers, kein Entitlement. Unbekannte `com.apple.security.*`-Schlüssel
sind bei der Annahme ein unnötiges Risiko und fehlen hier bewusst.

**`read-write`, nicht `read-only`.** Bei Mika+FileScope war genau das der reale
Ablehnungsgrund am 2026-09-01 (Guideline 2.1(a)): Mit `read-only` öffnet die Powerbox den
Dialog gar nicht — ohne Fehlermeldung, die Funktion wirkt einfach tot. Ein Test hält auch
das fest.

## Was die Store-Fassung nicht kann

Gehört in die Beschreibung, nicht ins Kleingedruckte — und steht dort auch:

| Einschränkung | Grund |
|---|---|
| Kein eingebauter Updater | Der Store aktualisiert. Sparkle ist in dieser Fassung nicht enthalten (AK-04) |
| Der Speicherordner muss einmal gewählt werden | Die Sandbox kennt keinen Weg nach `~/Pictures`, den die Anwendung selbst nehmen dürfte |
| Nichts wird aus der Direktfassung übernommen | Eine sandboxed Anwendung kann die alten Einstellungen nicht lesen — nicht einmal nachsehen, ob es welche gibt. Sie fragt deshalb nicht und startet mit Vorgaben |

Der Ehrlichkeitsabschnitt „BEFORE YOU DOWNLOAD" in `metadata/en-US/description.txt` sagt
alle drei Punkte vor dem Download. Er steht bewusst in der **Beschreibung**, nicht im
Werbetext: Der Werbetext ist ohne Review änderbar und taugt nicht als Träger einer
Pflichtangabe.

## Screenshots

Die Bilder aus `screenshots/en-US/mac-2880x1800/` in der Nummernreihenfolge hochladen.
**Stand 2026-09-04 sind es zwei** — Apple verlangt mindestens eines, drei bis fünf wären
besser. Welche Motive fehlen und warum, steht in [README.md](README.md); als Aufgabe hängt
es in [CHECKLISTE.md](CHECKLISTE.md).
