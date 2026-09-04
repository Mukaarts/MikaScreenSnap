# 16 · App-Store-Auslieferung — Systemdesign

Status: `architected` · Stand: 2026-09-03 · Stack-Profil: `swiftui-macos`

> **Überarbeitet am 2026-09-03 (BF-35).** Die Entscheidung zu OF-04 hat den Umzug
> gestrichen; `spec.md` und der Code wurden nachgezogen, dieses Dokument blieb stehen und
> beschrieb weiter einen `MigrationImporter`, den es nicht mehr gibt. Ebenfalls
> eingearbeitet: BUG-04, BUG-06 und BUG-07 aus den QA-Runden 2 und 3.

**Kein Code in diesem Dokument.** Es wird gelesen und freigegeben, nicht ausgeführt.

> **Abweichung vom Stack-Profil.** `~/.claude/sdd/stacks/swiftui-macos.md` legt fest:
> „der Vertrieb läuft direkt über DMG und Sparkle, nicht über den App Store". Dieses
> Feature weicht davon ab. Das Profil ist projektübergreifend und wird hier **nicht**
> geändert; die Abweichung steht als technische Entscheidung TE-01.

## Überblick

Aus derselben Quelle entstehen zwei Programmpakete. Welches gebaut wird, entscheidet eine
Umgebungsvariable beim Aufruf des Build-Skripts — nicht eine Datei, die von Hand
umgeschaltet wird. Im Store-Paket fehlt Sparkle vollständig (Abhängigkeit, Framework,
Aufrufe), dafür ist die Sandbox aktiv.

Die Sandbox kostet die Anwendung genau eine Fähigkeit: den freien Zugriff auf
`~/Pictures/` und `~/Library/Application Support/`. Alles andere — ScreenCaptureKit,
Carbon-Hotkeys, `SMAppService`, die Overlay-Panels — funktioniert unverändert, weil keines
davon einen Dateipfad außerhalb des Containers braucht. Ersetzt wird der feste Pfad durch
einen Ordner, den der Nutzer einmal auswählt; die Erlaubnis dazu überlebt Neustarts als
gespeichertes Lesezeichen.

Der Umzug von einer bestehenden DMG-Installation ist der unangenehmste Teil: Die
Store-Fassung darf den alten Ablageort nicht von sich aus lesen. Sie erfährt von ihm nur
dadurch, dass der Nutzer ihn im selben Dialog auswählt, den er ohnehin für den
Speicherordner sieht.

## Fenster und Bildschirme

Die Anwendung hat keine Routen. Betroffen sind vier Oberflächen, alle bestehend:

| Oberfläche | Änderung | Nur im Store-Build |
|---|---|---|
| Ersteinrichtung (`Sources/Onboarding/`) | neuer Schritt *Speicherort* nach der Berechtigungsseite | ja |
| Einstellungen → *Advanced* (`Sources/Preferences/AdvancedTabView.swift`) | Update-Bereich wird durch einen Hinweistext ersetzt | ja |
| Menüleisten-Menü (`Sources/MikaScreenSnapApp.swift`) | Eintrag „Check for Updates…" entfällt | ja |
| Einstellungen → Speicherort | „Ordner wählen" statt Pfadfeld; „Im Finder öffnen" folgt dem aufgelösten Ordner, nicht dem gespeicherten Pfad | ja |
| Einstellungen → Zurücksetzen | öffnet im Store-Build unmittelbar die Ersteinrichtung wieder | ja |

Die vier Zustände je Oberfläche:

| Oberfläche | leer | ladend | Fehler | gefüllt |
|---|---|---|---|---|
| Schritt *Speicherort* | kein Ordner gewählt, „Weiter" gesperrt | — (Dialog ist synchron) | Ordner nicht beschreibbar → Meldung unter der Schaltfläche, Auswahl bleibt offen | Pfad wird angezeigt, „Weiter" frei |
| Speicherort in den Einstellungen | — (nie leer nach Einrichtung) | — | Ordner verschwunden → Warnhinweis mit „Neu wählen" | Pfad und „Ändern" |

## Komponentenstruktur

