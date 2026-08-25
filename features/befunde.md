# Befunde — projektweit

Stand: 2026-08-25 · Quelle: **die Rückerfassung** (`sdd-erfassen` Phase 2), nicht QA-Berichte

> Abweichung vom Regelfall: Diese Liste wird sonst von `sdd-qa` aus den `qa-report.md`
> fortgeschrieben. Hier stammen die Einträge aus der Rückerfassung selbst — sie entstanden
> beim Lesen des Codes, bevor je eine QA lief. Sobald `sdd-qa` läuft, schreibt sie hier
> weiter; die Herkunft bleibt an der Spalte *Gefunden von* erkennbar.

## Offen

Keine. Alle 89 Einträge aus den Feature-Specs sind entweder behoben oder mit Begründung
und Datum akzeptiert.

## Behoben

Ausgeliefert mit **3.5.0**. Die Reihenfolge folgt dem Schweregrad.

| ID | Feature | Befund | Grad | Fundstelle | Behoben |
|---|---|---|---|---|---|
| BF-01 | B04, B09 | Auto-Save schrieb vor dem Editor, also immer das unzensierte Original — eine Zensur schützte nur das Weitergegebene | hoch | `CaptureEngine.postCapture` | 2026-08-25 |
| BF-02 | B08 | Angeheftete Bilder wurden nie gelöscht; geschlossene kehrten beim Start zurück, weil alphabetisch die ältesten wiederhergestellt wurden | hoch | `PinnedScreenshotManager` | 2026-08-25 |
| BF-03 | B10, B11 | Ereignisbehandler wurden bei jeder Neuanmeldung erneut installiert — nach *n* Änderungen löste ein Tastendruck *n+1* Aufnahmen aus | hoch | `HotkeyManager.registerHotkeys` | 2026-08-25 |
| BF-04 | B01 | Vollbild und Bereich rechneten gegen `displays.first`; die Skalierung kam aus `NSScreen.main` bzw. einem festen Faktor 2 | mittel | `CaptureEngine` | 2026-08-25 |
| BF-05 | B03, B09 | Dateinamen mit Sekundengenauigkeit, Schreiben ohne Prüfung — zwei Aufnahmen in derselben Sekunde ergaben eine Datei | mittel | `AppPreferences.saveImage` | 2026-08-25 |
| BF-06 | B03, B05, B08, B09, B13 | Sechs `print()` in Fehlerpfaden, die in einem Programm ohne Dock-Symbol niemanden erreichen | mittel | mehrere | 2026-08-25 |
| BF-07 | B12, B15 | Die Berechtigung wurde nie angefordert, beim Erststart nicht einmal angestoßen | mittel | `PermissionScreen`, `AppDelegate` | 2026-08-25 |
| BF-08 | B04 | Weichzeichnen ohne Kantenfortsetzung; Zensurstärke unabhängig von der Bildauflösung | mittel | `AnnotationModels` | 2026-08-25 |
| BF-09 | B11, B12 | Vier Einstellungsschlüssel ohne jeden Leser | mittel | `AppPreferences` | 2026-08-25 |
| BF-10 | B06 | Palette wurde befüllt und nirgends angezeigt; Farbverlauf überstand das Zurücksetzen | mittel | `ColorHistoryManager` | 2026-08-25 |
| BF-11 | B03 | `⌘S` sicherte auf den Schreibtisch, immer als PNG, und überschrieb die Zwischenablage | mittel | `AnnotationEditor.save` | 2026-08-25 |
| BF-12 | B11 | README und CHANGELOG beschrieben die Einstellungen als dunkel und markenfarben | mittel | `README.md` | 2026-08-25 |
| BF-13 | B05 | Leeres OCR-Ergebnis blieb stumm; die beiden OCR-Wege verhielten sich unterschiedlich | mittel | `CaptureEngine`, `AnnotationEditor` | 2026-08-25 |
| BF-14 | B02 | Nur laufende Programme waren ausschließbar | mittel | `ExcludedAppsManager` | 2026-08-25 |
| BF-15 | B14 | `canCheckForUpdates` war toter Code; keine Delegates, also konnte ein Update ungesicherte Anmerkungen vernichten | mittel | `SparkleUpdater` | 2026-08-25 |
| BF-16 | B08, B11 | Die Speicherverwaltung kannte nur einen von zwei Ablageorten | mittel | `AdvancedTabView` | 2026-08-25 |
| BF-17 | B09 | `clearAll()` löschte nur, was beim Start eingelesen wurde; die Speichergröße ließ Vorschaubilder aus | niedrig | `ScreenshotHistoryManager` | 2026-08-25 |
| BF-18 | B07 | Leertaste doppelt belegt — Einheitenwechsel und Verschieben lösten gemeinsam aus | niedrig | `MeasurementTool` | 2026-08-25 |
| BF-19 | B11 | Standard-Strichstärke 3 stand nicht zur Auswahl (2/4/6) | niedrig | `AppPreferences` | 2026-08-25 |
| BF-20 | B12 | Anmeldestart war vorangekreuzt und wurde bei Abbruch dennoch nicht gesetzt | niedrig | `ShortcutsScreen` | 2026-08-25 |
| BF-21 | B13 | Fehlschlag beim Anmeldestart blieb unsichtbar, der Schalter zeigte den falschen Zustand | niedrig | `LaunchAtLoginManager` | 2026-08-25 |
| BF-22 | B07, B01 | `startMeasurement(appState:)` ignorierte seinen Parameter; der Controller wurde nie freigegeben | niedrig | `CaptureEngine` | 2026-08-25 |
| BF-23 | projektweit | Keine Tests — die Fehlerklasse aus BF-04 wäre prüfbar gewesen | mittel | `Tests/` fehlte | 2026-08-25 |

