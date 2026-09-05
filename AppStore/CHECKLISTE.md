# Vor der Einreichung

Was im Repository liegt, ist fertig. Offen ist, was sich ausschließlich im Apple-Konto
oder auf einem fremden Dienst erledigen lässt — und eine Reihenfolgefrage, die vor allem
anderen steht.

Abgehakt wird nur, was **belegt** ist. Was sich aus dem Repository heraus nicht nachprüfen
lässt, steht unter „Nicht nachprüfbar" und wartet auf eine Bestätigung.

## Zuerst: die Auslieferung von 3.5.0 als DMG abschließen

`Resources/Info.plist` und `CHANGELOG.md` tragen seit dem 2026-09-04 die Version
**3.6.0** — das war T34 des Aufgabenplans, ausgeführt auf ausdrückliche Anweisung.
Der Plan sah dafür eigentlich die Auslieferung von 3.5.0 als DMG vor, und die ist nur zur
Hälfte durch. **Solange sie offen ist, erzeugt `scripts/create-dmg.sh` ein DMG mit
3.6.0 — ein 3.5.0-DMG wäre vorher zu bauen oder der Schritt zu überspringen.**

- [x] 3.5.0 notarisiert (2026-09-03, `stapler validate` erfolgreich, `spctl` accepted)
- [ ] GitHub-Release für 3.5.0 anlegen
- [ ] `sign_update` über die heruntergeladene Kopie laufen lassen
- [ ] `appcast.xml` ergänzen und nach `main` **und** `master` pushen
- [ ] **Letzter Push nach `Mukaarts`.** Ohne ihn erreicht das Update genau die
      Installationen nie, die am alten Feed hängen (BF-31, qa-report.md) — und damit
      erreicht sie auch nie ein Hinweis auf die Store-Fassung

## Im Apple Developer Account

- [ ] **Store-Zertifikate erzeugen** — `Apple Distribution` **und**
      `3rd Party Mac Developer Installer`, beide unter Team `CWJM4J4HFN`. Ein
      `Developer ID`-Zertifikat genügt **nicht**; es signiert den Direktvertrieb, nicht
      den Store.
      Prüfen mit `security find-identity -v -p codesigning`.
      Stand 2026-09-04 liegen dort nur:
      `Apple Development … (8C9HV4CHBN)` (dreimal) und
      `Developer ID Application: Michael Rodrigues (CWJM4J4HFN)`.
      **`scripts/package-appstore.sh` bricht deshalb heute sofort ab** — das ist die
      einzige echte Blockade der ganzen Kette.
- [ ] **App-ID `lu.daumedia.screensnap`** unter `CWJM4J4HFN` registrieren.
      Achtung: Das Team, das heute die Entwicklerzertifikate trägt (`8C9HV4CHBN`), ist
      ein anderes. Entschieden ist `CWJM4J4HFN` — dasselbe, das den Direktvertrieb
      signiert (OF-01).
- [ ] **Provisioning Profile** für `lu.daumedia.screensnap` (Mac App Store) anlegen und
      laden. Ob eines überhaupt verlangt wird, klärt sich beim ersten Upload (OP-01 des
      Entwurfs).
- [ ] **App-Datensatz in App Store Connect** anlegen: Name, Bundle-ID, SKU aus
      [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md). **Nur eine Kennung** —
      `lu.daumedia.screensnap`, beide Fassungen teilen sie.

## Beim Hochladen

- [ ] `bash scripts/package-appstore.sh` — baut, re-signiert mit der Verteilungsidentität,
      paketiert über `productbuild` und validiert gegen App Store Connect, wenn
      `MIKA_ASC_KEY_ID` und `MIKA_ASC_ISSUER_ID` gesetzt sind.
      **Der Upload selbst ist bewusst nicht automatisiert**: Das Skript gibt den
      `xcrun altool --upload-app`-Befehl aus, führt ihn aber nicht aus.

      Ob die Projektstruktur trägt, lässt sich **ohne** Store-Zertifikat prüfen:

      ```bash
      xcodegen generate
      xcodebuild archive -project MikaScreenSnap.xcodeproj \
        -scheme "Mika+ScreenSnap (App Store)" \
        -destination "generic/platform=macOS" -archivePath /tmp/Probe.xcarchive \
        CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
      /usr/libexec/PlistBuddy -c "Print :ApplicationProperties" /tmp/Probe.xcarchive/Info.plist
      ```

      Kommt dort ein Block mit `ApplicationPath = Applications/Mika+ScreenSnap.app`, ist
      es ein App-Archiv. Fehlt `ApplicationProperties` ganz, bietet Xcode beim Verteilen
      nur „Custom" an.
- [ ] **Kategorie in App Store Connect auf *Dienstprogramme* setzen.** Sie muss zu
      `LSApplicationCategoryType` in `Resources/Info.plist` passen
      (`public.app-category.utilities`), sonst weist der Upload mit Fehler 90242 ab.
