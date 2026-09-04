# 16 · App-Store-Auslieferung — Testbericht

Stand: 2026-09-03 · **Runde 6**, nach dem Kennungswechsel und den Aufgaben T35/T36 ·
Geprüft gegen `spec.md` mit 55 Kriterien

## Fazit

**Production-ready: nein.**

**Drei neue Befunde, und zwei davon zeigen dasselbe Muster zum dritten Mal.** Der
Kennungswechsel und die Aufgabe T35 haben das Verhalten geändert; die Versionshinweise,
die vorher geschrieben wurden, sagen weiterhin das Alte. In Runde 4 versprach der Text
**mehr**, als belegt war (BF-36). Diesmal verspricht er **weniger**, als gebaut wurde —
dieselbe Ursache, andere Richtung:

| Der Text sagt | Tatsächlich |
|---|---|
| *Your settings do not come with you* | `LegacyDefaultsImport` übernimmt sie im DMG-Build seit T35 — mit fünf Tests belegt |
| *neither do pinned screenshots* | Der Pin-Ordner heißt `MikaScreenSnap/PinnedScreenshots` und hängt **nicht** an der Bundle-Kennung. Im DMG-Build sind die Bilder nach dem Update unverändert da |

**Für den Nutzer ist das die unangenehmere Fehlerrichtung, als sie klingt.** Wer liest, er
verliere seine Einstellungen, richtet sie vorsorglich neu ein — und überschreibt damit
genau das, was der Import gerettet hätte.

**Gut ist:** T35 und T36 selbst sind sauber gebaut. AK-54 ist am Binärstand belegt
(`nm -a`: 12 Symbole im DMG-Build, **0** im Store-Build), der Kern der Übernahme ist mit
fünf Tests abgedeckt, und zwei Umkehrproben belegen, dass die Tests ihren Fehler fangen.
Der Angriffsdurchlauf findet nichts: kein Netzwerkpfad, keine Geheimnisse, und der Import
liest **genau eine** fremde Domain, nicht mehr.

---

**Aus Runde 5: Es gab keinen offenen Befund mehr.** BUG-01 bis BUG-10 sind alle behoben, H-04 auch.
Der Angriffsdurchlauf findet nichts: kein Netzwerkpfad im Store-Binary, keine
Ausnahme-Entitlements, keine Geheimnisse in der Historie. Alle vier Artefakte — Spec,
Entwurf, Plan, dieser Bericht — decken dieselben 53 Kriterien ab, ohne Verweis ins Leere.

**Und trotzdem ist das Feature nicht abnehmbar.** 26 von 53 Kriterien und **alle acht
Randfälle** konnten in keiner der fünf Runden ausgeführt werden. Sie brauchen ein
signiertes, sandboxed Programm mit erteilter Bildschirmaufnahme-Berechtigung — und das
braucht zwei Zertifikate, die es nicht gibt.

**Der Unterschied ist der Kern dieses Berichts:** Ein Feature ohne offenen Befund und ein
geprüftes Feature sind nicht dasselbe. Was hier fünfmal grün geworden ist, betrifft
Verpackung, Struktur und Text. **Ob die Anwendung unter Sandbox tut, was sie soll, ist
nach wie vor ungeprüft** — bei einem Werkzeug, das den gesamten Bildschirminhalt liest, ist
das der Teil, auf den es ankommt.

### Was für eine Abnahme fehlt

| Voraussetzung | Schaltet frei |
|---|---|
| `Apple Distribution` und `3rd Party Mac Developer Installer` unter `CWJM4J4HFN` | T27–T30, damit AK-40 bis AK-44 |
| Ein daraus gebautes, installiertes Paket | T19, T20, T22, T25, T26 — und damit 22 weitere Kriterien und alle acht Randfälle |
| ~~Notary-Profil im Schlüsselbund~~ — **liegt bereits vor** (`MikaScreenSnap`), zusammen mit `Developer ID Application`. Die Auslieferung von 3.5.0 als DMG ist damit **sofort ausführbar**, sie wurde nur nie angestoßen | T34 |

**Keine davon ist Arbeit an diesem Projekt.** Alle drei brauchen ein eingeloggtes
Entwicklerkonto und ein app-spezifisches Passwort.

---

**AK-33 ist erfüllt**, und der Abschnitt in `CHANGELOG.md` leistet mehr, als das Kriterium
verlangt: Er sagt nicht nur, dass angeheftete Bilder nicht mitkommen, sondern **wo die
Originale unangetastet liegen** und wie man sie zurückholt. Damit liest sich das Fehlen als
erwartetes Verhalten statt als Datenverlust — genau der Zweck des Kriteriums.

**BUG-10 ist behoben, und zwar an der richtigen Stelle:** Die Zusage sagt jetzt, wie sicher
sie ist — Mechanismus, Vorbehalt (*measured, but not yet with a build signed for the App
Store*) und Handlungsanweisung in einem Absatz. Sie deckt sich damit wörtlich mit dem
Vorbehalt aus `design.md`, TE-07. Auch H-04 ist erledigt.

`design.md` ist überarbeitet und verweist nicht mehr auf Entfallenes — nachgeprüft: 53 von
53 Zeilen gefüllt, keine nennt `MigrationImporter` oder `migrationOffered`. Die
Abdeckungstabelle in `tasks.md` verweist dagegen weiter auf T09, T10, T14 und T16, die alle
entfallen sind. Der Bauvorgang durfte sie nicht anfassen; sie gehört nach `/sdd-tasks 16`.

