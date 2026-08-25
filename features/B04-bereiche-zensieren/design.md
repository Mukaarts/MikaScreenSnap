# B04 · Bereiche zensieren — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Zensur ist in dieser Anwendung keine Bildänderung, sondern eine **Annotation wie jede
andere** — ein Rechteck mit einer Zeichenvorschrift. Die Vorschrift lautet: Nimm den
Ausschnitt aus dem Originalbild, schicke ihn durch einen Systemfilter, zeichne das
Ergebnis an dieselbe Stelle.

Daraus folgt alles Weitere. Die Zensur ist rückgängig zu machen, verschiebbar und
skalierbar, weil das Original bis zum Export erhalten bleibt. Beim Export wird flach
gerendert — die Ausgabedatei enthält keine Ebenen und kein Original mehr.

Sie folgt daraus aber auch in einer unerwünschten Richtung: Das Original ist zum
Zensurzeitpunkt **bereits auf die Festplatte geschrieben** (siehe *Zugriffsregeln*).

## Komponentenstruktur

```
AnnotationCanvasView                  verteilt Mausereignisse an das aktive Werkzeug
├── BlurTool                          Rechteck ziehen → BlurAnnotation
│   └── drawPreview                   gestrichelte weiße Linie während des Ziehens
└── PixelateTool                      Rechteck ziehen → PixelateAnnotation
    └── drawPreview                   dieselbe Vorschau

AnnotationStore                       hält die Annotationen, verwaltet Undo
├── BlurAnnotation                    Rechteck + Radius (15)
└── PixelateAnnotation                Rechteck + Blockgröße (10)

AnnotationRenderer.renderFinalImage   zeichnet Original, dann alle Annotationen nach zIndex
```

Beide Werkzeuge sind bis auf den Filter identisch aufgebaut — gleiche Mindestgröße, gleiche
Vorschau, gleiche Ereignisbehandlung.

## Datenmodell

### `BlurAnnotation` / `PixelateAnnotation` — flüchtig, nur im Speicher

| Feld | Typ | Standard | Bedeutung |
|---|---|---|---|
| `id` | `UUID` | neu | Identität für Auswahl und Undo |
| `rect` | `CGRect` | — | zensierter Bereich, **in Bildpixeln** |
| `radius` (Blur) | `CGFloat` | `15.0` | Stärke der Unschärfe |
| `blockSize` (Pixelate) | `CGFloat` | `10.0` | Kantenlänge eines Blocks |
| `zIndex` | `Int` | `0` | Zeichenreihenfolge |
| `color`, `strokeWidth` | — | `.clear`, `0` | vom Protokoll gefordert, hier bedeutungslos |

Nichts davon wird persistiert. Nach dem Schließen des Editors existiert nur noch das
gerenderte Ergebnis — und die zuvor automatisch gesicherte Originaldatei.

## Zugriffsregeln

Keine Rollen. Die einzige relevante Regel ist die über den **Verbleib der Originaldaten**,
und sie ist die schwächste Stelle des Features:

| Zeitpunkt | Wo liegt das unzensierte Original |
|---|---|
| unmittelbar nach der Aufnahme | im Arbeitsspeicher **und** als Datei im Verlaufsordner |
| während der Bearbeitung | ebenso — die Zensur überdeckt es nur beim Zeichnen |
| nach dem Export | im Arbeitsspeicher freigegeben, **die Datei bleibt** |
| nach dem Schließen des Editors | **die Datei bleibt, unbefristet** |

Die zensierte Fassung entsteht ausschließlich in dem Moment, in dem der Nutzer exportiert.
Die automatisch gesicherte Fassung wird davon nicht berührt — siehe FB-01.

## Missbrauchsschutz

Nicht anwendbar — keine Endpunkte, keine Kosten, keine Netzwerkaufrufe.

## Externe Dienste

