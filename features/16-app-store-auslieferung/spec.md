# 16 · App-Store-Auslieferung — Spezifikation

Status: `planned` · Stand: 2026-09-03

> **Dieses Feature hebt eine PRD-Entscheidung auf.** `docs/prd.md` führt App-Store-Vertrieb
> unter *Nicht im Scope* (OF-01, bestätigt 2026-08-25) mit der Begründung, die Anwendung
> brauche den Verzicht auf die Sandbox für ScreenCaptureKit und Carbon-Tastenkombinationen.
> Beides ist sachlich falsch (Nachweis unter *Decision Log*, Zeile 1 und 16). Das PRD ist
> entsprechend nachzuführen — Abschnitte *Nicht im Scope*, *Rahmenbedingungen · Sandbox*,
> *Rahmenbedingungen · Vertrieb*, *Datenschutz* und *OF-01*. Solange das nicht geschehen
> ist, widersprechen sich zwei Artefakte.

## Zweck

Mika+ScreenSnap wird über den Mac App Store installierbar, ohne dass jemand ein DMG lädt,
einer Signatur vertraut oder eine Gatekeeper-Warnung wegklickt. Der Direktvertrieb über
DMG und Sparkle bleibt unverändert daneben bestehen.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 Bildschirmaufnahme | approved | muss unter Sandbox dieselben drei Aufnahmeformen liefern |
| B02 App-Ausschluss | approved | die einzige Zugriffsregel der Anwendung — muss unter Sandbox greifen |
| B08 Screenshots anheften | approved | schreibt nach `Application Support`, das im Container liegt |
| B09 Screenshot-Verlauf | approved | schreibt nach `~/Pictures/`, das ohne Nutzerwahl unerreichbar wird |
| B11 Einstellungen | approved | zeigt Update-Einstellungen, die es im Store-Build nicht gibt |
| B12 Ersteinrichtung | approved | bekommt den Ordnerwahl-Schritt |
| B14 Automatische Updates | approved | entfällt im Store-Build vollständig |

Alle fünfzehn Bestandsfeatures sind mittelbar betroffen, weil sie unter Sandbox laufen
müssen. Die sieben oben genannten ändern ihr Verhalten sichtbar.

## User Stories

- **US-01** · Als jemand, der die App auf GitHub gefunden hat, möchte ich sie über den
  App Store installieren, damit ich keiner Signatur vertrauen und keine
  Gatekeeper-Warnung wegklicken muss.
- **US-02** · Als bestehender DMG-Nutzer möchte ich beim Wechsel auf die Store-Fassung
  meine Tastenkürzel, Ausschlussliste und angehefteten Bilder behalten, damit der
  Wechsel kein Neuanfang ist.
- **US-03** · Als Nutzer der Store-Fassung möchte ich meine Screenshots im Finder an
  einer Stelle wiederfinden, die ich selbst bestimmt habe, damit sie nicht in einem
  Systemordner verschwinden.
- **US-04** · Als Autor möchte ich beide Ausgaben aus einer Quelle bauen, damit ein
  Fehler nicht zweimal behoben werden muss.
- **US-05** · Als Autor möchte ich, dass die Datenschutzzusage auch für Store-Nutzer
  stimmt, damit die Seite unter `web/app/privacy/` keine Behauptung enthält, die für
  einen Teil der Nutzer falsch geworden ist.

## Nicht im Scope

- **In-App-Käufe, Abonnements, Preis.** Die App bleibt kostenlos (`docs/prd.md`,
  *Monetarisierung*). Ein Erlösmodell wäre ein eigenes Feature mit StoreKit,
  Funktionsgrenze und Wiederherstellen-Funktion.
- **Universal Binary / Intel-Unterstützung.** Bleibt arm64-only (OF-02). Der Store
  blendet die App auf Intel-Macs aus.
- **Lokalisierung der Oberfläche.** Der Store-Eintrag ist englisch, die Oberfläche
  bleibt englisch. Eine deutsche Fassung wäre ein eigenes Feature.