```
Ersteinrichtung  (bestehend, TabView mit Seiten-Tags)
├── WelcomeScreen                    unverändert
├── PermissionScreen                 unverändert, weiterhin bedingt
├── SaveLocationScreen        NEU    nur Store-Build; Ordnerauswahl, erklärt warum.
│                                    Erscheint auch nach einem Zurücksetzen wieder
└── ShortcutsScreen                  unverändert

Einstellungen → Advanced  (bestehend)
├── Speicherort-Bereich              DMG: Pfadfeld · Store: „Ordner wählen" + Warnzustand
├── Update-Bereich                   DMG: unverändert · Store: durch Hinweistext ersetzt
└── Speicherplatz-Bereich            unverändert

Aktualisierungsweg  (neu abstrahiert, ersetzt den direkten Zugriff auf SparkleUpdater)
├── UpdateChannel             NEU    gemeinsame Schnittstelle: zeigt die App
│                                    Update-Bedienelemente, und was tun sie
├── SparkleUpdateChannel      NEU    umschließt den bestehenden SparkleUpdater; nur im
│                                    DMG-Build übersetzt
└── AppStoreUpdateChannel     NEU    meldet „keine Bedienelemente"; nur im Store-Build

Ablage  (bestehend, erweitert)
└── SaveLocationStore         NEU    hält den gewählten Ordner und seine Erlaubnis
    ├── resolve                      welcher Ordner — oder warum keiner
    ├── readingSaveFolder            **stille** Klammer, für Lesevorgänge
    ├── withSaveFolder               **meldende** Klammer, für Schreib- und Löschvorgänge
    └── adopt                        übernimmt einen Ordner, den der Nutzer gewählt hat
```

**Einen Umzug-Baustein gibt es nicht.** Was von einer Vorgängerinstallation mitkommt,
bringt macOS mit (Einstellungen); was nicht mitkommt, kommt gar nicht mit (angeheftete
Bilder). Begründung unter TE-06.

`SparkleUpdater` selbst bleibt unverändert. Er wird nur nicht mehr direkt aus vier Dateien
angesprochen, sondern über `UpdateChannel` — sonst müssten `MikaScreenSnapApp.swift`,
`AdvancedTabView.swift`, `PreferencesContainerView.swift` und
`PreferencesWindowController.swift` je eine Übersetzungsweiche tragen.

## Datenmodell

Es gibt keine Datenbank. Das Modell sind Einstellungsschlüssel und Dateiablagen.

### Geänderte Schlüssel in `UserDefaults`

| Schlüssel | Typ | Pflicht | Bedeutung | Änderung |
|---|---|---|---|---|
| `saveLocation` | String (Pfad) | nein | Speicherordner im DMG-Build | **bleibt** — im Store-Build ungenutzt |
| `saveLocationBookmark` | Data | nein | Lesezeichen auf den gewählten Ordner, überlebt Neustarts und Umbenennungen | **neu**, nur Store-Build |

Der neue Schlüssel gehört in `AppPreferences.ownedDefaultsKeys`. Die Konvention aus
`CLAUDE.md` und der Test, der sie erzwingt, gelten unverändert — ein Schlüssel, der dort
fehlt, überlebt „Reset All Preferences" unbemerkt.

**Das Zurücksetzen muss mehr tun, als Werte zu löschen.** Es entfernt das Lesezeichen und
nimmt der Anwendung damit ihren Speicherort. Ein bloßes Merkmal „Ersteinrichtung wieder
nötig" genügt nicht — es wird ausschließlich beim Programmstart gelesen, und diese
Anwendung liegt dauerhaft in der Menüleiste. Das Zurücksetzen **meldet deshalb an seinen
Aufrufer zurück**, ob die Ersteinrichtung laufen muss, und der öffnet sie sofort (TE-10).

### Dateiablagen

