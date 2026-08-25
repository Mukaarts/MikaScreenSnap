# Design-System — Mika+ScreenSnap

Stand: 2026-08-25 · rückwirkend aus dem Code gelesen · **auf Stand 3.5.0 nachgeführt**

**Was hier steht, ist eine Bestandsaufnahme, keine Vorgabe.** Wo der Bestand
uneinheitlich ist, steht das als Befund da und wird nicht begradigt — eine Aufräumaktion
ist ein eigenes Feature mit eigener Spec, keine Nebenwirkung der Erfassung.

---

## Farben

Die Markenpalette liegt vollständig in `Sources/MikaPlusColors.swift`, doppelt
ausgeführt als `NSColor.MikaPlus` und `Color.MikaPlus`. Definiert über einen
`init(hex:)`-Convenience-Initializer in sRGB.

| Token | Hex | Verwendung im Bestand |
|---|---|---|
| `tealPrimary` | `#1D9E75` | Akzent: aktives Werkzeug, Auswahlring, Fokus |
| `tealLight` | `#5DCAA5` | sekundärer Akzent |
| `tealLightest` | `#9FE1CB` | zugleich `textSecondary` |
| `tealSurface` | `#E1F5EE` | helle Fläche, zugleich `textPrimary` |
| `darkBg` | `#1A1A2E` | Flächen der dunklen Oberflächen |
| `darkBgDeep` | `#0F0F1A` | tiefere Ebene, Fensterhintergrund |
| `textPrimary` | `#E1F5EE` | **identisch mit** `tealSurface` |
| `textSecondary` | `#9FE1CB` | **identisch mit** `tealLightest` |
| `destructive` | `#E24B4A` | Löschen, Zurücksetzen (seit 3.4.0) |

Neun Namen für sieben Werte: `textPrimary`/`tealSurface` und
`textSecondary`/`tealLightest` sind je zwei Namen für denselben Hex-Wert. Das ist
gewollt lesbar (Rolle vs. Farbe), sollte aber bewusst bleiben — wer `tealSurface`
ändert, ändert stillschweigend die Textfarbe mit.

### Wo die Palette gilt — und wo nicht

| Bereich | Palette |
|---|---|
| Annotations-Toolbar und Bottom-Bar | `MikaPlus` |
| Onboarding (alle vier Bildschirme) | `MikaPlus` |
| „Über"-Fenster | `MikaPlus` |
| Angeheftetes Screenshot-Panel | `MikaPlus` |
| Fensterauswahl-Overlay | `MikaPlus` |
| **Einstellungen (alle vier Tabs)** | **keine** — durchgehend Systemfarben |
| **Verlauf-Browser** | **keine** — durchgehend Systemfarben |
| **Farbpresets im Editor** | **keine** — `.systemRed`, `.systemBlue`, `.systemGreen`, `.yellow`, `.white`, `.black` |

Die sechs Farbpresets sind bewusst Systemfarben: Sie sind das Zeichenmaterial des
Nutzers, nicht Oberfläche der App. Bei Einstellungen und Verlauf ist die Lage anders —
siehe Befund DS-01.

## Typografie

Keine Schriftskala, keine Tokens. Größen stehen als Zahlen an der Stelle, an der sie
gebraucht werden. Erhoben über Einstellungen, Onboarding und die beiden Editor-Leisten:

| Verwendung | Aufruf | Häufigkeit |
|---|---|---|
| Abschnittsüberschrift | `.font(.headline)` | 10× |
| Betonter Text | `.font(.system(size: 14, weight: .medium))` | 3× |
| Fließtext | `.font(.system(size: 13))` | 3× |
| Hilfstext | `.font(.caption)` | 3× |
| Symbolgröße groß | `.font(.system(size: 48))` | 2× |
| Titel | `.font(.system(size: 20, weight: .semibold))` | 2× |
| Titel, abweichend | `.font(.system(size: 22, weight: .semibold))` | 1× |
| Zahlen und HEX-Werte | `.font(.system(size: 12/13, design: .monospaced))` | 2× |
| Weitere | `.subheadline`, `size: 12`, `size: 14` | je 1× |

Semantische Stile (`.headline`, `.caption`) und feste Punktgrößen stehen nebeneinander.
Zwei Titelgrößen (20 und 22) erfüllen erkennbar dieselbe Rolle. Monospace wird konsequent
für Zahlen und Farbwerte eingesetzt — das ist die einzige durchgehaltene Regel.

## Abstände

