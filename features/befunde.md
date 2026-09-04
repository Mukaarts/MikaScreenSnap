# Befunde — projektweit

Stand: 2026-09-03 · Quelle: Rückerfassung (`sdd-erfassen` Phase 2), QA der fünfzehn
Bestandsfeatures **und** QA von Feature `16` (2026-09-03)

> Die Einträge BF-01 bis BF-23 und BF-A1 bis BF-A15 stammen aus der Rückerfassung — sie
> entstanden beim **Lesen** des Codes. BF-24 und BF-25 stammen aus der QA, also aus dem
> **Ausführen**. Der Unterschied ist der Grund, warum beide Durchgänge nötig waren.

## Offen

### Aus der QA von Feature 16 (2026-09-03)

Alle fünf am **noch nicht ausgelieferten** Store-Build. Sie berühren den DMG-Vertrieb
nicht — das ist nachgewiesen (16/AK-38).

| ID | Feature | Befund | Grad | Fundstelle |
|---|---|---|---|---|

**Alle Codebefunde an Feature 16 sind behoben** (Stand Runde 3, 2026-09-03):
BF-26 (war *hoch*), BF-27, BF-28, BF-29, BF-30, BF-32, BF-33. Zwei davon — BF-26 und
BF-33 — sind per **Umkehrprobe** verifiziert: die Behebung wurde zurückgedreht, der
zugehörige Test fiel durch, nach Wiederherstellung war er grün.

**Das Muster über drei Runden, und warum es diesmal aufgehört hat.**
BF-26 war derselbe Fehlertyp wie in der Erfassung: *einmal behoben, an vier Stellen
stehengeblieben.* Seine Behebung erzeugte ihrerseits zwei neue Befunde — BF-32 und BF-33
waren **Folgen der Korrektur**, keine Altlasten: Dass die neue Klammer *meldet* und dass
Löschen dreierlei bedeuten kann (Ordner weg · Datei gelöscht · Datei war schon weg), wurde
nicht mitgedacht.

Runde 3 hat **keinen neuen Codebefund** gefunden. Der Unterschied war ein expliziter
Schritt vor der Behebung: aufzuschreiben, welche anderen Aufrufer sich mitändern. Die
beiden verbleibenden Befunde BF-34 und BF-35 liegen außerhalb des Codes.

**Kein offener Befund mehr an Feature 16.** BF-26 bis BF-30, BF-32 bis BF-36 sind alle
behoben; BF-36 zuletzt am 2026-09-03, indem die Zusage in `CHANGELOG.md` auf das
abgeschwächt wurde, was das Messprotokoll zu TE-07 hergibt.

**Was das nicht heißt.** Feature 16 ist damit **nicht abgenommen**: 26 seiner 53 Kriterien
und alle acht Randfälle konnten nie ausgeführt werden. Ein Feature ohne offenen Befund und
ein geprüftes Feature sind zwei verschiedene Dinge — die Befundliste sagt, was gefunden
wurde, nicht was geprüft werden konnte.

**BF-34 und BF-35 behoben am 2026-09-03** — BF-35 in zwei Schritten: `design.md` über
`/sdd-architektur 16`, `tasks.md` über `/sdd-tasks 16`. Die Abdeckung ist danach
ausführend geprüft: 53 von 53 Kriterien zugeordnet, keine Zeile verweist mehr auf eine
entfallene Aufgabe.

**BF-34 behoben am 2026-09-03** (Abschnitt *Mac App Store edition* in `CHANGELOG.md`).

**Das eigentliche Muster zeigt sich erst über vier Runden.** Runde 1 fand fünf Codefehler,
Runde 2 zwei Folgefehler ihrer Behebung, Runde 3 und 4 keinen einzigen im Code. Was seither
gefunden wird, sitzt **zwischen** den Artefakten:

| Befund | Was passierte |
|---|---|
| BF-35 | Eine Anforderungsänderung (OF-04) wurde in `spec.md` nachgezogen und im Code zurückgebaut — `design.md` und `tasks.md` blieben stehen |
| BF-36 | Eine Aussage wanderte vom Entwurf in die Versionshinweise und **verlor dabei ihren Vorbehalt** |

Beide Male hat kein Werkzeug versagt. `sdd-build` darf `design.md` nicht ändern, `sdd-qa`
auch nicht, und keiner der Skills liest beim Schreiben eines Texts nach, welche
Einschränkung an der Quelle stand. **Der Kette fehlt die Stelle, die nach einer Änderung
prüft, was sonst noch davon abhängt** — bei Artefakten wie bei Aussagen.

Für ein Projekt, dessen aufschlussreichster Befund aus der Erfassung lautete *„ein Fehler
wurde einmal behoben und blieb an drei anderen Stellen stehen"*, ist das dieselbe Lücke
eine Ebene höher.

### Nebenbefund an einem Bestandsfeature

| ID | Feature | Befund | Grad | Fundstelle |
|---|---|---|---|---|
| BF-31 | B14, B11 | Die installierte Fassung trägt `SUFeedURL = …/Mukaarts/…` in den Einstellungen, während `Resources/Info.plist` `…/daumedia/…` nennt. Sparkle bevorzugt den Wert aus `UserDefaults` — **diese Installation prüft gegen ein anderes Repository als das im Code hinterlegte.** Keiner der `SU*`-Schlüssel steht in `ownedDefaultsKeys`, sie überleben also „Reset All Preferences" | **zu bewerten** | `Resources/Info.plist:31` gegen die installierte Einstellungsdatei |

