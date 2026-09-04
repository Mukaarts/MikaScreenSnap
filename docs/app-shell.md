# App-Shell — Mika+ScreenSnap

Stand: 2026-08-25 · rückwirkend aus dem Code gelesen · **auf Stand 3.5.0 nachgeführt**

Bei einer Menüleisten-App ist die Shell nicht Navigation, sondern **Erreichbarkeit**: Es
gibt kein Hauptfenster, keinen Zurück-Weg und keinen Ort, an dem die App „offen" ist. Was
auf jeder Ebene gleich bleibt, ist das Statusleistensymbol und die Art, wie Fenster
davor treten.

---

## Der Rahmen

**`LSUIElement = true`** in `Resources/Info.plist`. Die App hat kein Dock-Symbol, keine
Menüleiste am oberen Bildschirmrand und erscheint nicht im App-Umschalter. Sie bleibt
**dauerhaft** in `.accessory` — die Aktivierungsrichtlinie wird nie umgeschaltet.

Das war nicht immer so: Bis 3.4.0 wechselte die App die Policy und wurde nach dem
Schließen aus dem Dock unerreichbar (`a1b57e8`, Issue #18). Seither gilt die Regel aus
`CLAUDE.md` ausnahmslos — Fenster kommen über `NSApp.activate()` nach vorn, nicht über
einen Policy-Wechsel.

`applicationShouldTerminateAfterLastWindowClosed` liefert `false`. Die App läuft weiter,
wenn alle Fenster zu sind; beendet wird nur über *Quit* im Menü.

## Der einzige Einstiegspunkt

`MenuBarExtra` in `Sources/MikaScreenSnapApp.swift`, Symbol
`Resources/MenubarIconTemplate.png` (Template-Bild, folgt hell/dunkel automatisch).

Das Menü in seiner tatsächlichen Reihenfolge:

```
About Mika+ScreenSnap
Check for Updates…
⚠ Screen Recording not granted        ← nur wenn Berechtigung fehlt
─────────────────────────────
Capture Area                 ⌃⇧⌘4
Capture Full Screen          ⌃⇧⌘3
Capture Window…
Capture Frontmost Window     ⌃⇧⌘5
─────────────────────────────
Capture Text                  ⇧⌘6
Pick Color                    ⇧⌘7
Measure                       ⇧⌘8
─────────────────────────────
Pinned Screenshots      ▸     ← Untermenü, leer: „No pinned screenshots"
Color History           ▸     ← Untermenü, leer: „No colors picked yet"
Colour Palette          ▸     ← Untermenü, leer: Hinweis auf Umschalt+Klick
Screenshot History            ⇧⌘H
─────────────────────────────
Preferences…                    ⌘,
Quit                            ⌘Q
```

Drei Muster, die durchgehalten sind:

1. **Die Tastenkombination steht im Titel**, nicht als `keyEquivalent` — sie ist ja
   global registriert (Carbon) und nicht an das geöffnete Menü gebunden. Ausnahmen sind
   `Preferences…` und `Quit`, die echte `.keyboardShortcut` tragen.
2. **Untermenüs zeigen ihren Leerzustand als Text**, statt zu verschwinden.
3. **Der Berechtigungshinweis erscheint nur bei Bedarf**, geprüft über
   `CGPreflightScreenCaptureAccess()` bei jedem Öffnen des Menüs, und führt per
   `x-apple.systempreferences:`-Deeplink direkt in die Systemeinstellung. Fehlt die
   Berechtigung, sind seit 3.5.0 **alle sieben Aufnahme- und Zusatzeinträge deaktiviert** —
   der Weg dorthin führt nicht mehr durch einen misslungenen Versuch.

Der Menüpunkt `Capture Window…` hat bewusst **keine** Tastenkombination: Er öffnet die
interaktive Fensterauswahl, während `⌃⇧⌘5` das vorderste Fenster ohne Rückfrage nimmt.

## Fensterarten

Zwei Familien, sauber getrennt. Reguläre Fenster für alles, womit man arbeitet; Panels
für alles, was sich über den Bildschirm legt.

### Reguläre Fenster — `NSWindow`, über einen Controller

| Fenster | Stilmaske | Besonderheit |
|---|---|---|
| Annotations-Editor | `.titled .closable .resizable .miniaturizable` | einziges Fenster, das sich **selbst öffnet** — nach jeder Aufnahme |
| Verlauf-Browser | `.titled .closable .resizable .miniaturizable` | `LazyVGrid` mit Vorschaubildern |
| Einstellungen | `.titled .closable` | vier Tabs |
| Onboarding | `.titled .closable` | `TabView`, seitenweise |
| „Über" | `.titled .closable` | Version aus `Bundle.main` |

Alle folgen demselben Muster: ein Controller wird beim ersten Aufruf erzeugt, in
`AppState` gehalten und danach wiederverwendet. `showWindow()` ruft `NSApp.activate()`,
damit das Fenster trotz `.accessory` den Fokus bekommt.

### Panels — `NSPanel`, borderless und nonactivating

Das Muster aus `CLAUDE.md`, hier in seiner tatsächlichen Ausprägung:

| Panel | Ebene | Hintergrund |
|---|---|---|
| Bereichsauswahl | `.screenSaver` | `.clear` |
| Fensterauswahl | `.screenSaver` | `.clear` |
| Mess-Overlay | `.screenSaver` | `.clear` |
| Farbpipette — Klickfläche je Display | `.screenSaver` | `NSColor.clear.withAlphaComponent(0.001)` |
| Farbpipette — Lupe | **`.screenSaver + 1`** | `.clear` |
| Angehefteter Screenshot | `.floating` | `.clear` |
| Farb-Toast | `.floating` | `.clear` |
| Status-Toast | `.floating` | `.clear` |
| OCR-Ergebnis | `.hudWindow .utilityWindow .titled .closable` | systemgesteuert |

Zwei Feinheiten, die keine Willkür sind:

- **Die Lupe liegt eine Ebene über allem anderen** (`.screenSaver + 1`), damit sie nicht
  von der eigenen Klickfläche verdeckt wird.
- **Die Klickfläche der Pipette ist nicht ganz durchsichtig** (`alpha 0.001`): Ein
  vollständig transparentes Panel nimmt keine Mausereignisse entgegen.
- **Das OCR-Ergebnis ist das einzige Panel mit Titelleiste** — es wird gelesen, nicht
  darübergezogen.

## Was auf jeder Ebene gleich ist

**Rückmeldung.** `StatusToast` (Fehler, seit 3.4.1) und `ColorPickerToast` (Erfolg) sind
die einzige Art, wie die App ohne Fenster spricht. In einem `LSUIElement`-Bundle geht
`print()` ins Leere — Fehler, die keinen Toast auslösen, erreichen niemanden.

**Protokoll.** `CaptureLog` schreibt über `OSLog` unter dem Subsystem
`lu.daumedia.screensnap`, Kategorien `capture` und `hotkey`. Lesbar in Console.app.

**Zustand.** `AppState` ist der gemeinsame Halter: Manager, Controller, offene Pin-Panels
und Einstellungen. Alle UI-Klassen sind `@MainActor`, Zustand ist `@Observable`.

**Erreichbarkeit.** Jede Funktion ist über zwei Wege erreichbar — Menü und
Tastenkombination — mit einer Ausnahme: `Capture Window…` gibt es nur im Menü.

## Ablauf nach einer Aufnahme

Der einzige Ablauf, der mehrere Ebenen berührt, und deshalb hier statt in einer
Feature-Spec:

```
Hotkey oder Menü
   └→ Aufnahme (ScreenCaptureKit, ausgeschlossene Apps herausgefiltert)
        └→ postCapture
             ├→ Auslöseton                     (wenn captureSoundEnabled)
             ├→ automatisches Sichern + Vorschaubild   (wenn autoSaveEnabled)
             │    └→ die geschriebene Datei wandert als Verweis in den Editor
             └→ Annotations-Editor öffnet sich
                  └→ Kopieren · Sichern · Sichern unter · Anheften · Verwerfen
                       └→ jeder Ausgabeweg **ersetzt** die automatisch gesicherte Datei,
                          ebenso das Schließen, sobald eine Zensur im Bild liegt
```

Der Editor öffnet sich **immer**, auch wenn nichts annotiert werden soll. Der schnelle
Weg hinaus ist `Escape`: ohne Annotationen kopiert das die unveränderte Aufnahme und
schließt; mit Annotationen erscheint eine Rückfrage.

---

## Fehlbestand

**Keiner offen.**

| Ursprünglich | Ausgang |
|---|---|
| FB-AS-01 · Onboarding nur über die Einstellungen wiederauffindbar | **akzeptiert** 2026-08-25 — der Ablauf ist eine Einführung, kein Werkzeug; der dauerhafte Schutz ist der Menühinweis und die gesperrten Aufnahmeeinträge |
| FB-AS-02 · Der Berechtigungshinweis blockierte nicht | **behoben** 2026-08-25 — die Einträge sind ohne Berechtigung deaktiviert, und das Onboarding fordert sie an |
| FB-AS-03 · Sechs `print()` in Fehlerpfaden | **behoben** 2026-08-25 — alle sechs gehen über `CaptureLog`, das protokolliert und eine Kurzmeldung zeigt |
| FB-AS-04 · Keine Fensterwiederherstellung | **akzeptiert** 2026-08-25 — der Editor öffnet sich zu einem jeweils anderen Bild und wird auf dessen Größe gebracht; eine gemerkte Fenstergröße wäre für den nächsten Screenshot meist die falsche |