| Ablage | DMG-Build | Store-Build |
|---|---|---|
| Aufnahmen | `~/Pictures/MikaScreenSnap/`, frei änderbar | vom Nutzer gewählter Ordner, Zugriff über Lesezeichen |
| Angeheftete Bilder | `~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/` | derselbe Pfad **innerhalb des Containers** — `PinnedScreenshotManager.persistenceDir` (`Sources/PinnedScreenshotManager.swift:16`) löst ihn ohne Änderung dorthin auf |
| Einstellungen | `~/Library/Preferences/…` | dieselbe Datei innerhalb des Containers |

Der Pin-Pfad braucht **keine** Codeänderung: `FileManager.urls(for: .applicationSupportDirectory)`
liefert im Sandbox den Containerpfad. Der bestehende `persistenceDirOverride` für Tests
bleibt unberührt.

### Löschregeln

Unverändert: Jeder Schreibpfad hat sein Gegenstück. Der Umzug **kopiert**, er verschiebt
nicht (AK-35) — die alte Installation bleibt vollständig, weil ein fehlgeschlagener Umzug
sonst Daten vernichtet, die niemand wiederherstellen kann.

## Zugriffsregeln

Die Anwendung hat keine Konten und keine Zeilen. Die Grenzen sind Sandbox und TCC.

| Wer | Darf lesen | Darf schreiben | Erzwungen durch |
|---|---|---|---|
| Store-Fassung | Bildschirminhalte aller Apps außer den ausgeschlossenen | eigener Container | TCC „Bildschirmaufnahme" — Nutzerentscheidung, nicht durch ein Entitlement ersetzbar |
| Store-Fassung | den vom Nutzer gewählten Ordner | denselben Ordner | Sandbox + Lesezeichen; Zugriff wird je Schreibvorgang geöffnet und geschlossen |
| Store-Fassung | alles Übrige im Dateisystem: **nein** | **nein** | Sandbox, ohne Ausnahme-Entitlement |
| Ausgeschlossene Apps | — | — | `ExcludedAppsManager` filtert vor dem Aufnahmeaufruf — unverändert, sandbox-unabhängig |

### Entitlements des Store-Builds

| Schlüssel | Wert | Wofür |
|---|---|---|
| `com.apple.security.app-sandbox` | `true` | Voraussetzung des Stores |
| `com.apple.security.files.user-selected.read-write` | `true` | der Ordner, den der Nutzer auswählt |
| `com.apple.security.files.bookmarks.app-scope` | `true` | damit diese Erlaubnis Neustarts überlebt |
| `com.apple.security.screen-capture` | **entfernt** | nicht dokumentiert, war ohne Sandbox wirkungslos; die Aufnahme entscheidet TCC (AK-53, TE-04) |
| `com.apple.security.cs.disable-library-validation` | **entfernt** | wurde nur für die eingebettete Sparkle.framework gebraucht |
| irgendein `com.apple.security.temporary-exception.*` | **nie** | Decision Log der Spec, Zeile 12 |

Der DMG-Build behält seine Entitlement-Datei unverändert — einschließlich
`disable-library-validation`, das er für Sparkle weiterhin braucht.

## Missbrauchsschutz

| Endpunkt | Limit | Verhalten bei Überschreitung | Wo konfiguriert |
|---|---|---|---|
| — | — | — | Es gibt keinen. Die Anwendung hat kein Backend, keinen Netzwerkpfad (im Store-Build auch keinen Update-Check) und ruft keinen kostenpflichtigen Dienst auf |
| Angeheftete Bilder | 20 gleichzeitig | Meldung über `CaptureLog.report`, kein weiterer Pin | `PinnedScreenshotManager.maxPins` — bestehend, unverändert |
| Ordnerwahl | keins nötig | — | Der Dialog ist die einzige Stelle, an der die Anwendung Zugriff auf fremde Ordner erhält, und er wird vom System gestellt |

**Der Umzug war einmal der einzige neue Angriffsweg** — er hätte eine Datei außerhalb der
Anwendung gelesen. Mit der Entscheidung zu OF-04 entfällt er, und damit auch dieser Weg.
Was bleibt, ist der vom System gestellte Ordnerdialog: Die Anwendung erhält Zugriff auf
genau einen Ordner, den der Nutzer benannt hat, und auf keinen anderen.

## Externe Dienste

