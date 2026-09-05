# App-Store-Paket — Mika+ScreenSnap

Alles, was App Store Connect für die Erstveröffentlichung braucht: Texte, Screenshots
und die Skripte, um beides jederzeit reproduzierbar neu zu erzeugen.

> **Vor der Einreichung:** [CHECKLISTE.md](CHECKLISTE.md) durchgehen — dort stehen die
> Pflichtangaben, die nur im Apple-Konto zu erledigen sind, und der eine Punkt, der vor
> allem anderen steht.

Aufgebaut wie die Pakete von Mika+FileScope und Mika+Grid, damit die drei Projekte gleich
funktionieren. Wo etwas abweicht, steht der Grund dabei.

---

## Was wohin gehört

| In App Store Connect | Datei |
|---|---|
| App-Name | `metadata/<locale>/name.txt` |
| Untertitel | `metadata/<locale>/subtitle.txt` |
| Werbetext (jederzeit ohne Review änderbar) | `metadata/<locale>/promotional_text.txt` |
| Beschreibung | `metadata/<locale>/description.txt` |
| Keywords | `metadata/<locale>/keywords.txt` |
| Neue Funktionen | `metadata/<locale>/release_notes.txt` |
| Support-URL / Marketing-URL | `metadata/<locale>/support_url.txt`, `marketing_url.txt` |
| Datenschutz-URL | `metadata/<locale>/privacy_url.txt` |
| Screenshots (2880 × 1800) | `screenshots/<locale>/mac-2880x1800/NN_name.jpg` |

Die Dateinamen folgen der Fastlane-Konvention — ein späterer Wechsel auf
`fastlane deliver` funktioniert ohne Umbau.

Grunddaten, Kategorien, Prüfungshinweise und die Antworten des Datenschutz-Fragebogens
stehen in [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md), die des
Altersfreigabe-Fragebogens in [ALTERSFREIGABEN.md](ALTERSFREIGABEN.md) — dort mit Beleg
aus dem Code, damit sie nach einem Feature-Umbau nachprüfbar bleiben.

## Sprachen

**`en-US` ist die einzige Lokalisierung und die Primärsprache.** Das ist keine
Sparsamkeit, sondern Konsequenz: Die Oberfläche der Anwendung ist englisch, und eine
deutsche Headline über einem englischen Fenster liest sich wie ein Fehler.

Die Struktur ist trotzdem mehrsprachig angelegt. Eine weitere Sprache kostet einen Ordner
unter `metadata/`, einen Block in `tools/shots.json`, einen Eintrag in `SPRACHE`
(`tools/compose.swift`) und eine Zeile in `locales` (`Tests/StoreAssetTests.swift`)
— plus eigene Rohaufnahmen, sobald die Anwendung selbst übersetzt ist.

## Was die Texte über diese Fassung sagen müssen

Die Beschreibung trägt einen Abschnitt **BEFORE YOU DOWNLOAD**, und der steht dort aus
demselben Grund wie bei Mika+Grid: Er nennt eine Pflichtangabe, und der Werbetext ist
ohne Review änderbar und taugt deshalb nicht als Träger. Drei Dinge stehen darin:

- **Die Ersteinrichtung fragt einmal nach einem Speicherordner.** Die Sandbox kennt
  keinen Weg nach `~/Pictures`, den die Anwendung selbst nehmen dürfte.
- **Wer von der Direktfassung wechselt, nimmt nichts mit** — keine Einstellungen, keine
  angehefteten Bilder. Eine sandboxed Anwendung kann die alte Ablage nicht lesen, nicht
  einmal nachsehen, ob es etwas zu holen gibt.
- **Die Dateien bleiben unangetastet liegen**, wo sie waren. Das gehört dazu, sonst liest
  sich der Absatz wie eine Drohung.

Ein Test prüft, dass die Beschreibung `macOS 14` nennt — die Zahl kommt aus
`LSMinimumSystemVersion` in `Resources/Info.plist` und darf nicht auseinanderlaufen.

## Screenshots

**Stand 2026-09-04: zwei von fünf geplanten Motiven liegen vor.** Beide sind aus der
**Direktfassung** aufgenommen, nicht aus der Store-Fassung — die Gründe stehen unten, und
beide Punkte hängen als offene Aufgaben in [CHECKLISTE.md](CHECKLISTE.md).

| # | Motiv | Aussage | Layout | Thema | Aufnahme | Stand |
|---|---|---|---|---|---|---|
| 01 | Editor mit Verpixeln, Hervorheben und Pfeil | der Hook | `hero` | dunkel | Fenster | ✅ |
| 02 | Bereichsauswahl im Ziehen | die Kernhandlung | `text-top` | hell | Bildschirm | ✅ |
| — | Texterkennung, Ergebnisfenster | der Unterschied | `highlight` | hell | Bildschirm | offen |
| — | Farblupe | die Werkzeugtiefe | `highlight` | dunkel | Bildschirm | offen |
| — | Angeheftetes Bild | der Alltag | `frame-top` | hell | Bildschirm | offen |