Keine. Beide Filter sind Systemfilter von CoreImage und arbeiten auf dem Gerät.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Zensur als umkehrbare Annotation | das Bild sofort dauerhaft verändern | erlaubt Undo, Verschieben, Skalieren — der Preis ist, dass das Original bis zum Export vorliegt |
| 2 | Ausschnitt bei jedem Zeichnen neu aus dem Original | einmal verfremden und zwischenspeichern | keine Qualitätsverluste beim Verschieben; dafür wird bei jedem Neuzeichnen gefiltert |
| 3 | Zuschneiden auf die Bildgrenzen vor dem Filtern | ungeprüft filtern | verhindert Abstürze bei Bereichen über dem Bildrand |
| 4 | Zeichenkontext auf den Bereich beschnitten | ohne Beschnitt zeichnen | verhindert, dass die Unschärfe über den gewählten Bereich hinausblutet |
| 5 | Feste Stärkewerte, keine Oberfläche dafür | einstellbar über die Werkzeugleiste | **Grund nicht erkennbar** |
| 6 | Keine Kantenfortsetzung vor dem Weichzeichnen | `clampedToExtent` vor dem Filter | **Grund nicht erkennbar** — Wirkung siehe FB-02 |
| 7 | Zwei Verfahren statt einem | nur Verpixeln | Grund nicht dokumentiert; erkennbar eine Wahlmöglichkeit für den Nutzer, nicht eine Abstufung der Sicherheit |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `BlurTool.cursor`, Werkzeugwahl im Editor | Taste `B` |
| AK-02 | `BlurTool.drawPreview` → `BlurAnnotation` | |
| AK-03 | `PixelateTool` → `PixelateAnnotation` | Taste `X` |
| AK-04 | Mindestgröße > 2 in `mouseUp` | |
| AK-05 | `AnnotationStore.addAnnotation` mit Undo-Eintrag | |
| AK-06 | `moved(by:)` und `resized(from:to:)` | Auswahlwerkzeug aus B03 |
| AK-07 | `AnnotationRenderer.renderFinalImage` in allen vier Ausgabewegen | belegt in `AnnotationEditor` |
| AK-08 | Schnittmenge mit den Bildgrenzen vor dem Filtern | |
| AK-09 ⚠ | feste Standardwerte in beiden Annotationen | keine Einstellung vorhanden |
| AK-10 ⚠ | `CIGaussianBlur` ohne Kantenfortsetzung | Kanten schwächer verfremdet |
| AK-11 | flaches Rendern beim Export | keine Ebenen im Ergebnis |
| AK-12 ⚠ | **keine Komponente** | die Originaldatei entsteht in B01/B09 und wird nie ersetzt |
| AK-13 | `renderFinalImage` vor `copyToClipboard` | |

AK-12 hat bewusst keine Zuordnung: Das Kriterium beschreibt, was **fehlt**. Es steht hier,
damit die QA es reproduziert und nicht als erfüllt durchwinkt.

## Übergabe an die QA

Dieses Feature ist als **Sicherheitsprüfung** zu behandeln, nicht als Funktionsprüfung.

1. **AK-12 zuerst.** Ein Passwort auf den Bildschirm bringen, aufnehmen, verpixeln,
   exportieren — dann `~/Pictures/MikaScreenSnap/` öffnen. Das erwartete Ergebnis nach
   Aktenlage: Das Passwort ist dort lesbar. Wenn ja, ist der Befund kritisch und die
   Erfassung pausiert, bis die Reparatur ausgeliefert ist.
2. **AK-09 und AK-10 messbar prüfen.** Die Anwendung hat die Texterkennung an Bord: Text
   ins Bild, zensieren, exportieren, Texterkennung auf das Ergebnis ansetzen. Erkennt sie
   noch etwas, ist die Zensur unwirksam. Das ist ein automatisierbarer Nachweis und der
   einzige, der die Frage wirklich beantwortet.
3. **Randlage gesondert prüfen** (AK-10): Text so platzieren, dass er genau an der Kante
   des zensierten Bereichs liegt.
4. **EC-03** — überlappende Zensuren verstärken sich nicht. Prüfen, ob das in der Praxis
   zu einem schwächer zensierten Bereich führt als erwartet.
