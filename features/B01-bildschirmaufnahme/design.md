# B01 · Bildschirmaufnahme — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.** Beschrieben ist der Aufbau, wie er ist — nicht, wie er
sein sollte.

## Überblick

Alle vier Aufnahmearten laufen über eine Klasse, `CaptureEngine`. Sie baut für jede
Aufnahme einen Inhaltsfilter, in dem steht, was aufgenommen wird und was ausgeschlossen
bleibt, und übergibt ihn an ScreenCaptureKit. Zwei Arten sind sofortig (Vollbild,
vorderstes Fenster), zwei brauchen erst eine Auswahl am Bildschirm (Bereich, Fenster) —
diese legen ein Overlay über jedes Display, warten auf Maus oder `Escape` und nehmen erst
danach auf.

Alle vier enden an derselben Stelle: einer gemeinsamen Nachbereitung, die den Ton spielt,
an den Verlauf übergibt und den Editor öffnet. Das ist der einzige Weg nach draußen —
eine Aufnahme, die diese Stelle nicht erreicht, existiert für den Nutzer nicht.

## Einstiegspunkte

| Auslöser | Weg | Interaktion |
|---|---|---|
| `⌃⇧⌘3` · *Capture Full Screen* | Vollbild | keine |
| `⌃⇧⌘4` · *Capture Area* | Bereichsauswahl | ziehen |
| *Capture Window…* (nur Menü) | Fensterauswahl | zeigen und klicken |
| `⌃⇧⌘5` · *Capture Frontmost Window* | vorderstes Fenster | keine |

## Komponentenstruktur

```
CaptureEngine                          hält alle vier Wege und die Filterlogik
├── Filterung
│   ├── excludedWindows(…)             eigene Fenster + Ausschlussliste + Zeiger-Overlay
│   ├── isPointerOverlay(…)            erkennt den Bedienungshilfen-Zeiger
│   └── selectableWindows(…)           Ziele der Fensterauswahl, vorne nach hinten
├── Aufnahme
│   ├── captureFullScreen()            Filter über Display, ohne Ausschnitt
│   ├── captureArea(rect:)             Filter über Display, mit Ausschnitt
│   ├── captureWindow()                sucht das vorderste Fenster und ruft ↓
│   └── captureWindow(_ window:)       Filter über genau ein Fenster
├── Auswahl-Oberflächen
│   ├── AreaSelectionPanel             je Display eines, borderless, .screenSaver
│   │   └── AreaSelectionView          Verdunkelung, Ausschnitt, Größenanzeige
│   └── WindowSelectionController      Panels je Display + globaler ESC-Beobachter
│       ├── WindowTarget               Fenster, Rahmen, Programmname, Symbol
│       └── WindowSelectionPanel       Hervorhebung des Fensters unter dem Zeiger
└── postCapture(_:)                    Ton · automatisches Sichern · Editor öffnen
```

`ScreenGeometry` steht daneben: eine Erweiterung von `NSScreen`, die zwischen AppKit
(Ursprung unten links) und CoreGraphics (Ursprung oben links) umrechnet — bezogen auf das
Display, dem der AppKit-Ursprung gehört, ausdrücklich **nicht** auf `NSScreen.main`.

## Datenmodell

Keine Persistenz. Die Aufnahme entsteht als `CGImage`, wird zu `NSImage` und dann
weitergereicht. Der einzige gehaltene Zustand ist `AppState.lastCapture`.

### `WindowTarget` — flüchtig, nur während der Fensterauswahl

| Feld | Typ | Bedeutung |
|---|---|---|
| `scWindow` | `SCWindow` | das Ziel selbst |
| `globalFrame` | `NSRect` | Rahmen in globalen AppKit-Koordinaten |
| `appName` | `String` | Anzeigename des Programms |
| `icon` | `NSImage?` | Programmsymbol, über die Prozess-ID geholt |

Die Umrechnung des Rahmens läuft über `ScreenGeometry` — der Fensterpfad benutzt also,
was der Bereichspfad ungenutzt lässt (siehe *Erkennbare Entscheidungen*, Zeile 6).

## Zugriffsregeln

Es gibt keine Rollen und keine Datenbank. Die einzige Zugriffsregel ist die
Systemberechtigung — und die Ausschlussliste, die B02 pflegt und dieses Feature anwendet.

| Wer | Darf aufnehmen | Erzwungen durch |
|---|---|---|
| Die Anwendung | alles, was das System freigibt | macOS-Bildschirmaufnahme-Berechtigung, geprüft über `CGPreflightScreenCaptureAccess()` |
| — | **nicht**: Fenster ausgeschlossener Apps | eigener Filter, bei jedem Aufruf neu gebildet |
| — | **nicht**: eigene Fenster | Filter über die eigene Prozess-ID |
| — | **nicht**: Bedienungshilfen-Zeiger | Erkennung über Titel „Cursor", leere Bundle-ID, Ebene > 100 |

Die Berechtigung ist eine Alles-oder-nichts-Entscheidung des Systems: Ohne sie schlägt
jede Aufnahme fehl, mit ihr ist jeder Bildschirminhalt lesbar. Eine Abstufung sieht macOS
nicht vor.

## Missbrauchsschutz

| Endpunkt | Limit | Warum |
|---|---|---|
| alle vier Aufnahmearten | **keins** | rein lokal, kostet kein Geld, ruft keinen fremden Dienst — Abschnitt 4 des Sicherheitskatalogs trifft nicht zu |

## Externe Dienste

**Keine.** Dieses Feature spricht ausschließlich mit dem Betriebssystem.

