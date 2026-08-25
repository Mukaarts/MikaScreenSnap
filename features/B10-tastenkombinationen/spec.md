# B10 · Tastenkombinationen — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.

## Zweck

Sieben Funktionen sind systemweit über Tastenkombinationen erreichbar, ohne dass die
Anwendung im Vordergrund sein muss. Alle sieben lassen sich umbelegen.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01, B05, B06, B07, B09 | `bestand` | die ausgelösten Funktionen |
| B11 Einstellungen | `bestand` | beherbergt den Reiter *Shortcuts* |

## User Stories

- **US-01** · Als Nutzer möchte ich aus jedem Programm heraus aufnehmen können, ohne zur
  Menüleiste zu greifen.
- **US-02** · Als Nutzer möchte ich Kombinationen ändern können, wenn sie mit anderen
  Programmen kollidieren.
- **US-03** · Als Nutzer möchte ich zu den Voreinstellungen zurückkehren können.

## Nicht im Scope

- Kombinationen für Werkzeuge im Editor — die sind fest und Teil von B03
- Mehrere Kombinationen für dieselbe Funktion — nicht vorhanden
- Kombinationen ohne Zusatztaste — von der verwendeten Systemschnittstelle nicht sinnvoll
  unterstützt

## Akzeptanzkriterien

- **AK-01** · Angenommen, die Anwendung läuft, wenn eine der sieben Kombinationen gedrückt
  wird, dann wird die zugehörige Funktion ausgelöst — unabhängig davon, welches Programm
  gerade im Vordergrund ist.
- **AK-02** · Angenommen, die Anwendung startet zum ersten Mal, wenn die Kombinationen
  angemeldet werden, dann gelten: `⌃⇧⌘3` Vollbild, `⌃⇧⌘4` Bereich, `⌃⇧⌘5` vorderstes
  Fenster, `⇧⌘6` Text erfassen, `⇧⌘7` Farbpipette, `⇧⌘8` Messen, `⇧⌘H` Verlauf.
- **AK-03** · Angenommen, der Reiter *Shortcuts* ist offen, wenn eine Zeile zum Aufzeichnen
  angeklickt wird, dann wird die nächste gedrückte Kombination übernommen und in
  Symbolschreibweise angezeigt.
- **AK-04** · Angenommen, eine Kombination ist bereits einer **anderen Funktion dieser
  Anwendung** zugewiesen, wenn sie aufgezeichnet wird, dann erscheint der Hinweis „Conflict
  with <Funktion>".
- **AK-05** · Angenommen, Kombinationen wurden geändert, wenn die Anwendung neu startet,
  dann gelten die geänderten.
- **AK-06** · Angenommen, der Reiter *Shortcuts* ist offen, wenn *Restore Defaults* gewählt
  wird, dann gelten wieder die sieben Voreinstellungen.
- **AK-07** ⚠ · Angenommen, eine Kombination ist bereits vom System oder einem anderen
  Programm belegt, wenn sie zugewiesen wird, dann **schlägt die Anmeldung still fehl**: Die
  Einstellung zeigt die neue Kombination, sie löst aber nichts aus.
  *(`HotkeyManager.swift:245` protokolliert den Fehler und fährt fort; die Oberfläche erfährt
  nichts davon. Die Konflikterkennung in `ShortcutsTabView.swift:82` vergleicht
  ausschließlich mit den eigenen sieben Aktionen. Zur Klärung vorgelegt.)*
- **AK-08** ⚠ · Angenommen, die Belegung wurde seit dem Start **n**-mal geändert, wenn danach
  eine Kombination gedrückt wird, dann wird die zugehörige Funktion **(n+1)-mal** ausgelöst.
  *(`HotkeyManager.swift:234` ruft `InstallEventHandler` innerhalb von `registerHotkeys()`.
  Diese Methode läuft im Initialisierer **und** bei jedem `reRegisterAll`. Ein Aufruf von
  `RemoveEventHandler` existiert im gesamten Quelltext nicht, und die Kennung des
  installierten Handlers wird nicht einmal aufbewahrt. `unregisterAll` entfernt nur die
  Kombinationen selbst, nicht den Ereignisbehandler. Folge: Wer im Reiter *Shortcuts*
  zweimal etwas ändert, löst mit `⌃⇧⌘3` danach drei Aufnahmen aus. Zur Klärung vorgelegt —
  dies ist der schwerste Befund dieses Features.)*

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 in Kraft.

- **AK-09** · Angenommen, Kombinationen sind angemeldet, wenn Tasten gedrückt werden, dann
  erfährt die Anwendung **ausschließlich** von den sieben angemeldeten Kombinationen — die
  verwendete Systemschnittstelle liefert keine allgemeinen Tastatureingaben und die
  Anwendung fordert keine Bedienungshilfen-Berechtigung an.
