# B12 · Ersteinrichtung — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja, mit einer Pflichtprüfung**

Dieses Feature ist am schwersten zu prüfen und zugleich das, bei dem ein Fehler den
Erstkontakt kostet. Es lässt sich nur mit einem **frischen Benutzerkonto** beurteilen — die
Berechtigung wird pro Konto und Programm vergeben, und ein einmal beantworteter Systemdialog
erscheint nicht wieder.

Belegbar war, dass der Befund behoben ist: `CGRequestScreenCaptureAccess` wird aufgerufen,
und der wirkungslose Vermerk `permissionSkipped` ist samt Schlüssel entfernt. Ob der Dialog
im Erstkontakt tatsächlich erscheint und die Anwendung danach in der Systemliste steht, ist
die Pflichtprüfung.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 18 |
| davon bestanden | 4 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 14 |
| Edge Cases belegt | 0 von 5 |
| Tests neu geschrieben | 0 |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Fenster beim Erststart | ⚠️ nicht prüfbar | braucht ein frisches Benutzerkonto |
| AK-02 Drei oder zwei Seiten | ⚠️ nicht prüfbar | dito |
| AK-03 Punktanzeige | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-04 Übergang zur nächsten Seite | ⚠️ nicht prüfbar | dito |
| AK-05 *Grant Access* öffnet die Systemeinstellung | ⚠️ nicht prüfbar | braucht die Systemabfrage |
| AK-06 Erkennung im Sekundentakt | ⚠️ nicht prüfbar | dito |
| AK-07 *Skip for now* | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-08 Sieben Kombinationen auf der letzten Seite | ✅ bestanden | `HotkeyBindingTests` belegt, dass genau sieben Aktionen mit eigenen Voreinstellungen existieren |
| AK-09 *Done* setzt den Anmeldestart | ⚠️ nicht prüfbar | Systemänderung |
| AK-10 Schließen gilt als Abschluss | ⚠️ nicht prüfbar | Fensterlebenszyklus |
| AK-11 *Show Onboarding Again* | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-12 Escape schließt und schließt ab | ⚠️ nicht prüfbar | dito; bewusstes Verhalten (BF-A10) |
| AK-13 Schalter zeigt den Systemzustand | ✅ bestanden | `_launchAtLogin = State(initialValue: launchAtLoginManager.isEnabled)` — kein fester Wert mehr; `isEnabled` fragt `SMAppService` |
| AK-14 Abbruch ändert den Anmeldestart nicht | ✅ bestanden | `setEnabled` wird ausschließlich in der *Done*-Aktion gerufen, und der Anfangswert ist jetzt der Systemzustand — angezeigter und tatsächlicher Zustand stimmen damit überein |
| AK-15 Berechtigung wird angefordert | ✅ bestanden | `CGRequestScreenCaptureAccess()` in `PermissionScreen.requestAccess()` — Gegenprobe: `grep -c CGRequestScreenCaptureAccess Sources/` liefert 1, vorher 0 |
| AK-16 Zweck und Datenzusage im Text | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-17 Nur ein Wahrheitswert gespeichert | ✅ bestanden | `permissionSkipped` ist entfernt; `ownedDefaultsKeys` führt nur `hasCompletedOnboarding` |
| AK-18 *Skip for now* speichert nichts | ✅ bestanden | derselbe Beleg |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 bis EC-05 | ⚠️ nicht prüfbar | sämtlich an den Berechtigungsfluss und den Fensterlebenszyklus gebunden |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Nur Wahrheitswerte gespeichert | ✅ bestanden | `ownedDefaultsKeys` |
| Personendaten in Logs | ✅ bestanden | A5 |
| Personendaten an externe Dienste | ✅ bestanden | A1, L1 — der Deeplink überträgt nichts |
| Rechteumfang | ✅ bestanden | A7 |

## Fehler

Keine.

## Neue Tests

Keine. Der Ablauf besteht aus Berechtigungsabfragen und Systemänderungen, die in einem
Testlauf nichts zu suchen haben (BF-06 der Spec, akzeptiert).

## Nächster Schritt

`/sdd-deploy B12` — **mit dieser Pflichtprüfung, die ein frisches Benutzerkonto braucht:**

1. Neues Benutzerkonto anlegen, 3.5.0 installieren, starten.
2. Erscheint der Systemdialog nach *Grant Access*?
3. Steht die Anwendung danach in *Systemeinstellungen → Datenschutz → Bildschirmaufnahme*?

Punkt 3 ist der eigentliche Befund: Vor 3.5.0 stand sie dort zu diesem Zeitpunkt nicht.
