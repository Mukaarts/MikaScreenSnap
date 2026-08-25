# B08 · Screenshots anheften — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Ein angehefteter Screenshot ist ein rahmenloses, nicht aktivierendes Panel auf der
schwebenden Ebene, das ein Bild anzeigt und Maus­ereignisse selbst auswertet: Ziehen
verschiebt, Umschalt+Ziehen skaliert, Scrollen ändert die Durchsichtigkeit.

Parallel dazu schreibt die Anwendung das Bild als PNG in einen eigenen Ordner unterhalb
von *Application Support*. Beim Start liest sie diesen Ordner aus und stellt bis zu zwanzig
Bilder wieder her. Dieser Schreibvorgang hat **kein Gegenstück**: Es gibt keinen Pfad, der
je eine dieser Dateien entfernt.

## Komponentenstruktur

```
PinnedScreenshotManager               (statisch, kein Zustand außer der Obergrenze)
├── pinImage(_:appState:)             Obergrenze prüfen → Panel → Liste → Datei schreiben
├── unpinPanel(_:appState:)           Fenster ausblenden, aus der Liste nehmen
├── unpinAll(appState:)               dito für alle
├── restorePins(appState:)            Ordner lesen, alphabetisch, erste 20 wiederherstellen
└── savePinnedImage(_:)               PNG mit Zeitstempel auf Millisekunden

PinnedScreenshotPanel                 rahmenlos, nicht aktivierend, .floating
├── Bilddarstellung                   höchstens 400 Punkte breit
├── Schaltfläche zum Schließen        erscheint bei Mauskontakt
├── Ziehen / Umschalt+Ziehen          verschieben / skalieren (mindestens 100 Punkte)
├── Scrollrad                         Durchsichtigkeit 20–100 %
├── Doppelklick                       schließen
└── Kontextmenü                       Kopieren · Sichern · Editor · Durchsichtigkeit · Schließen

AppState.pinnedPanels                 Liste der offenen Fenster — Grundlage des Untermenüs
```

## Datenmodell

### Auf der Festplatte

| Was | Wo | Benennung | Gelöscht durch |
|---|---|---|---|
| PNG des angehefteten Bildes | `~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/` | `pin_JJJJ-MM-TT_HH-mm-ss-SSS.png` | **nichts** |

Gespeichert wird ausschließlich das Bild. Es gibt keine Begleitdatei und keinen Eintrag in
den Einstellungen — also auch keine Position, Größe oder Durchsichtigkeit.

### Im Speicher

`AppState.pinnedPanels`: die Liste der offenen Fenster. Sie und der Ordnerinhalt laufen
auseinander, sobald ein Fenster geschlossen wird — das Fenster verschwindet aus der Liste,
die Datei bleibt.

## Zugriffsregeln

| Wer | Darf lesen | Darf schreiben | Erzwungen durch |
|---|---|---|---|
| Die Anwendung | den Ablageordner | anlegen — **nie löschen** | Dateirechte, keine Sandbox |
| Der Nutzer | denselben Ordner, wenn er ihn findet | über den Finder | — |

Der Ordner liegt in der Benutzerbibliothek, die der Finder standardmäßig ausblendet. Weder
Einstellungen noch Menü verweisen darauf. **Der Nutzer kann diese Daten in der Anwendung
weder sehen noch entfernen.**

## Missbrauchsschutz

| Vorgang | Limit | Anmerkung |
|---|---|---|
| gleichzeitig offene Fenster | 20 | ohne Rückmeldung bei Überschreitung (FB-04) |
| Dateien im Ablageordner | **keins** | wächst unbegrenzt (FB-01) |

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Rahmenloses, nicht aktivierendes Panel | gewöhnliches Fenster | ein angehefteter Screenshot soll den Arbeitsfluss nicht unterbrechen |
| 2 | `.floating` statt `.screenSaver` | höhere Ebene | über gewöhnlichen Fenstern, aber unter Auswahl-Overlays — sonst läge ein Pin über der Bereichsauswahl |
| 3 | Ablage in *Application Support* | im Bilderordner beim Verlauf | Programmdaten, die der Nutzer nicht selbst verwaltet — die Folge ist, dass er sie auch nicht findet |
| 4 | Zeitstempel mit Millisekunden | auf die Sekunde | verhindert Namenskollisionen (im Verlauf fehlt das, siehe B09/FB-02) |
| 5 | Wiederherstellung alphabetisch, erste 20 | nach Änderungsdatum, jüngste zuerst | **Grund nicht erkennbar** — die Folge (AK-14) wirkt unbeabsichtigt |
| 6 | Nur das Bild sichern | Anordnung mitsichern | **Grund nicht erkennbar** (FB-03) |
| 7 | Kein Löschpfad | beim Schließen entfernen | **Grund nicht erkennbar** (FB-01) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `pinImage` aus dem Editor | |
| AK-02 | Skalierung im Panel-Initialisierer | |
| AK-03 | Ziehen im Panel | |
| AK-04 | Umschalt+Ziehen, Untergrenze 100 | |
| AK-05 | Scrollrad, 0,2–1,0 | |
| AK-06 | Mauskontakt-Verfolgung | |
| AK-07 | Kontextmenü, fünf Einträge | |
| AK-08 | Doppelklick | |
| AK-09 | Untermenü über `AppState.pinnedPanels` | Umsetzung in B15 |
| AK-10 | `restorePins` beim Start | Anordnung geht verloren |
| AK-11 ⚠ | `print()` bei Erreichen der Obergrenze | keine sichtbare Rückmeldung |
| AK-12 ⚠ | `savePinnedImage` ohne Prüfung der Einstellung | |
| AK-13 ⚠ | **keine Komponente** — es gibt keinen Löschpfad | |
| AK-14 ⚠ | alphabetische Sortierung in `restorePins` | |
| AK-15 ⚠ | **keine Komponente** — die Speicherverwaltung kennt den Ordner nicht | |
| AK-16 | kein Protokollaufruf mit Bildbezug | |
| AK-17 | kein Netzwerkaufruf im Feature | |

Fünf ⚠-Kriterien, davon drei ohne jede Zuordnung. Das ist kein Darstellungsproblem: Es
sind drei Stellen, an denen etwas fehlt, das es geben müsste.

## Übergabe an die QA

1. **AK-13 zuerst und mit Zählung.** Ordner leeren, zehnmal anheften und schließen,
   Dateien zählen. Erwartung nach Aktenlage: zehn Dateien, null offene Fenster.
2. **AK-14 danach**: 25 Bilder anheften, Anwendung neu starten, prüfen **welche** zwanzig
   zurückkehren. Erwartung: die ältesten.
3. **AK-12**: automatisches Sichern abschalten, anheften, Ordner prüfen.
4. **AK-15**: Speicheranzeige mit dem tatsächlichen Verbrauch beider Ordner vergleichen.
5. Ist AK-13 bestätigt, ist der Befund **hoch bis kritisch** — er betrifft dauerhaft
   abgelegte Bildschirminhalte ohne Kenntnis des Nutzers, und die Erfassung pausiert nach
   der Regel aus `~/.claude/sdd/artefakte.md`, bis die Reparatur ausgeliefert ist.