Apple verlangt mindestens ein Bild; zwei tragen den Eintrag, drei bis fünf wären besser.
Wer nachliefert, trägt das Motiv in `tools/shots.json` ein — `StoreAssetTests` verlangt
dann von selbst Rohaufnahme und Text dazu.

**Warum die drei fehlen.** Ihre Gegenstände sind Panels, die nur kurz und über allem
liegen, und die Aufnahme scheiterte reproduzierbar an der Umgebung, nicht an den
Werkzeugen: Auf der Maschine, auf der aufgenommen wurde, kamen synthetische Mausereignisse
mit Verzögerungen von mehreren Sekunden an. Das Skript wartet deshalb auf Fenster, statt
fest zu schlafen (`warte_auf`), und das hat Motiv 01 und 02 gerettet. Bei der
Texterkennung reicht es nicht: Ihr Ergebnisfenster liegt auf `.floating` — derselben Ebene
wie die Demo-Kulisse — und geriet dahinter. Die Farblupe erschien gar nicht erst. Beides
ist auf einer ruhigen Maschine wahrscheinlich unproblematisch.

**Warum kein Motiv das Menü der Menüleiste zeigt.** Zwei Gründe, und der zweite ist der
wichtigere. Erstens ist das Symbol bei einer Installation mit Menüleisten-Ausblender nicht
anklickbar. Zweitens — und deshalb bleibt es auch dauerhaft draußen — ist dieses Menü der
**einzige sichtbare Unterschied** zwischen den beiden Fassungen: Die Direktfassung trägt
dort „Check for Updates…", die Store-Fassung nicht
(`Sources/MikaScreenSnapApp.swift`, Abfrage auf `updateChannel.showsUpdateControls`). Ein
Bild davon wäre das einzige, das aus der falschen Fassung heraus **falsch** würde —
Guideline 2.3, Accurate Metadata. Ohne dieses Motiv sind alle übrigen in beiden Fassungen
gleich, und die Aufnahme aus der Direktfassung ist damit unbedenklich.

**Warum der Verlaufsbrowser nie vorkommt.** Er rendert echte Dateien aus dem
Speicherordner und gehört deshalb auf keine veröffentlichte Aufnahme.

**Warum Motiv 01 über die Vollbildaufnahme entsteht und nicht über die Bereichsauswahl.**
Die Bereichsauswahl braucht ein vollständiges Ziehen samt Loslassen. Kommt das Loslassen
verspätet oder mit einem zu kleinen Rechteck an, verwirft `AreaSelectionView.mouseUp` die
Auswahl stumm — **und schließt die Overlay-Panels nicht**, weil dieser Zweig `onCancel`
nicht aufruft (`Sources/AreaSelectionOverlay.swift:173-177`). Die Vollbildaufnahme braucht
kein Ziehen und liefert dasselbe Bild: die ganze Kulisse im Editor.

Vier Layouts statt einem: Fünf identisch aufgebaute Kacheln nebeneinander lesen sich in
der Store-Galerie wie ein Bild. `compose.swift` kennt deshalb

- `hero` — Aufnahme fast formatfüllend, Headline im abgedunkelten Fuß,
- `text-top` — Headline oben, Aufnahme darunter, unten angeschnitten,
- `frame-top` — Aufnahme läuft **oben** aus dem Bild, Text steht unten,
- `highlight` — wie `text-top`, davor ein vergrößerter Ausschnitt als schwebende Karte.
  Die Karte liegt in beiden Achsen genau über ihrer eigenen Herkunft und verdeckt sie;
  stünde sie woanders, sähe man denselben Inhalt zweimal.

Welches Motiv welches Layout bekommt — samt Ausschnitt — steht in `tools/shots.json`.

Format: **2880 × 1800 px**, JPEG ohne Alphakanal — eine der von Apple für den Mac
akzeptierten Größen. `2560x1600` ist in `FORMATE` bereits hinterlegt; alle Layoutmaße
leiten sich aus der Leinwandgröße ab, ein weiteres Format kostet deshalb nur einen Eintrag
und einen Lauf mit `--format`.

JPEG und nicht PNG: Bei dieser Größe wiegt ein PNG rund 3 MB. App Store Connect nimmt
beides, solange kein Alphakanal drin ist.

---

## Neu erzeugen

