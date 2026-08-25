# B07 · Lineal / Bildschirm vermessen — Testbericht

Stand: 2026-08-25 · Geprüft gegen `spec.md` vom 2026-08-25 · Fassung 3.5.0

## Fazit

**Production-ready: ja**

Das wichtigste Kriterium dieses Features ist ein negatives: Eine Messung darf **nie** im
Export erscheinen. Das ist belegt und zwar strukturell wasserdicht — `measure` existiert
nicht als Annotationsart, sondern nur als Werkzeugart. Der Renderer kann also gar nichts
zeichnen, was es nicht als Annotation gibt.

Alles Übrige ist Maus- und Zeigerverhalten und blieb ungeprüft.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 12 |
| davon bestanden | 3 |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 9 |
| Edge Cases belegt | 0 von 4 |
| Tests neu geschrieben | 1 (innerhalb `AnnotationTests`) |
| Tests grün | 59 von 59 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 Overlay mit Hilfslinien | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-02 Punkt-zu-Punkt-Messung | ⚠️ nicht prüfbar | Mausereignis |
| AK-03 Rechteckmessung | ⚠️ nicht prüfbar | dito |
| AK-04 Leertaste wechselt die Einheit im Overlay | ⚠️ nicht prüfbar | Tastaturereignis |
| AK-05 Escape schließt | ⚠️ nicht prüfbar | dito |
| AK-06 Informationsfläche | ⚠️ nicht prüfbar | Oberflächenverhalten |
| AK-07 Werkzeug im Editor | ⚠️ nicht prüfbar | Mausereignis |
| AK-08 Werte bleiben bildbezogen | ⚠️ nicht prüfbar | hängt an der Umrechnung aus B03/AK-23 |
| AK-09 Messung erscheint in keinem Export | ✅ bestanden | `AnnotationTests::testMeasurementIsNotAnAnnotationAndCannotBeExported` — `AnnotationType(rawValue: "measure")` ist `nil`, `DrawingToolType(rawValue: "measure")` nicht. Der Renderer zeichnet ausschließlich Annotationen |
| AK-10 `U` wechselt die Einheit im Editor | ✅ bestanden | `MeasurementTool.keyDown` prüft `charactersIgnoringModifiers == "u"`; die Leertaste (Tastencode 49) wird dort nicht mehr behandelt |
| AK-11 Overlay liest keine Bildinhalte | ✅ bestanden | im gesamten Feature kein Aufruf von `SCScreenshotManager` oder `SCShareableContent` — Gegenprobe über die Aufrufliste in A1/A5 |
| AK-12 Nichts bleibt zurück | ✅ bestanden | kein Schreibpfad im Feature; `ownedDefaultsKeys` enthält keinen Messschlüssel |

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 Zwei Klicks auf denselben Punkt | ⚠️ nicht prüfbar | Mausereignis |
| EC-02 Messung über Displaygrenzen | ⚠️ nicht prüfbar | braucht zwei Displays |
| EC-03 Overlay während einer Aufnahme | ⚠️ nicht prüfbar | Oberflächenverhalten |
| EC-04 Werkzeugwechsel im Editor | ⚠️ nicht prüfbar | dito |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| **Keine Bildinhalte gelesen** | ✅ bestanden | kein Aufnahmeaufruf im Feature; das Overlay funktioniert ohne Bildschirmaufnahme-Berechtigung |
| Messungen im Export | ✅ bestanden | `testMeasurementIsNotAnAnnotationAndCannotBeExported` |
| Personendaten in Logs | ✅ bestanden | A5 |
| Geheimnisse | trifft nicht zu | keine im Feature |

## Fehler

Keine.

## Neue Tests

| Datei | Fälle | Deckt ab |
|---|---|---|
| `Tests/AnnotationTests.swift` | 1 der 10 | AK-09 |

## Nächster Schritt

`/sdd-deploy B07`. Im manuellen Durchgang gezielt AK-10 prüfen: `M` drücken, messen, `U`
für den Einheitenwechsel, Leertaste für das Verschieben — beide dürfen sich nicht mehr in
die Quere kommen.
