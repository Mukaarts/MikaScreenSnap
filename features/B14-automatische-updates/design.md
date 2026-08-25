# B14 · Automatische Updates — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Die Anwendung enthält kein eigenes Aktualisierungswerk. Sie bettet Sparkle als Rahmenwerk
ein und stellt eine dünne Hülle darum, die drei Dinge nach außen gibt: prüfen, den Schalter
für die automatische Prüfung, den Zeitpunkt der letzten Prüfung. Alles Weitere — Oberfläche,
Download, Signaturprüfung, Installation, Neustart — leistet Sparkle.

Der Ablauf: Sparkle lädt eine XML-Datei von GitHub, vergleicht die dort genannte Fassung
mit der eigenen, prüft bei Bedarf die EdDSA-Signatur des Programmpakets gegen den
öffentlichen Schlüssel aus dem eigenen Paket und installiert.

## Komponentenstruktur

```
SparkleUpdater                        dünne Hülle, @MainActor
├── canCheckForUpdates                bereitgestellt — von niemandem gelesen (FB-01)
├── automaticallyChecksForUpdates     lesen und schreiben
├── lastUpdateCheckDate               nur lesen
└── checkForUpdates()                 stößt Sparkles Ablauf an

SPUStandardUpdaterController          Sparkle, mit dem Start des Werks beim Erzeugen
├── updaterDelegate: nil
└── userDriverDelegate: nil

Einstiegspunkte
├── Menüleiste → „Check for Updates…"
└── Einstellungen → Advanced → Schalter + Schaltfläche + Zeitpunkt
```

## Datenmodell

Kein eigenes. Sparkle führt seinen Zustand in eigenen Schlüsseln der
Benutzereinstellungen — Zeitpunkt der letzten Prüfung, automatische Prüfung, übersprungene
Fassungen. Diese Schlüssel sind der Anwendung nicht bekannt und werden von
*Reset All Preferences* **nicht** erfasst.

### Konfiguration im Programmpaket

| Schlüssel | Wert | Bedeutung |
|---|---|---|
| `SUFeedURL` | `…/daumedia/MikaScreenSnap/main/appcast.xml` | Adresse des Appcasts, seit `db55d1f` auf `main` |
| `SUPublicEDKey` | `eauiHgP4…` | öffentlicher Schlüssel zur Signaturprüfung |
| `SUSendProfileInfo` | **nicht gesetzt** | Voreinstellung „nein" — kein Systemprofil |
| `SUScheduledCheckInterval` | **nicht gesetzt** | Sparkles Voreinstellung greift |

### Appcast

Ein RSS-Kanal mit einem `<item>` je Fassung; derzeit drei. Jeder Eintrag trägt Fassung,
Beschreibung, Datum und ein `<enclosure>` mit Adresse, Länge und EdDSA-Signatur des DMG.

## Zugriffsregeln

| Wer | Darf | Erzwungen durch |
|---|---|---|
| Sparkle | den Appcast und Programmpakete über HTTPS laden | Systemvertrauensspeicher |
| Sparkle | ein Update installieren | **nur** bei gültiger EdDSA-Signatur |
| Die Anwendung | prüfen anstoßen, Schalter setzen | die Hülle |

Die Signaturprüfung ist die einzige echte Sicherheitsschranke der ganzen Anwendung: Ohne
sie könnte jeder, der den Feed unterschiebt, beliebigen Code auf dem Rechner ausführen.

## Missbrauchsschutz

| Vorgang | Limit | Anmerkung |
|---|---|---|
| Aktualisierungsprüfung | **keins** in der Anwendung | ruft eine statische Datei ab; GitHub begrenzt seinerseits |

## Externe Dienste

| Dienst | Wofür | Was geht hin | Was wird vorher entfernt |
|---|---|---|---|
| GitHub (`raw.githubusercontent.com`) | Appcast abrufen | HTTP-Anfrage — unvermeidlich IP-Adresse, Zeitpunkt, Programmkennzeichnung | nichts zu entfernen: es werden **keine** Anwendungsdaten gesendet |
| GitHub Releases | Programmpaket laden | dito | dito |

Kein Auftragsverarbeitungsvertrag erforderlich, weil keine personenbezogenen Daten
übermittelt werden. Die Verbindung selbst ist auf der Datenschutzseite unter „The one
network connection" ausgewiesen — Zusage und Code stimmen hier überein.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Sparkle statt eigener Lösung | selbst gebauter Prüf- und Installationsweg | Signaturprüfung und Installation sind sicherheitskritisch und ungeeignet zum Selberbauen |
| 2 | Standardcontroller ohne Delegates | eigene Delegates | einfachste Einbindung; Preis siehe FB-02 und FB-03 |
| 3 | Appcast auf GitHub statt eigenem Server | eigene Infrastruktur | keine Betriebskosten, keine Serverpflege |
| 4 | `@preconcurrency import` | auf Sparkles Nebenläufigkeitsangaben warten | Sparkle ist nicht auf Swift-6-Nebenläufigkeit vorbereitet; ohne die Kennzeichnung baut das Projekt nicht |
| 5 | Hülle als eigene Klasse | Sparkle direkt in der Oberfläche verwenden | hält den `@preconcurrency`-Bereich klein und die Oberfläche testbar |
| 6 | Kein Systemprofil senden | Sparkles Profilübermittlung einschalten | Voreinstellung beibehalten — passt zur Zusage „keine Analyse" |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `checkForUpdates()` → Sparkle | Oberfläche von Sparkle |
| AK-02 | Sparkle, Beschreibung aus dem Appcast | |
| AK-03 | `automaticallyChecksForUpdates` | Abstand nach Sparkles Voreinstellung |
| AK-04 | Reiter *Advanced* | Umsetzung in B11 |
| AK-05 | Sparkles Signaturprüfung gegen `SUPublicEDKey` | |
| AK-06 | Sparkles Fehlerbehandlung | die Anwendung erfährt nichts davon (FB-02) |
| AK-07 ⚠ | **keine Komponente** — `canCheckForUpdates` wird nicht gelesen | |
| AK-08 ⚠ | ins Paket kompilierte Feed-Adresse älterer Fassungen | organisatorisch gelöst, nicht technisch |
| AK-09 | Sparkle sendet keine Anwendungsdaten | belegbar: die Hülle übergibt nichts |
| AK-10 | unvermeidliche Eigenschaft jeder HTTP-Verbindung | im PRD ausgewiesen |
| AK-11 | `SUSendProfileInfo` nicht gesetzt | Voreinstellung |
| AK-12 | `SUPublicEDKey` im Programmpaket | |
| AK-13 | HTTPS in Feed und Enclosure-Adressen | im Appcast nachprüfbar |

## Übergabe an die QA

1. **AK-12 und AK-05 sind die wichtigsten Kriterien der gesamten Erfassung.** Zu prüfen mit
   einem manipulierten lokalen Appcast: Signatur verfälschen und sicherstellen, dass die
   Installation verweigert wird. Gelingt eine Installation trotz falscher Signatur, ist das
   ein kritischer Befund, der alles andere überlagert.
2. **AK-13**: Appcast und alle Enclosure-Adressen auf HTTPS prüfen — ein einzelner
   HTTP-Eintrag genügt für einen Angriff auf dem Übertragungsweg.
3. **FB-03** in der Praxis: Editor mit Anmerkungen offen halten und ein Update einspielen.
   Zu beobachten, ob gewarnt wird.
4. **AK-08** ist organisatorisch, nicht technisch — die QA sollte prüfen, ob `master` den
   aktuellen Appcast trägt.
