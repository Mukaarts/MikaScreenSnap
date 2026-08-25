# B14 · Automatische Updates — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst, Befunde bearbeitet in 3.5.0**

> Beschrieben ist, **was der Code tut**. Beide markierten Kriterien sind bearbeitet.
>
> **Dies ist das einzige Feature mit Netzwerkverkehr** — und das einzige, das
> ausführbaren Code auf den Rechner bringt. Beides hebt es in der Prüfreihenfolge
> nach vorn, unabhängig von seiner geringen Größe.

## Zweck

Die Anwendung findet selbst heraus, dass eine neue Fassung vorliegt, und installiert sie
auf Wunsch. Ohne diesen Weg erreicht keine Fehlerbehebung einen bestehenden Nutzer — der
Vertrieb läuft nicht über den App Store.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B11 Einstellungen | `bestand` | beherbergt Schalter und Schaltfläche im Reiter *Advanced* |
| B15 Menüleisten-Hub | `bestand` | zweiter Einstiegspunkt |

Extern: das Sparkle-Rahmenwerk (2.6 oder neuer), eingebettet ins Programmpaket, und der
Appcast auf `raw.githubusercontent.com`.

## User Stories

- **US-01** · Als Nutzer möchte ich von neuen Fassungen erfahren, ohne die Projektseite zu
  besuchen.
- **US-02** · Als Nutzer möchte ich selbst nachsehen können, wann zuletzt geprüft wurde.
- **US-03** · Als Nutzer möchte ich die automatische Prüfung abschalten können.

## Nicht im Scope

- Zurückrollen auf eine ältere Fassung — nicht vorhanden
- Auswahl zwischen Vorab- und stabilen Fassungen — der Appcast kennt nur einen Kanal
- Änderungsprotokoll in der Anwendung — die Beschreibung kommt aus dem Appcast und wird
  von Sparkle angezeigt

## Akzeptanzkriterien

- **AK-01** · Angenommen, die Anwendung läuft, wenn *Check for Updates…* im Menü oder im
  Reiter *Advanced* gewählt wird, dann prüft Sparkle den Appcast und meldet das Ergebnis —
  auch dann, wenn keine neue Fassung vorliegt.
- **AK-02** · Angenommen, eine neue Fassung liegt vor, wenn die Prüfung sie findet, dann
  zeigt Sparkle deren Beschreibung an und bietet die Installation an.
- **AK-03** · Angenommen, die automatische Prüfung ist eingeschaltet, wenn die Anwendung
  läuft, dann prüft Sparkle in seinem voreingestellten Abstand selbsttätig.
- **AK-04** · Angenommen, der Reiter *Advanced* ist offen, wenn er angezeigt wird, dann
  steht dort ein Schalter *Automatic updates* und darunter der Zeitpunkt der letzten
  Prüfung.
- **AK-05** · Angenommen, ein Update wird geladen, wenn die Signatur nicht zum hinterlegten
  öffentlichen Schlüssel passt, dann verweigert Sparkle die Installation.
- **AK-06** · Angenommen, ein Update wird geladen, wenn die Verbindung fehlschlägt, dann
  meldet Sparkle den Fehler und die Anwendung läuft unverändert weiter.
- **AK-07** · Angenommen, das Aktualisierungswerk ist noch nicht bereit, wenn der
  Menüeintrag *Check for Updates…* angezeigt wird, dann ist er **deaktiviert** — wie es der
  Eintrag zu 3.3.1 in `CHANGELOG.md` seit jeher zusagt.
- **AK-08** · Angenommen, eine Fassung bis einschließlich 3.4.1 ist installiert, wenn sie
  nach Updates sucht, dann fragt sie den Appcast auf dem Zweig **`master`** ab, nicht auf
  `main`.
  *(Die Feed-Adresse ist ins Programmpaket kompiliert und lässt sich nachträglich nicht
  ändern. Der Umgang damit ist organisatorisch geregelt — siehe *Befunde*, BF-04.)*
- **AK-14** · Angenommen, der Annotationseditor hält ungesicherte Anmerkungen, wenn ein
  Update installiert werden soll, dann fragt die Anwendung, ob später aktualisiert werden
  soll, und verschiebt auf Wunsch auf den nächsten Start.

### Datenschutz und Missbrauchsschutz

