# B05 · Bildschirmtext erfassen (OCR) — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde bearbeitet in 3.5.0**

> Beschrieben ist, **was der Code tut**. Alle drei markierten Kriterien sind bearbeitet.

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
- **AK-05** · Angenommen, im gewählten Bereich ist **kein** Text zu erkennen, wenn die
  Erkennung fertig ist, dann erscheint die Kurzmeldung „No text found in selection".

### Weg 2 — im Editor

- **AK-06** · Angenommen, der Editor ist offen, wenn *Extract Text* in der Werkzeugleiste
  gewählt wird, dann wechselt der Editor in einen Auswahlmodus mit sichtbarer Rückmeldung.
- **AK-07** · Angenommen, der Auswahlmodus ist aktiv, wenn ein Bereich gezogen wird, dann
  erscheint dasselbe Ergebnisfenster wie bei Weg 1.
- **AK-08** · Angenommen, Text wird im Editor erkannt, wenn das Fenster erscheint, dann
  liegt der Text **ebenso in der Zwischenablage** wie bei Weg 1 — beide Wege verhalten sich
  gleich.

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
- **AK-17** · Angenommen, erkannter Text wird in die Zwischenablage gelegt, wenn das
  geschieht, dann trägt der Eintrag zusätzlich die Kennzeichnung
  `org.nspasteboard.ConcealedType`, an der Zwischenablage-Verwaltungen und Verlaufswerkzeuge
  erkennen, dass sie ihn nicht aufbewahren sollen — dieselbe Kennzeichnung, die
  Passwortverwaltungen setzen.
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

## Befunde

### Behoben

- **FB-01 · Leeres Ergebnis blieb stumm** — behoben 2026-08-25 in beiden Wegen.
- **FB-02 · Die beiden Wege verhielten sich unterschiedlich** — behoben 2026-08-25: Der
  Editor-Weg kopiert ebenfalls.
- **FB-05 · Fehler im Editor-Weg erreichten niemanden** — behoben 2026-08-25 über
  `CaptureLog`.
- **FB-06 · Die Zwischenablage war nicht als vertraulich markiert** — behoben 2026-08-25
  über `ClipboardManager.copyToClipboard(text:concealed:)`.

### Akzeptiert

- **BF-03 · Der Erkennungs-Gütewert wird verworfen** — akzeptiert 2026-08-25. Der Nutzer
  sieht den erkannten Text im Ergebnisfenster und beurteilt ihn selbst; ein Zahlenwert
  daneben würde eine Genauigkeit suggerieren, die er nicht hat.
- **BF-04 · Die Sprachen sind fest verdrahtet** — akzeptiert 2026-08-25. Deutsch, Englisch
  und Französisch decken den Bedarf des Autors; eine Spracheinstellung wäre ein Feature mit
  eigener Nummer.
- **BF-07 · Keine Tests** — akzeptiert 2026-08-25. Die Erkennung selbst ist Apples Vision,
  und ein Test darüber prüfte deren Güte, nicht diesen Code. Als Messwerkzeug für die
  Wirksamkeit der Zensur (B04) bleibt sie in der QA vorgesehen.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Leeres Ergebnis melden? | ja, als Kurzmeldung in beiden Wegen | 2026-08-25 |
| OF-02 · Editor-Weg ebenfalls kopieren? | ja — zwei Wege desselben Features dürfen sich nicht unterschiedlich verhalten | 2026-08-25 |
| OF-03 · Zwischenablage als vertraulich kennzeichnen? | ja für Text. Für Bilder gibt es keine entsprechende Kennzeichnung (B03/BF-07); das PRD weist die Einschränkung aus | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Welche Texterkennung? | Apples Vision, auf dem Gerät | keine Netzwerkübertragung, keine Kosten, keine Abhängigkeit — passt zur Stufe A |
| 2 | Erkennungsstufe | `accurate` statt `fast` | Genauigkeit vor Geschwindigkeit; die Bereiche sind klein |
| 3 | Sprachkorrektur an | aus | verbessert zusammenhängenden Text, kann einzelne Zeichenfolgen wie Kennwörter verschlechtern |
| 4 | Drei Sprachen | Systemsprache übernehmen | **Grund nicht erkennbar** (FB-04) |
| 5 | Zwei Einstiegswege | nur einer | vom Bildschirm für Fremdinhalte, aus dem Editor für bereits Aufgenommenes |
| 6 | Selbstschließendes Ergebnisfenster nach 10 s | dauerhaft offen | es ist ein Zwischenergebnis, kein Dokument — Zeitgeber pausiert bei Mauskontakt |
| 7 | Automatisches Kopieren in beiden Wegen (3.5.0) | erst auf Knopfdruck | erspart den zweiten Handgriff — und die frühere Abweichung zwischen den Wegen war für niemanden vorhersehbar |
| 8 | Zwischenablage als vertraulich gekennzeichnet (3.5.0) | ohne Kennzeichnung | erkannter Text kann ein Passwort sein, das zufällig im Rahmen lag |