## Erkennbare Entscheidungen

Was im Code bewusst gewählt wurde, mit der Alternative, die es gegeben hätte. Wo die
Begründung nicht rekonstruierbar ist, steht das.

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | ScreenCaptureKit für alles | `CGWindowListCreateImage` | ab macOS 14 der einzige unterstützte Weg; 3.4.1 hat den letzten Rest ersetzt |
| 2 | Fensterreihenfolge über den Ursprungsindex stabilisiert | nur nach Ebene sortieren | `Array.sorted` ist nicht stabil, und alle normalen Fenster teilen Ebene 0 — ohne den Index wäre die Reihenfolge zufällig |
| 3 | Ebenen 0–19 als Fensterziele | alle Ebenen | schließt Schreibtisch und Rückwand (stark negativ) ebenso aus wie Dock, Menüleiste (24), Statussymbole (25) und offene Menüs (101) |
| 4 | Mindestgröße 40 × 40 Punkte | keine Untergrenze | hält Hilfsfenster und Schatten-Fenster aus der Auswahl |
| 5 | Zeiger-Overlay über drei Merkmale erkannt | nur über die Bundle-ID | 3.4.1: WindowServer meldet mitunter gar kein besitzendes Programm, dann greift die Bundle-ID-Prüfung nicht |
| 6 | Fensterpfad rechnet über `ScreenGeometry`, Vollbild- und Bereichspfad nicht | überall dieselbe Umrechnung | **Grund nicht erkennbar.** Der Fensterpfad wurde in 3.4.1 überarbeitet, die anderen beiden nicht — das erklärt den Unterschied, rechtfertigt ihn aber nicht (siehe FB-02) |
| 7 | 100 ms Pause zwischen Auswahl und Aufnahme | auf das Verschwinden der Panels warten | **Grund nicht dokumentiert.** Erkennbar soll das Overlay weg sein, bevor aufgenommen wird; ein fester Wert statt einer Zusicherung |
| 8 | Fenster werden nicht deckend aufgenommen | wie Vollbild deckend | erhält Transparenz und runde Ecken, statt sie schwarz zu hinterlegen |
| 9 | Vollbild rechnet die Pixelgröße fest mit Faktor 2 | `pointPixelScale` des Filters | **Grund nicht erkennbar**, vermutlich Annahme „Retina immer" — siehe AK-03 |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `captureFullScreen` → `postCapture` | |
| AK-02 ⚠ | `content.displays.first` | keine Displaywahl vorhanden |
| AK-03 ⚠ | feste Multiplikation mit 2 | falsch bei Skalierung ≠ 2 |
| AK-04 | `startAreaSelection` über `NSScreen.screens` | ein Panel je Display |
| AK-05 | `AreaSelectionView.draw` + `drawSizeLabel` | |
| AK-06 | `AreaSelectionView.keyDown`, Tastencode 53 | |
| AK-07 | Schwelle > 3 Punkte in `mouseUp` | |
| AK-08 ⚠ | `captureArea` gegen `displays.first` | Mehrschirm-Fehler |
| AK-09 ⚠ | `NSScreen.main?.backingScaleFactor` | folgt dem Schlüsselfenster |
| AK-10 | `WindowSelectionPanel` + `WindowTarget` | |
| AK-11 | `onSelect` → `captureWindow(_:)` | |
| AK-12 | globaler ESC-Beobachter, Rechtsklick im Panel | |
| AK-13 | `captureWindow()` über `frontmostApplication` | |
| AK-14 | `SCContentFilter.contentRect` + `.pointPixelScale` | in 3.4.1 korrigiert |
| AK-15 | Titelprüfung entfernt (3.4.1) | |
| AK-16 | Mindestgröße in `selectableWindows` | |
| AK-17 | `nonTargetBundleIdentifiers` | |
| AK-18 | `postCapture` | einziger Ausgang aller vier Wege |
| AK-19 | `postCapture`, Systemton „Tink" | respektiert `captureSoundEnabled` |
| AK-20 | `postCapture` → `historyManager.autoSave` | Umsetzung in B09 |
| AK-21 | `isPointerOverlay` + `showsCursor = false` | |
| AK-22 | `CaptureLog.report` → `OSLog` + Kurzmeldung | |
| AK-23 | `CaptureLog.message(for:action:)`, Fehlercode −3801 | |
| AK-24 | `excludedWindows` in allen vier Wegen | Liste kommt aus B02 |
| AK-25 | `CaptureLog` protokolliert nur Fehlertexte | keine Bildinhalte |
| AK-26 | kein Netzwerkaufruf im Feature | belegbar durch Suche nach `URLSession` |
| AK-27 | Filter über die eigene Prozess-ID | |

Keine Zeile ohne Zuordnung, keine Komponente ohne Kriterium — mit einer Ausnahme:
`startMeasurement(appState:)` liegt in derselben Datei, gehört aber zu **B07** und
benutzt seinen Parameter nicht (FB-05).

## Übergabe an die QA

Worauf besonders zu achten ist:

1. **Mehrschirmbetrieb.** AK-02, AK-03, AK-08 und AK-09 sind die vier ⚠-Kriterien und
   hängen zusammen. Ein zweites Display mit abweichender Skalierung reproduziert alle vier.
2. **Die Ausschlussliste** (AK-24) muss in **jedem** der vier Wege greifen, nicht nur im
   geprüften. Sie ist die einzige Datenschutzzusage dieses Features.
3. **Der Berechtigungsfall** (AK-23, FB-03) — ohne erteilte Berechtigung, aus dem Menü
   und über jeden der sieben Hotkeys.