| Dienst | Wofür | Was geht hin | Was wird vorher entfernt |
|---|---|---|---|
| App Store Connect | Einreichung, Metadaten, Absturz- und Nutzungsberichte | das signierte Paket; danach von Apple erhobene Absturz- und Nutzungsdaten, sofern der Nutzer sie in den Systemeinstellungen erlaubt hat | nichts — die Anwendung sendet selbst nichts. Der Datenfluss entsteht durch den Vertriebsweg, nicht durch Code |
| Sparkle-Appcast | Updates des DMG-Builds | unverändert | im Store-Build **gar nicht vorhanden** (AK-25) |

Kein AV-Vertrag nötig: Es werden keine personenbezogenen Daten im Auftrag verarbeitet.
Die Präzisierung der Datenschutzseite ist die Konsequenz (AK-46), nicht ein Vertrag.

## Technische Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| TE-01 | Abweichung vom Stack-Profil, das App-Store-Vertrieb ausschließt | Profil ändern | Das Profil gilt projektübergreifend; eine Aussage über *dieses* Projekt gehört ins PRD, wo sie am 2026-09-03 auch korrigiert wurde |
| TE-02 | Die Ausgabe wählt eine Umgebungsvariable, die `Package.swift` beim Auflösen liest — sie entscheidet über Sparkle als Abhängigkeit und setzt ein Übersetzungsmerkmal | Zwei `Package.swift`; ein Xcode-Projekt einführen; Sparkle immer linken und nur zur Laufzeit abschalten | `Package.swift` ist gewöhnlicher Swift-Code und darf die Umgebung lesen. Die dritte Variante scheidet aus: Ein gelinktes Framework, das nicht im Paket liegt, verhindert den Start — und ein Paket, das es enthält, wird vom Store abgewiesen. Ein Xcode-Projekt widerspricht der Rahmenbedingung *Projektform: reines Swift Package* |
| TE-03 | `UpdateChannel` als gemeinsame Schnittstelle, zwei Umsetzungen | `#if` an jeder der sechs Aufrufstellen | Übersetzungsweichen in der Oberfläche sind die Stelle, an der zwei Ausgaben unbemerkt auseinanderlaufen. Eine Schnittstelle hält den Unterschied an einem Ort — und macht ihn testbar |
| TE-04 | `com.apple.security.screen-capture` wird entfernt statt behalten | belassen | Der Schlüssel steht in keiner Entitlement-Referenz von Apple. Ohne Sandbox war er wirkungslos; mit Sandbox ist die Bildschirmaufnahme eine TCC-Entscheidung. Ein unbekannter `com.apple.security.*`-Schlüssel ist ein vermeidbares Risiko bei der Prüfung |
| TE-05 | Der Speicherordner wird als Lesezeichen gespeichert, der Zugriff je Schreibvorgang geöffnet und wieder geschlossen | Zugriff beim Start öffnen und offen lassen | Ein dauerhaft offener Zugriff überlebt kein Aushängen des Volumes und verdeckt genau den Fehler, den EC-02 sichtbar machen soll |
| TE-06 | **Aufgehoben am 2026-09-03 (OF-04).** Es gibt keinen Umzug mehr, den die Anwendung selbst durchführt: Einstellungen wandern über die Container-Übernahme, angeheftete Bilder gar nicht | eigener zweiter Dialog; Ausnahme-Entitlement auf den Home-Ordner | Der ursprüngliche Entwurf nahm an, der Altbestand liege im Speicherordner. T01 hat das widerlegt. Ein zweiter Dialog scheidet aus, weil die Anwendung ohne Lesezugriff nicht erkennen kann, **ob** es etwas zu holen gibt — sie müsste jeden Nutzer fragen, was AK-34 verbietet |
| TE-07 | **Beantwortet durch T01 am 2026-09-03** — siehe Messprotokoll unten. Einstellungen wandern automatisch, Dateien nicht | auf die Automatik setzen, ohne sie zu prüfen | Die Quellenlage war widersprüchlich; die Messung hat sie ersetzt |
| TE-08 | Signatur und Paketierung laufen über ein eigenes Skript neben `scripts/build.sh` | `scripts/build.sh` erweitern | Das bestehende Skript signiert ad-hoc und bettet Sparkle ein — beides ist für den Store falsch. Zwei kurze Skripte sind lesbarer als eines mit zwei Betriebsarten |
| TE-10 | Das Zurücksetzen **meldet zurück**, ob die Ersteinrichtung erneut laufen muss; der Aufrufer öffnet sie | nur ein Merkmal setzen und auf den nächsten Start warten | Das Merkmal wird ausschließlich beim Programmstart gelesen. Bei einer Anwendung, die dauerhaft in der Menüleiste liegt, kann der nächste Start Tage entfernt sein — bis dahin hätte sie keinen Speicherort und keinen Weg zu einem (BUG-04) |
| TE-11 | **Zwei Klammern statt einer:** eine stille für Lesevorgänge, eine meldende für Schreib- und Löschvorgänge | eine Klammer für alles | Eine Klammer, die immer meldet, macht aus einem Normalzustand einen Fehler: „noch kein Ordner gewählt" ist beim ersten Start richtig, und `loadHistory` läuft beim Programmstart, `storageUsage` bei jedem Neuzeichnen der Einstellungen (BUG-06). Die Regel aus `CLAUDE.md` verlangt sichtbare Fehlerpfade — nicht sichtbare Normalzustände |
| TE-12 | Löschen hat **drei** Ausgänge, und nur zwei sind Fehlschläge: Ordner unerreichbar · Datei nicht entfernbar · Datei war schon weg | „gelöscht oder nicht" | Der dritte Fall ist das, was der Nutzer wollte. Ihn als Fehlschlag zu behandeln ließ Einträge im Verlauf zurück, die sich nie wieder entfernen ließen (BUG-07) |
| TE-09 | Keine neue Abhängigkeit | — | Alles Nötige ist im System: `NSOpenPanel`, Lesezeichen, `codesign`, `productbuild`, `notarytool` |

