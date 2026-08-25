# B13 · Automatischer Start bei Login — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Das kleinste Feature der Anwendung: eine Klasse mit einer abgeleiteten Eigenschaft und
einer Methode. Sie kapselt den Systemdienst für Anmeldeobjekte und führt **bewusst keinen
eigenen Zustand** — der Schalter fragt bei jedem Lesen das System.

Das ist die richtige Entscheidung und im Dateikopf begründet: Eine eigene Ablage könnte von
dem abweichen, was in den Systemeinstellungen steht, und der Nutzer kann dort jederzeit
eingreifen.

## Komponentenstruktur

```
LaunchAtLoginManager                   @MainActor, kein eigener Zustand
├── isEnabled                          fragt den Systemdienst
└── setEnabled(_:)                     eintragen oder entfernen, Fehler → print()

Einstiegspunkte
├── Einstellungen → Advanced → Schalter
└── Ersteinrichtung → letzte Seite → Schalter (voreingestellt ein, B12/AK-13)
```

## Datenmodell

**Keines.** Der Zustand liegt ausschließlich im System.

## Zugriffsregeln

| Wer | Darf | Erzwungen durch |
|---|---|---|
| Die Anwendung | sich selbst als Anmeldeobjekt eintragen und entfernen | Systemdienst; der Nutzer kann in den Systemeinstellungen widersprechen |

## Missbrauchsschutz

Nicht anwendbar.

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Systemdienst für Anmeldeobjekte | Hilfsanwendung mit eigenem Bündel | ab macOS 13 der vorgesehene Weg, ohne eingebettete Hilfsanwendung |
| 2 | Kein eigener Zustand | Zustand in den Benutzereinstellungen spiegeln | ausdrücklich begründet: das System ist die Wahrheit |
| 3 | Klasse nicht beobachtbar | `@Observable` | **Grund nicht erkennbar** — trägt zu FB-01 bei |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `setEnabled(true)` | |
| AK-02 | `setEnabled(false)` | |
| AK-03 | `isEnabled` fragt den Systemdienst | |
| AK-04 | Aufruf in der Ersteinrichtung | Umsetzung in B12 |
| AK-05 | ausschließlich der Systemdienst | belegbar: keine weitere Schnittstelle im Feature |
| AK-06 | kein Schlüssel in den Einstellungen | |
| AK-07 ⚠ | `print()` + fehlende Beobachtbarkeit | |

## Übergabe an die QA

1. **AK-07** erzwingen, indem die Anwendung außerhalb von `/Applications` betrieben wird —
   etwa direkt aus dem Erstellungsverzeichnis. Beobachten, ob der Schalter danach den
   tatsächlichen Zustand zeigt.
2. **AK-03** prüfen: Anmeldeobjekt in den Systemeinstellungen entfernen, dann die
   Einstellungen der Anwendung öffnen.
