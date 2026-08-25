# B05 · Bildschirmtext erfassen (OCR) — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.

## Zweck

Der Nutzer zieht einen Rahmen um Text, der auf dem Bildschirm steht — in einem Bild, einem
Video, einem PDF ohne Textebene — und hat ihn danach als Text zur Verfügung. Ohne
Abtippen, ohne fremden Dienst.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 Bildschirmaufnahme | `bestand` | liefert Bereichsauswahl und Bildausschnitt |
| B02 App-Ausschluss | `bestand` | ausgeschlossene Programme dürfen auch hier nicht gelesen werden |
| B03 Annotationseditor | `bestand` | beherbergt den zweiten Einstiegsweg |
| B10 Tastenkombinationen | `bestand` | `⇧⌘6` |

## User Stories

- **US-01** · Als Nutzer möchte ich Text aus einem Bildbereich herausziehen, damit ich ihn
  weiterverwenden kann, ohne ihn abzutippen.
- **US-02** · Als Nutzer möchte ich das auch nachträglich aus einem bereits aufgenommenen
  Screenshot heraus können.
- **US-03** · Als Nutzer möchte ich den erkannten Text sehen, bevor ich ihn einfüge, damit
  ich Erkennungsfehler bemerke.

## Nicht im Scope

- Erkennung von Handschrift — Vision leistet das in dieser Konfiguration nicht
- Übersetzung des erkannten Textes — nicht vorhanden
- Erhalt des Layouts (Tabellen, Spalten) — der Text wird zeilenweise aneinandergehängt
- Weitere Sprachen als Deutsch, Englisch, Französisch — fest eingestellt, siehe AK-09

## Akzeptanzkriterien

### Weg 1 — vom Bildschirm (`⇧⌘6`)

- **AK-01** · Angenommen, `⇧⌘6` wird gedrückt oder *Capture Text* gewählt, wenn die
  Auswahl erscheint, dann liegt über jedem Display dieselbe abgedunkelte Fläche wie bei der
  Bereichsaufnahme.
- **AK-02** · Angenommen, ein Bereich mit Text wird gezogen, wenn losgelassen wird, dann
  erscheint ein Fenster „Extracted Text" mit dem erkannten Text und den Schaltflächen
  *Copy* und *Copy as Markdown*.
- **AK-03** · Angenommen, ein Bereich mit Text wird gezogen, wenn die Erkennung fertig ist,
  dann liegt der Text **bereits in der Zwischenablage**, ohne dass eine Schaltfläche
  gedrückt wurde.
- **AK-04** · Angenommen, der Auslöseton ist aktiviert, wenn Text erkannt wurde, dann
  erklingt „Tink".
- **AK-05** ⚠ · Angenommen, im gewählten Bereich ist **kein** Text zu erkennen, wenn die
  Erkennung fertig ist, dann geschieht **nichts**: kein Fenster, kein Ton, keine Meldung.
  *(`CaptureEngine.swift:358` führt alles innerhalb von `if !recognizedText.isEmpty` aus.
  Der Nutzer kann nicht unterscheiden, ob die Erkennung nichts fand oder die Funktion nicht
  ausgelöst hat. Zur Klärung vorgelegt.)*

### Weg 2 — im Editor

- **AK-06** · Angenommen, der Editor ist offen, wenn *Extract Text* in der Werkzeugleiste
  gewählt wird, dann wechselt der Editor in einen Auswahlmodus mit sichtbarer Rückmeldung.
- **AK-07** · Angenommen, der Auswahlmodus ist aktiv, wenn ein Bereich gezogen wird, dann
  erscheint dasselbe Ergebnisfenster wie bei Weg 1.
- **AK-08** ⚠ · Angenommen, Text wird im Editor erkannt, wenn das Fenster erscheint, dann
  liegt der Text **nicht** in der Zwischenablage — anders als bei Weg 1.
  *(`AnnotationEditor.swift:262` öffnet nur das Ergebnisfenster. Zwei Wege desselben
  Features verhalten sich unterschiedlich. Zur Klärung vorgelegt.)*