**Der Code ist seit Runde 3 unverändert** — dieser Durchgang hat nur Text geändert. 76
Tests grün in beiden Ausgaben.

Von 53 Kriterien konnten **25 ausgeführt** werden; 26 brauchen weiterhin ein laufendes,
sandboxed Programm mit erteilter Bildschirmaufnahme-Berechtigung.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 53 von 53 |
| Akzeptanzkriterien | **55** (AK-54 und AK-55 neu) |
| davon bestanden | 25 |
| davon durchgefallen | 0 |
| **offene Befunde** | **3** (BUG-11 bis BUG-13) |
| **nicht prüfbar** | 27 |
| trifft nicht zu (begründet) | 3 |
| Edge Cases belegt | 0 von 8 (EC-05 entfallen) |
| Befunde behoben (Runden 1–5) | 10 von 10, dazu H-04 |
| Befunde neu in Runde 5 | keine |
| Tests grün | 76 von 76 (DMG) · 76 von 76 (Store) |

**Die Testzahl ist gesunken, und das ist richtig so:** Zwölf Tests sind mit dem
zurückgebauten Importer entfallen. Sie prüften Code, den es nicht mehr gibt.

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 | ✅ bestanden | `scripts/build-appstore.sh` Selbstprüfung: `ok sandbox enabled` |
| AK-02 | ✅ bestanden | Selbstprüfung: `ok no temporary-exception entitlements` |
| AK-03 | ⚠️ nicht prüfbar | Container entsteht erst beim Start des signierten Pakets. In einer Wegwerf-Kennung nachgestellt (T01), aber nicht am echten Paket |
| AK-04 | ✅ bestanden | Selbstprüfung: `ok no Sparkle.framework embedded` + `ok binary does not link Sparkle`; `otool -L` nennt kein Sparkle |
| AK-05 | ✅ bestanden | Selbstprüfung: `ok no SUFeedURL` + `ok no SUPublicEDKey` |
| AK-06 | ⚠️ nicht prüfbar | braucht laufendes sandboxed Programm mit erteilter Aufnahmeberechtigung |
| AK-07 | ⚠️ nicht prüfbar | wie AK-06 |
| AK-08 | ⚠️ nicht prüfbar | wie AK-06 |
| AK-09 | ⚠️ nicht prüfbar | wie AK-06. **Die einzige Zugriffsregel der Anwendung — unbedingt manuell nachzuweisen** |
| AK-10 | ⚠️ nicht prüfbar | wie AK-09 |
| AK-11 | ⚠️ nicht prüfbar | Oberflächenverhalten, elf Werkzeuge |
| AK-12 | ⚠️ nicht prüfbar | BUG-01 behoben (`generateThumbnail` läuft in der Klammer), aber der positive Nachweis braucht ein laufendes sandboxed Programm |
| AK-13 | ⚠️ nicht prüfbar | braucht Aufnahmeberechtigung |
| AK-14 | ⚠️ nicht prüfbar | wie AK-13 |
| AK-15 | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-16 | ⚠️ nicht prüfbar | Fensterlebenszyklus über einen Neustart |
| AK-17 | ⚠️ nicht prüfbar | wie AK-16 |
| AK-18 | ⚠️ nicht prüfbar | BUG-01 behoben und per Umkehrprobe verifiziert. **Aber BUG-06 und BUG-07 betreffen genau diesen Pfad** — der Nachweis steht aus |
| AK-19 | ⚠️ nicht prüfbar | braucht echte Tastendrücke |
| AK-20 | ⚠️ nicht prüfbar | braucht Neuanmeldung |
| AK-21 | ⚠️ nicht prüfbar | Menü wird zur Laufzeit gebaut; die Bedingung ist im Code gesetzt, aber nicht ausgeführt worden |
| AK-22 | ⚠️ nicht prüfbar | teils belegt (`testSaveLocationBookmarkIsOwned`). **BUG-04 nur halb behoben** — siehe unten |
| AK-23 | ⚠️ nicht prüfbar | Oberflächenverhalten der Einstellungen |
| AK-24 | ⚠️ nicht prüfbar | wie AK-23 |
| AK-25 | ✅ bestanden | `otool -L` auf das Store-Binary: kein Sparkle, kein CFNetwork; `strings` findet keine Appcast-URL. Laufzeitbeobachtung über eine Stunde steht aus |
| AK-26 | ⚠️ nicht prüfbar | Ersteinrichtung ist Oberflächenverhalten |
| AK-27 | ⚠️ nicht prüfbar | braucht Ordnerauswahl im Panel |
| AK-28 | ⚠️ nicht prüfbar | Lesezeichen lassen sich ohne vorherige Nutzerauswahl nicht einmal erzeugen — in der Sandbox-Probe belegt |
| AK-29 | ⚠️ nicht prüfbar | wie AK-27 |
| AK-30 | ⚠️ nicht prüfbar | Fehlerzustand im Code angelegt, nicht ausgeführt |
| AK-31 | ✅ bestanden | `LegacyDefaultsCarryOverTests` — fünf Fälle: was ankommt, was nicht überschrieben wird, was unangetastet bleibt. Umkehrprobe: Schutz entfernt → `("OLD") is not equal to ("NEW")`. **Der Durchlauf mit einer echten Vorgängerinstallation steht aus (T26)** |
| AK-54 | ✅ bestanden | `nm -a` auf beide Binärstände: 12 `LegacyDefaultsImport`-Symbole im DMG-Build, **0** im Store-Build |
| AK-55 | ⚠️ nicht prüfbar | Auslösebedingung im Code erweitert; ob die Ersteinrichtung tatsächlich erscheint, ist Oberflächenverhalten |
| AK-32 | ✅ bestanden | Negativnachweis: `grep` über `Sources/` auf `migrat`, `carry-over`, `Übernahme`, `import.*pin` findet **keine Fundstelle**. Es gibt keine Abfrage, die erscheinen könnte |
| AK-33 | ✅ bestanden | `CHANGELOG.md`, Abschnitt *Moving from the direct download*: der Satz *Pinned screenshots do not come with you* samt *This is expected, not a failure* und dem Ablageort der Originale |
| AK-34 | ✅ bestanden | wie AK-32 — dieselbe Negativprüfung. Widerspruchsfrei erfüllbar, seit OF-04 entschieden ist |
| AK-35 | ✅ bestanden | Negativnachweis: keine hartkodierten Altpfade in `Sources/`; die einzigen Verweise auf `picturesDirectory` und `applicationSupportDirectory` sind Standardwert und Container-Auflösung. Die Anwendung schreibt nirgends in einen Altbestand |
| AK-36 | ✅ bestanden | `swift build` und `MIKA_APPSTORE=1 swift build` nacheinander, ohne Handänderung dazwischen; beide `Build complete!` |
| AK-37 | ✅ bestanden | beide Pakete melden `3.5.0 / 3.5.0`; die Store-`Info.plist` wird aus der gemeinsamen abgeleitet |
| AK-38 | ✅ bestanden | am gebauten DMG: Sparkle.framework eingebettet, `SUFeedURL` vorhanden, Sandbox-Wert `false`, ein Sparkle-Verweis im Binary |
| AK-39 | ✅ bestanden | 76 grün in beiden Ausgaben. `SaveLocationStoreTests` (9 Fälle) deckt Auflösung, Klammer und Ablehnung ab; zwei Umkehrproben (BUG-01, BUG-07) belegen, dass die Tests ihre Fehler fangen |
| AK-40 | ⚠️ nicht prüfbar | OF-07: `Apple Distribution` fehlt im Schlüsselbund |
| AK-41 | ⚠️ nicht prüfbar | OF-07 |
| AK-42 | ⚠️ nicht prüfbar | OF-07, OF-08 |
| AK-43 | ⚠️ nicht prüfbar | OF-07 |
| AK-44 | ⚠️ nicht prüfbar | OF-07 |
| AK-45 | ✅ bestanden | mit Vorbehalt: die drei neuen Protokollstellen geben nur `action` und den Problemtyp aus, keine Pfade und keine Dateinamen. **Hinweis H-01** zu `localizedDescription` |
| AK-46 | ✅ bestanden | `web/app/privacy/page.tsx`: Absatz „Mac App Store" unter *Analytics* nennt Apples Erhebung, die Systemeinstellung und die Abgrenzung zur App |
| AK-47 | ⚠️ nicht prüfbar | Store-Eintrag existiert nicht (OF-07) |
| AK-48 | ✅ bestanden | wie AK-25, statisch am Binary |
| AK-49 | ✅ bestanden | `git log --all -p` über die gesamte Historie: 0 Treffer auf private Schlüssel oder `.p8` |
| AK-50 | ✅ bestanden | `scripts/appstore-credentials.example.sh` vorhanden; `git check-ignore` bestätigt, dass die echte Datei ignoriert wird |
| AK-51 | ➖ trifft nicht zu | wie in der Spec begründet: keine Konten, kein Backend |
| AK-52 | ➖ trifft nicht zu | wie in der Spec begründet |
| AK-53 | ✅ bestanden | Selbstprüfung: `ok no undocumented screen-capture entitlement`; zusätzlich `ok no library-validation opt-out` |

