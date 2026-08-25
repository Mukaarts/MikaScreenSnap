# B14 · Automatische Updates — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · **rückwirkend erfasst**

> Beschrieben ist, **was Version 3.4.1 tut**. Kriterien mit ⚠ stehen zur Klärung.
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
- **AK-07** ⚠ · Angenommen, das Aktualisierungswerk ist noch nicht bereit, wenn der
  Menüeintrag *Check for Updates…* angezeigt wird, dann ist er **trotzdem anklickbar**.
  *(`SparkleUpdater.swift:13` stellt `canCheckForUpdates` bereit; die Eigenschaft wird von
  **keiner** Oberfläche gelesen. Der Eintrag in `CHANGELOG.md` zu 3.3.1 — „Update menu
  button — now visually disabled when Sparkle updater is not ready" — beschreibt einen
  Zustand, den der Code heute nicht mehr herstellt. Zur Klärung vorgelegt.)*
- **AK-08** ⚠ · Angenommen, eine Fassung bis einschließlich 3.4.1 ist installiert, wenn sie
  nach Updates sucht, dann fragt sie den Appcast auf dem Zweig **`master`** ab, nicht auf
  `main`.
  *(Die Feed-Adresse ist ins Programmpaket kompiliert; erst `db55d1f` hat sie auf `main`
  umgestellt. Solange solche Installationen bestehen, muss `main:master` mitgepusht werden,
  sonst erreichen sie keine Aktualisierung mehr. Vermerkt in `README.md`. Zur Klärung
  vorgelegt: bis wann?)*

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

## Fehlbestand

- **FB-01 · `canCheckForUpdates` ist toter Code, und die Dokumentation behauptet das
  Gegenteil.** Fundstelle: `SparkleUpdater.swift:13`, ohne Leser; `CHANGELOG.md`, Eintrag
  3.3.1. Folge: Ein Zustand, den die Dokumentation zusichert, wird nicht hergestellt —
  vermutlich bei der Neugestaltung der Einstellungen in 3.4.0 verloren gegangen.
- **FB-02 · Keine Delegates am Aktualisierungswerk.** Fundstelle:
  `SparkleUpdater.swift:23` übergibt `nil` für beide Delegates. Folge: Die Anwendung erfährt
  nichts über Verlauf und Ausgang einer Prüfung, kann Fehler nicht protokollieren und den
  Ablauf nicht beeinflussen — etwa um eine Installation zu verschieben, während der Editor
  ungesicherte Anmerkungen hält.
- **FB-03 · Ein Update kann ungesicherte Arbeit vernichten.** Es gibt keine Prüfung, ob der
  Editor offen ist oder `hasUnsavedChanges` gesetzt ist, bevor Sparkle die Anwendung für die
  Installation beendet. Folge: Anmerkungen gehen ohne Rückfrage verloren. Ohne Delegate
  (FB-02) ist dieser Punkt auch nicht nachrüstbar.
- **FB-04 · Der Zweigwechsel des Feeds hat kein Ende.** Fundstelle: `README.md`,
  Abschnitt *Auto-Update*. Folge: `main:master` muss auf unbestimmte Zeit mitgepusht
  werden; vergisst der Autor es einmal, bemerkt es niemand, weil die betroffenen
  Installationen still auf altem Stand bleiben.
- **FB-05 · Kein Prüfweg für den Appcast.** Es gibt keinen Test und keinen
  Auslieferungsschritt, der die XML-Datei gegen Sparkles Erwartung prüft. Folge: Der Fehler
  aus 3.3.2 (falscher Namensraum) konnte ausgeliefert werden und war erst am Gerät des
  Nutzers sichtbar.
- **FB-06 · Keine Tests.**

## Offene Fragen

- **OF-01** · Bis wann muss `master` mitgepflegt werden? — entscheidet der Autor.
- **OF-02** · Soll ein Update verschoben werden, wenn der Editor ungesicherte Anmerkungen
  hält? — entscheidet der Autor.
- **OF-03** · Soll `canCheckForUpdates` wieder benutzt oder entfernt werden? — entscheidet
  der Autor. Der CHANGELOG-Eintrag zu 3.3.1 ist bis dahin unzutreffend.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie werden Updates verteilt? | Sparkle mit Appcast auf GitHub | ohne App Store gibt es keinen anderen Weg zum bestehenden Nutzer; die Sandbox ist aus (siehe PRD) |
| 2 | Wie wird die Echtheit gesichert? | EdDSA-Signatur, öffentlicher Schlüssel im Paket | Sparkles empfohlener Weg; der private Schlüssel liegt im Schlüsselbund |
| 3 | Wo liegt der Appcast? | `raw.githubusercontent.com`, Zweig `main` | keine eigene Serverinfrastruktur nötig |
| 4 | Wie wird Sparkle eingebunden? | dünne Hülle um den Standardcontroller | die Oberfläche kommt vollständig von Sparkle |
| 5 | Delegates? | keine | **Grund nicht erkennbar** — vermutlich nicht gebraucht (FB-02) |
| 6 | Wo steht der Schalter für die automatische Prüfung? | Reiter *Advanced* | wird selten geändert |
| 7 | Zweigwechsel `master` → `main` | `db55d1f` | `master` war seit März unberührt, wodurch die Auslieferung von 3.4.1 zunächst unsichtbar blieb |
