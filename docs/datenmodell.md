# Datenmodell — Mika+ScreenSnap

Stand: 2026-08-25 · rückwirkend erfasst aus Version 3.4.1

**Es gibt keine Datenbank.** Die App hält vier Arten von Zustand: Einstellungen in
`UserDefaults`, Bilddateien im Dateisystem, flüchtigen Zustand im Speicher und ein paar
Listen in `UserDefaults`, die eigentlich Daten sind. Dieses Dokument nimmt alle vier auf
— so, wie sie sind.

---

## 1 · `UserDefaults` — Einstellungen

Alle Schlüssel liegen in der Standard-Suite unter `com.mika.mikaplusscreensnap`.
Geschrieben ausschließlich über `AppPreferences` (`Sources/AppPreferences.swift`),
jeweils per `didSet`.

| Schlüssel | Typ | Standard | Bedeutung |
|---|---|---|---|
| `autoSaveEnabled` | Bool | `true` | jede Aufnahme automatisch sichern |
| `saveLocation` | String (Pfad) | `~/Pictures/MikaScreenSnap` | Zielordner der Aufnahmen |
| `imageFormat` | String | `PNG` | `PNG` oder `JPEG` |
| `jpegQuality` | CGFloat | `0.85` | nur bei JPEG wirksam |
| `hasCompletedOnboarding` | Bool | `false` | steuert den Erststart-Flow |
| `permissionSkipped` | Bool | `false` | Berechtigung im Onboarding übersprungen |
| `captureSoundEnabled` | Bool | `true` | Auslöseton **— wird konsumiert** |
| `floatingPreviewEnabled` | Bool | `false` | **wirkungslos**, siehe Fehlbestand |
| `previewDismissDuration` | Int | `5` | **wirkungslos**, siehe Fehlbestand |
| `defaultAnnotationTool` | String | `arrow` | Startwerkzeug im Editor **— wird konsumiert** |
| `defaultStrokeColorData` | Data | `nil` | archivierte `NSColor` |
| `defaultStrokeWidth` | CGFloat | `3.0` | Strichstärke |
| `rememberLastTool` | Bool | `true` | überschreibt beim Schließen `defaultAnnotationTool` **— wird konsumiert** |
| `showToolbarLabels` | Bool | `false` | **wirkungslos**, siehe Fehlbestand |
| `excludedBundleIdentifiers` | [String] | `[]` | Bundle-IDs, die in keiner Aufnahme erscheinen |
| `hotkeyBindings` | Data (JSON) | `nil` | `[String: HotkeyBinding]`, siehe unten |
| `colorHistory` | [String] | `[]` | HEX-Werte, **max. 10** |
| `colorPalette` | [String] | `[]` | HEX-Werte, **max. 20** |

`resetAll()` (`AppPreferences.swift:135`) entfernt eine **fest verdrahtete Liste** von
Schlüsseln. `colorHistory` und `colorPalette` stehen nicht darin — siehe Fehlbestand.

### `HotkeyBinding`

```
struct HotkeyBinding: Codable, Equatable, Sendable {
    let keyCode:   UInt32     // Carbon-Keycode, z. B. 0x14 = "3"
    let modifiers: UInt32     // Carbon-Maske: cmdKey | shiftKey | controlKey | optionKey
}
```

Persistiert als JSON-Wörterbuch unter `hotkeyBindings`, Schlüssel ist der `rawValue` von
`HotkeyAction`. Sieben Aktionen: `fullScreen`, `area`, `window`, `captureText`,
`colorPicker`, `measure`, `history`.

---

## 2 · Dateisystem

### Aufnahmen — `~/Pictures/MikaScreenSnap/` (konfigurierbar)

| Was | Wo | Benennung | Gelöscht durch |
|---|---|---|---|
| Aufnahme | `<saveLocation>/` | Zeitstempel + `.png`/`.jpg` | Verlauf-Browser (einzeln), *Clear History* (alle) |
| Vorschaubild | `<saveLocation>/.thumbnails/` | gleicher Dateiname wie das Original | dieselben Pfade |

`HistoryItem` wird beim Start **aus dem Verzeichnis rekonstruiert**, nicht aus einem
Index gelesen:

```
struct HistoryItem: Identifiable, Sendable {
    let id: UUID          // bei jedem Start neu vergeben — nicht stabil
    let url: URL
    let thumbnailURL: URL
    let date: Date        // Änderungsdatum der Datei, nicht Aufnahmezeit
    let pixelWidth: Int
    let pixelHeight: Int
}
```