**Bestanden: 18 · Durchgefallen: 2 · Eingeschränkt: 1 · Nicht prüfbar: 30 · Trifft nicht zu: 3**

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 | ⚠️ nicht prüfbar | im Code angelegt (`SaveLocationScreen.chooseFolder` kehrt bei Abbruch unverändert zurück), nicht ausgeführt |
| EC-02 | ⚠️ nicht prüfbar | braucht ein aushängbares Volume |
| EC-03 | ⚠️ nicht prüfbar | Fehlerzustand angelegt, nicht ausgeführt |
| EC-04 | ⚠️ nicht prüfbar | braucht Ordnerauswahl |
| EC-05 | ⚠️ nicht prüfbar | **T20 nicht gebaut**; Teilverhalten belegt durch `testCorruptFileIsSkippedWithoutLosingTheRest` |
| EC-06 | ⚠️ nicht prüfbar | braucht zwei Installationen |
| EC-07 | ⚠️ nicht prüfbar | wie EC-06 |
| EC-08 | ⚠️ nicht prüfbar | OF-07 |
| EC-09 | ⚠️ nicht prüfbar | braucht Entzug der Berechtigung am laufenden Programm |

**Kein einziger Randfall ist belegt.** Das ist der ehrlichste Satz in diesem Bericht.

## Sicherheitsprüfung