- [ ] Texte aus `metadata/en-US/` einsetzen, Screenshots aus
      `screenshots/en-US/mac-2880x1800/` in Nummernreihenfolge hochladen.
- [ ] **Screenshots ergänzen — zwei von fünf liegen vor.** Apple verlangt mindestens
      eines, aber zwei Kacheln lassen die Galerie dünn aussehen. Es fehlen die
      Texterkennung, die Farblupe und das angeheftete Bild; Gründe und Weg zum
      Nachliefern in [README.md](README.md), Abschnitt *Screenshots*.
- [ ] **Die vorhandenen zwei stammen aus der Direktfassung** (`capture.sh --direct`),
      weil die Store-Fassung ihre Bildschirmaufnahme-Berechtigung noch nicht hat.
      **Das ist hier unbedenklich, aber nur solange kein Motiv das Menü der Menüleiste
      zeigt:** Dort trägt die Direktfassung „Check for Updates…", das die Store-Fassung
      nicht hat — das wäre Guideline 2.3. Alle übrigen Ansichten sind in beiden
      Fassungen gleich. Wer ein Menü-Motiv nachliefert, nimmt es **zwingend** aus der
      Store-Fassung auf.
- [ ] Datenschutz-Fragebogen: durchgehend **Data Not Collected**.
- [ ] Altersfreigabe-Fragebogen: alle 24 Kategorien „Nein"/„Nie", Ergebnis **4+**.
      Antworten und Belege in [ALTERSFREIGABEN.md](ALTERSFREIGABEN.md).
- [ ] **Prüfungshinweise aus [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md) eintragen.**
      **Nicht auslassen.** Diese Anwendung hat kein Dock-Symbol und kein Fenster: Ein
      Prüfer, der sie startet und nichts sieht, lehnt nach Guideline 2.1 ab. Ebenso, wenn
      er nicht weiß, dass die Bildschirmaufnahme erst in den Systemeinstellungen erteilt
      und die Anwendung danach neu gestartet werden muss — bis dahin ist jede Aufnahme
      leer.

## Außerhalb des Apple-Kontos

- [ ] **`screensnap.daumedia.lu` veröffentlichen.** Zwei der drei URL-Dateien in
      `metadata/en-US/` zeigen dorthin, und Apple ruft sie auf. Die Adresse kommt aus
      `NEXT_PUBLIC_SITE_URL` im Vercel-Projekt (`web/app/layout.tsx:20`); es gibt heute
      keinen fest hinterlegten Produktivwert. Weicht die Adresse ab, sind
      `metadata/en-US/marketing_url.txt` und `privacy_url.txt` nachzuziehen.
- [ ] Prüfen, dass **`/privacy`** unter dieser Adresse mit HTTP 200 antwortet — sie ist
      die Datenschutz-URL des Store-Eintrags, und ein Test hier prüft nur, dass die
      Adresse auf `/privacy` endet, nicht dass sie antwortet.
- [x] Die Datenschutzseite nennt Apples eigene Erhebung bei Store-Installationen (AK-46)
      — steht in `web/app/privacy/page.tsx`, Abschnitt *Analytics*.
- [x] Die Support-Adresse zeigt auf die GitHub-Issues des Projekts (AK-43).

## Nicht nachprüfbar

Steht offen, weil das Repository darüber nichts weiß — nicht, weil es nachweislich fehlt.
Eine kurze Bestätigung genügt, dann wandern die Punkte nach oben.

- [ ] **App-Store-Connect-Schlüssel** erzeugen und als `MIKA_ASC_KEY_ID` und
      `MIKA_ASC_ISSUER_ID` in `scripts/appstore-credentials.sh` hinterlegen (Vorlage:
      `scripts/appstore-credentials.example.sh`, die reale Datei ist in `.gitignore`).
      Ohne sie überspringt `package-appstore.sh` die Validierung.
- [ ] Aktive Mitgliedschaft im Apple Developer Program (99 $/Jahr) unter `CWJM4J4HFN`.

## Nur für den Direktvertrieb (nicht Store-relevant)

- [x] Notarisierung eingerichtet — `scripts/notarize.sh` lief am 2026-09-03 erfolgreich.

## Zuletzt

- [ ] `swift test` und `MIKA_APPSTORE=1 swift test` — beide grün, einschließlich
      `StoreAssetTests`.
- [ ] `bash scripts/build-appstore.sh` — die zehn Selbstprüfungen des Bundles laufen durch.
- [ ] Version in `Resources/Info.plist`, `CHANGELOG.md` und `web/lib/content.ts` stimmt
      überein. **Stand 2026-09-04: `content.ts` steht noch auf 3.5.0**, Info.plist auf
      3.6.0 — nachzuziehen, sobald die DMG-Auslieferung oben abgeschlossen ist, denn der
      Download-Link der Website leitet sich aus dieser Konstante ab.
- [ ] Die 26 Akzeptanzkriterien, die ein installiertes, signiertes Sandbox-Paket brauchen
      (T19, T20, T22, T25, T26 in `features/16-app-store-auslieferung/tasks.md`).