BF-31 stammt nicht aus einer Prüfung von B14, sondern fiel beim Sichern der Nutzerdaten
für Feature 16 auf.

**Nachgemessen am 2026-09-03:** Beide Adressen antworten mit `200`, und die beiden
`appcast.xml` sind **byte-identisch** (`9b445e7b…`). Die installierte Fassung bekommt also
dieselben Updates wie jede andere — akute Gefahr besteht nicht. **Was bleibt, ist eine
dritte Pflegestelle, die nirgends dokumentiert ist:** `docs/prd.md` kennt unter OF-03 nur
die Doppelpflege `main`/`master` innerhalb von `daumedia`, nicht das zweite Repository.
**Entschieden am 2026-09-03 (PRD/OF-10): `Mukaarts` läuft aus.** Dabei ist ein Detail
entscheidend, das die Entscheidung sonst in ihr Gegenteil verkehrt: **Sparkle bevorzugt
`SUFeedURL` aus `UserDefaults` gegenüber `Info.plist`, und die Anwendung löscht diesen
Schlüssel nirgends** — nachgeprüft, im gesamten `Sources/` kommt er nicht vor. Wer also nur
aufhört, nach `Mukaarts` zu pushen, leitet die betroffenen Installationen nicht um, sondern
**schneidet sie ab**.

Die Reihenfolge muss deshalb lauten:

1. Ein Update über `Mukaarts` veröffentlichen, das beim Start `SUFeedURL` aus den
   Einstellungen entfernt — danach greift wieder `Info.plist` mit `daumedia`.
2. Erst wenn diese Fassung verbreitet ist, `Mukaarts` einfrieren.

Schritt 1 ist eine Codeänderung an **B14**, nicht an Feature 16. Sie gehört zusammen mit
der fehlenden Aufnahme der `SU*`-Schlüssel in `ownedDefaultsKeys` in ein eigenes Feature,
das auf B14 verweist.

### Weiterhin offene Nachweise aus der QA der Bestandsfeatures

**Keine Befunde dort.** Aber: Die QA konnte 145 von 269 Kriterien nicht
ausführen, weil sie Oberflächenverhalten, eine erteilte Bildschirmaufnahme-Berechtigung
oder ein zweites Display brauchen. Sie stehen in den Testberichten unter *nicht prüfbar* —
ausdrücklich **nicht** unter *bestanden*.

Die vier wichtigsten, die vor der Auslieferung manuell zu durchlaufen sind:

| Prüfung | Feature | Warum sie zählt |
|---|---|---|
| Ausgeschlossenes Programm in allen sechs Aufnahmewegen | B02/AK-03 | die einzige Zugriffsregel der Anwendung; einer der sechs Wege, der doch etwas zeigt, ist ein Datenleck |
| Ein Tastendruck nach zweimaliger Neubelegung | B10/AK-08 | der behobene Vervielfachungsfehler — zählbar, aber nur mit echtem Tastendruck |
| Erstkontakt auf einem frischen Benutzerkonto | B12/AK-15 | steht die Anwendung nach *Grant Access* in der Systemliste? Vor 3.5.0 nicht |
| Manipulierte Update-Signatur wird abgelehnt | B14/AK-05 | der einzige Weg, auf dem fremder Code auf den Rechner kommt |

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
| BF-24 | B14 | **Aus der QA:** Sparkles Controller wurde beim Programmstart sofort erzeugt und greift dabei nach dem umgebenden Programmpaket. In jeder Umgebung ohne Bundle blockiert das — der Testlauf hing daran, bis er abgebrochen wurde | mittel | `AppState.init` | 2026-08-25 |
| BF-25 | B08 | **Aus der QA:** Der Ablageort angehefteter Bilder war fest verdrahtet, sodass ein Test zwangsläufig in die echten Daten des Nutzers geschrieben hätte | niedrig | `PinnedScreenshotManager.persistenceDir` | 2026-08-25 |

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

- **Was beim Start sofort erzeugt wird, muss überall erzeugbar sein.** BF-24 kam erst
  heraus, als der Testlauf hing: Sparkle griff im Initialisierer nach einem Programmpaket,
  das es in einem Testprozess nicht gibt. Träge Erzeugung löst es und spart nebenbei
  Startzeit.

Für den Betrieb (`sdd-betrieb`) folgt daraus: Der wirksamste Hebel dieses Projekts ist
nicht mehr Sorgfalt im Einzelfall, sondern **Tests für alles, was rechnet**, und **ein
Blick auf die Dokumentation bei jedem Umbau**.

## Was die QA nicht leisten konnte

Von 269 Akzeptanzkriterien über 15 Features waren **124 ausführbar** und sind bestanden;
**145 sind als nicht prüfbar ausgewiesen**. Durchgefallen ist keines. Das Verhältnis ist kein Mangel des Berichts,
sondern die Lage einer macOS-Anwendung: Mausereignisse, Fensterlebenszyklen,
Systemberechtigungen und Mehrschirmanordnungen lassen sich ohne Bedienung nicht nachweisen.

Das Stack-Profil sieht dafür Screenshots und Bildschirmaufnahmen als gültigen Nachweis vor.
Diese Belege fehlen und sind der Grund, warum jeder Testbericht mit einer benannten
manuellen Auflage endet statt mit einem pauschalen „bestanden".