Stufe A. **Dies ist die einzige Stelle, an der die Anwendung eine Netzwerkverbindung
aufbaut** — die Zusage im PRD („kein Byte verlässt den Rechner") gilt für Nutzerdaten, hier
ist die Ausnahme.

- **AK-09** · Angenommen, eine Aktualisierungsprüfung läuft, wenn die Verbindung besteht,
  dann werden **keine Nutzerdaten** übertragen: kein Bildinhalt, keine Einstellungen, keine
  Kennung. Es wird eine Datei abgerufen.
- **AK-10** · Angenommen, eine Aktualisierungsprüfung läuft, wenn sie stattfindet, dann
  erfährt GitHub als Gegenstelle unvermeidlich IP-Adresse, Zeitpunkt und
  Programmkennzeichnung des Aufrufs.
- **AK-11** · Angenommen, Sparkle prüft, wenn die Voreinstellung zur Übermittlung eines
  anonymen Systemprofils unverändert ist, dann wird **kein** Systemprofil gesendet
  (`SUSendProfileInfo` ist in `Resources/Info.plist` nicht gesetzt, Sparkles Voreinstellung
  ist „nein").
- **AK-12** · Angenommen, ein Update wird installiert, wenn es angewandt wird, dann ist es
  über EdDSA gegen den in `Resources/Info.plist` hinterlegten öffentlichen Schlüssel geprüft.
- **AK-13** · Angenommen, Feed und Programmpaket werden geladen, wenn die Verbindung
  aufgebaut wird, dann geschieht das ausschließlich über HTTPS.

*Abschnitt 4 (Rate Limits): trifft nicht zu — die Prüfung ruft eine statische Datei ab und
kostet nichts. Abschnitt 6 (Geheimnisse): Der **öffentliche** Signaturschlüssel steht
bestimmungsgemäß im Programmpaket; der private liegt im Schlüsselbund des Autors und darf
das Repository nie berühren.*

## Edge Cases

- **EC-01** · Kein Netz → Sparkle meldet einen Fehler, die Anwendung läuft weiter.
- **EC-02** · Appcast fehlerhaft → Sparkle meldet „error parsing the update feed" (in 3.3.2
  bereits einmal aufgetreten).
- **EC-03** · Signatur passt nicht → Installation wird verweigert.
- **EC-04** · Update während laufender Aufnahme → Verhalten ungeprüft; ein Neustart der
  Anwendung während geöffneter Panels ist nicht abgesichert.
- **EC-05** · Herabstufung im Appcast (kleinere Fassungsnummer) → Sparkle bietet sie nicht an.
- **EC-06** · Nicht beglaubigtes Programmpaket → Gatekeeper verweigert den Start nach der
  Installation; der Nutzer sitzt dann vor einer beschädigten Installation.

## Befunde

### Behoben

- **FB-01 · `canCheckForUpdates` war toter Code** — behoben 2026-08-25. Der Menüeintrag
  liest die Eigenschaft und ist andernfalls deaktiviert; der CHANGELOG-Eintrag zu 3.3.1
  trifft damit wieder zu.
- **FB-02 · Keine Delegates am Aktualisierungswerk** — behoben 2026-08-25. `SparkleUpdater`
  ist selbst `SPUUpdaterDelegate`.
- **FB-03 · Ein Update konnte ungesicherte Arbeit vernichten** — behoben 2026-08-25 über
  `updater(_:shouldPostponeRelaunchForUpdate:untilInvokingBlock:)`, das den Editor prüft und
  auf Wunsch verschiebt. Zusätzlich meldet `didAbortWithError` fehlgeschlagene Prüfungen ins
  Protokoll.

### Akzeptiert

- **BF-04 · Der Zweigwechsel des Feeds hat kein Ende** — akzeptiert 2026-08-25. Die
  Feed-Adresse älterer Installationen lässt sich nachträglich nicht ändern; `main:master`
  muss mitgepusht werden, solange solche Installationen bestehen. Der Ablauf steht in
  `README.md` unter *Auto-Update*. Ein Ende wäre nur nach einer Zählung der verbleibenden
  Installationen begründbar — und die gibt es bewusst nicht, weil die Anwendung keine
  Nutzungsdaten erhebt.
- **BF-05 · Kein Prüfweg für den Appcast** — akzeptiert 2026-08-25. Ein Test müsste
  Sparkles Auswertung nachbilden; verlässlicher ist der Schritt, der in `README.md` ohnehin
  vorgeschrieben ist: die Signatur über das von GitHub geladene DMG bilden und die
  Aktualisierung vor der Veröffentlichung an einer echten Installation prüfen.
- **BF-06 · Keine Tests** — akzeptiert 2026-08-25. Der Code besteht aus Weiterleitungen an
  Sparkle; ein Test darüber prüfte das Rahmenwerk.

## Offene Fragen

Keine offen.

| Frage | Entscheidung | Datum |
|---|---|---|
| OF-01 · Bis wann `master` mitpflegen? | unbefristet, solange keine Zählung der Installationen existiert — und die soll es nicht geben. Der Aufwand ist ein zusätzlicher Push je Release und in `README.md` festgehalten | 2026-08-25 |
| OF-02 · Update bei ungesicherten Anmerkungen verschieben? | ja, mit Rückfrage | 2026-08-25 |
| OF-03 · `canCheckForUpdates` benutzen oder entfernen? | benutzen — der Menüeintrag ist deaktiviert, solange das Werk nicht bereit ist | 2026-08-25 |

## Decision Log## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie werden Updates verteilt? | Sparkle mit Appcast auf GitHub | ohne App Store gibt es keinen anderen Weg zum bestehenden Nutzer; die Sandbox ist aus (siehe PRD) |
| 2 | Wie wird die Echtheit gesichert? | EdDSA-Signatur, öffentlicher Schlüssel im Paket | Sparkles empfohlener Weg; der private Schlüssel liegt im Schlüsselbund |
| 3 | Wo liegt der Appcast? | `raw.githubusercontent.com`, Zweig `main` | keine eigene Serverinfrastruktur nötig |
| 4 | Wie wird Sparkle eingebunden? | dünne Hülle um den Standardcontroller | die Oberfläche kommt vollständig von Sparkle |
| 5 | Delegates (3.5.0) | Aktualisierungs-Delegate an der Hülle | ohne ihn konnte ein Update den Editor mitsamt ungesicherter Anmerkungen schließen, und ein Fehlschlag hinterließ keine Spur |
| 6 | Wo steht der Schalter für die automatische Prüfung? | Reiter *Advanced* | wird selten geändert |
| 7 | Zweigwechsel `master` → `main` | `db55d1f` | `master` war seit März unberührt, wodurch die Auslieferung von 3.4.1 zunächst unsichtbar blieb |