## Akzeptiert

Bewusst nicht behoben. Ohne Begründung und Datum ist ein Befund nicht akzeptiert, sondern
vergessen.

| ID | Feature | Befund | Grad | Begründung | Beschlossen |
|---|---|---|---|---|---|
| BF-A1 | B03, B06 | Die Zwischenablage trägt für **Bilder** keine Vertraulichkeitskennzeichnung, sodass die geräteübergreifende Zwischenablage sie an andere Geräte trägt | mittel | macOS kennt eine solche Kennzeichnung nur für Text — dort wird sie gesetzt (B05). Für Bilder gibt es keinen Weg, das von der Anwendung aus zu unterbinden. Im PRD als Einschränkung der Datenschutzzusage ausgewiesen | 2026-08-25 |
| BF-A2 | B02 | Der Ausschluss ist für den Nutzer nicht nachprüfbar | mittel | Eine Anzeige „hier wurde etwas ausgelassen" wäre irreführend: Ein Fenster kann auch fehlen, weil es nicht offen war. Der Ausschluss greift dort, wo er wirkt — als Filter an ScreenCaptureKit, bevor das Bild entsteht | 2026-08-25 |
| BF-A3 | B10 | Fehlgeschlagene Anmeldung einer Tastenkombination bleibt in der Oberfläche unsichtbar; Konflikte mit fremden Programmen werden nicht erkannt | mittel | macOS stellt keine Abfrage bereit, über die sich fremde Belegungen feststellen ließen. Jede Anzeige wäre geraten; der Fehler steht in der Konsole | 2026-08-25 |
| BF-A4 | B14 | Der Feed älterer Installationen zeigt auf `master`, ohne absehbares Ende | niedrig | Die Adresse ist in ausgelieferte Programmpakete kompiliert. Ein Ende wäre nur über eine Zählung der Installationen begründbar — und die soll es nicht geben, weil die Anwendung keine Nutzungsdaten erhebt | 2026-08-25 |
| BF-A5 | B06 | Die Lupe zeigt einen eingefrorenen Bildschirm | niedrig | Sie zeichnet bei jeder Mausbewegung neu; fortlaufendes Neulesen würde ruckeln und den gesamten Bildschirminhalt dauernd erneuern | 2026-08-25 |
| BF-A6 | B09 | Der Verlauf wird beim Start vollständig und synchron eingelesen | niedrig | Das Verzeichnis **ist** das Datenmodell; ein Index könnte von der Wirklichkeit abweichen. Ein Zwischenspeicher wäre ein eigenes Feature | 2026-08-25 |
| BF-A7 | B09 | Endgültiges Löschen statt Papierkorb; kein automatisches Aufräumen | niedrig | Beides ist beabsichtigt: Löschen soll löschen, und eine automatische Bereinigung würde Aufnahmen entfernen, die noch gebraucht werden | 2026-08-25 |
| BF-A8 | B08 | Position, Größe und Deckkraft angehefteter Bilder überleben keinen Neustart | niedrig | Ein angehefteter Screenshot ist ein Arbeitsmittel für den Moment | 2026-08-25 |
| BF-A9 | B03 | Kein bearbeitbarer Projektstand; `AnnotationSnapshot.data` untypisiert | niedrig | Der Editor ist ein Durchgangsschritt. Neun typisierte Momentaufnahmen für einen rein internen Pfad wären Aufwand ohne Ertrag | 2026-08-25 |
| BF-A10 | B12 | Jedes Schließen des Einrichtungsablaufs gilt als Abschluss | niedrig | Ein Ablauf, der nach `Escape` wiederkommt, ist aufdringlich. Der Schutz liegt im dauerhaften Menühinweis und den gesperrten Aufnahmeeinträgen | 2026-08-25 |
| BF-A11 | B05 | Erkennungsgüte wird verworfen; die Sprachen sind fest | niedrig | Der Nutzer sieht den Text und beurteilt ihn selbst; drei Sprachen decken den Bedarf | 2026-08-25 |
| BF-A12 | B07 | Zwei getrennte Implementierungen des Messens | niedrig | Overlay und Editorwerkzeug arbeiten in verschiedenen Koordinatenräumen; ein gemeinsamer Kern kostete mehr als die Dopplung | 2026-08-25 |
| BF-A13 | B11 | Sparkles eigene Einstellungen überstehen *Reset All Preferences* | niedrig | Sie gehören dem Rahmenwerk; in fremde Schlüssel zu greifen, deren Namen sich ändern können, wäre unsicherer als sie stehen zu lassen | 2026-08-25 |
| BF-A14 | B15 | Kein Verweis auf das Projekt aus der Anwendung heraus | niedrig | Das Menü trägt bereits fünfzehn Einträge; wer die Anwendung bezogen hat, kennt die Quelle | 2026-08-25 |
| BF-A15 | projektweit | Keine Schemaversion in den Benutzereinstellungen | niedrig | Kein Formatwechsel steht an. Die Rücksetzliste ist zentralisiert und getestet, was den häufigsten Fehlerfall abdeckt | 2026-08-25 |

