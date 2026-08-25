# App-Shell — Mika+ScreenSnap

Stand: 2026-08-25 · rückwirkend aus dem Code gelesen, Version 3.4.1

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
   `x-apple.systempreferences:`-Deeplink direkt in die Systemeinstellung.

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
`com.mika.mikaplusscreensnap`, Kategorien `capture` und `hotkey`. Lesbar in Console.app.

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
             └→ Annotations-Editor öffnet sich
                  └→ Kopieren · Sichern · Sichern unter · Anheften · Verwerfen
```

Der Editor öffnet sich **immer**, auch wenn nichts annotiert werden soll. Der schnelle
Weg hinaus ist `Escape`: ohne Annotationen kopiert das die unveränderte Aufnahme und
schließt; mit Annotationen erscheint eine Rückfrage.

---

## Fehlbestand

**FB-AS-01 · Kein Weg zurück ins Onboarding außer über die Einstellungen.** Der
Erststart-Flow wird über `hasCompletedOnboarding` gesteuert; wer ihn abbricht, erreicht
ihn nur über *Preferences → Show Onboarding Again* wieder. Das ist auffindbar, aber nicht
naheliegend, wenn die Berechtigung fehlt — dort führt der Menüeintrag stattdessen direkt
in die Systemeinstellungen.

**FB-AS-02 · Der Berechtigungshinweis prüft, aber blockiert nicht.** Fehlt die
Bildschirmaufnahme-Berechtigung, erscheint der Warneintrag im Menü — die Aufnahme-Punkte
bleiben trotzdem aktiv und anklickbar. Der Fehlschlag wird seit 3.4.1 als Toast
gemeldet („Screen Recording permission required"), aber der Weg dorthin führt durch einen
misslungenen Versuch. Gehört in die Spec von **B01** und **B12**.

**FB-AS-03 · Sechs `print()`-Aufrufe in Fehlerpfaden.** 3.4.1 hat das Protokollieren auf
`OSLog` umgestellt, aber nur im Aufnahmepfad. Verblieben sind:
`AnnotationEditor.swift:267` (OCR fehlgeschlagen), `LaunchAtLoginManager.swift:24`,
`ClipboardManager.swift:32` und `:40` (Speichern fehlgeschlagen),
`AppPreferences.swift:196` (automatisches Sichern fehlgeschlagen),
`PinnedScreenshotManager.swift:21` (Höchstzahl erreicht). In einem
`LSUIElement`-Bundle, das aus dem Finder gestartet wird, erreichen diese Meldungen
niemanden — **der Nutzer erfährt nicht, dass sein Screenshot nicht gespeichert wurde.**
Betrifft die Specs von **B03**, **B05**, **B08**, **B09** und **B13**.

**FB-AS-04 · Kein Fenster-Wiederherstellungsverhalten.** Editor, Verlauf und
Einstellungen merken sich Größe und Position nicht über einen Neustart hinweg. Bei einer
App, die mehrmals stündlich benutzt wird, ist das spürbar — es ist aber nirgends als
Entscheidung festgehalten.