| Wert | Häufigkeit | Rolle im Bestand |
|---|---|---|
| `spacing: 0` | 19× | Listen ohne Zwischenraum, Trennlinien tragen die Struktur |
| `spacing: 4` | 5× | eng: Farbkreise, Symbolreihen |
| `spacing: 20` | 5× | Abschnittsabstand |
| `spacing: 12` | 3× | mittel |
| `spacing: 8` | 2× | eng-mittel |
| `spacing: 24` | 2× | Abschnittsabstand, abweichend |
| `spacing: 1` | 1× | Trennlinie |
| `padding(20)` | 1× | Fensterrand |

Kein 4er- oder 8er-Raster: 20 und 24 erfüllen dieselbe Rolle, 8 und 12 ebenso.

## Radien

`cornerRadius: 8` (3×) · `cornerRadius: 6` (1×, Toolbar-Schaltflächen) ·
`cornerRadius: 5` (2×) · `cornerRadius: 1` (1×, Strichstärken-Vorschau).
Vier Werte, drei davon im selben Größenbereich.

## Wiederkehrende Komponenten

**Werkzeug-Schaltfläche** (`AnnotationToolbar.swift:102`) — die einzige Komponente mit
konsistenter Ausprägung im ganzen Projekt:
`28 × 28`, `cornerRadius: 6`, Symbol `18 × 18`, aktiv hinterlegt mit
`tealPrimary.opacity(0.2)`.

**Farbkreis** — `Circle()`, `18 × 18`, bei Auswahl `stroke(tealPrimary, lineWidth: 2)`.

**Strichstärken-Vorschau** — `RoundedRectangle(cornerRadius: 1)`, `20 × <Stärke>`, in
einer `28 × 28`-Schaltfläche. Drei Stärken: 2, 4, 6 px.

**Toolbar-Leiste** — `height: 50`, `padding(.horizontal, 16)`,
`padding(.vertical, 8)`, Gruppen durch `Divider().frame(height: 24)` getrennt.

**Einstellungs-Abschnitt** — Überschrift in `.headline`, darunter ein Block; die
Struktur trägt `Divider`, nicht Abstand.

## Symbole

Durchgehend SF Symbols über `Image(systemName:)`. Die Tab-Symbole der Einstellungen sind
in `PreferencesTab` zentral definiert (`gearshape`, `keyboard`, `pencil.and.outline`,
`slider.horizontal.3`) — die einzige Stelle, an der Symbolnamen als Tokens vorliegen.
Werkzeugsymbole stehen verstreut in `AnnotationEditor`.

## Erscheinungsbild der Fenster

| Fenster | Erscheinung |
|---|---|
| Annotations-Editor | dunkel, Markenfarben |
| Onboarding | dunkel, Markenfarben, Vollflächen-Verlauf |
| „Über" | dunkel, Markenfarben |
| Einstellungen | **systemnativ**, folgt der Systemeinstellung hell/dunkel |
| Verlauf-Browser | **systemnativ** |
| OCR-Ergebnis | `.hudWindow` — systemgesteuert |

---

## Fehlbestand

**Keiner offen.** Einer behoben, vier bewusst akzeptiert.

| Ursprünglich | Ausgang |
|---|---|
| FB-DS-01 · README und CHANGELOG beschrieben die Einstellungen falsch | **behoben** 2026-08-25 — `README.md` nennt sie „native System Settings layout"; das Fenster bleibt systemeigen |
| FB-DS-02 · Zwei Oberflächen ohne Markenbezug | **akzeptiert** 2026-08-25 — die Trennung ist stimmig: Einstellungen und Verlauf sind Systemdialoge und sehen nach System aus, Editor und Onboarding sind das Produkt |
| FB-DS-03 · Keine Tokens für Typografie, Abstände, Radien | **akzeptiert** 2026-08-25 — bei zwei Oberflächenfamilien und einer Person am Projekt trüge eine Token-Ebene mehr Aufwand als Ertrag. Sollte eine dritte Oberfläche hinzukommen, ist das der Anlass, es zu ändern — als eigenes Feature |
| FB-DS-04 · Kein Hell-Modus für die Markenoberflächen | **akzeptiert** 2026-08-25 — der Editor ist bewusst dunkel, damit das aufgenommene Bild und nicht die Oberfläche die Aufmerksamkeit trägt |
| FB-DS-05 · Kontrast ungeprüft | **akzeptiert** 2026-08-25 — Barrierefreiheit steht nicht im PRD. Die Werte sind hier dokumentiert, sodass eine Prüfung jederzeit ohne Codelesen möglich ist |