Aktiv geprüft, nicht nur gelesen. Grundlage: `~/.claude/sdd/sicherheit.md`, nach Stufe A
verkürzt auf Abschnitt 4 und 6, erweitert um Abschnitt 1.

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Zugriff auf fremde ID (IDOR) | ➖ trifft nicht zu | keine Konten, keine IDs, kein Backend |
| Rate Limit greift | ➖ trifft nicht zu | kein Endpunkt, kein kostenpflichtiger Aufruf |
| Personendaten in Logs | bestanden, mit H-01 | drei neue Protokollstellen geprüft: keine Pfade, keine Dateinamen |
| Personendaten an externe Dienste | bestanden | Store-Binary verlinkt weder Sparkle noch CFNetwork; `strings` findet keine URL |
| Sandbox als echte Grenze | **bestanden — gemessen** | sandboxed Probe: Lesen außerhalb des Containers scheitert mit `NSFileReadNoPermissionError` (257). Keine `temporary-exception` im Paket |
| Lesezeichen ohne Nutzerauswahl erzeugbar? | **bestanden** | Angriff: `bookmarkData(.withSecurityScope)` auf einen nicht ausgewählten Ordner schlägt fehl — die Ordnerwahl lässt sich nicht umgehen |
| Undokumentierte Entitlements | bestanden | `screen-capture` und `disable-library-validation` sind entfernt |
| Geheimnisse im Repository | bestanden | `git log --all -p`: 0 Treffer |

## Fehler

### BUG-12 · Die Versionshinweise sagen, Einstellungen gingen verloren — sie gehen nicht verloren — mittel *(neu in Runde 6)*

**Betrifft:** AK-31
**Fundstelle:** `CHANGELOG.md`, Abschnitt `[Unreleased]`, erster Punkt unter *Moving from
the direct download*: *Your settings do not come with you … hotkeys, the exclusion list and
drawing defaults return to their defaults.*
**Tatsächlich:** `LegacyDefaultsImport` übernimmt genau diese drei beim ersten Start unter
der neuen Kennung. Fünf Tests belegen es, eine Umkehrprobe belegt die Tests.
**Wie es entstand:** Der Text wurde beim Kennungswechsel geschrieben, als die Übernahme
noch nicht entschieden war. T35 kam danach und baute das Gegenteil; der Text blieb stehen.
**Warum es zählt — und zwar mehr, als es klingt:** Wer liest, er verliere seine
Einstellungen, richtet sie vorsorglich neu ein. Damit überschreibt er genau das, was der
Import gerettet hätte — die Schutzklausel *nicht überschreiben, was schon da ist* wendet
sich dann gegen ihn.
**Vorschlag:** Den Absatz auf das gebaute Verhalten umstellen: Einstellungen kommen im
Direktvertrieb mit, im App Store nicht; die Aufnahmeberechtigung ist in beiden Fällen weg.

### BUG-13 · Die Versionshinweise sagen, angeheftete Bilder gingen verloren — im Direktvertrieb tun sie das nicht — mittel *(neu in Runde 6)*

**Betrifft:** AK-33, AK-35
**Fundstelle:** `CHANGELOG.md`, derselbe Abschnitt: *neither do pinned screenshots* und
*Pinned screenshots do not come with you.*
**Tatsächlich:** `PinnedScreenshotManager.persistenceDir` löst auf
`~/Library/Application Support/MikaScreenSnap/PinnedScreenshots` auf — ein **fester
Ordnername, nicht die Bundle-Kennung** (`Sources/PinnedScreenshotManager.swift:16`). Im
DMG-Build sind die angehefteten Bilder nach dem Update also unverändert vorhanden.
**Wo der Satz stimmt:** beim Wechsel **zum App Store**. Dort liegt der Ordner im Container
und ist unerreichbar. Der Abschnitt vermengt zwei verschiedene Übergänge — Kennungswechsel
im Direktvertrieb und Wechsel der Vertriebsform —, die sich unterschiedlich verhalten.
**Warum es entstand:** Beim Schreiben wurde angenommen, der Pin-Ordner hänge wie
`UserDefaults` an der Bundle-Kennung. Er tut es nicht; das wurde nie nachgesehen.
**Vorschlag:** Die beiden Übergänge im Text trennen.

### BUG-11 · Toter Code nach der Umstellung von T36 — niedrig *(neu in Runde 6)*

**Betrifft:** kein Kriterium
**Fundstelle:** `Sources/MikaScreenSnapApp.swift:132`, `checkScreenCapturePermission()`
**Tatsächlich:** T36 hat die einzige Aufrufstelle durch `showOnboarding()` ersetzt. Die
Funktion samt Warnfenster und Systemeinstellungs-Verweis steht noch da und wird nie
aufgerufen — `grep` findet genau eine Fundstelle, die Definition.
**Vorschlag:** Entfernen. Der Ablauf lebt jetzt in der Ersteinrichtung.

### Stand aller bisherigen Befunde

| Befund | Grad | Status nach Runde 3 | Nachweis |
|---|---|---|---|
| BUG-01 | hoch | **behoben** | Umkehrprobe in Runde 2 |
| BUG-02 | mittel | **behoben, nicht ausgeführt** | Oberflächenverhalten |
| BUG-03 | niedrig | **behoben** | Ordnername stammt aus der geschriebenen Datei |
| BUG-04 | mittel | **behoben** | `resetAllPreferences` meldet jetzt, ob die Ersteinrichtung laufen muss; `testResetReportsWhetherFirstRunSetupMustRunAgain` prüft, dass Rückgabewert und Merkmal nie auseinanderlaufen |
| BUG-05 | niedrig | **behoben** | `SaveLocationStoreTests`, 9 Fälle |
| BUG-06 | mittel | **behoben** | `readingSaveFolder` (still) für `loadHistory`, `storageUsage`, `generateThumbnail`; `withSaveFolder` (meldend) bleibt für `saveImage`, `overwrite`, `deleteItem`, `clearAll`. Die Trennung ist im Code belegt, das Verhalten braucht ein laufendes Programm |
| BUG-07 | mittel | **behoben** | **Umkehrprobe:** `catch`-Zweig ausgehebelt → `("1") is not equal to ("0")`; wiederhergestellt → grün |