### Erkennung

- **AK-09** · Angenommen, Text in Deutsch, Englisch oder Französisch liegt im Bereich, wenn
  die Erkennung läuft, dann wird er mit Sprachkorrektur und der genauen Erkennungsstufe
  gelesen.
- **AK-10** · Angenommen, mehrere Textzeilen liegen im Bereich, wenn das Ergebnis gebildet
  wird, dann sind sie durch Zeilenumbrüche getrennt, in der Reihenfolge, die Vision liefert.
- **AK-11** · Angenommen, das Ergebnisfenster ist offen, wenn zehn Sekunden vergehen, ohne
  dass der Zeiger darüber liegt, dann schließt es sich selbst.
- **AK-12** · Angenommen, der Zeiger liegt über dem Ergebnisfenster, wenn die zehn Sekunden
  ablaufen würden, dann bleibt es offen.
- **AK-13** · Angenommen, das Ergebnisfenster ist offen, wenn *Copy as Markdown* gedrückt
  wird, dann liegt der Text als Markdown-Codeblock in der Zwischenablage.

### Datenschutz und Missbrauchsschutz

Stufe A, Abschnitt 1 des Katalogs ausdrücklich in Kraft. **Dieses Feature liest fremde
Bildschirminhalte in Textform** — es kann Passwörter, Nachrichten und Gesundheitsdaten
erfassen, die zufällig im gewählten Rahmen liegen.

- **AK-14** · Angenommen, ein Bereich wird erkannt, wenn Vision arbeitet, dann geschieht
  das vollständig auf dem Gerät — kein Netzwerkaufruf, kein fremder Dienst.
- **AK-15** · Angenommen, ein Programm steht auf der Ausschlussliste, wenn ein Bereich
  darüber gezogen wird, dann ist dessen Inhalt nicht Teil des erkannten Textes.
- **AK-16** · Angenommen, Text wird erkannt, wenn der Vorgang abgeschlossen ist, dann steht
  weder der Text noch ein Teil davon in einem Protokoll.
- **AK-17** ⚠ · Angenommen, erkannter Text wird in die Zwischenablage gelegt, wenn auf dem
  Rechner die geräteübergreifende Zwischenablage aktiv ist, dann **überträgt macOS diesen
  Text an die anderen Apple-Geräte des Nutzers**.
  *(`CaptureEngine.swift:362` und `OCRResultPanel.swift:89` schreiben in die allgemeine
  Zwischenablage ohne die Markierung, mit der Passwortverwaltungen eine Übernahme
  unterbinden. Die Anwendung selbst überträgt nichts — der Systemdienst tut es. Das
  schränkt die Zusage aus `docs/prd.md` ein, wonach kein Byte den Rechner verlässt. Zur
  Klärung vorgelegt.)*
- **AK-18** · Angenommen, die Erkennung schlägt fehl, wenn der Fehler auftritt, dann
  erscheint bei Weg 1 eine Kurzmeldung.

*Abschnitt 4 (Rate Limits): trifft nicht zu — die Erkennung läuft lokal und kostet nichts.
Abschnitt 6 (Geheimnisse): trifft nicht zu.*

## Edge Cases

- **EC-01** · Bereich enthält Text in einer nicht eingestellten Sprache → wird meist
  fehlerhaft oder gar nicht erkannt, ohne Hinweis.
- **EC-02** · Sehr kleiner Bereich → Erkennung liefert leeres Ergebnis, siehe AK-05.
- **EC-03** · Sehr großer Bereich (ganzer Bildschirm) → Erkennung dauert spürbar; es gibt
  keine Fortschrittsanzeige.
- **EC-04** · Bereich enthält Text auf gemustertem Hintergrund → Erkennungsgüte sinkt, ohne
  dass ein Gütewert angezeigt wird (Vision liefert einen, er wird verworfen).
