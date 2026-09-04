# Datenmodell — Mika+ScreenSnap

Stand: 2026-08-25 · rückwirkend erfasst · **auf Stand 3.5.0 nachgeführt**

**Es gibt keine Datenbank.** Die App hält vier Arten von Zustand: Einstellungen in
`UserDefaults`, Bilddateien im Dateisystem, flüchtigen Zustand im Speicher und ein paar
Listen in `UserDefaults`, die eigentlich Daten sind. Dieses Dokument nimmt alle vier auf
— so, wie sie sind.

---

## 1 · `UserDefaults` — Einstellungen

Alle Schlüssel liegen in der Standard-Suite unter `lu.daumedia.screensnap`.
Geschrieben ausschließlich über `AppPreferences` (`Sources/AppPreferences.swift`),
jeweils per `didSet`.

| Schlüssel | Typ | Standard | Bedeutung |
|---|---|---|---|
| `autoSaveEnabled` | Bool | `true` | jede Aufnahme automatisch sichern |
| `saveLocation` | String (Pfad) | `~/Pictures/MikaScreenSnap` | Zielordner der Aufnahmen |
| `imageFormat` | String | `PNG` | `PNG` oder `JPEG` |
| `jpegQuality` | CGFloat | `0.85` | nur bei JPEG wirksam |
| `hasCompletedOnboarding` | Bool | `false` | steuert den Erststart-Flow |
| `captureSoundEnabled` | Bool | `true` | Auslöseton **— wird konsumiert** |
| `defaultAnnotationTool` | String | `arrow` | Startwerkzeug im Editor **— wird konsumiert** |
| `defaultStrokeColorData` | Data | `nil` | archivierte `NSColor` |
| `defaultStrokeWidth` | CGFloat | `4.0` | Strichstärke — einer der drei angebotenen Werte |
| `rememberLastTool` | Bool | `true` | überschreibt beim Schließen `defaultAnnotationTool` **— wird konsumiert** |
| `showToolbarLabels` | Bool | `false` | Werkzeugsymbole tragen ihre Bezeichnung |
| `excludedBundleIdentifiers` | [String] | `[]` | Bundle-IDs, die in keiner Aufnahme erscheinen |
| `hotkeyBindings` | Data (JSON) | `nil` | `[String: HotkeyBinding]`, siehe unten |
| `colorHistory` | [String] | `[]` | HEX-Werte, **max. 10** |
| `colorPalette` | [String] | `[]` | HEX-Werte, **max. 20** |

`resetAllPreferences()` entfernt alle Schlüssel aus `AppPreferences.ownedDefaultsKeys` —
einer Liste, die neben den Eigenschaften steht, die sie schreiben, und `colorHistory` sowie
`colorPalette` einschließt. Ein Test hält das fest
(`Tests/CaptureFilenameTests.swift`). Sparkles eigene Schlüssel bleiben bewusst unberührt
(`features/befunde.md`, BF-A13).

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
| Aufnahme | `<saveLocation>/` | `MikaSnap_JJJJ-MM-TT_HH-mm-ss-SSS` + `.png`/`.jpg`, bei Gleichstand mit Zählnummer | Verlauf-Browser (einzeln), *Clear History* (alle Dateien im Ordner) |
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
| PNG des angehefteten Bildes | `pin_JJJJ-MM-TT_HH-mm-ss-SSS.png` | Schließen des Fensters · *Close All* · *Clear* im Reiter *Advanced* · überzählige beim Start |

Gespeichert wird **ausschließlich das Bild**. Position, Größe und Deckkraft des Panels
werden nicht abgelegt; beim Neustart erscheinen wiederhergestellte Pins in Standardgröße an
Standardposition (bewusst, `features/befunde.md`, BF-A8). Wiederhergestellt werden die
**zwanzig neuesten**; ältere Dateien werden beim Start entfernt.

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
| Farbverlauf und Palette | ja | Untermenüs *Color History* und *Colour Palette*, dazu *Reset All Preferences* |
| Angeheftete Bilder | ja | Fenster schließen, *Close All*, oder *Clear* im Reiter *Advanced* |
| Hotkey-Belegungen | ja | *Restore Defaults* im Shortcuts-Tab |

---

## Fehlbestand

**Keiner offen.** Die acht Einträge dieses Dokuments sind in 3.5.0 behoben oder mit
Begründung akzeptiert; die vollständige Liste steht in `features/befunde.md`.

| Ursprünglich | Ausgang |
|---|---|
| FB-DM-01 · Angeheftete Bilder wurden nie gelöscht | behoben — jedes Panel kennt seine Datei, Schließen löscht sie, Wiederherstellung nimmt die neuesten |
| FB-DM-02 · Vier Schlüssel ohne Wirkung | behoben — `showToolbarLabels` wirkt, die drei anderen sind entfernt |
| FB-DM-03 · `resetAll()` erfasste Farbverlauf und Palette nicht | behoben — `ownedDefaultsKeys` steht neben den Eigenschaften und ist getestet |
| FB-DM-04 · `HistoryItem.id` neu bei jedem Start, `date` ist das Änderungsdatum | akzeptiert — Folge daraus, dass das Verzeichnis die Wahrheit ist; die Kennung dient nur der Darstellung |
| FB-DM-05 · `AnnotationSnapshot.data` untypisiert | akzeptiert — rein interner Pfad, neun typisierte Momentaufnahmen wären Aufwand ohne Ertrag |
| FB-DM-06 · Keine Schemaversion | akzeptiert — kein Formatwechsel steht an, und der häufigste Fehlerfall (die Rücksetzliste) ist jetzt zentralisiert und geprüft |
| FB-DM-07 · Sparkles Schlüssel nicht erfasst | akzeptiert — sie gehören dem Rahmenwerk |
| FB-DM-08 · Standard-Strichstärke nicht wählbar | behoben — Standard ist 4 |
