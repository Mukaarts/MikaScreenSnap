# B02 · App-Ausschluss von Aufnahmen — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Der Nutzer wählt in den Einstellungen Programme aus einer Liste. Gespeichert werden nur
deren Bundle-Kennungen, als Menge in den Benutzereinstellungen. Bei **jeder** Aufnahme
baut B01 daraus die Liste der Fenster, die ScreenCaptureKit auslassen soll — die Prüfung
findet also zum Aufnahmezeitpunkt statt, nicht beim Speichern.

Die Liste der auswählbaren Programme wird bei jedem Öffnen frisch von ScreenCaptureKit
geholt und mit der bestehenden Auswahl zusammengeführt, damit ein ausgewähltes, aber
gerade nicht laufendes Programm nicht verschwindet.

## Komponentenstruktur

```
GeneralTabView
└── ExcludedAppsSection              Abschnitt „Privacy"
    ├── Zusammenfassung              „None" · „1 app" · „<n> apps"
    ├── Schaltfläche „Choose…"
    └── ExcludedAppsPicker           als Blatt (sheet), 420 × 400
        ├── ExcludedAppsManager      lädt und mischt die Programmliste
        ├── Liste mit Schaltern      Name + Bundle-Kennung je Zeile
        ├── „Refresh"                lädt die Liste neu
        └── „Done"                   schließt; gespeichert wird laufend
```

Angewandt wird die Liste außerhalb dieses Baums, in `CaptureEngine.excludedWindows` —
dort, wo B01, B05 und B06 ihre Filter bauen.

## Datenmodell

### Gespeichert

| Schlüssel | Typ | Standard | Bedeutung |
|---|---|---|---|
| `excludedBundleIdentifiers` | `[String]` in den Benutzereinstellungen, im Speicher `Set<String>` | drei Bedienungshilfen-Dienste | Programme, die in keiner Aufnahme erscheinen |

Standardwerte: `com.apple.inputmethod.AssistiveControl` (Bedienungshilfen-Tastatur),
`com.apple.DwellControl` (Verweilsteuerung), `com.apple.AccessibilityVisualsAgent`
(Zoom-Darstellung).

**Wichtig:** Nur ein *fehlender* Schlüssel fällt auf die Standardwerte zurück. Eine
ausdrücklich geleerte Liste bleibt leer.

### Flüchtig

`CapturableApp` — Bundle-Kennung (zugleich Identität) und Anzeigename. Existiert nur,
solange die Auswahl offen ist.

## Zugriffsregeln

| Wer | Darf lesen | Darf schreiben | Erzwungen durch |
|---|---|---|---|
| Der Nutzer | die Liste laufender Programme | seine Auswahl | Systemberechtigung Bildschirmaufnahme |
| B01, B05, B06 | die Auswahl | — | lesen sie bei jeder Aufnahme neu |

Die Regel wirkt **nicht** in der Anwendung, sondern in ScreenCaptureKit: Die Fenster
werden dem Systemdienst als Ausschlussliste übergeben, bevor das Bild entsteht. Damit
existiert der ausgeschlossene Inhalt zu keinem Zeitpunkt im Prozess der Anwendung — das
ist deutlich stärker als nachträgliches Übermalen.

## Missbrauchsschutz

Nicht anwendbar — kein Endpunkt, keine Kosten, keine Netzwerkaufrufe.

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Ausschluss über die ScreenCaptureKit-Filterliste | nachträgliches Schwärzen im Bild | der Inhalt entsteht gar nicht erst — ein Fehler beim Schwärzen wäre ein Datenleck, ein Fehler beim Filtern nur ein fehlendes Fenster |
| 2 | Bundle-Kennung als Schlüssel | Fenster-ID oder Prozess-ID | beide wechseln bei jedem Programmstart |
| 3 | Menge statt Liste | Array | Reihenfolge bedeutungslos, Doppelte unmöglich |
| 4 | Geleerte Liste bleibt leer | immer auf Standard zurückfallen | ausdrücklich kommentiert — sonst käme jeder entfernte Eintrag beim Neustart zurück |
| 5 | Liste bei jedem Öffnen neu laden | einmal beim Start | laufende Programme ändern sich ständig |
| 6 | Auswahl ohne Bestätigungsschritt | „Übernehmen"-Schaltfläche | folgt dem Muster der übrigen Einstellungen |
| 7 | Auswahl beschränkt auf laufende Programme | Auswahl aus `/Applications` | **Grund nicht erkennbar** — siehe FB-01 |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `ExcludedAppsPicker` + `ExcludedAppsManager.refresh` | Sortierung über `localizedStandardCompare` |
| AK-02 | Bindung schreibt direkt in die Einstellungen | |
| AK-03 | `CaptureEngine.excludedWindows` in allen vier Aufnahmewegen | Umsetzung in B01 |
| AK-04 | derselbe Aufruf in `startColorPicker` und `captureAreaForOCR` | Umsetzung in B05, B06 |
| AK-05 | `excludedSummary` | |
| AK-06 | `defaultExcludedBundleIdentifiers` | |
| AK-07 | Rückfall nur bei fehlendem Schlüssel | |
| AK-08 | Einmischen bereits ausgewählter Kennungen in `refresh` | |
| AK-09 | Leerzustand des Pickers | greift, wenn `SCShareableContent` fehlschlägt |
| AK-10 ⚠ | Liste stammt aus laufenden Programmen | siehe FB-01 |
| AK-11 ⚠ | — | **keine Komponente**: es gibt keine Rückmeldung |
| AK-12 | gespeichert wird nur die Kennung | |
| AK-13 | kein Protokollaufruf im Feature | |
| AK-14 | `resetAll()` entfernt den Schlüssel, danach greifen die Standardwerte | |

AK-11 hat bewusst keine Zuordnung: Das Kriterium beschreibt, dass etwas **nicht**
existiert. Es steht hier, damit die QA es nicht als erfüllt durchwinkt.

## Übergabe an die QA

1. **AK-03 und AK-04 sind der Kern.** Sie müssen in allen vier Aufnahmewegen **und** in
   Pipette und Texterkennung geprüft werden — es genügt nicht, einen zu prüfen. Ein
   ausgeschlossenes Fenster, das im OCR-Pfad doch erscheint, ist ein Datenleck.
2. **AK-07** ist leicht zu übersehen und leicht zu brechen: Liste leeren, Anwendung neu
   starten, prüfen dass sie leer bleibt.
3. **FB-03** — ein Fenster ohne besitzendes Programm über die Liste auszuschließen ist
   nicht möglich. Ob das in der Praxis vorkommt, sollte die QA feststellen.
