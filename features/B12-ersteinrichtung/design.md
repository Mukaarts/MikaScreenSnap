# B12 · Ersteinrichtung — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Der Ablauf ist ein SwiftUI-`TabView` in einem gewöhnlichen Fenster, das dem Muster des
„Über"-Fensters folgt. Seine Besonderheit ist die **Berechtigungserkennung im
Sekundentakt**: Weil macOS die Anwendung nicht benachrichtigt, wenn der Nutzer in den
Systemeinstellungen eine Berechtigung erteilt, fragt die Berechtigungsseite jede Sekunde
selbst nach.

Der Ablauf hat drei oder zwei Seiten, je nachdem, ob die Berechtigung beim Aufbau bereits
vorliegt. Diese Entscheidung fällt einmal, beim Aufbau der Ansicht.

## Komponentenstruktur

```
OnboardingWindowController             gewöhnliches Fenster, .titled .closable
└── OnboardingView                     480 × 560, dunkler Verlauf
    ├── TabView                        seitenweise, ohne Reiterleiste
    │   ├── WelcomeScreen              Begrüßung → weiter
    │   ├── PermissionScreen           nur wenn die Berechtigung fehlt
    │   │   ├── Zeitgeber, 1 s         fragt die Berechtigung ab
    │   │   ├── „Open System Settings" öffnet die Systemeinstellung
    │   │   └── „Skip for now"         setzt permissionSkipped (ohne Wirkung)
    │   └── ShortcutsScreen            sieben Tastenkombinationen
    │       ├── Schalter Anmeldestart  voreingestellt ein
    │       └── „Done"                 setzt den Anmeldestart, schließt
    ├── Punktanzeige                   Anzahl und Position, nicht bedienbar
    └── Escape                         schließt sofort
```

## Datenmodell

| Schlüssel | Typ | Gesetzt von | Gelesen von |
|---|---|---|---|
| `hasCompletedOnboarding` | Bool | beim Schließen des Fensters, immer | Programmstart |
| `permissionSkipped` | Bool | *Skip for now* | **niemandem** |

## Zugriffsregeln

Keine. Der Ablauf liest den Berechtigungszustand des Systems und schreibt zwei
Wahrheitswerte.

Die Berechtigung selbst wird **nicht** über diesen Ablauf erteilt — er verweist nur
dorthin. Erteilt wird sie durch den Nutzer in den Systemeinstellungen; wirksam wird sie
für die Anwendung beim nächsten Aufnahmeversuch.

## Missbrauchsschutz

Nicht anwendbar.

## Externe Dienste

Keine. Der Deeplink `x-apple.systempreferences:` öffnet eine Systemoberfläche, überträgt
aber nichts.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | `TabView` seitenweise statt eigener Navigation | eigener Zustandsautomat | mit Bordmitteln, wenige Zeilen |
| 2 | Abfrage im Sekundentakt | Systembenachrichtigung abwarten | es gibt keine Benachrichtigung für diese Berechtigung |
| 3 | Sekunde Verzögerung vor dem Weiterblättern | sofort | das grüne Häkchen soll gesehen werden |
| 4 | Seitenzahl beim Aufbau festgelegt | fortlaufend anpassen | verhindert, dass sich die Seitenstruktur unter dem Nutzer verändert — mit der Folge von EC-01 |
| 5 | Fenster folgt dem Muster des „Über"-Fensters | eigenes Muster | in `CLAUDE.md` als Konvention festgehalten |
| 6 | Aufgabe zum Weiterblättern wird beim Verschwinden abgebrochen | laufen lassen | verhindert Weiterblättern nach dem Schließen |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `AppDelegate` prüft `hasCompletedOnboarding` beim Start | |
| AK-02 | `needsPermission` bestimmt den Aufbau | einmalig beim Aufbau |
| AK-03 | Punktanzeige | |
| AK-04 | `withAnimation` beim Seitenwechsel | |
| AK-05 | Deeplink in die Systemeinstellungen | |
| AK-06 | Zeitgeber + Aufgabe mit einer Sekunde Verzögerung | |
| AK-07 | *Skip for now* | Vermerk ohne Wirkung |
| AK-08 | `ShortcutsScreen` | |
| AK-09 | *Done* → `setEnabled` → schließen | |
| AK-10 | `windowWillClose` | greift bei **jedem** Schließweg |
| AK-11 | Rückruf aus den Einstellungen | Umsetzung in B11 |
| AK-12 ⚠ | `Escape` + `windowWillClose` | |
| AK-13 ⚠ | Anfangswert `true` | |
| AK-14 ⚠ | `setEnabled` nur in *Done* | |
| AK-15 ⚠ | **keine Komponente** — es wird nie angefordert | |
| AK-16 | Text der Berechtigungsseite | |
| AK-17 | zwei Wahrheitswerte | |
| AK-18 ⚠ | `permissionSkipped` ohne Leser | |

## Übergabe an die QA

1. **AK-15 mit einem frischen Benutzerkonto prüfen** — das ist der einzige aussagekräftige
   Weg. Anwendung installieren, starten, dem Ablauf folgen und feststellen, ob die
   Anwendung in der Liste der Systemeinstellungen überhaupt erscheint, bevor sie zum ersten
   Mal aufzunehmen versucht hat. Das ist die praktisch wichtigste Prüfung dieses Features.
2. **AK-13 und AK-14 zusammen**: Ablauf bis zur letzten Seite, Schalter unangetastet
   lassen, `Escape` drücken — dann in den Systemeinstellungen nachsehen, ob ein
   Anmeldeobjekt existiert. Danach dasselbe mit *Done*.
3. **AK-12**: `Escape` auf der Begrüßungsseite, Anwendung neu starten.