### BUG-10 · Die Versionshinweise machen eine Zusage, die der Entwurf ausdrücklich offen lässt — mittel *(Runde 4, in Runde 5 behoben)*

**Betrifft:** AK-31
**Fundstelle:** `CHANGELOG.md`, Abschnitt *Moving from the direct download*, erster Punkt.
**Was dort steht:** *Your settings come with you. Hotkeys, the exclusion list and drawing
defaults are there on first launch.* Ohne Einschränkung, als Tatsache.
**Was der Entwurf an derselben Stelle sagt:** `design.md`, Messprotokoll zu TE-07 —
*gemessen wurde mit einer ad-hoc signierten Probe; ob eine vom Store signierte Fassung mit
anderer Team-ID sich gleich verhält, ist wahrscheinlich, aber nicht bewiesen. Endgültige
Gewissheit gibt erst T28.*
**Warum es zählt:** Das ist die eine Aussage, die einen wechselnden Nutzer beruhigen soll.
Trifft sie nicht zu, verliert er sieben belegte Tastenkürzel und die Ausschlussliste — und
liest gleichzeitig in den Versionshinweisen, dass beides mitkommt. Eine unbelegte Zusage
gegenüber Nutzern wiegt schwerer als eine unbelegte Annahme im Entwurf, weil niemand mehr
nachfragt.
**Auch bemerkenswert:** AK-31 steht in diesem Bericht unter *nicht prüfbar*. Die
Versionshinweise behaupten damit etwas, das die QA ausdrücklich nicht bestätigen konnte.
**Vorschlag:** Entweder die Aussage bis zum Nachweis aus T28 abschwächen — oder T28
vorziehen und sie belegen. Beides ist vertretbar; sie unverändert stehen zu lassen nicht.

### BUG-08 · Die Versionshinweise sagen nichts über den App Store — mittel *(Runde 3, in Runde 4 behoben)*

**Betrifft:** AK-33
**Reproduktion:** `CHANGELOG.md` öffnen und nach „App Store" suchen.
**Erwartet:** AK-33 verlangt, dass die Versionshinweise **ausdrücklich** sagen, dass
angeheftete Bilder beim Wechsel vom Direktvertrieb nicht mitkommen.
**Tatsächlich:** Kein Treffer. Die neueste Fassung ist 3.5.0 vom 2026-08-25 und beschreibt
die SDD-Rückerfassung; der App Store kommt darin nicht vor.
**Warum es zählt:** Ohne diesen Satz erscheint das Fehlen der angehefteten Bilder als
Datenverlust. Genau deshalb steht er im Kriterium.
**Ort:** `CHANGELOG.md`
**Bemerkenswert:** Der Bauvorgang hat diese Lücke **selbst gemeldet**, statt sie ungefragt
zu füllen — das ist das gewünschte Verhalten, und der Befund steht hier, weil er dort
richtig gemeldet wurde.

### BUG-09 · Die Abdeckungstabellen zeigen ins Leere — mittel *(neu in Runde 3)*

**Betrifft:** die Nachverfolgbarkeit von AK-31 bis AK-35, nicht das Laufzeitverhalten
**Reproduktion:** In `design.md` und `tasks.md` die Zeilen zu AK-31 bis AK-35 lesen und die
dort genannten Bausteine im Code suchen.
**Tatsächlich:**

| Artefakt | verweist auf | im Code |
|---|---|---|
| `design.md` AK-31, AK-32, AK-34 | `MigrationImporter` (6 Nennungen) | **nicht vorhanden** |
| `design.md` AK-33 | `migrationOffered` | **nicht vorhanden** |
| `design.md` Komponentenbaum | `MigrationPrompt` | **nie gebaut** |
| `tasks.md` AK-31–AK-35 | T09, T10, T14, T16 | **entfallen** |

**Warum es zählt:** Die Abdeckungstabelle ist der Mechanismus, der garantiert, dass kein
Kriterium unbemerkt verschwindet. Zeigt sie auf Entfallenes, ist die Garantie weg — wer
AK-33 nachprüfen will, sucht eine gelöschte Eigenschaft statt der Versionshinweise, die
das Kriterium tatsächlich verlangt. Und genau AK-33 ist das eine, das durchgefallen ist.
**Ort:** `features/16-app-store-auslieferung/design.md`, Abschnitte *Komponentenstruktur*
und *Abdeckung* · `tasks.md`, Abschnitt *Abdeckung*
**Warum es nicht der Bauvorgang war:** `sdd-build` darf `design.md` nicht ändern. Der
Rückbau war korrekt; nachzuziehen ist er über `/sdd-architektur 16`.
**Vorschlag:** `design.md` über `/sdd-architektur 16` neu fassen, danach `tasks.md`.

### Behobene Befunde im Wortlaut (Runde 1 und 2)

| Befund | Status Runde 2 | Nachweis |
|---|---|---|
| BUG-01 | **behoben** | Umkehrprobe: Schutzzeilen entfernt → `testDeletingDoesNotDropTheEntryWhenTheFolderIsGone` und `testClearAllKeepsTheListWhenTheFolderIsGone` fallen durch; wiederhergestellt → grün. `resolve` kommt im `ScreenshotHistoryManager` nicht mehr vor |
| BUG-02 | **behoben, nicht ausgeführt** | „Open Folder" geht durch `resolve` und meldet bei `.failure`. Oberflächenverhalten, in dieser Sitzung nicht ausführbar |
| BUG-03 | **behoben** | Der Ordnername stammt aus der geschriebenen Datei |
| BUG-04 | **nur halb behoben** | siehe unten |
| BUG-05 | **behoben** | `SaveLocationStoreTests`, 9 Fälle |

