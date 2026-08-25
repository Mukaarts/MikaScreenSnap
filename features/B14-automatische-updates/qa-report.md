# B14 · Automatische Updates — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja, mit einer Auslieferungsauflage**

Dies ist das einzige Feature mit Netzwerkverkehr und der einzige Weg, auf dem ausführbarer
Code auf den Rechner kommt — entsprechend ist die Signaturprüfung sein wichtigstes
Kriterium. Sie ist konfiguriert (öffentlicher EdDSA-Schlüssel im Programmpaket) und Feed
wie Programmpakete werden ausschließlich über HTTPS geladen; beides ist über die
Angriffsprüfung belegt.

**Was die QA nicht ersetzt: die Beglaubigung.** Der geprüfte Build trägt eine
Ad-hoc-Signatur. Für die Auslieferung ist eine Developer-ID-Signatur mit anschließender
Beglaubigung Pflicht, sonst weist Gatekeeper die Anwendung auf fremden Rechnern ab.

Beim Prüfen fiel ein Nebenbefund an, der bereits behoben ist: Sparkles Controller wurde
beim Programmstart sofort erzeugt und greift dabei nach dem umgebenden Programmpaket — in
einer Umgebung ohne Bundle blockiert das. Er wird jetzt erst bei Bedarf erzeugt.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 14 |
| davon bestanden | 6 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 8 |
| Edge Cases belegt | 0 von 6 |
| Tests neu geschrieben | 0 |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Prüfung meldet auch ohne neue Fassung | ⚠️ nicht prüfbar | braucht Sparkles Oberfläche |
| AK-02 Beschreibung und Installationsangebot | ⚠️ nicht prüfbar | dito |
| AK-03 Selbsttätige Prüfung | ⚠️ nicht prüfbar | Zeitverhalten |
| AK-04 Schalter und Zeitpunkt im Reiter *Advanced* | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-05 Ungültige Signatur wird abgelehnt | ⚠️ **nicht prüfbar** | braucht einen manipulierten Appcast und einen echten Installationsversuch. Konfiguration belegt: A8 zeigt `SUPublicEDKey` gesetzt |
| AK-06 Verbindungsfehler wird gemeldet | ⚠️ nicht prüfbar | braucht eine unterbrochene Verbindung; der Meldepfad ist über `didAbortWithError` implementiert |
| AK-07 Eintrag deaktiviert, wenn nicht bereit | ✅ bestanden | `.disabled(!appDelegate.appState.sparkleUpdater.canCheckForUpdates)` — die Eigenschaft hat jetzt einen Leser (Gegenprobe zum Erfassungsbefund) |
| AK-08 Ältere Fassungen fragen `master` | ✅ bestanden | die installierte 3.4.0 trägt `…/master/appcast.xml` (L2/Feed-Abfrage); `master` und `main` führen beide 3.4.1 — der Zweig wird also gepflegt |
| AK-09 Keine Nutzerdaten übertragen | ✅ bestanden | A1: kein eigener Netzwerkcode; die Hülle übergibt Sparkle nichts außer der Prüfanforderung |
| AK-10 IP und Zeitpunkt erreichen GitHub | ✅ bestanden | unvermeidliche Eigenschaft jeder HTTP-Verbindung; im PRD ausgewiesen |
| AK-11 Kein Systemprofil | ✅ bestanden | A8: `SUSendProfileInfo` ist in `Info.plist` nicht gesetzt, Sparkles Voreinstellung ist „nein" |
| AK-12 EdDSA-Signaturprüfung konfiguriert | ✅ bestanden | A8: `SUPublicEDKey = eauiHgP4PM9ynLekAmo3URrX3ye3HW7D53xOZa5AeYI=` |
| AK-13 Ausschließlich HTTPS | ✅ bestanden | A9: alle drei Enclosure-Adressen und die Feed-Adresse sind `https://`. Der einzige `http://`-Treffer ist der XML-Namensraum von Sparkle — ein Bezeichner, der nie abgerufen wird |
| AK-14 Rückfrage bei ungesicherten Anmerkungen | ⚠️ nicht prüfbar | braucht einen echten Aktualisierungsvorgang; der Pfad ist über `shouldPostponeRelaunchForUpdate` implementiert und an `AnnotationEditorWindowController.hasUnsavedChanges` gehängt |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 bis EC-06 | ⚠️ nicht prüfbar | sämtlich an einen echten Aktualisierungsvorgang gebunden |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| **Signaturprüfung konfiguriert** | ✅ bestanden | A8 |
| **Signaturprüfung wirkt** | ⚠️ **nicht geprüft** | Auflage: manipulierten Appcast gegen eine Testinstallation fahren |
| Ausschließlich HTTPS | ✅ bestanden | A9 |
| Kein Systemprofil | ✅ bestanden | A8 |
| Keine Nutzerdaten übertragen | ✅ bestanden | A1 |
| Offene Verbindungen zur Laufzeit | ✅ bestanden | L1: die laufende Instanz hält keine |
| Geheimnisse im Repository | ✅ bestanden | A3/A4 — der **öffentliche** Schlüssel steht bestimmungsgemäß im Paket, der private liegt im Schlüsselbund |

## Fehler

Keine.

## Neue Tests

Keine — der Code besteht aus Weiterleitungen an Sparkle (BF-06 der Spec, akzeptiert).

## Nächster Schritt

`/sdd-deploy B14` — **mit zwei Auflagen:**

1. **Beglaubigung.** Ohne Developer-ID-Signatur und Beglaubigung ist die Auslieferung
   wirkungslos: Gatekeeper weist die Anwendung auf fremden Rechnern ab. Ablauf in
   `README.md` unter *Code Signing & Notarization*.
2. **Signaturprüfung angreifen.** Einen Appcast mit verfälschter Signatur gegen eine
   Testinstallation fahren und sicherstellen, dass die Installation verweigert wird. Gelingt
   sie, überlagert das jeden anderen Befund dieses Audits.