### Messprotokoll zu TE-07 (T01, 2026-09-03)

Aufbau: eine Wegwerf-Bundle-ID, unsandboxed mit zwei Werten belegt, danach dieselbe
Kennung als sandboxed Programmpaket gestartet. Die echte Installation blieb unberührt.

| Frage | Ergebnis |
|---|---|
| Sind unsandboxed geschriebene `UserDefaults` im Container lesbar? | **Ja.** Beide Werte kamen unverändert an; die alte Einstellungsdatei liegt als Kopie im Container |
| Wohin löst `applicationSupportDirectory` im Sandbox auf? | `~/Library/Containers/<id>/Data/Library/Application Support` — wie im Entwurf angenommen |
| Ist der alte `Application Support` von dort erreichbar? | **Nein.** Nicht sichtbar, und direktes Lesen scheitert mit `NSFileReadNoPermissionError` (257) |

**Folge für den Umzug — der Zuschnitt von T09 und T10 ändert sich:**

- **Einstellungen brauchen keinen Umzug.** Tastenkürzel, Ausschlussliste und
  Zeichen-Standards sind nach dem ersten Start da, ohne Zutun der Anwendung.
- **Angeheftete Bilder kommen gar nicht mit.** Sie liegen außerhalb des Containers und
  sind ohne ausdrückliche Auswahl durch den Nutzer nicht lesbar. Aus dieser Messung folgte
  OF-04, und aus OF-04 die Streichung des Umzugs: Ohne Lesezugriff kann die Anwendung nicht
  erkennen, **ob** es etwas zu holen gibt, und müsste jeden Nutzer fragen — was AK-34
  verbietet.
- **Vorbehalt:** Gemessen wurde mit einer ad-hoc signierten Probe. Ob eine vom Store
  signierte Fassung mit anderer Team-ID sich gleich verhält, ist damit wahrscheinlich,
  aber nicht bewiesen — der Container wird über die Bundle-ID adressiert, nicht über das
  Team. Endgültige Gewissheit gibt erst T28.

## Offene Punkte des Entwurfs