### BUG-04 · Die Sackgasse nach dem Zurücksetzen besteht bis zum Neustart fort — mittel *(aus Runde 1, halb behoben)*

**Betrifft:** AK-22, AK-26
**Behebung war:** `hasCompletedOnboarding` wird im Store-Build beim Zurücksetzen auf
`false` gesetzt.
**Warum das nicht reicht:** Der Wert wird an genau einer Stelle ausgewertet —
`Sources/MikaScreenSnapApp.swift:59`, beim Programmstart. Wer in den Einstellungen
zurücksetzt, sitzt danach in einer laufenden Anwendung ohne Speicherort: Jede Aufnahme
meldet „Choose a folder to save screenshots to.", und die Ersteinrichtung erscheint erst
beim **nächsten Start**. Bei einem Programm, das dauerhaft in der Menüleiste liegt, kann
das Tage dauern.
**Ort:** `Sources/AppPreferences.swift:166`–`:172` zusammen mit `MikaScreenSnapApp.swift:59`
**Vorschlag:** Beim Zurücksetzen im Store-Build die Ersteinrichtung direkt öffnen, statt
nur ein Merkmal zu setzen, das niemand mehr liest.

### BUG-06 · Lesevorgänge melden jetzt wie Schreibvorgänge — mittel *(neu in Runde 2)*

**Betrifft:** AK-18, AK-24
**Reproduktion:** Store-Build vor der Ordnerwahl starten (oder nach einem Zurücksetzen),
Einstellungen öffnen.
**Erwartet:** Die Anwendung startet still; die Einstellungen zeigen „0 screenshots".
**Tatsächlich:** `loadHistory` läuft im `init` des Verlaufs (`ScreenshotHistoryManager.swift:28`),
`storageUsage` direkt im Rumpf der SwiftUI-Ansicht (`AdvancedTabView.swift:97`) — also bei
**jedem Neuzeichnen**. Beide gehen seit der Behebung von BUG-01 durch
`SaveLocationStore.withSaveFolder`, das jeden Fehlschlag über `CaptureLog.report`
**als Hinweis anzeigt**. Im Erststart-Zustand ist „kein Ordner gewählt" aber der normale
Zustand, kein Fehler. Ergebnis: ein Hinweis beim Start und eine Folge weiterer beim Öffnen
der Einstellungen.
**Ort:** `Sources/SaveLocationStore.swift:117` in Verbindung mit
`ScreenshotHistoryManager.swift:79, :174`
**Warum es zählt:** Die Regel aus `CLAUDE.md` lautet, Fehlerpfade sichtbar zu machen — nicht,
Normalzustände zu melden. Eine Anwendung, die beim ersten Start Fehler meldet, wird
deinstalliert, bevor sie erklären kann, dass alles in Ordnung ist.
**Vorschlag:** Die Klammer um eine stille Variante ergänzen, die `nil` liefert, ohne zu
melden — Lesepfade benutzen sie, Schreibpfade die meldende.

### BUG-07 · Ein Eintrag, dessen Datei extern gelöscht wurde, lässt sich nicht mehr aus dem Verlauf entfernen — mittel *(neu in Runde 2)*

**Betrifft:** AK-18
**Reproduktion:** Aufnahme machen, die Datei im Finder löschen, im Verlauf den Eintrag
entfernen.
**Erwartet:** Der Eintrag verschwindet — die Datei ist ohnehin weg.
**Tatsächlich:** `removeItem` wirft „No such file", die Klammer meldet den Fehler und gibt
`nil` zurück, und `guard removed == true else { return }` lässt den Eintrag stehen. Er ist
damit dauerhaft nicht mehr zu entfernen.
**Ort:** `Sources/ScreenshotHistoryManager.swift:118`–`:131`
**Beleg:** `AppStoreQAProbeTests.testEntryCanStillBeRemovedAfterTheFileVanishedExternally`
— läuft mit `XCTExpectFailure`; ohne die Erwartung meldet der Test `("1") is not equal to ("0")`.
**Warum es entstanden ist:** Die Behebung von BUG-01 hat richtig unterschieden zwischen
„Ordner nicht erreichbar" und „gelöscht". Sie hat aber den dritten Fall übersehen: „Datei
schon weg" — und der ist ein Erfolg, kein Fehlschlag.
**Vorschlag:** Ein `NSFileNoSuchFileError` beim Entfernen als Erfolg behandeln.

### BUG-01 · Verlauf, Löschen und Vorschaubilder arbeiten ohne offenen Sandbox-Zugriff — hoch