- **AK-10** · Angenommen, Kombinationen werden gespeichert, wenn sie abgelegt werden, dann
  enthalten die Daten nur Tastencodes und Zusatztasten-Masken.
- **AK-11** · Angenommen, eine Kombination wird ausgelöst, wenn das geschieht, dann steht
  nichts davon in einem Protokoll; protokolliert wird nur eine **fehlgeschlagene Anmeldung**.

*Abschnitt 4 (Rate Limits) und Abschnitt 6 (Geheimnisse): treffen nicht zu.*

## Edge Cases

- **EC-01** · Kombination bereits vom System belegt (etwa `⌘Leertaste`) → siehe AK-07.
- **EC-02** · Aufzeichnung mit `Escape` → Verhalten ungeprüft.
- **EC-03** · Kombination ohne Zusatztaste → wird angenommen, fängt danach aber
  gewöhnliche Tasteneingaben systemweit ab.
- **EC-04** · Gespeicherte Belegung ist beschädigt → Rückfall auf die Voreinstellungen, weil
  die Dekodierung fehlschlägt.
- **EC-05** · Zwei Funktionen auf derselben Kombination trotz Warnung → die zuletzt
  angemeldete gewinnt; die andere schlägt still fehl.
- **EC-06** · Kombination wird gedrückt, während bereits eine Auswahl läuft → die alte wird
  verworfen (B01/EC-07).

## Fehlbestand

- **FB-01 · Ereignisbehandler werden bei jeder Neuanmeldung erneut installiert.**
  Fundstelle: `HotkeyManager.swift:234`, ohne Gegenstück. Folge: mehrfaches Auslösen nach
  jeder Änderung der Belegung — mehrere Aufnahmen, mehrere Editorfenster, mehrere Dateien
  aus einem Tastendruck. Über `AdvancedTabView.swift:170` (*Reset All Preferences*) tritt
  derselbe Effekt auf, ohne dass der Nutzer die Kombinationen überhaupt angefasst hat.
- **FB-02 · Fehlgeschlagene Anmeldungen bleiben unsichtbar.** Fundstelle:
  `HotkeyManager.swift:245`. Folge: Eine Kombination steht in den Einstellungen und tut
  nichts; der Grund ist nur in der Konsole zu finden.
- **FB-03 · Die Konflikterkennung kennt nur die eigene Anwendung.** Fundstelle:
  `ShortcutsTabView.swift:82`. Folge: Der häufigste Konfliktfall — mit dem System oder
  einem anderen Programm — wird nicht erkannt. Zusammen mit FB-02 gibt es dafür keinerlei
  Rückmeldung.
- **FB-04 · Keine Prüfung auf sinnlose Belegungen.** Eine Kombination ohne Zusatztaste wird
  angenommen und fängt danach systemweit eine gewöhnliche Taste ab.
- **FB-05 · Keine Tests.** Kodierung und Dekodierung der Belegung sowie die
  Symbolschreibweise sind reine Umwandlung und ideal prüfbar.

## Offene Fragen

- **OF-01** · Soll die Anmeldung eines Ereignisbehandlers einmalig erfolgen? — entscheidet
  der Autor. Bis dahin gilt AK-08 als beschriebenes Verhalten.
- **OF-02** · Soll eine fehlgeschlagene Anmeldung in der Oberfläche erscheinen? —
  entscheidet der Autor.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Welche Schnittstelle für systemweite Kombinationen? | Carbon `RegisterEventHotKey` | die einzige, die ohne Bedienungshilfen-Berechtigung auskommt — ein Ereignisabgriff bräuchte weitreichende Rechte |
| 2 | Wie findet der Rückruf zur Instanz? | statischer Verweis, `nonisolated(unsafe)` | Carbon-Rückrufe sind C-Funktionszeiger ohne Zustand; in `CLAUDE.md` als Muster festgehalten |
| 3 | Signatur `0x4D534E53` | beliebiger Wert | „MSNS" als Kennzeichnung der Anwendung |
| 4 | Wie werden Belegungen gespeichert? | JSON in den Benutzereinstellungen | Tastencode und Maske sind Zahlen; es gibt keine Schemaversion (siehe `docs/datenmodell.md`, FB-DM-06) |
| 5 | Rückfall bei fehlerhaften Daten | Voreinstellungen | besser als keine Kombinationen |
| 6 | Konflikterkennung nur intern | auch gegen das System prüfen | **Grund erkennbar**: macOS bietet dafür keine brauchbare Abfrage — dass der Fehlschlag dann aber unsichtbar bleibt, ist die eigentliche Lücke (FB-02) |