```bash
AppStore/tools/capture.sh --build      # Store-Fassung bauen, Kulisse, Rohaufnahmen
swift AppStore/tools/compose.swift     # Layouts + Texte → fertige Screenshots
swift test --filter StoreAssetTests    # Limits, Bildmaße, Vollständigkeit
```

`capture.sh` ohne `--build` überspringt den Bau und nimmt nur neu auf. `--direct` weicht
auf die Direktfassung aus, wenn die Store-Fassung ihre Berechtigungen noch nicht hat —
ein Notnagel, den das Skript bei jedem Lauf ansagt.
`compose.swift en-US` beschränkt die Komposition auf eine Sprache,
`compose.swift --format 2560x1600` schreibt ein zweites Format.

### Wie das funktioniert

**Aufgenommen wird die Store-Fassung** aus `build-appstore/`, nicht die Direktfassung aus
`/Applications`. Der Unterschied ist sichtbar: Das Menü der Direktfassung trägt
„Check for Updates…", das der Store-Fassung nicht — die Abfrage steht in
`Sources/MikaScreenSnapApp.swift` auf `updateChannel.showsUpdateControls`. Ein Bild der
Direktfassung zeigte im Store also einen Eintrag, den es dort nicht gibt. `capture.sh`
bricht ab, wenn das Store-Bundle fehlt, statt still auf die Direktfassung auszuweichen —
und prüft nach dem Start, dass wirklich sie läuft. Beide Fassungen tragen dieselbe
Bundle-Kennung; die Verwechslung wäre sonst lautlos.

Die Kulisse ist die erzeugte Demo-Leinwand (`scripts/GenerateDemoCanvas.swift`), gezeigt
von `scripts/DemoStage.swift` als randloses Fenster über dem ganzen Bildschirm. Nie der
echte Schreibtisch: Dort stehen Dateinamen, Gerätename und was sonst gerade offen ist.

Drei Fallen, die das Skript bewusst behandelt:

- **Die Bereichsauswahl gibt es nur, solange die Maustaste unten ist.** `drag` endet
  immer mit einem Loslassen, und danach ist nichts mehr zu sehen. Dafür gibt es in
  `scripts/UIDriver.swift` den Befehl `drag-shot`: ziehen, aufnehmen, dann loslassen.
- **Die Bühne liegt auf `.floating`** — über gewöhnlichen Fenstern, aber unter den
  Overlays der Anwendung (`.screenSaver`). Für die Overlay-Motive ist das genau richtig;
  vor der Editoraufnahme muss sie weg, sonst liegt sie über dem Editor.
- **Der grüne Klickring.** Die Bedienungshilfen zeichnen nach einem synthetischen Klick
  einen Ring an die Mausposition. Vor jeder Aufnahme geht der Zeiger deshalb in die Ecke.
- **Feste Pausen tragen nicht.** Zwischen einem synthetischen Ereignis und der Reaktion
  der Anwendung lagen auf der Aufnahmemaschine mehrere Sekunden. `warte_auf` pollt
  deshalb die Fensterliste, statt zu schlafen — mit `sleep 3` entstanden vorher Bilder
  der nackten Kulisse, und der Fehler sah aus wie ein Fehler der Anwendung.

Die Store-Fassung braucht für eine Aufnahme mehr als einen Bau: einmal erteilte
Bildschirmaufnahme **und** einen gewählten Speicherordner. Sie ist ein anderes Binary als
die Direktfassung und bekommt einen eigenen TCC-Eintrag; beides lässt sich nicht
skripten. `capture.sh` prüft es und bricht mit einer Anleitung ab, statt fünf Bilder mit
einem Einrichtungsfenster darauf zu erzeugen.

**Vor der Freigabe echt signieren — sonst hält sie keinen Tag.** `build-appstore.sh`
signiert ad-hoc, und TCC erkennt eine ad-hoc signierte App an ihrem CDHash. Der ändert
sich bei **jedem** Bau: Die gestern erteilte Freigabe gilt der App von gestern, die neu
gebaute steht als weiterer, gleichnamiger Eintrag daneben. In der Liste sind sie nicht
auseinanderzuhalten — beide heißen „Mika+ScreenSnap", beide tragen
`lu.daumedia.screensnap`. Wer den falschen schaltet, sieht keinen Fehler, nur ein
Einrichtungsfenster, das nicht weggeht. (Bei einem Lauf lagen drei solcher Leichen
übereinander.)

Deshalb vor der Aufnahme einmal mit einem echten Zertifikat übersignieren — dann
identifiziert TCC die App über Team- und Bundle-ID, und die Freigabe überlebt jeden
weiteren Bau:

```bash
codesign --force --sign "Developer ID Application: … (CWJM4J4HFN)" \
    --entitlements Resources/MikaScreenSnap-AppStore.entitlements \
    --options runtime build-appstore/Mika+ScreenSnap.app
```