**Betrifft:** AK-12, AK-18
**Reproduktion:** Store-Build installieren, Speicherordner wählen, drei Aufnahmen machen,
Verlauf öffnen.
**Erwartet:** Alle drei erscheinen; eine lässt sich löschen; „Clear History" leert den
Ordner.
**Tatsächlich:** `SaveLocationStore.resolve` liefert die URL, schließt den Zugriff aber im
selben Aufruf wieder (`accessing(_:)` mit `defer`). Die anschließenden Dateioperationen
laufen ohne offenen Zugriff und scheitern in der Sandbox. Der Verlauf bliebe leer,
Vorschaubilder entstünden nicht, und **gelöscht würde nichts** — bei stillem `try?` ohne
jede Meldung.
**Ort:** `Sources/ScreenshotHistoryManager.swift:80` (`loadHistory`), `:118`/`:119`
(`deleteItem`), `:133`–`:144` (`clearAll`), `:176`–`:209` (`generateThumbnail`)
**Warum es zählt:** Verletzt die App-weite Regel aus `docs/prd.md` — „jeder Schreibpfad hat
einen Löschpfad". Ein stiller Löschfehler ist genau das Muster, das bei B08 schon einmal zu
einem unbegrenzt wachsenden Ablageort geführt hat.
**Vorschlag:** Diese vier Stellen durch `SaveLocationStore.withSaveFolder` führen statt
durch `resolve` — die Klammer existiert bereits und wird von `saveImage` korrekt benutzt.

### BUG-02 · „Im Finder öffnen" zeigt auf den falschen Ordner — mittel

**Betrifft:** AK-18
**Reproduktion:** Store-Build, in den Einstellungen den Speicherordner im Finder öffnen.
**Erwartet:** der gewählte Ordner.
**Tatsächlich:** `preferences.saveLocation` wird direkt benutzt statt des aufgelösten
Ordners. Nach einem Zurücksetzen zeigt der Wert auf `~/Pictures/MikaScreenSnap`, wo im
Store-Build nie etwas lag.
**Ort:** `Sources/Preferences/AdvancedTabView.swift:125`
**Vorschlag:** über `SaveLocationStore.resolve` gehen; bei `.failure` den Hinweis aus
`SaveLocationProblem` zeigen statt einen leeren Ordner zu öffnen.

### BUG-03 · Bestätigung nennt möglicherweise den falschen Ordnernamen — niedrig

**Betrifft:** AK-27
**Reproduktion:** Store-Build, angeheftetes Bild sichern.
**Tatsächlich:** Der Hinweis liest `prefs.saveLocation.lastPathComponent`, nicht den
tatsächlich beschriebenen Ordner. Weichen beide ab, behauptet die Anwendung etwas
Falsches.
**Ort:** `Sources/PinnedScreenshotPanel.swift:189`
**Vorschlag:** den Namen aus dem Ergebnis des Schreibvorgangs nehmen.

### BUG-04 · Nach dem Zurücksetzen hat der Store-Build keinen Speicherort und keinen Weg zu einem — mittel

**Betrifft:** AK-22, AK-26
**Reproduktion:** Store-Build, „Reset All Preferences" ausführen, Aufnahme auslösen.
**Erwartet:** Die Anwendung ist wieder benutzbar.
**Tatsächlich:** `resetAllPreferences` löscht `saveLocationBookmark`, lässt aber
`hasCompletedOnboarding` bewusst auf `true`. Die Ersteinrichtung — der einzige Ort, der
nach einem Ordner fragt — läuft damit nie wieder. Jede Aufnahme meldet „Choose a folder…",
ohne dass es einen Weg dorthin gibt außer den Einstellungen, die der Nutzer nicht von
selbst aufsucht.
**Ort:** `Sources/AppPreferences.swift:170`–`:181`
**Beleg:** `AppStoreQAProbeTests.testResetLeavesAppStoreBuildWithoutASaveLocation`
**Vorschlag:** Im Store-Build beim Zurücksetzen entweder `hasCompletedOnboarding` auf
`false` setzen oder direkt den Ordnerdialog anbieten.

### BUG-05 · Die von T21 geforderte Lesezeichen-Abdeckung fehlte — niedrig

**Betrifft:** AK-39
**Tatsächlich:** T21 verlangte ausdrücklich „Lesezeichen auflösen und ins Leere laufen
lassen". Der Bauvorgang lieferte Tests für den Importer und die Einstellungsschlüssel,
aber keinen einzigen für `SaveLocationStore`. Die Komponente, an der der gesamte
Schreibpfad hängt, war ungetestet — und BUG-01 wäre genau dort aufgefallen.
**Ort:** `Tests/AppStoreEditionTests.swift`
**Beleg:** QA hat `AppStoreQAProbeTests` nachgelegt; die Auflösung unter echter Sandbox
bleibt ungetestet, weil ein Lesezeichen ohne Nutzerauswahl nicht erzeugbar ist.
**Vorschlag:** Auflösung mit einspeisbarem Lesezeichen testbar machen.

## Hinweise

**H-01 · Ordnername kann über `localizedDescription` ins Protokoll geraten.**
`CaptureLog.report(error, action:)` gibt die Fehlerbeschreibung des Systems aus, und die
enthält bei Dateifehlern den Namen des betroffenen Ordners. Dateinamen dieser Anwendung
sind Zeitstempel und damit unverfänglich — ein vom Nutzer gewählter Ordnername muss das
nicht sein. Kein durchgefallenes Kriterium, aber ein Punkt für die Spec.

**H-04 · Der Einleitungssatz zählt falsch.** `CHANGELOG.md`, zweiter Absatz: *Which one
you have determines the two differences below* — darunter stehen fünf Punkte in zwei
Abschnitten. Kein Kriterium betroffen, aber der Satz stimmt nicht.