Das Verzeichnis **ist** das Datenmodell. Eine Datei, die dort von Hand hineingelegt wird,
erscheint im Verlauf; eine gelöschte verschwindet. Das ist robust und hat den Preis, dass
`id` und `date` nicht das sind, wonach sie aussehen.

### Angeheftete Bilder — `~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/`

| Was | Benennung | Gelöscht durch |
|---|---|---|
| PNG des angehefteten Bildes | `pin_JJJJ-MM-TT_HH-mm-ss-SSS.png` | **nichts** — siehe Fehlbestand |

Gespeichert wird **ausschließlich das Bild**. Position, Größe und Deckkraft des Panels
werden nicht abgelegt; beim Neustart erscheinen wiederhergestellte Pins in Standardgröße
an Standardposition.

---

## 3 · Flüchtiger Zustand — nur im Speicher

`AnnotationStore` (`Sources/AnnotationModels.swift:1025`) hält den gesamten Editorzustand
und wird **nie persistiert**:

```
final class AnnotationStore {
    var annotations:          [any Annotation]
    var selectedAnnotationID: UUID?
    var currentColor:         NSColor
    var currentStrokeWidth:   CGFloat
    var selectedTool:         DrawingToolType
    var zoomLevel:            CGFloat
    var panOffset:            CGPoint
    var hasUnsavedChanges:    Bool
    let undoManager:          UndoManager
}
```

**Es gibt kein Projektformat.** Ein geschlossener Editor verliert alle Annotationen; ein
exportiertes PNG ist flach und nicht mehr bearbeitbar. Das ist eine bewusst wirkende
Entscheidung — sie steht nirgends geschrieben, weshalb sie als offener Punkt in der Spec
von B03 landet und nicht hier als Tatsache.

### `Annotation` — das Protokoll

Neun Typen (`arrow`, `rectangle`, `ellipse`, `line`, `freehand`, `text`, `highlight`,
`blur`, `pixelate`) implementieren dasselbe Protokoll. Sie zeichnen sich selbst, sind
nach `zIndex` sortiert und liefern für Undo einen `AnnotationSnapshot`:

```
protocol Annotation: AnyObject, Identifiable {
    var id: UUID { get }
    var annotationType: AnnotationType { get }
    var bounds: CGRect { get }
    var color: NSColor { get set }
    var strokeWidth: CGFloat { get set }
    var isSelected: Bool { get set }
    var zIndex: Int { get set }

    func contains(_ point: CGPoint) -> Bool
    func draw(in ctx: CGContext, baseImage: CGImage?)
    func moved(by delta: CGSize)
    func resized(from oldBounds: CGRect, to newBounds: CGRect)
    func snapshot() -> AnnotationSnapshot
    func restore(from snapshot: AnnotationSnapshot)
}
```

`AnnotationSnapshot.data` ist ein `[String: any Sendable]` — untypisiert. Jede
Annotation kennt ihre eigenen Schlüssel; ein Tippfehler fällt erst zur Laufzeit auf.

`baseImage` in `draw(in:baseImage:)` existiert für `BlurAnnotation` und
`PixelateAnnotation`: Beide lesen den Bereich aus dem **Originalbild** und rendern ihn
verfremdet darüber. Das heißt auch, dass ihre Wirkung erst beim Rendern entsteht — im
Modell steht nur ein Rechteck.

`DrawingToolType` kennt zusätzlich `select` und `measure`; beide erzeugen keine
Annotation. Messungen werden **nicht exportiert**.

### `ExcludedAppsManager.CapturableApp`

```
struct CapturableApp: Identifiable, Hashable {
    let bundleIdentifier: String   // zugleich die id
    let name: String
}
```

Wird bei jedem Öffnen der Einstellungen aus `SCShareableContent.current` neu aufgebaut.
Bereits ausgewählte, aber nicht laufende Apps werden eingemischt, damit eine bestehende
Auswahl nicht unbemerkt aus der Liste fällt — der Name kommt dann über
`NSWorkspace.urlForApplication(withBundleIdentifier:)`.

---

## 4 · Löschregeln — Bestandsaufnahme

