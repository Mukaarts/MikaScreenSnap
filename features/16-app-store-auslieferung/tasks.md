# 16 · App-Store-Auslieferung — Aufgabenplan

Status: `tasked` · Stand: 2026-09-03

Ebenen laufen in Reihenfolge. `[P]` heißt: innerhalb dieser Ebene unabhängig von den
anderen `[P]`-Aufgaben, darf parallel an einen Subagenten gehen.

Nach jeder Ebene läuft die Verifikation. **Rot heißt anhalten.**

```bash
swift build 2>&1 | tail -20
swift test
```

**Die Store-Ausgabe übersetzt erst ab Ebene 3.** Ursprünglich stand hier
`MIKA_APPSTORE=1 swift build` ab Ebene 1 — das war ein Fehler im Plan, festgestellt beim
Bauen am 2026-09-03: Sobald T02 die Sparkle-Abhängigkeit fallen lässt, scheitert
`SparkleUpdater.swift` am fehlenden Modul, und das lässt sich erst durch T08 und T13
auflösen. Die Fehlermeldung *ist* der Nachweis, dass T02 wirkt. Ab Ebene 3 gilt:

```bash
MIKA_APPSTORE=1 swift build 2>&1 | tail -20    # beide Ausgaben müssen übersetzen
MIKA_APPSTORE=1 swift test
```

> **T01 steht bewusst vor allem anderen.** Der Entwurf weigert sich, das Verhalten der
> Container-Übernahme anzunehmen (TE-07). Solange T01 nicht beantwortet ist, ist die
> Reichweite von T09 und T10 unbekannt — und ein Umzug, der stillschweigend die
> Tastenkürzel verliert, fällt erst dem Nutzer auf.

## Ebene 1 · Fundament — Build-Konfiguration und Ablage

- [x] **T01** `[P]` · Verhalten der Container-Übernahme feststellen: eine unsandboxed
      Installation mit belegten Einstellungen anlegen, dieselbe Bundle-ID sandboxed
      starten, prüfen ob `UserDefaults` im Container ankommt. Ergebnis als Absatz in
      `design.md` unter TE-07 nachtragen — `Grundlage für T09, T10`
- [x] **T02** `[P]` · `Package.swift`: Sparkle-Abhängigkeit nur aufnehmen, wenn die
      Umgebungsvariable `MIKA_APPSTORE` fehlt; im Store-Fall das Übersetzungsmerkmal
      `APPSTORE` setzen — `AK-04, AK-36`
- [x] **T03** `[P]` · `Resources/MikaScreenSnap-AppStore.entitlements` anlegen: Sandbox,
      `files.user-selected.read-write`, `files.bookmarks.app-scope`. **Ohne**
      `screen-capture`, **ohne** `disable-library-validation`, ohne jede
      `temporary-exception` — `AK-01, AK-02, AK-53`
- [x] **T04** `[P]` · Store-Fassung der `Info.plist` ohne `SUFeedURL` und `SUPublicEDKey`,
      Version aus derselben Quelle wie der DMG-Build — `AK-05, AK-37`
- [x] **T05** `[P]` · `saveLocationBookmark` und `migrationOffered` in `AppPreferences`
      anlegen und in `ownedDefaultsKeys` eintragen. Beim Zurücksetzen wird das Lesezeichen
      gelöscht, `migrationOffered` bleibt — mit Kommentar, warum das keine Nachlässigkeit
      ist — `AK-22`
- [x] **T06** · `scripts/build-appstore.sh`: baut mit `MIKA_APPSTORE=1`, setzt die
      Store-Entitlements und die Store-`Info.plist`, bettet **kein** Sparkle-Framework
      ein — `AK-01, AK-03, AK-04`

## Ebene 2 · Logik

- [x] **T07** `[P]` · `SaveLocationStore`: Ordner als Lesezeichen ablegen und auflösen,
      Zugriff je Schreibvorgang öffnen und wieder schließen, Fehlerzustände für
      verschwundenen und schreibgeschützten Ordner über `CaptureLog.report` —
      `AK-27, AK-28, AK-30`