- **TestFlight-Vorabverteilung.** Bewusst ausgelassen (Decision Log, Zeile 12).
- **Ablösung des Direktvertriebs.** DMG, Appcast und Sparkle bleiben unverändert;
  OF-03 des PRD („unbefristet") gilt weiter.
- **Änderungen am PRD.** Gehören nach `/sdd-init`, nicht hierher.

## Akzeptanzkriterien

### Sandbox aktiv und begrenzt

- **AK-01** · Angenommen, die Store-Fassung ist gebaut, wenn
  `codesign -d --entitlements - "build/Mika+ScreenSnap.app"` ausgeführt wird, dann ist
  `com.apple.security.app-sandbox` auf `true` gesetzt.
- **AK-02** · Angenommen, die Store-Fassung ist gebaut, wenn ihre Entitlements gelesen
  werden, dann enthält die Liste keinen Schlüssel, der mit
  `com.apple.security.temporary-exception` beginnt.
- **AK-03** · Angenommen, die Store-Fassung wurde einmal gestartet, wenn im Finder
  `~/Library/Containers/com.mika.mikaplusscreensnap/` geöffnet wird, dann existiert
  dieser Ordner.
- **AK-04** · Angenommen, die Store-Fassung ist gebaut, wenn ihr Programmpaket auf
  `Contents/Frameworks/Sparkle.framework` geprüft wird, dann ist dieser Pfad nicht
  vorhanden.
- **AK-05** · Angenommen, die Store-Fassung ist gebaut, wenn ihre `Info.plist` gelesen
  wird, dann enthält sie weder `SUFeedURL` noch `SUPublicEDKey`.
- **AK-53** · Angenommen, die Store-Fassung ist gebaut, wenn ihre Entitlements gelesen
  werden, dann ist `com.apple.security.screen-capture` **nicht** enthalten, und die
  Bildschirmaufnahme funktioniert trotzdem (AK-06 bis AK-08). Der Schlüssel ist in
  Apples Entitlement-Referenz nicht dokumentiert; die Prüfung bei der Einreichung
  beanstandet unbekannte `com.apple.security.*`-Schlüssel.

### Funktionsgleichheit — jedes Bestandsfeature unter Sandbox

- **AK-06** · Angenommen, die Store-Fassung hat die Bildschirmaufnahme-Berechtigung,
  wenn eine Vollbildaufnahme ausgelöst wird, dann öffnet sich der Editor mit einem Bild,
  das den gesamten Bildschirm unter dem Mauszeiger in voller Auflösung zeigt.
- **AK-07** · Angenommen wie AK-06, wenn eine Bereichsaufnahme ausgelöst und ein Rechteck
  gezogen wird, dann zeigt der Editor genau diesen Bereich.
- **AK-08** · Angenommen wie AK-06, wenn eine Fensteraufnahme ausgelöst und ein fremdes
  Fenster gewählt wird, dann zeigt der Editor dieses Fenster.
- **AK-09** · Angenommen, eine App steht auf der Ausschlussliste, wenn eine
  Vollbildaufnahme gemacht wird, während ein Fenster dieser App sichtbar ist, dann ist
  dieses Fenster in der Aufnahme nicht enthalten.
- **AK-10** · Angenommen wie AK-09, wenn stattdessen die Texterkennung oder die
  Farbpipette über diesem Fenster benutzt wird, dann liefert auch sie keinen Inhalt aus
  diesem Fenster.
- **AK-11** · Angenommen, der Editor ist offen, wenn nacheinander alle elf Werkzeuge
  benutzt und je einmal rückgängig gemacht werden, dann verhält sich jedes so wie in der
  DMG-Fassung, und der Export enthält das erwartete Ergebnis.
- **AK-12** · Angenommen, ein Bereich wurde verpixelt, wenn exportiert wird, dann ist der
  verpixelte Bereich in der Ausgabedatei nicht rekonstruierbar, und die automatisch
  gesicherte Datei im Verlauf zeigt ebenfalls die zensierte Fassung.
- **AK-13** · Angenommen wie AK-06, wenn die Texterkennung über einem Bereich mit
  deutschem, englischem oder französischem Text ausgeführt wird, dann liegt der erkannte
  Text in der Zwischenablage.
- **AK-14** · Angenommen wie AK-06, wenn die Farbpipette benutzt und ein Pixel gewählt
  wird, dann steht dessen HEX-Wert in der Zwischenablage.
- **AK-15** · Angenommen wie AK-06, wenn das Lineal-Overlay geöffnet und ein Abstand
  gemessen wird, dann entspricht der angezeigte Wert dem Pixelabstand auf dem Bildschirm,
  auf dem gemessen wurde.
- **AK-16** · Angenommen, ein Screenshot ist angeheftet, wenn die App beendet und neu
  gestartet wird, dann erscheint das angeheftete Fenster wieder.
- **AK-17** · Angenommen, ein angehefteter Screenshot wird geschlossen, wenn danach der
  Ablageort im Container geöffnet wird, dann ist die zugehörige Datei gelöscht.
- **AK-18** · Angenommen, es wurden drei Aufnahmen gemacht, wenn der Verlauf geöffnet
  wird, dann sind alle drei sichtbar, und „Im Finder zeigen" öffnet den vom Nutzer
  gewählten Ordner mit ausgewählter Datei.
- **AK-19** · Angenommen, die Store-Fassung läuft, wenn nacheinander alle sieben
  systemweiten Tastenkombinationen gedrückt werden, dann löst jede genau eine Aktion aus
  — auch nachdem eine Belegung zuvor dreimal geändert wurde.
- **AK-20** · Angenommen, „Bei Anmeldung starten" ist in den Einstellungen aktiviert,
  wenn der Rechner neu angemeldet wird, dann erscheint das Menüleistensymbol ohne
  weiteres Zutun.
- **AK-21** · Angenommen, die Store-Fassung läuft, wenn auf das Menüleistensymbol
  geklickt wird, dann öffnet sich das Menü mit allen Einträgen, und die Anwendung
  erscheint weiterhin nicht im Dock.
- **AK-22** · Angenommen, „Alle Einstellungen zurücksetzen" wird ausgeführt, wenn danach
  jede Einstellung geprüft wird, dann steht jede auf ihrem Standardwert.

### Update-Weg im Store-Build

- **AK-23** · Angenommen, die Store-Fassung läuft, wenn die Einstellungen geöffnet
  werden, dann gibt es dort weder eine Schaltfläche „Nach Updates suchen" noch eine
  Einstellung zur automatischen Aktualisierung.
- **AK-24** · Angenommen wie AK-23, wenn an derselben Stelle nachgesehen wird, dann steht
  dort ein Hinweis, dass Updates über den App Store kommen.
- **AK-25** · Angenommen, die Store-Fassung läuft eine Stunde lang, wenn der Netzwerkverkehr
  des Prozesses beobachtet wird, dann geht keine Verbindung zu `raw.githubusercontent.com`.

### Speicherort und Ordnerwahl

- **AK-26** · Angenommen, die Store-Fassung wird zum ersten Mal gestartet, wenn die
  Ersteinrichtung bis zum Ende durchlaufen wird, dann wurde nach der Berechtigungsseite
  ein Schritt gezeigt, auf dem ein Speicherordner gewählt wird.
- **AK-27** · Angenommen, in diesem Schritt wurde ein Ordner gewählt, wenn danach eine
  Aufnahme gemacht wird, dann liegt die Datei in genau diesem Ordner und ist im Finder
  sichtbar.
- **AK-28** · Angenommen, ein Ordner wurde gewählt, wenn die App beendet und neu gestartet
  wird und eine weitere Aufnahme erfolgt, dann landet auch diese in demselben Ordner —
  ohne erneuten Dialog.
- **AK-29** · Angenommen, in den Einstellungen wird ein anderer Ordner gewählt, wenn
  danach eine Aufnahme gemacht wird, dann liegt sie im neuen Ordner, und die vorherigen
  Aufnahmen bleiben im alten liegen.
- **AK-30** · Angenommen, der gewählte Ordner wurde außerhalb der App umbenannt oder
  gelöscht, wenn eine Aufnahme ausgelöst wird, dann erscheint ein Hinweis, der zur
  erneuten Ordnerwahl auffordert, und die Aufnahme geht nicht verloren.

### Umzug von der DMG-Fassung

> **Neu gefasst am 2026-09-03 durch die Entscheidung zu OF-04.** Bis dahin beschrieben
> diese fünf Kriterien eine Übernahme, die die Anwendung selbst durchführt. T01 hat
> gemessen, dass macOS die Einstellungen von sich aus übernimmt — und dass angeheftete
> Bilder aus dem Container nicht erreichbar sind. Die Nummern bleiben, weil `design.md`,
> `tasks.md` und `qa-report.md` auf sie verweisen; der Inhalt beschreibt jetzt, was
> tatsächlich geschieht.

- **AK-31** · Angenommen, eine DMG-Installation mit sieben belegten Tastenkürzeln,
  gefüllter Ausschlussliste und geänderten Zeichen-Standards ist vorhanden, wenn die
  Store-Fassung zum ersten Mal gestartet wird, dann sind alle drei unverändert vorhanden —
  **ohne dass gefragt wurde**.
- **AK-32** · Angenommen wie AK-31, wenn die Ersteinrichtung durchlaufen wird, dann
  erscheint an keiner Stelle eine Frage nach der Übernahme alter Daten.
- **AK-33** · Angenommen, eine DMG-Installation mit zwei angehefteten Bildern ist
  vorhanden, wenn die Store-Fassung zum ersten Mal gestartet wird, dann erscheinen diese
  Bilder **nicht** — und die Versionshinweise sagen das ausdrücklich, statt es dem Nutzer
  als Fehler erscheinen zu lassen.
- **AK-34** · Angenommen, es existierte nie eine DMG-Installation, wenn die Store-Fassung
  zum ersten Mal gestartet wird, dann wird zu keinem Zeitpunkt nach einer Übernahme
  gefragt. *(Unverändert — und jetzt widerspruchsfrei erfüllbar.)*
- **AK-35** · Angenommen, die Store-Fassung wurde nach einer DMG-Installation gestartet,
  wenn danach `~/Pictures/MikaScreenSnap/` und
  `~/Library/Application Support/MikaScreenSnap/` im Finder geöffnet werden, dann sind
  beide **unverändert vorhanden** — die Store-Fassung hat nichts verschoben und nichts
  gelöscht.

### Eine Quelle, zwei Ausgaben

- **AK-36** · Angenommen, das Projekt liegt unverändert vor, wenn nacheinander der
  DMG-Build und der Store-Build erzeugt werden, dann entstehen zwei Programmpakete, ohne
  dass zwischen den Läufen eine Quelldatei von Hand geändert werden musste.
- **AK-37** · Angenommen, beide Ausgaben sind gebaut, wenn ihre Versionsnummern verglichen
  werden, dann sind `CFBundleShortVersionString` und `CFBundleVersion` in beiden gleich.
- **AK-38** · Angenommen, der DMG-Build wird nach Einführung des Store-Builds erzeugt,
  wenn er installiert und gestartet wird, dann verhält er sich wie vor diesem Feature:
  Sparkle prüft den Appcast, der Speicherort ist `~/Pictures/MikaScreenSnap/`, und es
  erscheint kein Ordnerdialog.
- **AK-39** · Angenommen, `swift test` wird ausgeführt, wenn der Lauf endet, dann sind
  alle Tests grün, und die Testabdeckung schließt die Ordnerwahl und den Umzug ein.

### Einreichung

- **AK-40** · Angenommen, das Store-Paket ist gebaut und signiert, wenn
  `codesign -dvvv` darauf ausgeführt wird, dann nennt die Ausgabe die Team-ID des
  Entwicklerkontos und keine Ad-hoc-Signatur.
- **AK-41** · Angenommen, das Store-Paket liegt vor, wenn es über App Store Connect
  hochgeladen wird, dann wird es ohne Fehlermeldung angenommen und erscheint als Build
  im Eintrag.
- **AK-42** · Angenommen, der Store-Eintrag ist angelegt, wenn er vor dem Einreichen
  geprüft wird, dann sind Name, Untertitel, Beschreibung, Stichworte, Support-Adresse,
  Datenschutz-Link, Kategorie, Alterseinstufung und mindestens ein Bildschirmfoto
  ausgefüllt — alles auf Englisch.
- **AK-43** · Angenommen, der Store-Eintrag ist ausgefüllt, wenn die Support-Adresse und
  der Datenschutz-Link geöffnet werden, dann führen sie auf die GitHub-Issues des
  Projekts beziehungsweise auf die bestehende Datenschutzseite.
- **AK-44** · Angenommen, alles Vorstehende ist erfüllt, wenn der Build zur Prüfung
  eingereicht wird, dann steht der Eintrag in App Store Connect auf „Warten auf Prüfung".

### Datenschutz und Missbrauchsschutz

Fragenkatalog: `~/.claude/sdd/sicherheit.md`. Nach Stufe A gilt er verkürzt auf
Abschnitt 4 und 6, hier erweitert um Abschnitt 1 (`docs/prd.md`, *Datenschutz*).

- **AK-45** · *(Katalog 1)* Angenommen, die Store-Fassung wird benutzt, wenn danach die
  Systemprotokolle nach dem Prozess durchsucht werden, dann enthält kein Eintrag
  Bildinhalte, erkannten Text, Farbwerte oder Dateinamen mit erkennbarem Inhalt — auch
  nicht aus dem Umzug oder der Ordnerwahl.
- **AK-46** · *(Katalog 1+2)* Angenommen, die Datenschutzseite unter `web/app/privacy/`
  wird geöffnet, wenn sie gelesen wird, dann nennt sie ausdrücklich, dass Apple bei
  Installation über den App Store eigene Absturz- und Nutzungsdaten erhebt, sofern der
  Nutzer das in den Systemeinstellungen erlaubt hat — und dass die App selbst weiterhin
  nichts erhebt.
- **AK-47** · *(Katalog 1+2)* Angenommen, der Store-Eintrag ist ausgefüllt, wenn die
  Datenschutzangaben („App Privacy") geprüft werden, dann steht dort, dass die App keine
  Daten erfasst.
- **AK-48** · *(Katalog 4)* Angenommen, die Store-Fassung läuft, wenn ihr Netzwerkverkehr
  über eine Stunde normaler Benutzung beobachtet wird, dann baut sie keine ausgehende
  Verbindung auf. Es gibt keinen Endpunkt, für den ein Rate Limit nötig wäre — die
  Anwendung hat kein Backend und ruft keinen kostenpflichtigen Dienst auf.
- **AK-49** · *(Katalog 6)* Angenommen, das Repository wird mit
  `git log -p` vollständig durchsucht, wenn nach Verteilungszertifikat, privatem
  Schlüssel, Bereitstellungsprofil oder App-Store-Connect-Schlüssel gesucht wird, dann
  findet sich keiner davon — weder im aktuellen Stand noch in der Historie.
- **AK-50** · *(Katalog 6)* Angenommen, ein Dritter klont das Repository, wenn er den
  Store-Build ausführen will, dann findet er eine Anleitung und eine Beispieldatei, aber
  keinen verwendbaren Schlüssel.
- **AK-51** · *(Katalog 3)* Zugriffsregeln im Sinne des Katalogs — Rollen, fremde IDs,
  Datenbankregeln — treffen nicht zu, weil die Anwendung keine Konten, kein Backend und
  keine Mehrbenutzerfähigkeit hat. Die einzige Zugriffsregel der Anwendung ist die
  Ausschlussliste, geprüft in AK-09 und AK-10.
- **AK-52** · *(Katalog 5)* Kontolöschung und Datenauskunft treffen nicht zu, weil es
  keine Konten und keine serverseitigen Daten gibt. Der lokale Löschpfad bleibt
  unverändert: jeder Schreibpfad hat sein Gegenstück (AK-17, AK-22).

## Edge Cases

- **EC-01** · Nutzer bricht die Ordnerwahl in der Ersteinrichtung ab → Die Einrichtung
  lässt sich nicht abschließen, ohne dass ein Ordner gewählt wurde; der Schritt wird
  erneut gezeigt, mit Erklärung warum.
- **EC-02** · Gewählter Ordner liegt auf einem externen Volume, das beim nächsten Start
  nicht angeschlossen ist → Aufnahme schlägt nicht still fehl, sondern meldet den
  fehlenden Ordner über den bestehenden Fehlerweg (`CaptureLog.report`) und bietet die
  erneute Wahl an.
- **EC-03** · Gewählter Ordner ist schreibgeschützt → gleiche Behandlung wie EC-02,
  mit eigener Meldung.
- **EC-04** · Nutzer wählt den Container selbst als Speicherort → zulässig, keine
  Sonderbehandlung.
- **EC-05** · ~~Umzug mit beschädigten Einstellungen~~ → **gegenstandslos seit OF-04
  (2026-09-03).** Die Anwendung liest keine fremde Einstellungsdatei mehr; die Übernahme
  macht macOS. Ein beschädigter Bestand wäre damit ein Fehler des Betriebssystems, nicht
  dieser Anwendung.
- **EC-06** · Store-Fassung wird über eine laufende DMG-Fassung installiert (gleiche
  Bundle-ID) → Die alte Fassung wird ersetzt. Beim nächsten Start greift AK-31.
- **EC-07** · Nutzer installiert nach der Store-Fassung wieder das DMG → Der Store
  aktualisiert diese Installation nicht mehr, Sparkle übernimmt wieder. Kein
  Datenverlust, aber der Speicherort fällt auf `~/Pictures/MikaScreenSnap/` zurück.
- **EC-08** · Apple lehnt die Einreichung ab → Das Feature bleibt auf `building`, die
  Ablehnungsgründe werden als Befunde aufgenommen und abgearbeitet. Eine Ablehnung ist
  kein Fehlschlag des Features, sondern ein Rückschritt in der Bearbeitung.
- **EC-09** · Bildschirmaufnahme-Berechtigung wird nach dem Einrichten entzogen → wie in
  der DMG-Fassung: Aufnahmeeinträge sind gesperrt, die Ersteinrichtung führt erneut
  durch die Berechtigung.

## Offene Fragen

- **OF-01** · ~~Welches Konto trägt den Store-Eintrag?~~ **Entschieden am 2026-09-03:
  Team `CWJM4J4HFN`** — dasselbe, das den Direktvertrieb signiert. Ein Konto für beide
  Wege. **Was daraus folgt und noch aussteht:** Unter dieser Team-ID müssen
  `com.mika.mikaplusscreensnap` als App-ID registriert und die Zertifikate
  `Apple Distribution` und `3rd Party Mac Developer Installer` erzeugt werden; im
  Schlüsselbund liegt heute nur `Developer ID Application`. Das ist Beschaffung, keine
  Entscheidung mehr — **beschafft: der Autor, vor T27.**
- **OF-02** · ~~Kategorie und Alterseinstufung?~~ **Entschieden am 2026-09-03:
  *Utilities*, Alterseinstufung 4+.** Dort stehen Screenshot- und Menüleisten-Werkzeuge;
  4+, weil die Anwendung keine fremden Inhalte anzeigt — kein Web, kein Nutzerinhalt,
  keine Werbung. Fließt in AK-42 ein.
- **OF-04** · ~~Wie ziehen angeheftete Bilder um?~~ **Entschieden am 2026-09-03: gar
  nicht.** Der Umzug deckt nur noch Einstellungen ab, und die wandern nach dem Messergebnis
  aus T01 ohnehin von selbst. **Der Grund ist ein Widerspruch, kein Bequemlichkeitsargument:**
  Die Store-Fassung darf den alten Ablageort nicht lesen und kann deshalb nicht erkennen,
  ob es etwas zu holen gibt — sie müsste **jeden** Nutzer fragen, auch jeden, der nie eine
  DMG-Fassung besessen hat. Genau das verbietet AK-34. AK-31 bis AK-35 sind entsprechend
  neu gefasst. **Folge für den Code:** `MigrationImporter`, `migrationOffered` und der
  eingebettete `MigrationPrompt` werden nicht gebraucht; T14, T16 und T20 entfallen.

- **OF-03** · ~~Lizenz ändern?~~ **Entschieden am 2026-09-03: MIT bleibt.** Es gibt
  keinen Umsatz zu schützen, und Apple verlangt bei der Einreichung ohnehin den Nachweis
  der Rechte an Name und Symbol — die Marke schützt hier, nicht die Lizenz.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | PRD schließt App Store aus (OF-01) — wie damit umgehen? | Umkehren, Spec schreiben, PRD danach über `/sdd-init` nachführen | Die Begründung des PRD ist widerlegt: ScreenCaptureKit läuft im Sandbox mit `com.apple.security.screen-capture` — dem Entitlement, das `Resources/MikaScreenSnap.entitlements:7` bereits auf `true` setzt — und `RegisterEventHotKey` ist die einzige im Sandbox funktionierende Hotkey-API und braucht dort keine Entitlements |
| 2 | Ein Vertriebsweg oder zwei? | Beide parallel — DMG mit Sparkle bleibt unverändert | OF-03 des PRD verpflichtet unbefristet zum Appcast; bestehende Installationen haben die Feed-Adresse einkompiliert und würden sonst nie wieder ein Update sehen |
| 3 | Preis im Store? | Kostenlos | `docs/prd.md`, *Monetarisierung*: „keine — MIT-Lizenz, kostenlos". Der Store ist Vertriebsweg, kein Erlösmodell |
| 4 | Speicherort unter Sandbox? | Nutzer wählt einmalig einen Ordner, danach dauerhafter Zugriff | Screenshots im Container wären für den Nutzer praktisch unauffindbar; ein Sonderrecht auf `~/Pictures` wäre eine Ausnahme, die Entscheidung 12 ausschließt |
| 5 | Funktionsumfang des Store-Builds? | Identisch, nur B14 entfällt und B11 bekommt einen Hinweis | Jede weitere Abweichung machte die Specs B01–B15 mehrdeutig — sie müssten dann je Ausgabe zwei Wahrheiten beschreiben |
| 6 | Umzug bestehender Nutzer? | Einmalige Übernahme beim ersten Start anbieten | Wer wechselt, verlöre sonst sieben belegte Tastenkürzel, die Ausschlussliste und alle angehefteten Bilder |
| 7 | Wo endet das Feature? | Bei der Einreichung | Das Review liegt bei Apple und lässt sich nicht in ein Akzeptanzkriterium fassen; alles bis zur Einreichung ist prüfbar |
| 8 | Eine Bundle-ID oder zwei? | Gleiche ID für beide Ausgaben | Der Wechsel ist damit ein Ersetzen statt einer Parallelinstallation. Der Konflikt zwischen Sparkle und Store entfällt in der Praxis, weil die Store-Fassung kein Sparkle enthält (AK-04) — die umgekehrte Richtung ist EC-07 |
| 9 | Apple erhebt bei Store-Installationen eigene Daten — Zusage anpassen? | Zusage präzisieren, auf der Datenschutzseite und im PRD | „collects nothing" (`web/app/privacy/page.tsx:10`) wäre für Store-Nutzer nicht mehr vollständig richtig; eine still falsch gewordene Zusage ist schlimmer als ein zusätzlicher Absatz |
| 10 | Wo liegen Zertifikate und Upload-Schlüssel? | Schlüsselbund, nichts im Repository | Wie beim bestehenden Notary-Profil. Ein `git add -f` oder ein Backup reicht sonst, um den Upload-Schlüssel offenzulegen |
| 11 | Öffentlicher Kontakt im Store-Eintrag? | Projektadressen — GitHub-Issues und die bestehende Datenschutzseite | Keine private Adresse in einem Eintrag mit deutlich größerer Reichweite als das Repository |
| 12 | Ausnahme-Entitlements erlauben? | Keine | Sie schwächen genau die Grenze, deretwegen die App überhaupt in den Store darf, und machen das Review unvorhersagbar |
| 13 | Universal Binary für Intel? | Nein, arm64 bleibt | OF-02 unverändert. Keine der 269 Bestandsprüfungen wäre je auf Intel nachweisbar — es gibt kein Testgerät |
| 14 | Store-Eintrag mehrsprachig? | Nur Englisch | Passend zur englischen Oberfläche. Eine deutsche Beschreibung vor einer englischen App wäre ein Versprechen, das die App nicht einlöst |
| 20 | Lizenz im Store? | MIT bleibt | Kein Umsatz zu schützen; Apple prüft bei der Einreichung Rechte an Name und Symbol, nicht die Codelizenz |
| 19 | Store-Kategorie und Alterseinstufung? | *Utilities*, 4+ | Dort suchen Nutzer Screenshot-Werkzeuge; 4+, weil die Anwendung keine fremden Inhalte anzeigt |
| 18 | Welches Konto trägt den Store-Eintrag? | Team `CWJM4J4HFN` | Dasselbe Team wie der Direktvertrieb — eine Mitgliedschaft, ein Zertifikatssatz, keine Frage, welches Konto die Marke hält |
| 17 | Ziehen angeheftete Bilder mit um? | Nein — der Umzug deckt nur Einstellungen ab, und die wandern von selbst | **AK-32 und AK-34 waren unter Sandbox nicht gleichzeitig erfüllbar.** Ohne Lesezugriff auf den alten Ordner kann die Anwendung nicht erkennen, ob es etwas zu übernehmen gibt, und müsste jeden Nutzer fragen — auch jeden, der nie eine DMG-Fassung hatte |
| 16 | Wie kommt die Store-Fassung an die Bildschirmaufnahme? | Über TCC, nicht über ein Entitlement — `com.apple.security.screen-capture` wird **entfernt** (AK-53) | Nachrecherche am 2026-09-03 an Apples Entitlement-Referenz: Der Schlüssel ist nicht dokumentiert und war im Projekt wirkungslos, weil die Sandbox aus war. Die Zugriffsentscheidung trifft ausschließlich TCC („Bildschirmaufnahme" in den Systemeinstellungen) — das ist derselbe Weg, den `CGPreflightScreenCaptureAccess` in `Sources/MikaScreenSnapApp.swift:59` bereits benutzt. **Die Aussage von Decision Log Zeile 1 bleibt gültig — nur ihre Begründung war zu eng:** ScreenCaptureKit ist Apples sandbox-fähige Aufnahme-API, und dass die Sandbox aus sein müsse, war in keinem Fall richtig |
| 15 | TestFlight vor der Einreichung? | Nein, direkt einreichen | Entscheidung des Autors. **Vermerktes Risiko:** Sandbox-Fehler, die lokal nicht auftreten, zeigen sich dann erst in einer Ablehnung mit mehreren Tagen Wartezeit (EC-08) |