| Daten | Nutzer kann löschen? | Wie |
|---|---|---|
| Aufnahmen + Vorschaubilder | ja | Verlauf-Browser einzeln, *Advanced → Clear History* für alle |
| Einstellungen | ja | *Advanced → Reset All Preferences* |
| Farbverlauf und Palette | **nein** | von `resetAll()` nicht erfasst |
| Angeheftete Bilder | **nein** | kein Löschpfad im Code |
| Hotkey-Belegungen | ja | *Restore Defaults* im Shortcuts-Tab |

---

## Fehlbestand

Was hier steht, sind **Befunde, keine Kriterien.** Sie werden in der Spec des jeweiligen
Features aufgenommen und von `sdd-qa` bewertet — nicht hier repariert.

**FB-DM-01 · Angeheftete Bilder werden nie gelöscht.** `PinnedScreenshotManager`
schreibt bei jedem Anheften ein PNG nach
`~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/`. Es existiert kein
einziger `removeItem`-Aufruf: `unpinPanel` und `unpinAll` rufen nur `orderOut(nil)`, und
`closePanel` im Panel selbst ebenso. Folgen:

1. Bildschirminhalte sammeln sich dort **unbegrenzt** an, auch von längst geschlossenen Pins.
2. `maxPins = 20` begrenzt nur gleichzeitig offene Panels und die Wiederherstellung
   (`prefix(maxPins)`), nicht die Dateimenge.
3. `restorePins` sortiert alphabetisch — bei Zeitstempel-Dateinamen also **aufsteigend nach
   Alter** — und stellt die ersten 20 wieder her. Ein bewusst geschlossener Pin kann beim
   nächsten Start zurückkehren, während ein neuerer nicht erscheint.
4. Weder `storageUsage()` noch `clearAll()` kennen diesen Ordner: Die Speicheranzeige im
   Advanced-Tab arbeitet ausschließlich über `historyManager`, also über `saveLocation`.
   Der Nutzer sieht diese Daten nicht und kann sie in der App nicht entfernen.

Gemessen an der Datenschutzregel des PRD („was der Nutzer unkenntlich macht, bleibt
unkenntlich" und „lokale Ablagen sind eine bewusste Entscheidung") ist das der schwerste
Einzelbefund der Kartierung. Gehört in die Spec von **B08**.

**FB-DM-02 · Drei Einstellungen ohne Wirkung.** `floatingPreviewEnabled`,
`previewDismissDuration` und `showToolbarLabels` werden gespeichert, geladen,
zurückgesetzt und in der Oberfläche angeboten — aber von keinem Feature gelesen. Die
Gegenprobe mit `captureSoundEnabled`, `rememberLastTool` und `defaultAnnotationTool`
zeigt, dass die übrigen Schalter sehr wohl greifen. Der Nutzer stellt etwas ein, das
nichts tut. Gehört in die Spec von **B11**.

**FB-DM-03 · `resetAll()` erfasst Farbverlauf und Palette nicht.** Die Schlüsselliste in
`AppPreferences.swift:135` ist von Hand gepflegt; `colorHistory` und `colorPalette`
werden von `ColorHistoryManager` unter eigenen Schlüsseln geschrieben und überleben ein
*Reset All Preferences*. Gehört in die Spec von **B06**.

**FB-DM-04 · `HistoryItem.id` ist bei jedem Start neu.** Die UUID wird beim Einlesen des
Verzeichnisses vergeben. Solange sie nur zur Darstellung in einer Liste dient, ist das
folgenlos — sie darf aber nie zur Referenzierung über einen Start hinweg benutzt werden.
`date` ist das Änderungsdatum der Datei, nicht der Aufnahmezeitpunkt: Ein Kopiervorgang
verschiebt es. Gehört in die Spec von **B09**.

**FB-DM-05 · `AnnotationSnapshot.data` ist untypisiert.** `[String: any Sendable]` mit
Schlüsseln, die jede Annotation für sich definiert. Ein falscher Schlüssel oder ein
Typwechsel scheitert stumm zur Laufzeit statt beim Übersetzen — bei einem Undo-Pfad, der
selten läuft, fällt das lange nicht auf. Gehört in die Spec von **B03**.

**FB-DM-06 · Kein Migrationspfad für die Einstellungen.** Es gibt keine Schemaversion in
`UserDefaults`. Das Stack-Profil `swiftui-macos` benennt das ausdrücklich als Risiko:
Ändert sich das Format eines Schlüssels — etwa `hotkeyBindings` —, verliert der Nutzer
beim Update seine Konfiguration, ohne dass es auffällt. Gehört ins **Design des
nächsten Features**, das ein Format ändert; bis dahin projektweiter Befund.