**H-03 · `readingSaveFolder` schweigt auch bei echten Fehlern.** Die stille Klammer aus
der Behebung von BUG-06 unterscheidet nicht zwischen „noch kein Ordner gewählt" (normal)
und „Ordner verschwunden" (echter Fehler). Im zweiten Fall bleibt der Verlauf leer, ohne
Erklärung. AK-30 fängt das ab, sobald der Nutzer eine Aufnahme auslöst — bis dahin sieht
er einen leeren Verlauf und weiß nicht, warum. Kein durchgefallenes Kriterium, aber ein
Punkt für die Spec.

**H-02 · Nebenbefund aus dem Bauvorgang, gehört zu B14.** Die installierte Fassung trägt
`SUFeedURL = …/Mukaarts/…`, im Code steht `…/daumedia/…`; Sparkle bevorzugt den Wert aus
den Einstellungen. Keiner der `SU*`-Schlüssel steht in `ownedDefaultsKeys`. Aufgenommen in
`features/befunde.md`.

## Neue Tests

| Datei | Fälle | Deckt ab |
|---|---|---|
| `Tests/AppStoreEditionTests.swift` | 24 | AK-22, AK-31–AK-35, AK-39; `SaveLocationStoreTests` und `HistoryWithoutSaveLocationTests` aus der Behebung von BUG-01/BUG-05 |
| `Tests/AppStoreQAProbeTests.swift` | 4 | BUG-04, BUG-05, Sandbox-Erkennung, **BUG-07** (mit `XCTExpectFailure`) |

Alle grün: 77 von 77 (DMG), 87 von 87 (Store). Der Test zu BUG-07 ist grün, **weil der
Fehlschlag erwartet wird** — er dokumentiert den Befund, er behebt ihn nicht.

## Was dieser Bericht nicht sagen kann

Dreißig Kriterien und alle neun Randfälle stehen unter *nicht prüfbar*, nicht unter
*bestanden*. Sie brauchen ein signiertes, sandboxed Programm mit erteilter
Bildschirmaufnahme-Berechtigung — und für ein Drittel davon ein Entwicklerkonto, das es
noch nicht gibt. **Der ausgelieferte Store-Build ist damit in keiner seiner
Kernfunktionen geprüft.** Was hier grün steht, betrifft die Verpackung, nicht das Verhalten.

## Nächster Schritt

`/sdd-build 16` mit dem Auftrag **BUG-11 bis BUG-13**. Alle drei sind Text- und
Aufräumarbeit, keine braucht ein Zertifikat.

**Ein Hinweis für diesen Durchgang:** BUG-12 und BUG-13 stehen im selben Absatz und haben
verschiedene Ursachen — der eine Satz wurde vom Code überholt, der andere beruhte auf einer
ungeprüften Annahme über den Ablageort. Wer sie behebt, sollte den Absatz **entlang der
zwei Übergänge** neu schneiden, die er heute vermengt: Kennungswechsel im Direktvertrieb
(Einstellungen und Pins kommen mit, Berechtigung nicht) gegen Wechsel zum App Store (nichts
kommt mit). Ein Satz, der beide gleichzeitig beschreibt, wird wieder für einen der beiden
falsch sein.

## Was danach bleibt

**Keiner in dieser Kette.** Es gibt keinen Befund zu beheben, keine Aufgabe, die ohne
externe Voraussetzung ausführbar wäre, und keine offene Entscheidung. Fünf QA-Runden haben
den Anteil, der sich hier prüfen lässt, ausgeschöpft.

Der einzige Weg weiter führt über drei Schritte am Entwicklerkonto:

1. **`bash scripts/notarize.sh`** — **keine Einrichtung nötig.** Profil und Zertifikat
   liegen vor; der Schritt wurde seit dem 2026-08-25 nur nicht ausgeführt. **Größter
   unmittelbarer Nutzen:** 3.5.0 enthält den Fix, dass eine Zensur nicht mehr das
   unbearbeitete Original im Verlaufsordner zurücklässt.
2. **App-ID und Zertifikate unter `CWJM4J4HFN`** — `Apple Distribution` und
   `3rd Party Mac Developer Installer`. Schaltet T27 bis T30 frei.
3. **Das daraus gebaute Paket installieren** — schaltet T19, T20, T22, T25, T26 frei und
   damit 22 Kriterien und alle acht Randfälle.

Erst danach lohnt ein weiteres `/sdd-qa 16`.

## Beobachtung über fünf Runden

| Runde | Gefunden | Art |
|---|---|---|
| 1 | 5 | Codefehler, davon einer *hoch* |
| 2 | 2 | **Folgefehler der Behebung aus Runde 1** |
| 3 | 2 | keiner im Code — Artefakt und Versionshinweise |
| 4 | 1 | eine unbelegte Zusage in den Versionshinweisen |
| 5 | 0 | — |

Der Codeanteil ist seit Runde 3 sauber. Was danach gefunden wurde, saß **zwischen** den
Artefakten: BUG-09 war eine Anforderungsänderung, die nachgelagerte Dokumente nicht
erreichte; BUG-10 eine Aussage, die beim Weiterreichen ihren Vorbehalt verlor. Beide Male
hat kein Werkzeug versagt — es fehlt in der Kette die Stelle, die nach einer Änderung
prüft, **was sonst noch davon abhängt.**

**Und ein Satz, der wichtiger ist als die Nulllinie in Runde 5:** Dass nichts mehr gefunden
wird, heißt hier nicht, dass nichts mehr da ist. Es heißt, dass die Prüfmittel erschöpft
sind. Die 26 ungeprüften Kriterien betreffen die Aufnahme selbst, die Ausschlussliste und
das Zensurverhalten unter Sandbox — also genau die Funktionen, bei denen ein Fehler
Bildschirminhalte preisgäbe.
