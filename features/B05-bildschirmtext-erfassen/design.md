# B05 · Bildschirmtext erfassen (OCR) — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Die Texterkennung ist kein eigener Aufnahmeweg, sondern eine **Abzweigung**: Sie benutzt
dieselbe Bereichsauswahl und denselben Aufnahmecode wie B01, gibt das Ergebnis aber nicht
an den Editor weiter, sondern an Apples Vision-Framework. Was zurückkommt, ist eine
Zeichenkette.

Der zweite Weg führt durch den bereits geöffneten Editor: Dort wird nicht neu aufgenommen,
sondern ein Ausschnitt aus dem vorhandenen Bild genommen. Beide Wege enden im selben
Ergebnisfenster — nur der Umgang mit der Zwischenablage unterscheidet sich.

## Komponentenstruktur

```
Weg 1 — vom Bildschirm (⇧⌘6)
CaptureEngine.startTextCapture         Bereichsauswahl über alle Displays
└── captureAreaForOCR(rect:)           aufnehmen → erkennen → kopieren → anzeigen
    ├── OCREngine.recognizeText        Vision, auf dem Gerät
    ├── NSPasteboard.general           automatisch
    └── OCRResultPanel                 HUD-Fenster

Weg 2 — im Editor
AnnotationEditor                       Schaltfläche „Extract Text"
├── AnnotationCanvasView               Auswahlmodus mit eigener Darstellung
└── performOCROnRegion(rect:)          zuschneiden → erkennen → anzeigen
    └── OCRResultPanel                 dasselbe Fenster, ohne Kopieren

OCRResultPanel
├── NSTextView                         erkannter Text, scrollbar
├── „Copy"                             Text in die Zwischenablage
├── „Copy as Markdown"                 Text als Codeblock
└── Zeitgeber 10 s                     pausiert, solange der Zeiger darüber liegt
```

## Datenmodell

Kein persistenter Zustand. Der erkannte Text existiert als Zeichenkette im
Ergebnisfenster und in der Zwischenablage.

**Die Zwischenablage ist die einzige Ablage dieses Features** — und die einzige, die die
Anwendung nicht kontrolliert: Ihr Inhalt ist für jedes andere Programm lesbar und wird bei
aktivierter geräteübergreifender Zwischenablage vom System an andere Geräte des Nutzers
übertragen.

## Zugriffsregeln

| Wer | Darf lesen | Erzwungen durch |
|---|---|---|
| Die Anwendung | jeden Bildschirmbereich, den der Nutzer wählt | Systemberechtigung Bildschirmaufnahme |
| — | **nicht**: ausgeschlossene Programme | Filter aus B02, angewandt vor der Aufnahme |
| Andere Programme | den erkannten Text, sobald er in der Zwischenablage liegt | **nichts** — siehe AK-17 |

## Missbrauchsschutz

| Vorgang | Limit | Anmerkung |
|---|---|---|
| Texterkennung | **keins** | läuft lokal, kostet nichts; Abschnitt 4 des Katalogs trifft nicht zu |

Anzumerken bleibt: Ein großer Bereich beschäftigt die Erkennung spürbar lange, ohne dass
es eine Fortschrittsanzeige oder einen Abbruch gibt.

## Externe Dienste

**Keine.** Vision arbeitet auf dem Gerät.

Mittelbar berührt wird jedoch ein Systemdienst: Die geräteübergreifende Zwischenablage
überträgt den erkannten Text über iCloud an andere Geräte desselben Kontos, sofern der
Nutzer sie aktiviert hat. Das ist keine Übertragung der Anwendung, aber eine Folge ihres
Verhaltens — und deshalb hier vermerkt.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Vision auf dem Gerät | Cloud-Erkennungsdienst | keine Übertragung, keine Kosten, keine Schlüssel — Voraussetzung für Stufe A |
| 2 | Erkennung auf einer Hintergrundwarteschlange, Ergebnis über Fortsetzung | synchron | hält die Oberfläche frei |
| 3 | Nur der beste Kandidat je Zeile | mehrere Kandidaten anbieten | einfaches Ergebnis; der Gütewert geht verloren (FB-03) |
| 4 | Zeilen mit Zeilenumbruch verbunden | Layout nachbilden | Vision liefert keine Struktur, nur Beobachtungen |
| 5 | Eigenes HUD-Fenster statt einer Kurzmeldung | Toast wie bei der Farbwahl | Text muss lesbar und auswählbar sein, eine Kurzmeldung reicht dafür nicht |
| 6 | Automatisches Kopieren nur bei Weg 1 | in beiden Wegen | **Grund nicht erkennbar** — vermutlich Versehen (FB-02) |
| 7 | Zwischenablage ohne Vertraulichkeitsmarkierung | wie bei Passwortverwaltungen markieren | **Grund nicht erkennbar** — vermutlich nicht bedacht (FB-06) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `startTextCapture` → `AreaSelectionPanel` je Display | dieselbe Auswahl wie B01 |
| AK-02 | `OCRResultPanel` | |
| AK-03 | Kopieren in `captureAreaForOCR` | |
| AK-04 | Systemton, respektiert `captureSoundEnabled` | nur bei nicht leerem Ergebnis |
| AK-05 ⚠ | **keine Komponente** — der Leerfall ist nicht behandelt | |
| AK-06 | `isOCRSelectionMode` in der Zeichenfläche | |
| AK-07 | `performOCROnRegion` | |
| AK-08 ⚠ | **keine Komponente** — Weg 2 kopiert nicht | |
| AK-09 | `recognitionLevel = .accurate`, drei Sprachen, Sprachkorrektur | |
| AK-10 | Verbinden der Beobachtungen mit Zeilenumbruch | |
| AK-11 | Zeitgeber, 10 Sekunden | |
| AK-12 | Mauskontakt-Verfolgung im Panel | |
| AK-13 | `copyAsMarkdown` | |
| AK-14 | Vision, lokal | belegbar: kein Netzwerkaufruf im Feature |
| AK-15 | Filter aus B02 in `captureAreaForOCR` | **gilt nur für Weg 1** — Weg 2 arbeitet auf einem bereits gefilterten Bild |
| AK-16 | kein Protokollaufruf mit Textbezug | |
| AK-17 ⚠ | allgemeine Zwischenablage ohne Markierung | Übertragung durch den Systemdienst |
| AK-18 | `CaptureLog.report` in Weg 1 | Weg 2 hat nur ein `print()` |

## Übergabe an die QA

1. **AK-17 ist der schwerste Punkt** und zugleich der, der am ehesten übersehen wird: Er
   widerspricht der PRD-Zusage, dass kein Byte den Rechner verlässt. Zu prüfen mit
   aktivierter geräteübergreifender Zwischenablage und einem zweiten Apple-Gerät.
2. **AK-15 in beiden Wegen prüfen.** Bei Weg 2 ist die Filterung mittelbar — das Bild kam
   schon gefiltert aus B01. Sollte sich das je ändern, fällt es hier zuerst auf.
3. **AK-05 und AK-08** sind leicht zu reproduzieren und beschreiben beide fehlende
   Rückmeldung.
4. Die Erkennung eignet sich als **Messwerkzeug für B04**: Zensierten Text durch die
   Erkennung schicken. Findet sie etwas, ist die Zensur unwirksam.
