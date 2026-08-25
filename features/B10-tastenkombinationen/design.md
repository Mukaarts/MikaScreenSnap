# B10 · Tastenkombinationen — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Systemweite Tastenkombinationen laufen über die Carbon-Schnittstelle `RegisterEventHotKey`
— die einzige, die ohne Bedienungshilfen-Berechtigung auskommt. Das ist eine
Datenschutzentscheidung: Ein Ereignisabgriff sähe **jede** Taste, die der Nutzer drückt;
diese Schnittstelle meldet ausschließlich die angemeldeten Kombinationen.

Der Preis ist eine C-Schnittstelle ohne Zustandsbezug. Der Rückruf ist ein einfacher
Funktionszeiger, weshalb die Anwendung sich selbst über einen statischen Verweis
wiederfindet und die Kennung der ausgelösten Kombination auf eine von sieben Rückrufaktionen
abbildet.

## Komponentenstruktur

```
HotkeyManager                          @MainActor
├── currentBindings                    Aktion → Belegung
├── sieben Rückrufe                    je Aktion einer
├── statischer Verweis auf sich selbst nonisolated(unsafe) — Brücke zum C-Rückruf
├── registerHotkeys()                  installiert den Behandler **und** meldet die 7 an
├── unregisterAll()                    meldet die 7 ab — **nicht** den Behandler
├── reRegisterAll(bindings:)           abmelden · sichern · erneut anmelden
└── saveBindings()                     JSON in die Benutzereinstellungen

HotkeyAction                           7 Fälle, je mit Voreinstellung, Beschriftung, Kennung
HotkeyBinding                          Tastencode + Zusatztasten-Maske

ShortcutsTabView                       Reiter *Shortcuts*
├── Aufzeichner je Zeile               nimmt die nächste Kombination auf
├── Konflikthinweis                    nur gegen die eigenen sieben
├── „Apply"                            → reRegisterAll
└── „Restore Defaults"                 → reRegisterAll mit den Voreinstellungen
```

**Der Aufbau von `registerHotkeys()` ist die Ursache von FB-01:** Die Methode leistet
zweierlei — den Ereignisbehandler installieren und die Kombinationen anmelden —, wird aber
mehrfach aufgerufen, während nur der zweite Teil ein Gegenstück in `unregisterAll()` hat.

## Datenmodell

| Schlüssel | Typ | Inhalt |
|---|---|---|
| `hotkeyBindings` | Data (JSON) | Zuordnung vom Aktionsnamen auf Tastencode und Maske |

```
HotkeyBinding
├── keyCode   UInt32    Carbon-Tastencode, z. B. 0x14 = „3"
└── modifiers UInt32    Maske aus cmdKey · shiftKey · controlKey · optionKey
```

Für die Anzeige gibt es zwei Umwandlungen: Tastencode → Zeichen (feste Tabelle mit rund
70 Einträgen) und Maske → Symbole (⌃⌥⇧⌘). Unbekannte Tastencodes erscheinen als
`Key<Zahl>`.

## Zugriffsregeln

| Wer | Darf | Erzwungen durch |
|---|---|---|
| Die Anwendung | von sieben Kombinationen erfahren | Carbon meldet nur Angemeldetes |
| Die Anwendung | **keine** allgemeinen Tastatureingaben lesen | keine Bedienungshilfen-Berechtigung angefordert |

Das ist die datenschutzrelevante Eigenschaft dieses Features und sollte bei jeder Änderung
erhalten bleiben: Sobald ein Ereignisabgriff hinzukäme, sähe die Anwendung alles.

## Missbrauchsschutz

Nicht anwendbar.

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Carbon statt Ereignisabgriff | `CGEventTap` oder `NSEvent`-Beobachter | braucht keine Bedienungshilfen-Berechtigung und sieht keine fremden Eingaben |
| 2 | Statischer Verweis als Brücke | Nutzerdaten am Rückruf | die C-Schnittstelle führt keinen Zustand mit; in `CLAUDE.md` festgehalten |
| 3 | Kennungen 1–7 statt Aufzählungswerten | Zeichenketten | die Kennung der Kombination ist eine Ganzzahl |
| 4 | Rückruf auf den Hauptthread verlagert | im Rückruf arbeiten | Carbon ruft nicht zwingend auf dem Hauptthread |
| 5 | Belegungen als JSON | einzelne Schlüssel je Aktion | ein Schlüssel für alles; ohne Schemaversion |
| 6 | Behandler und Anmeldung in einer Methode | getrennt | **Grund nicht erkennbar** — Ursache von FB-01 |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `RegisterEventHotKey` + Ereignisbehandler | |
| AK-02 | `defaultBinding` je Aktion | |
| AK-03 | Aufzeichner im Reiter *Shortcuts* | |
| AK-04 | Vergleich in `ShortcutsTabView` | nur intern |
| AK-05 | `saveBindings` + Laden im Initialisierer | |
| AK-06 | *Restore Defaults* → `reRegisterAll` | |
| AK-07 ⚠ | Fehlerprotokoll ohne Oberfläche | |
| AK-08 ⚠ | wiederholtes `InstallEventHandler` | **ohne Gegenstück** |
| AK-09 | Wahl der Schnittstelle | die tragende Datenschutzeigenschaft |
| AK-10 | `HotkeyBinding` enthält nur Zahlen | |
| AK-11 | nur Fehlschläge werden protokolliert | |

## Übergabe an die QA

1. **AK-08 ist zählbar und sollte zuerst geprüft werden.** Anwendung starten, im Reiter
   *Shortcuts* zweimal eine Belegung ändern, dann `⌃⇧⌘3` **einmal** drücken und zählen, wie
   viele Editorfenster und Dateien entstehen. Erwartung nach Aktenlage: drei.
   Gegenprobe über *Reset All Preferences*, das denselben Weg nimmt.
2. **AK-07**: eine vom System belegte Kombination zuweisen und prüfen, ob die Oberfläche
   irgendetwas meldet.
3. **AK-09** ist eine Zusicherung, die erhalten bleiben muss: prüfen, dass die Anwendung
   nicht in der Liste der Bedienungshilfen-Berechtigungen auftaucht.
