# B13 · Automatischer Start bei Login — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja**

Das kleinste Feature der Anwendung und das mit der klarsten Prüflage: Es besteht aus zwei
Aufrufen an einen Systemdienst. Ein Test dafür müsste ein echtes Anmeldeobjekt eintragen —
eine Systemänderung, die in einem Testlauf nichts zu suchen hat (in der Spec als BF-03
akzeptiert).

Belegt ist, was ohne Systemänderung belegbar war: Die Klasse führt keinen eigenen Zustand,
fragt also immer das System, und der Fehlerpfad meldet sich sichtbar.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 7 |
| davon bestanden | 3 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 4 |
| Edge Cases belegt | 0 von 4 |
| Tests neu geschrieben | 0 |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Einschalten trägt ein | ⚠️ nicht prüfbar | echte Systemänderung |
| AK-02 Ausschalten entfernt | ⚠️ nicht prüfbar | dito |
| AK-03 Das System ist die Wahrheitsquelle | ✅ bestanden | `isEnabled` liest `SMAppService.mainApp.status`; es gibt keinen Schlüssel dafür in `ownedDefaultsKeys` — Gegenprobe über die Aufzählung im Test |
| AK-04 *Done* setzt entsprechend | ⚠️ nicht prüfbar | siehe B12/AK-09 |
| AK-05 Nur der Systemdienst | ✅ bestanden | im gesamten Feature kein Zugriff auf Startordner oder Hilfsdienste; `import ServiceManagement` ist die einzige Abhängigkeit |
| AK-06 Nichts wird selbst gespeichert | ✅ bestanden | kein Schlüssel in `ownedDefaultsKeys`, im Test aufgezählt |
| AK-07 Fehlschlag meldet, Schalter folgt dem System | ⚠️ nicht prüfbar | braucht einen erzwungenen Fehlschlag; der Meldepfad ist über A6 belegt, die Beobachtbarkeit über `@Observable` |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Anwendung außerhalb `/Applications` | ⚠️ nicht prüfbar | erzeugt eine echte Systemänderung |
| EC-02 Nutzer verweigert die Abfrage | ⚠️ nicht prüfbar | dito |
| EC-03 Anwendung verschoben | ⚠️ nicht prüfbar | Systemverhalten |
| EC-04 Zwei Kopien | ⚠️ nicht prüfbar | dito |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Kein Startordner, kein Hintergrunddienst | ✅ bestanden | nur `SMAppService`; A7 belegt, dass keine weiteren Rechte angefordert werden |
| Personendaten in Logs | ✅ bestanden | A5 |
| Geheimnisse | trifft nicht zu | keine im Feature |

## Fehler

Keine.

## Neue Tests

Keine — begründet in der Spec (BF-03).

## Nächster Schritt

`/sdd-deploy B13`. Im manuellen Durchgang: Schalter ein, abmelden, anmelden, prüfen — und
einmal mit der Anwendung außerhalb von `/Applications`, um AK-07 zu sehen.
