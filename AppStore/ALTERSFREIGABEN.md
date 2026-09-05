# Altersfreigaben — Antworten für App Store Connect

Der Fragebogen unter *App Store Connect → App-Informationen → Altersfreigaben* fragt
24 Kategorien ab. Hier stehen die Antworten mit dem Beleg aus dem Code, damit sie bei
einer Neueinreichung oder nach einem Feature-Umbau nachvollziehbar bleiben. Ändert sich
eine der belegten Stellen, gehört die Antwort geprüft.

Stand: 2026-09-04, App-Version 3.6.0. Grundlage:
[Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions).

**Ergebnis: 4+** — die niedrigste Stufe, und zwar ohne Ausnahme in irgendeiner
Kategorie.

Apple hat das System 2025 umgestellt: Die Stufen heißen jetzt 4+, 9+, 13+, 16+ und 18+
(vorher 4+, 9+, 12+, 17+), und mehrere Kategorien sind dazugekommen. Wer eine ältere
Anleitung im Kopf hat, findet die Fragen nicht wieder.

**Diese Anwendung hat es hier schwerer als ihre Schwesterprojekte**, und das ist der
Grund, warum die Antworten nicht aus Mika+Grid übernommen wurden: Mika+ScreenSnap
*zeigt* Bildschirminhalte an — die aufgenommene Fläche im Editor, angeheftete Bilder,
erkannten Text, den Verlaufsbrowser. Die Abgrenzung unten ist deshalb ausformuliert und
nicht mit „die Oberfläche zeigt Rechtecke" abgetan.

---

## Schritt 1: Funktionen

| Frage (deutsch / englisch) | Antwort | Beleg |
|---|---|---|
| Kindersicherung · *Parental Controls* | Nein | Die Anwendung kennt technische Einstellungen: Speicherort, Bildformat, Zeichenvorgaben, Tastenkürzel, Ausschlussliste, Start bei der Anmeldung (`Sources/AppPreferences.swift:139-149`). Keine Sperren, keine Profile, keine Konten. |
| Altersnachweis · *Age Assurance* | Nein | Keine Konten, keine Registrierung, keine Altersabfrage. Die Anwendung fragt nichts ab. |
| Uneingeschränkter Internetzugriff · *Unrestricted Web Access* | Nein | Kein Browser, keine Adresszeile. `grep -rn "URLSession\|WKWebView\|NSURLConnection" Sources/` liefert **nichts**. Die einzigen Sprünge nach außen sind `x-apple.systempreferences:`-Adressen in die Systemeinstellungen und das Öffnen des Speicherordners im Finder — beides führt in System-Apps, nicht ins Netz. Die Store-Fassung enthält nicht einmal einen Update-Kanal: `Sources/SparkleUpdater.swift` liegt vollständig in `#if !APPSTORE`. |
| Benutzergenerierte Inhalte · *User-Generated Content* | Nein | Siehe die Abgrenzung unten. |
| Soziale Medien · *Social Media* | Nein | Keine Feeds, keine Profile, keine Interaktion mit anderen Nutzern. |
| Soziale Medien für unter 13-Jährige deaktiviert · *Social Media Disabled for Users Under 13* | Nein | Gegenstandslos, da „Soziale Medien" bereits Nein ist. |
| Nachrichten und Chat · *Messaging and Chat* | Nein | Keine Kommunikationsfunktion. |
| Werbung · *Advertising* | Nein | Die Store-Fassung wird ohne jede Fremdabhängigkeit gebaut: `Package.swift` nimmt Sparkle nur auf, wenn `MIKA_APPSTORE` fehlt. `scripts/build-appstore.sh` bricht ab, wenn doch ein `Sparkle.framework` im Bundle liegt. Kein Werbe-SDK, keine Analytics. |

### Warum „Benutzergenerierte Inhalte = Nein"

Bei einer Anwendung, die den Bildschirm aufnimmt und das Ergebnis anzeigt, ist die Frage
berechtigt. Apples Kategorie zielt auf Inhalte, die **von anderen Nutzern** stammen und
zwischen ihnen verteilt werden — daher auch die Folgepflichten aus Guideline 1.2
(Meldefunktion, Blockieren, veröffentlichte Kontaktadresse). Hier trifft das aus vier
Gründen nicht zu:

- Der einzige Inhalt, den die Anwendung anzeigt, ist der **eigene Bildschirm des
  Nutzers**, aufgenommen auf seine eigene Tastenkombination hin. Es gibt keine zweite
  Person, deren Inhalte auftauchen könnten.
- **Es gibt keinen Kanal, über den etwas zu jemand anderem gelangen könnte.** Kein
  Backend, kein Konto, kein Teilen-Ziel, keine Netzverbindung. Was aufgenommen wird,
  landet als Datei in einem Ordner auf demselben Gerät.
- **Es gibt nichts zu melden und niemanden zu blockieren** — die Voraussetzung der
  Folgepflichten fehlt vollständig.