- [x] **T08** `[P]` · `UpdateChannel` als gemeinsame Schnittstelle, dazu
      `SparkleUpdateChannel` (umschließt den bestehenden `SparkleUpdater`) und
      `AppStoreUpdateChannel` (meldet „keine Bedienelemente"), je hinter `APPSTORE`
      getrennt — `AK-23, AK-24, AK-25`
- [x] ~~**T09**~~ **entfällt (OF-04, 2026-09-03)** — gebaut, aber nicht mehr gebraucht. Ursprünglich: `MigrationImporter`, Erkennung: findet angeheftete Bilder einer
      Vorgängerinstallation und meldet, wie viele übernehmbar sind. **Zuschnitt nach
      T01 verkleinert:** Einstellungen wandern von selbst, nur Bilder brauchen den
      Importer — `AK-31, AK-34`
- [x] ~~**T10**~~ **entfällt (OF-04, 2026-09-03)** — gebaut, aber nicht mehr gebraucht. Ursprünglich: `MigrationImporter`, Übernahme: kopiert die angehefteten Bilder in den
      Container — kopiert, verschiebt nicht. Jede Datei einzeln prüfen und
      Unlesbares überspringen, statt der Ablage als Ganzes zu vertrauen. **Nach T01
      ohne Einstellungen** — `AK-32, AK-35`
- [x] **T11** `[P]` · `ExcludedAppsManager` auf Sandbox-Verträglichkeit prüfen:
      `urlForApplication(withBundleIdentifier:)` und das Laden der App-Symbole
      (`Sources/ExcludedAppsManager.swift:71`). Bricht etwas, hier reparieren — die
      Ausschlussliste ist die einzige Zugriffsregel der Anwendung — `AK-09, AK-10`

## Ebene 3 · Anbindung

Diese Ebene läuft **vollständig seriell.** Alle drei Aufgaben fassen
`Sources/MikaScreenSnapApp.swift` an; parallel gesetzt würden sie einander überschreiben.

- [x] **T12** · Schreibpfade auf `SaveLocationStore` umstellen: automatisches Sichern,
      Export aus dem Editor, Verlaufsanzeige und „Im Finder zeigen". Der Ersetzungspfad
      aus 3.5.0 — gesicherte Datei wird bei Export und Zensur ersetzt — bleibt
      erhalten — `AK-12, AK-18`
- [x] **T13** · `AppState` und die vier Aufrufstellen auf `UpdateChannel` umstellen
      (`MikaScreenSnapApp.swift`, `AdvancedTabView`, `PreferencesContainerView`,
      `PreferencesWindowController`). Der DMG-Build muss sich danach exakt wie vorher
      verhalten — `AK-23, AK-38`
- [x] ~~**T14**~~ **entfällt (OF-04, 2026-09-03).** Es gibt keine Übernahme-Abfrage mehr;
      AK-32 und AK-33 sind neu gefasst und verlangen ausdrücklich, dass **nicht** gefragt
      wird — `AK-32, AK-33`

## Ebene 4 · Oberfläche

- [x] **T15** `[P]` · `SaveLocationScreen` mit vier Zuständen (kein Ordner gewählt ·
      Ordner nicht beschreibbar · gewählt · „Weiter" gesperrt bis zur Wahl), eingehängt
      nach der Berechtigungsseite — `AK-26`
- [x] ~~**T16**~~ **entfällt (OF-04, 2026-09-03).** Kein `MigrationPrompt`; AK-31 wird
      durch die Container-Übernahme von macOS erfüllt, nicht durch Code — `AK-31`
- [x] **T17** `[P]` · `AdvancedTabView`: Update-Bereich im Store-Build durch den Hinweis
      auf den App Store ersetzt; Speicherort als Ordnerwahl mit Warnzustand für einen
      verschwundenen Ordner — `AK-23, AK-24, AK-29`
- [x] **T18** `[P]` · Menüeintrag „Check for Updates…" entfällt im Store-Build — `AK-21`

## Ebene 5 · Feinschliff

- [ ] **T19** · Randfälle Speicherort: abgebrochene Wahl in der Einrichtung, externes
      Volume nicht angeschlossen, schreibgeschützter Ordner, Container selbst gewählt —
      `EC-01, EC-02, EC-03, EC-04`
- [ ] **T20** · Randfälle Umzug, **verkleinert durch OF-04**: EC-05 entfällt (es werden
      keine Einstellungen mehr gelesen, die beschädigt sein könnten). Bleiben:
      Installation über eine laufende DMG-Fassung, Rückkehr zum DMG nach dem Wechsel —
      `EC-06, EC-07`
- [x] **T21** `[P]` · Tests in `Tests/`: Lesezeichen auflösen und ins Leere laufen lassen,
      `MigrationImporter` gegen vorbereitete Ordner (vollständig, leer, beschädigt), die
      beiden neuen Schlüssel in `ownedDefaultsKeys` — `AK-39`
- [ ] **T22** `[P]` · Protokolle der neuen Pfade prüfen: Ordnerpfade dürfen hinein,
      Dateinamen mit erkennbarem Bildinhalt nicht — `AK-45`
- [x] **T23** `[P]` · `web/app/privacy/page.tsx`: Absatz über die Erhebung durch Apple bei
      Store-Installation, ohne die Zusage der Anwendung selbst aufzuweichen — `AK-46`
- [x] **T24** `[P]` · Beispieldatei und Anleitung für Verteilungszertifikat und
      Upload-Schlüssel neben dem Paketierungsskript. Gegenprobe mit `git log -p`, dass
      nichts Echtes je im Repository lag — `AK-49, AK-50`
- [ ] **T25** · Netzwerkverkehr des Store-Builds über eine Stunde Benutzung beobachten:
      keine ausgehende Verbindung, insbesondere keine zu `raw.githubusercontent.com` —
      `AK-25, AK-48`
- [ ] **T26** · Regressionsdurchlauf unter Sandbox, jedes Bestandsfeature einzeln:
      drei Aufnahmeformen, elf Werkzeuge, Zensur, OCR, Farbpipette, Lineal, Anheften über
      Neustart, sieben Tastenkombinationen nach dreimaliger Neubelegung, Start bei
      Anmeldung, Menüleisten-Hub. Dazu der Entzug der Aufnahmeberechtigung im
      laufenden Betrieb: Aufnahmeeinträge gesperrt, Ersteinrichtung führt erneut
      durch die Berechtigung — `AK-06, AK-07, AK-08, AK-09, AK-10, AK-11, AK-13, AK-14, AK-15, AK-16, AK-17, AK-19, AK-20, EC-09`

### Nach der Entscheidung zu OF-04 entstanden

Diese drei Aufgaben gab es im ursprünglichen Plan nicht. Sie bilden ab, wie AK-31 bis
AK-35 seit dem Wegfall des Umzugs tatsächlich erfüllt werden — ohne sie stünden die
Kriterien ohne Aufgabe da, und genau das war BF-35.

- [x] **T31** · Rückbau des Umzugs: `MigrationImporter`, `migrationOffered` und die
      zugehörigen Tests entfernt. Erfüllt AK-32, AK-34 und AK-35 durch **Abwesenheit** —
      es gibt keinen Baustein mehr, der fragen könnte, und keinen Schreibpfad auf die
      Altablagen — `AK-32, AK-34, AK-35`
- [x] **T32** · Abschnitt *Mac App Store edition* in `CHANGELOG.md`: nennt den Store,
      benennt das Fehlen der angehefteten Bilder als erwartet und sagt, wo die Originale
      liegen — `AK-33`
- [x] **T33** · Die Zusage *Your settings come with you* in `CHANGELOG.md` auf das
      abschwächen, was belegt ist. **Entschieden am 2026-09-03:** abschwächen statt T28
      vorziehen — der Nachweis hängt an Zertifikaten, die es noch nicht gibt, und bis dahin
      stünde eine unbelegte Zusage im Text. Wenn T28 später Gewissheit bringt, kann die
      Einschränkung wieder heraus. Dabei ist auch der Zählfehler *the two differences below*
      zu berichtigen (H-04) — **Aus BF-36** — `AK-31`
- [x] **T35** · `LegacyDefaultsImport`: liest beim ersten Start unter der neuen Kennung die
      Domain `com.mika.mikaplusscreensnap` und übernimmt Tastenkürzel, Ausschlussliste,
      Zeichen-Standards und Speicherort. **Nur im DMG-Build** — im Store-Build gar nicht
      erst übersetzt. Kopiert, löscht nichts; ein zweiter Start übernimmt nicht erneut —
      `AK-31, AK-54`
- [x] **T36** · Ersteinrichtung erneut auslösen, wenn die Aufnahmeberechtigung fehlt,
      obwohl sie als abgeschlossen gilt. Nutzt den Ablauf aus B12 mit neuer
      Auslösebedingung — `AK-55`
- [ ] **T34** · Version auf **3.6.0** anheben: `Resources/Info.plist` (beide Ausgaben lesen
      daraus, AK-37) und die Überschrift `[Unreleased]` in `CHANGELOG.md`. **Entschieden am
      2026-09-03.** Erst nach der Auslieferung von 3.5.0 als DMG — `AK-37`

### Einreichung — braucht OF-07

- [ ] **T27** · `scripts/package-appstore.sh`: Signatur mit der Verteilungsidentität,
      Paket über `productbuild` mit der Installer-Identität — `AK-40`
- [ ] **T28** · Paket nach App Store Connect hochladen. Klärt zugleich OP-01 des
      Entwurfs: ob ein Bereitstellungsprofil verlangt wird — `AK-41`
- [ ] **T29** · Store-Eintrag füllen: Name, Untertitel, Beschreibung, Stichworte,
      Support-Adresse und Datenschutz-Link auf die Projektadressen, Kategorie,
      Alterseinstufung, Bildschirmfotos, Datenschutzangabe „keine Daten erfasst" — alles
      englisch. Braucht OF-08 — `AK-42, AK-43, AK-47`
- [ ] **T30** · Zur Prüfung einreichen. Bei Ablehnung: Gründe als Befunde aufnehmen,
      Status auf `building` zurücksetzen und abarbeiten — eine Ablehnung ist ein
      Rückschritt in der Bearbeitung, kein Fehlschlag des Features —
      `AK-44, EC-08`

## Abdeckung

| AK | Aufgaben |
|---|---|
| AK-01 | T03, T06 |
| AK-02 | T03 |
| AK-03 | T06 |
| AK-04 | T02, T06 |
| AK-05 | T04 |
| AK-06 | T26 |
| AK-07 | T26 |
| AK-08 | T26 |
| AK-09 | T11, T26 |
| AK-10 | T11, T26 |
| AK-11 | T26 |
| AK-12 | T12 |
| AK-13 | T26 |
| AK-14 | T26 |
| AK-15 | T26 |
| AK-16 | T26 |
| AK-17 | T26 |
| AK-18 | T12 |
| AK-19 | T26 |
| AK-20 | T26 |
| AK-21 | T18 |
| AK-22 | T05 |
| AK-23 | T08, T13, T17 |
| AK-24 | T08, T17 |
| AK-25 | T08, T25 |
| AK-26 | T15 |
| AK-27 | T07 |
| AK-28 | T07 |
| AK-29 | T17 |
| AK-30 | T07, T19 |
| AK-31 | T35 |
| AK-32 | T31 |
| AK-33 | T32 |
| AK-34 | T31 |
| AK-35 | T31 |
| AK-36 | T02 |
| AK-37 | T04, T34 |
| AK-38 | T13 |
| AK-39 | T21 |
| AK-40 | T27 |
| AK-41 | T28 |
| AK-42 | T29 |
| AK-43 | T29 |
| AK-44 | T30 |
| AK-45 | T22 |
| AK-46 | T23 |
| AK-47 | T29 |
| AK-48 | T25 |
| AK-49 | T24 |
| AK-50 | T24 |
| AK-51 | — |
| AK-52 | — |
| AK-53 | T03 |
| AK-54 | T35 |
| AK-55 | T36 |

**AK ohne Aufgabe:** AK-51 und AK-52. Beide sind in der Spezifikation als „trifft nicht
zu, weil …" formuliert — Zugriffsregeln und Kontolöschung setzen Konten und ein Backend
voraus, die es nicht gibt. Sie bekommen keine Aufgabe, weil nichts zu bauen ist; ihr
Nachweis in `sdd-qa` ist die Begründung selbst. Die lokalen Löschpfade, die AK-52 nennt,
sind über AK-17 (T26) und AK-22 (T05) abgedeckt.

**Aufgabe ohne AK:** T01, T20 — und vier entfallene.

- **T01** beantwortet die Frage, von der ursprünglich die Reichweite von T09 und T10
  abhing. Sie ist als `Grundlage für …` gekennzeichnet. **Ihr Ergebnis hat OF-04 ausgelöst
  und damit die vier Aufgaben unten überflüssig gemacht** — eine Aufgabe, die nichts baut,
  hat hier den größten Zuschnitt verändert.
- **T20** trägt `EC-06` und `EC-07` statt eines AK. Das ist für Ebene 5 vorgesehen:
  Randfälle verweisen auf `EC-NN`. T19 tut dasselbe, ist über `AK-30` aber zusätzlich an
  ein Kriterium gebunden.
- **T09, T10, T14, T16 sind mit OF-04 entfallen.** Sie stehen durchgestrichen im Plan statt
  gelöscht, damit nachvollziehbar bleibt, dass sie nicht vergessen, sondern gegenstandslos
  wurden. T09 und T10 waren gebaut und wurden über T31 zurückgebaut; T14 und T16 wurden nie
  begonnen. Ihre Kriterien sind auf T31 bis T33 übergegangen.

**EC ohne Aufgabe:** keine. Acht aus der Spezifikation sind zugeordnet — EC-01 bis EC-04
an T19, EC-06 und EC-07 an T20, EC-09 an T26, EC-08 an T30. **EC-05 ist mit OF-04
gegenstandslos geworden** und in der Spezifikation entsprechend gekennzeichnet.

**Nachgezogen am 2026-09-03 (BF-35).** Vor dieser Überarbeitung verwiesen AK-31 bis AK-35
auf T09, T10, T14 und T16 — alle nach der Entscheidung zu OF-04 entfallen. Die
Abdeckungstabelle zeigte damit für fünf Kriterien ins Leere, also genau dort nicht mehr
hin, wofür sie da ist. T31 bis T33 bilden den tatsächlichen Erfüllungsweg ab.

## Parallelisierung

**Ebene 1:** T01, T02, T03, T04, T05 laufen gleichzeitig — T01 schreibt nur in
`design.md`, T02 in `Package.swift`, T03 und T04 in neue Dateien unter `Resources/`,
T05 in `Sources/AppPreferences.swift`. T06 hat **kein** `[P]`: Das Build-Skript braucht
die Ergebnisse von T02 bis T04 und läuft danach.

**Ebene 2:** T07, T08 und T11 laufen gleichzeitig — drei getrennte Dateien. (T09 und T10
sind mit OF-04 entfallen; sie standen hier ursprünglich mit.)

**Ebene 3:** vollständig seriell. Alle drei Aufgaben fassen
`Sources/MikaScreenSnapApp.swift` an — der klassische Fall, in dem zwei Aufgaben
unabhängig aussehen und es nicht sind.

**Ebene 4:** T15, T17, T18 laufen gleichzeitig — Onboarding, Einstellungen und
Menüleiste sind getrennte Dateien. (T16 ist mit OF-04 entfallen.)

**Ebene 5:** T21, T22, T23, T24 laufen gleichzeitig — `Tests/`, eine reine Prüfung,
`web/` und `scripts/` überschneiden sich nicht. **T32 und T33 dürfen es nicht**: Beide
schreiben in `CHANGELOG.md`. T19, T20, T25, T26, T31 und die vier Einreichungsaufgaben
laufen seriell — sie fassen die Logikdateien aus Ebene 2 an oder setzen einander voraus.

## Vor dem Bauen

- [ ] Feature-Branch: `git checkout -b feature/16-app-store-auslieferung`
- [ ] **OF-07 beschafft** — aktive Mitgliedschaft im Apple Developer Program und
      `lu.daumedia.screensnap` unter der Team-ID registriert. **Blockiert T27 bis
      T30**, sonst nichts
- [ ] **OF-08 entschieden** — Store-Kategorie und Alterseinstufung. Blockiert T29
- [ ] Verteilungszertifikat und Installer-Zertifikat im Schlüsselbund, App-Store-Connect-
      Schlüssel außerhalb des Projektordners
- [ ] Eine bestehende DMG-Installation mit belegten Einstellungen, angehefteten Bildern
      und gefüllter Ausschlussliste **gesichert** — T01, T20 und T26 brauchen sie, und T20
      verändert sie
- [ ] Der ausstehende Punkt aus `features/index.md` ist unberührt: 3.5.0 ist weiterhin
      nicht notarisiert. Dieses Feature ersetzt das nicht


## Baubericht — 2026-09-03

Gebaut über den Eingang *Aufgabenplan*. Branch `feature/16-app-store-auslieferung`.
Status bleibt `building`: dieser Schritt nimmt seine eigene Arbeit nicht ab.

**Erledigt (19 von 30):** T01–T13, T15, T17, T18, T21, T23, T24.

### Was nachgewiesen ist

| Nachweis | Ergebnis |
|---|---|
| `swift build` · `swift test` (DMG) | grün, 62 Tests |
| `MIKA_APPSTORE=1 swift build` · `swift test` | grün, 72 Tests |
| `scripts/build-appstore.sh` Selbstprüfung | 10 von 10 — Sandbox an, keine Ausnahme-Entitlements, kein `screen-capture`, kein `disable-library-validation`, kein `SUFeedURL`/`SUPublicEDKey`, kein Sparkle im Binary und nicht im Paket |
| AK-38 am gebauten DMG | Sparkle eingebettet, `SUFeedURL` vorhanden, Sandbox aus — unverändert |
| AK-37 | beide Ausgaben 3.5.0 / 3.5.0, abgeleitet aus einer `Info.plist` |

### Was nicht erfüllt werden konnte

| Aufgaben | Grund |
|---|---|
| T14, T16 | **OF-04.** Die Übernahme angehefteter Bilder braucht eine Entscheidung, die dem Autor gehört — der Entwurf ging unter TE-06 von einem Weg aus, den T01 widerlegt hat. Der Importer ist gebaut und bedient alle drei möglichen Antworten; die Oberfläche wurde bewusst **nicht** auf Verdacht gebaut |
| T20 | hängt an T14/T16 |
| T19 | im Code behandelt (Abbruch der Ordnerwahl, fehlender und schreibgeschützter Ordner über `SaveLocationProblem`), aber **nicht am laufenden Programm nachgewiesen** |
| T22, T25, T26 | brauchen ein laufendes, sandboxed Programm mit erteilter Aufnahmeberechtigung. In dieser Sitzung nicht durchführbar |
| T27–T30 | **OF-07, jetzt belegt statt vermutet:** Im Schlüsselbund liegen nur `Apple Development` (8C9HV4CHBN) und `Developer ID Application` (CWJM4J4HFN). `Apple Distribution` und `3rd Party Mac Developer Installer` fehlen beide, und die zwei Team-IDs sind ungeklärt |

### Getroffene Annahmen

1. **`Info.plist` wird abgeleitet statt als zweite Datei gepflegt.** T04 verlangte eine
   Store-Fassung; gebaut ist stattdessen ein Skriptschritt, der die gemeinsame Datei kopiert
   und zwei Schlüssel löscht. Damit können die Versionen der beiden Ausgaben gar nicht erst
   auseinanderlaufen — AK-37 gilt durch Konstruktion statt durch Disziplin.
2. **`SaveLocationStore.isSandboxed` unterscheidet Übersetzung und Ausführung.** Der
   Store-Build läuft nicht immer sandboxed — ein Testprozess nicht, ein lokal gebautes
   Binary nicht. Ohne diese Unterscheidung wäre der gesamte Schreibpfad untestbar (acht
   Tests fielen zunächst genau darüber aus). Die Umgebungsvariable
   `APP_SANDBOX_CONTAINER_ID` wurde vor dem Einbau gemessen, nicht angenommen.
3. **`migrationOffered` steht bewusst nicht in `ownedDefaultsKeys`** — mit Kommentar an
   der Stelle und einem Test, der das Weglassen festhält.

### Über das Feature hinaus verändert

- **`.gitignore`** um `scripts/appstore-credentials.sh` und `build-appstore/` ergänzt.
- **`web/app/privacy/page.tsx`** (T23) — die einzige Datei außerhalb der Anwendung.
- **`features/16-.../design.md`** unter TE-07 um das Messprotokoll aus T01 ergänzt, wie
  die Aufgabe es verlangte.
- **Verifikationsschwelle in diesem Plan korrigiert:** Ursprünglich sollte
  `MIKA_APPSTORE=1 swift build` ab Ebene 1 grün sein. Das war unmöglich — sobald T02 die
  Abhängigkeit fallen lässt, scheitert `SparkleUpdater.swift`, bis T08 und T13 gelaufen
  sind. Die Schwelle steht jetzt bei Ebene 3.
- **T09/T10 verkleinert** nach dem Ergebnis von T01: Einstellungen wandern von selbst.

### Nebenbefund, nicht gebaut — gehört zu B14

Die installierte Fassung trägt in ihren Einstellungen
`SUFeedURL = …/Mukaarts/MikaScreenSnap/…`, während `Resources/Info.plist`
`…/daumedia/MikaScreenSnap/…` nennt. Sparkle bevorzugt den Wert aus `UserDefaults`, das
heißt **diese Installation prüft gegen ein anderes Repository als das im Code hinterlegte.**
Verschärfend: keiner der `SU*`-Schlüssel steht in `ownedDefaultsKeys`, sie überleben also
„Reset All Preferences". Beides betrifft B14 und B11, nicht dieses Feature — hier nur
gemeldet.


## Baubericht II — Behebung BUG-01 bis BUG-05, 2026-09-03

Gebaut über den Eingang *Fehlerauftrag* (`qa-report.md`, Status `review`). Auftrag waren
die fünf Befunde, sonst nichts. **T14, T16 und T20 wurden nicht angefasst** — OF-04 ist
weiterhin unentschieden.

| Befund | Grad | Status | Behebung |
|---|---|---|---|
| BUG-01 | hoch | behoben | Fünf Stellen in `ScreenshotHistoryManager` gehen jetzt durch `SaveLocationStore.withSaveFolder` statt durch `resolve`: `loadHistory`, `deleteItem`, `clearAll`, `generateThumbnail` — und `storageUsage`, das die QA nicht aufgezählt hatte, aber denselben Fehler trug |
| BUG-02 | mittel | behoben | „Open Folder" löst den Ordner auf und meldet bei `.failure` den Hinweis, statt einen leeren `~/Pictures` zu öffnen |
| BUG-03 | niedrig | behoben | Die Bestätigung nennt den Ordner der tatsächlich geschriebenen Datei |
| BUG-04 | mittel | behoben | Im Store-Build setzt das Zurücksetzen `hasCompletedOnboarding` auf `false`, sobald die Anwendung sandboxed läuft — die Ersteinrichtung fragt dann wieder nach einem Ordner |
| BUG-05 | niedrig | behoben | `SaveLocationStoreTests` (9 Fälle) und `HistoryWithoutSaveLocationTests` (2 Fälle) |

### Über die Behebung hinaus

**`deleteItem` und `clearAll` melden jetzt ihren Fehlschlag, statt ihn zu verschlucken.**
Vorher entfernten beide den Eintrag aus der Liste, auch wenn keine Datei gelöscht wurde —
der Nutzer bekam „gelöscht" zu sehen, während die Aufnahme im Ordner blieb. Das ist der
Kern von BUG-01 und deckt sich mit der Regel aus `CLAUDE.md`, dass Fehlerpfade sichtbar
sein müssen. Streng genommen eine Verhaltensänderung über den Wortlaut des Befunds hinaus.

### Nachweis, dass die Tests den Fehler wirklich fangen

Die zwei Schutzzeilen wurden temporär entfernt und die Testsuite erneut ausgeführt:

```
testClearAllKeepsTheListWhenTheFolderIsGone      : ("0") is not equal to ("1")
testDeletingDoesNotDropTheEntryWhenTheFolderIsGone: ("0") is not equal to ("1")
Executed 2 tests, with 2 failures
```

Nach Wiederherstellung: `Executed 2 tests, with 0 failures`. Ein Regressionstest, der den
Fehler nicht fängt, wäre wertlos gewesen.

### Verifikation

| Prüfung | Ergebnis |
|---|---|
| `swift build -c release` (beide Ausgaben) | grün, je 2 Warnungen — beide aus dem Bestand (`AnnotationModels.swift`), keine neue |
| `swift test` | 76 grün (DMG) · 86 grün (Store) |
| `scripts/build-appstore.sh` Selbstprüfung | 10 von 10 |
| AK-38 am DMG | Sparkle eingebettet, `SUFeedURL` vorhanden — unverändert |
| Ungeklammerte Zugriffe | keine: `resolve` kommt im `ScreenshotHistoryManager` nicht mehr vor |

### Was weiterhin offen ist

Unverändert gegenüber Baubericht I: **T14, T16, T20** (OF-04), **T19, T22, T25, T26**
(brauchen ein laufendes sandboxed Programm mit Aufnahmeberechtigung) und **T27–T30**
(OF-07, Zertifikate fehlen). Die 30 nicht prüfbaren Kriterien und alle neun Randfälle aus
dem Testbericht sind durch diese Behebung **nicht** nachgewiesen worden.


## Baubericht III — BUG-04/06/07 und Rückbau des Umzugs, 2026-09-03

Eingang *Fehlerauftrag*. Auftrag: die drei offenen Befunde aus Runde 2, dazu der Rückbau,
den dieser Plan seit der Entscheidung zu OF-04 als *entfällt* führt.

| Befund | Behebung | Nachweis |
|---|---|---|
| BUG-04 | `resetAllPreferences()` gibt jetzt zurück, **ob** die Ersteinrichtung erneut laufen muss; `AdvancedTabView` ruft daraufhin `onShowOnboarding()`. Ein Merkmal allein genügte nicht — es wird nur beim Programmstart gelesen | `testResetReportsWhetherFirstRunSetupMustRunAgain` |
| BUG-06 | Neue stille Klammer `readingSaveFolder` für Lesevorgänge. `loadHistory`, `storageUsage` und `generateThumbnail` benutzen sie; `saveImage`, `overwrite`, `deleteItem` und `clearAll` bleiben bei der meldenden `withSaveFolder` | Aufteilung im Code belegt; das Verhalten selbst braucht ein laufendes Programm |
| BUG-07 | `NSFileNoSuchFileError` beim Entfernen gilt als Erfolg. Löschen hat drei Ausgänge, und nur zwei sind Fehlschläge | **Umkehrprobe:** Behebung ausgehebelt → `("1") is not equal to ("0")`; wiederhergestellt → grün |

### Rückbau nach OF-04

Entfernt: `Sources/MigrationImporter.swift`, die Eigenschaft `migrationOffered` samt
Schlüssel, die elf `MigrationImporterTests` und der Test, der das absichtliche Weglassen
von `migrationOffered` aus `ownedDefaultsKeys` festhielt. T14 und T16 entfallen ersatzlos,
T09 und T10 sind gegenstandslos.

**Warum vollständig entfernt statt stehengelassen:** Ein Importer, den nichts aufruft, wird
beim nächsten Durchgang mitgepflegt, mitgetestet und irgendwann versehentlich wieder
angeschlossen. Die Entscheidung zu OF-04 hat ihn überflüssig gemacht, nicht nur ungenutzt.

### Über den Auftrag hinaus verändert

**Zwei QA-Tests umgeschrieben.** `testEntryCanStillBeRemovedAfterTheFileVanishedExternally`
trug `XCTExpectFailure`, um BUG-07 zu dokumentieren — nach der Behebung meldete die Suite
`Expected failure but none recorded`. Das war das erste Signal, dass die Behebung greift.
Beide Tests beschreiben jetzt das erwartete Verhalten statt des Defekts und bleiben als
Regressionsschutz stehen.

**Ein Kommentar in `AppPreferences` stand nach der Behebung von BUG-04 hinter dem
`return`** — eingeführt vom vorigen Durchgang, entfernt mit dem Rückbau.

### Verifikation

| Prüfung | Ergebnis |
|---|---|
| `swift build -c release` (beide Ausgaben) | grün · Store 2 Warnungen, beide aus dem Bestand (`AnnotationModels.swift`), keine neue |
| `swift test` | 76 grün (DMG) · 76 grün (Store) |
| `scripts/build-appstore.sh` Selbstprüfung | 10 von 10 |
| AK-38 am DMG | Sparkle eingebettet, `SUFeedURL` vorhanden — unverändert |
| Reste des Umzugs | keine: `grep` auf `MigrationImporter` und `migrationOffered` findet nichts |

Die Testzahl **sinkt** von 77/87 auf 76/76 — zwölf Tests sind mit dem Importer entfallen.
Das ist Absicht: Sie prüften Code, den es nicht mehr gibt.

### Was weiterhin offen ist

- **AK-33 ist unerfüllt.** Die neue Fassung verlangt, dass die Versionshinweise
  ausdrücklich sagen, dass angeheftete Bilder beim Wechsel nicht mitkommen. In
  `CHANGELOG.md` steht davon nichts. Kein Befund aus diesem Auftrag, aber eine Lücke, die
  die nächste QA finden wird — hier gemeldet statt ungefragt gebaut.
- **T19, T22, T25, T26** brauchen ein laufendes sandboxed Programm mit Aufnahmeberechtigung.
- **T20** ist auf EC-06 und EC-07 verkleinert, weiterhin nicht ausgeführt.
- **T27–T30:** Unter `CWJM4J4HFN` müssen App-ID und die Zertifikate `Apple Distribution`
  und `3rd Party Mac Developer Installer` beschafft werden. Entschieden ist das, beschafft
  nicht.


## Baubericht IV — BUG-08, 2026-09-03

Eingang *Fehlerauftrag*. Auftrag: **nur BUG-08.** BUG-09 wurde zur Hälfte über
`/sdd-architektur 16` erledigt; die andere Hälfte (Abdeckungstabelle in diesem Dokument)
gehört nach `/sdd-tasks 16` und wurde hier **nicht** angefasst.

| Befund | Behebung | Nachweis |
|---|---|---|
| BUG-08 | Abschnitt `[Unreleased] — Mac App Store edition` in `CHANGELOG.md` | „App Store" kommt jetzt achtmal vor; der Satz *Pinned screenshots do not come with you* steht in Zeile 35 |

### Was der Abschnitt sagt

Drei Teile, weil AK-33 nur einen davon verlangt und die anderen beiden sonst gefehlt hätten:

1. **Was neu ist** — zweite Ausgabe, Sandbox, einmalige Ordnerwahl mit der Begründung,
   warum überhaupt gefragt wird.
2. **Was sich nur in der Store-Fassung ändert** — kein eingebauter Updater, und Apples
   eigene Erhebung bei Store-Installationen. Letzteres deckt sich mit dem Absatz auf der
   Datenschutzseite (AK-46) und mit `docs/prd.md`.
3. **Was beim Wechsel passiert** — Einstellungen kommen mit, angeheftete Bilder nicht.
   Genau das verlangt AK-33, und zwar ausdrücklich als erwartetes Verhalten: Der Text sagt,
   **wo** die Originale unangetastet liegen und wie man sie zurückholt, damit das Fehlen
   nicht wie Datenverlust aussieht.

### Getroffene Annahmen

**Der Abschnitt heißt `[Unreleased]`, nicht `[3.6.0]`.** Über die Versionsnummer der
Store-Fassung ist nichts entschieden, und `Resources/Info.plist` steht weiterhin auf 3.5.0.
Eine Nummer zu erfinden hätte eine Entscheidung vorweggenommen, die niemand getroffen hat.
Vor der Einreichung muss daraus eine echte Version werden — das gehört zu T27.

### Über den Auftrag hinaus verändert

Nichts. Kein Code angefasst, keine Testdatei, kein Artefakt außer diesem Bericht.

### Verifikation

| Prüfung | Ergebnis |
|---|---|
| `swift build` | grün — der Code ist unberührt |
| `swift test` | 76 grün (DMG) · 76 grün (Store) |
| AK-33 Gegenprobe | „App Store" 8 Nennungen; der geforderte Satz vorhanden |

### Was weiterhin offen ist

- **BUG-09, zweite Hälfte:** Die Abdeckungstabelle in diesem Dokument verweist für AK-31
  bis AK-35 weiter auf T09, T10, T14 und T16 — alle entfallen. `/sdd-tasks 16`.
- **T19, T22, T25, T26** brauchen ein laufendes sandboxed Programm mit
  Aufnahmeberechtigung.
- **T20** auf EC-06 und EC-07 verkleinert, nicht ausgeführt.
- **T27–T30:** App-ID und die Zertifikate `Apple Distribution` und
  `3rd Party Mac Developer Installer` unter `CWJM4J4HFN` sind entschieden, aber nicht
  beschafft. Dazu die Versionsnummer aus der Annahme oben.


## Baubericht V — T33, 2026-09-03

Eingang *Aufgabenplan*, Status `tasked`. **Von zehn offenen Aufgaben war genau eine
baubar.** Das ist der eigentliche Befund dieses Durchgangs.

| Aufgabe | Stand | Grund |
|---|---|---|
| **T33** | **erledigt** | Zusage abgeschwächt, Zählfehler H-04 berichtigt |
| T34 | **wartet** | Setzt die Auslieferung von 3.5.0 als DMG voraus, die noch aussteht (`appcast.xml` kennt kein 3.5.0). **Korrigiert am 2026-09-03:** Sie ist nicht blockiert — Notary-Profil `MikaScreenSnap` und `Developer ID Application` liegen vor |
| T19, T22, T25, T26 | nicht ausführbar | brauchen ein laufendes, sandboxed Programm mit erteilter Bildschirmaufnahme-Berechtigung |
| T20 | nicht ausführbar | braucht zwei Installationen nebeneinander |
| T27–T30 | blockiert | `Apple Distribution` und `3rd Party Mac Developer Installer` fehlen unter `CWJM4J4HFN` |

### Was T33 geändert hat

**Die Zusage sagt jetzt, wie sicher sie ist.** Aus *Your settings come with you* wurde
*Your settings **should** come with you* — mit dem Mechanismus in einem Satz (macOS kopiert
die Einstellungen in den Container, solange die Bundle-Kennung gleich bleibt), dem
ausdrücklichen Vorbehalt (*measured, but not yet with a build signed for the App Store*)
und einer Handlungsanweisung: Fehlendes ist ein Fehler und meldenswert, nicht Absicht.

Der Text nennt außerdem, dass die alte Installation unberührt bleibt — damit steht neben
der Einschränkung auch, dass niemand etwas verliert.

**H-04:** *Which one you have determines the two differences below* → *Which edition you
have decides what applies below.* Es waren nie zwei.

### Getroffene Annahmen

**Der Vorbehalt ist ausformuliert, nicht nur angedeutet.** Ein bloßes *should* hätte den
Satz schwammig gemacht, ohne zu sagen, warum. Die Fassung nennt den Grund, damit ein Leser
einschätzen kann, wie wahrscheinlich das Ausbleiben ist — und damit die Einschränkung
wieder entfernt werden kann, sobald T28 sie erledigt.

### Über den Auftrag hinaus verändert

Nichts. Kein Code, keine Testdatei, kein Artefakt außer diesem Bericht.

### Verifikation

| Prüfung | Ergebnis |
|---|---|
| `swift build` | grün — der Code ist unberührt |
| `swift test` | 76 grün (DMG) · 76 grün (Store) |
| AK-33 unberührt | *Pinned screenshots do not come with you* steht unverändert |
| H-04 | *the two differences below* kommt nicht mehr vor |

### Was der nächste Durchgang wissen muss

**Der bearbeitbare Teil dieses Features ist erschöpft.** Neun Aufgaben sind offen, und
keine davon scheitert an Code oder Text — sie scheitern an drei Dingen, die außerhalb
dieser Kette liegen:

1. **Die Auslieferung von 3.5.0 als DMG** (blockiert T34) — ausführbar, sobald jemand
   `bash scripts/notarize.sh` anstößt. Profil und Zertifikat liegen bereits vor.
2. **Zwei Zertifikate unter `CWJM4J4HFN`** (blockiert T27–T30).
3. **Ein signiertes, sandboxed Programm auf einem echten Rechner** (blockiert T19, T20,
   T22, T25, T26) — das folgt aus 2.

Solange keines davon vorliegt, findet auch eine weitere QA-Runde nur noch Text.


## Baubericht VI — T35 und T36, 2026-09-03

Eingang *Aufgabenplan*. Auftrag: die beiden Aufgaben aus der Entscheidung zu OF-05 — die
einzigen offenen ohne externe Blockade.

| Aufgabe | Nachweis |
|---|---|
| **T35** `LegacyDefaultsImport` | 12 Symbole im DMG-Binary, **0 im Store-Binary** (`nm -a`) — AK-54 damit belegt, nicht behauptet |
| **T36** Ersteinrichtung bei fehlender Berechtigung | Auslösebedingung in `MikaScreenSnapApp.swift` erweitert; nutzt den bestehenden Ablauf aus B12 |

### Der Zuschnitt der Übernahme

Übernommen wird **jeder Schlüssel aus `ownedDefaultsKeys`** außer zweien. Das ist Absicht:
Ein Schlüssel, der später dazukommt, wandert mit, ohne dass jemand daran denken muss — und
die Liste, die ohnehin gepflegt wird, ist die einzige Quelle.

Die zwei Ausnahmen stehen im Code mit Begründung:

- `hasCompletedOnboarding` — die Aufnahmeberechtigung hängt ebenfalls an der Kennung und ist
  mit ihr weg. Diesen Wert zu übernehmen hieße, eine Anwendung als eingerichtet zu melden,
  die nichts aufnehmen kann. Genau das verlangt AK-55 andersherum.
- `saveLocationBookmark` — Store-Build-eigen, und ein Lesezeichen aus einem fremden Bundle
  würde ohnehin nicht auflösen.

Ein Test prüft, dass beide Ausnahmen **tatsächlich** in `ownedDefaultsKeys` stehen — ein
Tippfehler würde sonst lautlos gar nichts ausschließen.

### Über den Auftrag hinaus verändert

**Die Quelldomäne wurde injizierbar gemacht.** Ursprünglich war sie eine Konstante; damit
ließen sich nur die Wächter-Klauseln testen, nicht die Übernahme selbst. Das ist genau die
Lücke, aus der BUG-01 entstanden ist — eine ungetestete Komponente, in der der Fehler
saß. Fünf Tests prüfen jetzt den Kern: was ankommt, was nicht überschrieben wird, was
unangetastet bleibt.

### Zwei Umkehrproben

| Ausgehebelt | Ergebnis |
|---|---|
| Schutz gegen Überschreiben entfernt | `testDoesNotOverwriteWhatTheNewInstallAlreadyHas`: `("OLD") is not equal to ("NEW")` |
| `hasCompletedOnboarding` aus der Ausschlussliste genommen | 2 Fehlschläge |

Nach Wiederherstellung beide grün. Ein Regressionstest, der seinen Fehler nicht fängt,
wäre wertlos.

### Verifikation

| Prüfung | Ergebnis |
|---|---|
| `swift build -c release` | grün · 2 Warnungen, beide aus dem Bestand (`AnnotationModels.swift`), keine neue |
| `swift test` | **86 grün** (DMG) · 76 grün (Store) — die 10 neuen laufen nur im DMG-Build |
| `scripts/build-appstore.sh` | 10 von 10 |

### Was weiterhin offen ist

Unverändert acht Aufgaben, alle mit externer Blockade: **T34** (wartet auf die Auslieferung
von 3.5.0), **T19, T20, T22, T25, T26** (brauchen ein laufendes sandboxed Programm),
**T27–T30** (Zertifikate unter `CWJM4J4HFN`).

**Und eine Einschränkung, die dieser Durchgang nicht auflösen konnte:** AK-31 ist im Test
belegt, aber nicht am echten Programm. Ob eine bestehende 3.5.0-Installation nach dem
Update tatsächlich ihre Tastenkürzel behält, zeigt erst ein Durchlauf mit einer echten
Vorgängerfassung — und der gehört zu T26.