Die Sandbox bleibt dabei an — die Entitlements werden mitgegeben. Für die Einreichung
ändert das nichts: `package-appstore.sh` übersigniert ohnehin mit *Apple Distribution*.
Stehen schon mehrere Karteileichen in der Liste, räumt
`tccutil reset ScreenCapture lu.daumedia.screensnap` sie alle ab. Es trifft auch die
Direktfassung; die fragt beim nächsten Start neu.

**Ungelöst, Stand 2026-09-05: Die Store-Fassung war so trotzdem nicht freizuschalten.**
In der Liste steht **ein** Eintrag „Mika+ScreenSnap", und er gehört der Direktfassung aus
`/Applications` — nachweisbar daran, dass sie mit ihm Zugriff hat, während die
Store-Fassung weiter ihr Einrichtungsfenster zeigt. Beide tragen dieselbe Bundle-Kennung.
Nach einem `tccutil reset` verschwand der Eintrag, und **kein** Weg brachte einen für die
Store-Fassung zurück: weder „Grant Access" im Einrichtungsfenster (das
`CGRequestScreenCaptureAccess()` aufruft und danach die Einstellungen öffnet — die Liste
blieb leer), noch dasselbe mit echt signierter Fassung, noch nachdem die Direktfassung
vorübergehend aus `/Applications` weggeschoben war.

Der Kommentar in `Sources/Onboarding/PermissionScreen.swift` sagt, `CGRequestScreenCaptureAccess`
registriere die App in der Liste. Für die Direktfassung mag das stimmen; für die
sandboxed Store-Fassung neben einer installierten Direktfassung galt es an diesem Tag
nicht. **Wer die drei fehlenden Motive nachliefern will, muss zuerst das klären** — bis
dahin bleibt es bei den zwei Motiven aus der Direktfassung.

### Bildmaterial

Zwei Sorten Bild liegen unter `assets/`, und beide sind **generiert** (Higgsfield,
Nano Banana Pro) — nicht fotografiert und nicht aufgenommen:

| Datei | Wo es landet | Wozu |
|---|---|---|
| `assets/backdrops/dark.jpg`, `light.jpg` | der Grund jeder Kachel, `compose.swift` | 3200 × 1800 — genau das, was 2880 × 1800 formatfüllend braucht, damit nichts hochskaliert wird |
| `assets/imagery/a.jpg`, `b.jpg` | der Abschnitt *Imagery* der Demo-Leinwand | gibt dem fiktiven Dokument Bildmaterial, damit es sich wie ein Dokument liest und nicht wie ein Wireframe |

**Wo die Grenze verläuft.** Generiert werden darf, was *hinter* und *im* Fenster liegt:
der Grund der Kachel und der Inhalt des erfundenen Dokuments. Die Oberfläche der
Anwendung selbst wird ausschließlich aufgenommen — jedes Pixel des Fensters kommt aus
`capture.sh`. Ein gemaltes Fenster verspräche eine Anwendung, die es nicht gibt
(Guideline 2.3, Accurate Metadata), und genau daran hängt auch die Regel, dass aus der
Store- und nicht aus der Direktfassung aufgenommen wird.

**Warum der Grund ein Bild ist und kein Verlauf.** Vorher zeichnete `compose.swift` ihn
aus zwei Farben plus Punktraster. Das trug eine Kachel, aber fünf nebeneinander sahen
nach Vorlage aus. Fehlt eine der beiden Dateien, bricht `compose.swift` ab und fällt
**nicht** auf den alten Verlauf zurück: Der sähe flüchtig ähnlich genug, dass er
unbemerkt in den Store liefe — und dort stünden dann Motive nebeneinander, deren Grund
sich unterscheidet. `GenerateDemoCanvas.swift` hält es mit den Imagery-Platten genauso.

Über dem Bildgrund liegt an Ober- und Unterkante ein Schleier in der Grundfarbe. Er ist
kein Schmuck: `text-top` setzt die Headline an den oberen Rand, `frame-top` an den
unteren, und ein Bildgrund ist dort — anders als ein Verlauf — nicht überall gleich hell.

### Texte ändern

Headlines und Sublines stehen in `tools/shots.json`, nach Sprache getrennt.
`compose.swift` verkleinert die Headline automatisch, bis der Textblock in die vorgesehene
Höhe passt — längere Übersetzungen brechen das Layout also nicht.

Farben stammen aus `Sources/MikaPlusColors.swift`, die Schrift ist SF Pro vom System;
Store-Assets und Anwendung haben dadurch dieselbe Handschrift. Wer die Markenfarbe
ändert, ändert sie dort und spiegelt sie in `compose.swift` und `web/app/globals.css`.