- **OP-01** · Ob ein Bereitstellungsprofil nötig ist, hängt davon ab, ob das Paket ein
  eingeschränktes Entitlement führt. Nach TE-04 führt es keines — dann ist keines nötig.
  Bestätigt wird das erst durch den Upload (AK-41), nicht durch Lektüre.
- **OP-03** · **AK-33 ist das einzige Kriterium, dessen Erfüllung außerhalb des Codes
  liegt** — in `CHANGELOG.md`. Ein Entwurf kann das nicht absichern; es fällt nur auf,
  wenn jemand die Versionshinweise gegen die Spezifikation liest. Genau so wurde es in
  QA-Runde 3 gefunden (BF-34).
- **OP-02** · `com.apple.developer.persistent-content-capture` existiert als
  genehmigungspflichtige Fähigkeit für dauerhafte Bildschirmaufnahme. Dieses Feature
  braucht sie **nicht** — die Anwendung nimmt auf Tastendruck auf, nicht dauerhaft. Wird
  die Einreichung dennoch daran scheitern, ist das ein Befund, kein Entwurfsfehler.

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | Entitlement-Datei des Store-Builds, gesetzt über TE-02 | |
| AK-02 | Entitlement-Tabelle oben — keine Ausnahme aufgeführt | Prüfbar am gebauten Paket |
| AK-03 | Folge der aktiven Sandbox, keine eigene Umsetzung | Plattformverhalten |
| AK-04 | TE-02: ohne Abhängigkeit gibt es kein Framework zum Einbetten | |
| AK-05 | Eigene `Info.plist`-Fassung für den Store-Build im Paketierungsskript (TE-08) | |
| AK-06 | unverändert; Sandbox berührt ScreenCaptureKit nicht | Nachweis manuell |
| AK-07 | unverändert | Nachweis manuell |
| AK-08 | unverändert | Nachweis manuell |
| AK-09 | `ExcludedAppsManager`, unverändert | Filter läuft vor dem Aufnahmeaufruf, sandbox-unabhängig |
| AK-10 | `ExcludedAppsManager`, unverändert | |
| AK-11 | Editor unverändert; kein Dateipfad beteiligt | |
| AK-12 | Zensurpfad unverändert; Schreibziel ist `SaveLocationStore` statt fester Pfad | Der Ersetzungspfad aus 3.5.0 bleibt, nur das Ziel wechselt |
| AK-13 | Vision-Framework, unverändert; läuft auf dem Gerät | |
| AK-14 | unverändert | |
| AK-15 | unverändert | |
| AK-16 | `PinnedScreenshotManager`, Pfad löst automatisch in den Container auf | Keine Codeänderung |
| AK-17 | `unpinPanel`, unverändert | |
| AK-18 | Verlauf und Löschen über die meldende Klammer, Anzeige über die stille (TE-11); „Im Finder zeigen" folgt dem aufgelösten Ordner | Deckt BUG-01, BUG-02, BUG-06 und BUG-07 mit ab |
| AK-19 | Carbon-Hotkeys, unverändert | Sandbox verlangt hier kein Entitlement |
| AK-20 | `SMAppService`, unverändert | Im Sandbox zulässig |
| AK-21 | Menüleisten-Hub unverändert, außer dem entfallenden Update-Eintrag | |
| AK-22 | `resetAllPreferences` plus `saveLocationBookmark` in `ownedDefaultsKeys`; Rückmeldung an den Aufrufer nach TE-10 | Ohne TE-10 bliebe die Anwendung bis zum Neustart ohne Speicherort |
| AK-23 | `AppStoreUpdateChannel` meldet „keine Bedienelemente"; `AdvancedTabView` wertet das aus | |
| AK-24 | Hinweistext an derselben Stelle, aus demselben Kanalobjekt | |
| AK-25 | Folge von AK-04: ohne Sparkle kein Abruf | |
| AK-26 | `SaveLocationScreen` als neuer Schritt der Ersteinrichtung | |
| AK-27 | `SaveLocationStore` schreibt in den gewählten Ordner | |
| AK-28 | Lesezeichen aus `saveLocationBookmark`, TE-05 | |
| AK-29 | Ordnerwechsel in den Einstellungen ersetzt nur das Lesezeichen | Alte Dateien bleiben liegen — kein Verschieben |
| AK-30 | Meldende Klammer (TE-11) über `CaptureLog.report`, Neuwahl angeboten | Deckt EC-02 und EC-03 mit. Lesevorgänge schweigen hier bewusst — der Hinweis kommt bei der nächsten Aufnahme |
| AK-31 | Container-Übernahme durch macOS, gemessen im Protokoll zu TE-07 | Kein Code der Anwendung beteiligt |
| AK-32 | **Abwesenheit von Code:** es gibt keinen Baustein, der fragen könnte (TE-06) | Negativkriterium — nachweisbar durch Suche über `Sources/` |
| AK-33 | Abschnitt in `CHANGELOG.md`, der den App Store nennt und das Fehlen der angehefteten Bilder ausdrücklich benennt | **Einziges Kriterium, das außerhalb des Codes erfüllt wird — und das einzige derzeit offene.** Siehe BF-34 |
| AK-34 | wie AK-32 | Seit OF-04 widerspruchsfrei zu AK-33 erfüllbar |
| AK-35 | **Abwesenheit von Schreibpfaden** auf die Altablagen: alle Ziele laufen über `SaveLocationStore` bzw. den Container | Negativkriterium — nachweisbar durch Suche nach hartkodierten Altpfaden |
| AK-36 | TE-02: eine Quelle, Umschaltung über die Umgebung | |
| AK-37 | Beide Skripte lesen dieselbe `Info.plist`-Vorlage | |
| AK-38 | `scripts/build.sh` bleibt unangetastet (TE-08) | Das stärkste Argument für zwei getrennte Skripte |
| AK-39 | Tests für Auflösung, beide Klammern, Ablehnung eines unbeschreibbaren Ordners und das Verhalten des Verlaufs ohne Speicherort | Zwei Umkehrproben belegen, dass die Tests ihre Fehler fangen |
| AK-40 | Paketierungsskript signiert mit der Verteilungsidentität | Braucht OF-07 der Spec |
| AK-41 | Upload über `notarytool`/App Store Connect | Braucht OF-07; klärt zugleich OP-01 |
| AK-42 | Eintrag in App Store Connect, keine Umsetzung im Code | Braucht OF-08 |
| AK-43 | Werte im Eintrag: GitHub-Issues und bestehende Datenschutzseite | |
| AK-44 | Einreichung über App Store Connect | |
| AK-45 | `CaptureLog` protokolliert Fehler, keine Inhalte — für die neuen Pfade ausdrücklich mitzuprüfen | Der Ordnerpfad selbst darf ins Protokoll, Dateinamen mit Bildinhalt nicht |
| AK-46 | Änderung an `web/app/privacy/page.tsx` | Einzige Datei außerhalb der App |
| AK-47 | Datenschutzangaben im Store-Eintrag | Bezieht sich auf die Anwendung, konsistent mit AK-46 |
| AK-48 | Folge von AK-04 und AK-25 | Kein Endpunkt, kein Limit nötig — siehe *Missbrauchsschutz* |
| AK-49 | Nichts Geheimes im Repository; Schlüssel im Schlüsselbund | Decision Log der Spec, Zeile 10 |
| AK-50 | Beispieldatei und Anleitung neben dem Paketierungsskript | |
| AK-51 | Trifft nicht zu — begründet in der Spec | Keine Umsetzung nötig, Zeile bleibt trotzdem stehen |
| AK-52 | Trifft nicht zu — begründet in der Spec | Lokale Löschpfade über AK-17 und AK-22 |
| AK-53 | Entitlement-Tabelle: Schlüssel entfernt (TE-04) | Zusammen mit AK-06 bis AK-08 zu prüfen — Entfernen ohne Funktionsnachweis wäre wertlos |

Alle 53 Kriterien sind zugeordnet. Vier davon (AK-40 bis AK-42, AK-44) sind erst
ausführbar, wenn OF-07 der Spezifikation beschafft ist.