- **EC-05** · Editor-Weg schlägt fehl → nur ein `print()`, der Nutzer sieht nichts.
- **EC-06** · Mehrere Ergebnisfenster nacheinander → jedes hat seinen eigenen Zeitgeber.

## Fehlbestand

- **FB-01 · Leeres Ergebnis bleibt stumm.** Fundstelle: `CaptureEngine.swift:358`,
  `AnnotationEditor.swift:261`. Folge: Der häufigste Fall — der Nutzer trifft den Text
  knapp nicht — sieht aus wie ein Programmfehler.
- **FB-02 · Die beiden Wege verhalten sich unterschiedlich.** Fundstelle: Weg 1 kopiert
  automatisch (`CaptureEngine.swift:362`), Weg 2 nicht (`AnnotationEditor.swift:262`).
  Folge: Der Nutzer kann sich nicht darauf verlassen, dass der Text in der Zwischenablage
  liegt.
- **FB-03 · Der Erkennungs-Gütewert wird verworfen.** Fundstelle: `OCREngine.swift:26`
  nimmt nur `topCandidates(1).first?.string` und ignoriert die mitgelieferte Bewertung.
  Folge: Unsichere Erkennung ist von sicherer nicht unterscheidbar.
- **FB-04 · Die Sprachen sind fest verdrahtet.** Fundstelle: `OCREngine.swift:32`. Folge:
  Wer regelmäßig andere Sprachen liest, kann nichts daran ändern; die Einstellungen bieten
  dafür nichts an.
- **FB-05 · Fehler im Editor-Weg erreichen niemanden.** Fundstelle:
  `AnnotationEditor.swift:267` — ein `print()`. Teil des projektweiten Befunds FB-AS-03.
- **FB-06 · Die Zwischenablage ist nicht als vertraulich markiert.** Fundstellen:
  `CaptureEngine.swift:362`, `OCRResultPanel.swift:89` und `:98`. Folge: siehe AK-17. Der
  übliche Weg, dies zu unterbinden, ist ein zusätzlicher Eintrag im Zwischenablage-Element,
  den Passwortverwaltungen verwenden; er fehlt.
- **FB-07 · Keine Tests.** Die Erkennung ist mit einem bekannten Bild und erwartetem Text
  gut prüfbar — und wäre zugleich der Nachweis für die Wirksamkeit der Zensur in B04.

## Offene Fragen

- **OF-01** · Soll ein leeres Erkennungsergebnis gemeldet werden? — entscheidet der Autor.
- **OF-02** · Soll der Editor-Weg ebenfalls automatisch kopieren? — entscheidet der Autor.
- **OF-03** · Soll die Zwischenablage als vertraulich markiert werden, um die
  geräteübergreifende Übernahme zu unterbinden? — entscheidet der Autor. Betrifft auch B03
  (Bild) und B06 (Farbwert) und berührt eine Zusage im PRD.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Welche Texterkennung? | Apples Vision, auf dem Gerät | keine Netzwerkübertragung, keine Kosten, keine Abhängigkeit — passt zur Stufe A |
| 2 | Erkennungsstufe | `accurate` statt `fast` | Genauigkeit vor Geschwindigkeit; die Bereiche sind klein |
| 3 | Sprachkorrektur an | aus | verbessert zusammenhängenden Text, kann einzelne Zeichenfolgen wie Kennwörter verschlechtern |
| 4 | Drei Sprachen | Systemsprache übernehmen | **Grund nicht erkennbar** (FB-04) |
| 5 | Zwei Einstiegswege | nur einer | vom Bildschirm für Fremdinhalte, aus dem Editor für bereits Aufgenommenes |
| 6 | Selbstschließendes Ergebnisfenster nach 10 s | dauerhaft offen | es ist ein Zwischenergebnis, kein Dokument — Zeitgeber pausiert bei Mauskontakt |
| 7 | Automatisches Kopieren bei Weg 1 | erst auf Knopfdruck | erspart den zweiten Handgriff; die Abweichung in Weg 2 ist vermutlich unbeabsichtigt (FB-02) |