- Der Verlaufsbrowser und die angehefteten Bilder zeigen ausschließlich Dateien, die die
  Anwendung selbst auf diesem Gerät angelegt hat
  (`~/Library/Application Support/MikaScreenSnap/PinnedScreenshots/` und der gewählte
  Speicherordner).

Auf einem Bildschirmfoto des Store-Eintrags **sind** natürlich Fensterinhalte zu sehen —
das ist der Zweck der Anwendung. Die Aufnahmen unter `screenshots/` zeigen deshalb
ausschließlich eine erzeugte Demo-Leinwand (`scripts/GenerateDemoCanvas.swift`), nie
einen privaten Bildschirm. Der Verlaufsbrowser wird bewusst nicht aufgenommen: Er
rendert echte Dateien.

## Schritt 2: Erwachsenenthemen

| Frage | Antwort | Beleg |
|---|---|---|
| Obszöner oder vulgärer Humor · *Profanity or Crude Humor* | Nie | Die Anwendung zeigt Werkzeuge und das eigene Bild des Nutzers. Alle eigenen Texte stehen in `Sources/`. |
| Horror-/Gruselszenen · *Horror/Fear Themes* | Nie | Keine Illustrationen außer dem App-Symbol und SF Symbols. |
| Alkohol, Tabak oder Drogen bzw. Verweise · *Alcohol, Tobacco, or Drug Use or References* | Nie | Kommt inhaltlich nicht vor. |

## Schritt 3: Gesundheit

| Frage | Antwort | Beleg |
|---|---|---|
| Medizinische oder Behandlungsinformationen · *Medical or Treatment Information* | Nie | Die Anwendung gibt keinerlei Ratschläge. |
| Gesundheits- oder Wellness-Themen · *Health or Wellness Topics* | Nein | Dito. |

## Schritt 4: Sexuelle Inhalte

| Frage | Antwort |
|---|---|
| Anzügliche Themen · *Mature or Suggestive Themes* | Nie |
| Sexuelle Inhalte oder Nacktheit · *Sexual Content or Nudity* | Nie |
| Explizite sexuelle Inhalte und Nacktheit · *Graphic Sexual Content and Nudity* | Nie |

Die Anwendung erzeugt keine eigenen Bildinhalte. Sie kann den Bildschirm des Nutzers
aufnehmen — was dort steht, bestimmt der Nutzer, und es verlässt das Gerät nicht. Das ist
dieselbe Lage wie bei der Bildschirmfoto-Funktion des Systems und begründet keine höhere
Einstufung.

## Schritt 5: Gewalt

| Frage | Antwort |
|---|---|
| Comic- oder Fantasy-Gewalt · *Cartoon or Fantasy Violence* | Nie |
| Realistische Gewalt · *Realistic Violence* | Nie |
| Anhaltende explizite oder sadistische realistische Gewalt · *Prolonged Graphic or Sadistic Realistic Violence* | Nie |
| Schusswaffen oder andere Waffen · *Guns or Other Weapons* | Nie |

## Schritt 6: Glücksspiel und Wettbewerbe

| Frage | Antwort |
|---|---|
| Glücksspiel · *Gambling* | Nein |
| Simuliertes Glücksspiel · *Simulated Gambling* | Nie |
| Wettbewerbe · *Contests* | Nie |
| Beutekisten · *Loot Boxes* | Nein |

Keine Käufe, keine Währung, keine Zufallsmechanik. Die Anwendung ist kostenlos und kennt
keine In-App-Käufe.

---

## Wenn sich etwas ändert

Diese fünf Antworten sind die einzigen, die ein neues Feature kippen könnte:

| Antwort | Was sie kippen würde |
|---|---|
| Uneingeschränkter Internetzugriff | Eine eingebettete Web-Ansicht oder ein Link, der frei navigierbare Seiten öffnet. Ein `WKWebView` oder eine `URLSession` in `Sources/` ist das Alarmsignal. |
| Benutzergenerierte Inhalte | Jede Funktion, über die eine Aufnahme zu einer anderen Person gelangt: Teilen-Ziel, Upload, Kurz-URL, gemeinsamer Ordner. Genau dann greifen die Folgepflichten aus Guideline 1.2. |
| Werbung | Jede Fremdabhängigkeit, die in der Store-Fassung mitgebaut wird — den `isAppStore`-Zweig in `Package.swift` und das Store-Ziel in `project.yml` prüfen. |
| Nachrichten und Chat | Jede Form der Kommunikation zwischen Nutzern. |
| *(alle)* | Jede Änderung an `Resources/MikaScreenSnap-AppStore.entitlements`. Wer dort etwas hinzufügt, erweitert das, was die Anwendung darf — und damit die Grundlage aller Antworten oben. |

Die ersten drei lassen sich mechanisch prüfen:

```bash
grep -rn "URLSession\|WKWebView\|NSURLConnection" Sources/   # muss leer bleiben
grep -rn "import Sparkle" Sources/                           # nur SparkleUpdater.swift, in #if !APPSTORE
plutil -p Resources/MikaScreenSnap-AppStore.entitlements     # genau drei Einträge
```

`swift test --filter StoreAssetTests` prüft die erste und die zweite Zusage bei jedem
Lauf mit.