## Muster

Was in mehreren Features zugleich auftrat — der eigentliche Ertrag der Vollerfassung.

- **Ein Fehler wurde einmal behoben und blieb an drei anderen Stellen stehen.** 3.4.1
  korrigierte die Displaywahl und die Skalierung für Fensteraufnahmen; Vollbild, Bereich
  und Texterkennung behielten `displays.first` und `NSScreen.main`. Die Anwendung besaß mit
  `ScreenGeometry` sogar die richtige Umrechnung — sie wurde nur an einer Stelle benutzt
  (BF-04). **Ursache: keine Tests.** Ein Test über die Koordinatenrechnung hätte alle vier
  Stellen zugleich erfasst; er existiert jetzt.
- **Fehlerpfade endeten in `print()`.** Sechs Stellen, alle nach demselben Muster, alle
  wirkungslos in einem Programm ohne Dock-Symbol (BF-06). 3.4.1 hatte das für den
  Aufnahmepfad bereits erkannt und `CaptureLog` eingeführt — die übrigen Pfade wurden nicht
  mitgezogen.
- **Einstellungen ohne Gegenstück.** Vier Schlüssel wurden gespeichert, geladen,
  zurückgesetzt und angeboten, ohne dass irgendetwas sie las (BF-09). Ein Schalter ist
  schnell gebaut, das Verhalten dahinter nicht.
- **Schreiben ohne Löschen.** Zwei Ablageorte wuchsen unbegrenzt, weil jeder Schreibpfad
  ein Gegenstück brauchte, das niemand gebaut hatte (BF-01, BF-02).
- **Die Dokumentation lief dem Code hinterher.** Drei Stellen beschrieben Verhalten, das es
  nicht mehr gab (BF-12, BF-15) oder nie so gegeben hatte (BF-10). Alle drei entstanden bei
  Umbauten, bei denen der Text nicht mitgezogen wurde.

Für den Betrieb (`sdd-betrieb`) folgt daraus: Der wirksamste Hebel dieses Projekts ist
nicht mehr Sorgfalt im Einzelfall, sondern **Tests für alles, was rechnet**, und **ein
Blick auf die Dokumentation bei jedem Umbau**.
