#!/usr/bin/env swift
// compose.swift — setzt die rohen Bildschirmaufnahmen zu fertigen App-Store-Bildern zusammen.
//
// Aus screenshots/raw/<sprache>/NN_name.png wird
// screenshots/<locale>/<format>/NN_name.jpg: Markenhintergrund, Headline, Subline
// und die Aufnahme in einem Rahmen.
//
// Übernommen aus Mika+Grid, und zwar wörtlich bis auf diesen Kopf: Die Markenpalette
// unten ist mit `Sources/MikaPlusColors.swift` byteweise identisch — beide Projekte
// teilen sich die Farben des Baukastens, einschließlich des blaustichigen Dunkels
// #1A1A2E/#0F0F1A. Es gab also nichts anzupassen, und wer hier etwas ändert, ändert es
// auch dort.
//
// Der Unterschied zum Vorbild liegt in den Aufnahmen, nicht im Werkzeug: Bei Mika+Grid
// ist die Rohaufnahme ein Bildschirmausschnitt mit mehreren gesnappten Fenstern, hier ist
// sie meist EIN Anwendungsfenster — der Editor, das Menü, die Textausgabe. Der gerundete
// Rahmen aus `fenster(...)` liest sich dafür so, wie er gedacht war.
//
// Die fünf Kacheln teilen sich vier Layouts (hero, text-top, frame-top, highlight),
// damit die Store-Galerie nicht fünfmal dasselbe Bild zeigt. Welches Motiv welches
// Layout bekommt — samt Highlight-Ausschnitt — steht in shots.json.
//
// AppKit statt Pillow, weil das Projekt seine Bilder schon so erzeugt
// (scripts/GenerateDMGBackground.swift, scripts/GenerateDemoCanvas.swift) und weil SF Pro
// nur über AppKit in allen Schnitten zur Verfügung steht.
//
// Alle Maße leiten sich aus der Leinwandgröße ab; ein weiteres Format kostet
// deshalb nur einen Eintrag in FORMATE.
//
//     swift AppStore/tools/compose.swift                    # alle Sprachen, 2880×1800
//     swift AppStore/tools/compose.swift en-US              # nur eine
//     swift AppStore/tools/compose.swift --format 2560x1600 # anderes Zielformat

import AppKit

// MARK: - Pfade

let werkzeuge = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent().standardizedFileURL
let appStore = werkzeuge.deletingLastPathComponent()
let roh = appStore.appendingPathComponent("screenshots/raw")
let ausgabe = appStore.appendingPathComponent("screenshots")

// MARK: - Markenpalette (Spiegel von Sources/MikaPlusColors.swift)
//
// Jeder Wert steht so in `NSColor.MikaPlus`: `tealPrimary`, `tealSurface`, `darkBg`,
// `darkBgDeep`, `textPrimary`, `textSecondary`. `tealTief` (#116B4E) ist die einzige
// Ausnahme — eine reine Schattenfarbe, die es in der App nicht gibt. Wer die Markenfarbe
// ändert, ändert sie in MikaPlusColors.swift und spiegelt sie hierher und nach
// web/app/globals.css.

let teal       = NSColor(srgbRed: 0x1D/255.0, green: 0x9E/255.0, blue: 0x75/255.0, alpha: 1)
let tealTief   = NSColor(srgbRed: 0x11/255.0, green: 0x6B/255.0, blue: 0x4E/255.0, alpha: 1)
let hellOben   = NSColor(srgbRed: 0xFA/255.0, green: 0xFD/255.0, blue: 0xFB/255.0, alpha: 1)
let hellUnten  = NSColor(srgbRed: 0xE1/255.0, green: 0xF5/255.0, blue: 0xEE/255.0, alpha: 1)
let dunkelOben = NSColor(srgbRed: 0x1A/255.0, green: 0x1A/255.0, blue: 0x2E/255.0, alpha: 1)
let dunkelUnten = NSColor(srgbRed: 0x0F/255.0, green: 0x0F/255.0, blue: 0x1A/255.0, alpha: 1)
let tinte      = NSColor(srgbRed: 0x0F/255.0, green: 0x0F/255.0, blue: 0x1A/255.0, alpha: 1)
let tinteMatt  = NSColor(srgbRed: 0x4A/255.0, green: 0x5B/255.0, blue: 0x55/255.0, alpha: 1)
let creme      = NSColor(srgbRed: 0xE1/255.0, green: 0xF5/255.0, blue: 0xEE/255.0, alpha: 1)
let cremeMatt  = NSColor(srgbRed: 0x9F/255.0, green: 0xE1/255.0, blue: 0xCB/255.0, alpha: 1)

struct Palette {
    let grundOben: NSColor, grundUnten: NSColor
    let headline: NSColor, subline: NSColor
    let kartenRahmen: NSColor
}

func palette(_ theme: String) -> Palette {
    theme == "dark"
        ? Palette(grundOben: dunkelOben, grundUnten: dunkelUnten,
                  headline: creme, subline: cremeMatt, kartenRahmen: creme)
        : Palette(grundOben: hellOben, grundUnten: hellUnten,
                  headline: tinte, subline: tinteMatt, kartenRahmen: .white)
}

// MARK: - Zielformate

// App Store Connect nimmt für den Mac vier Größen; hier die beiden großen.
let FORMATE: [String: NSSize] = [
    "2880x1800": NSSize(width: 2880, height: 1800),
    "2560x1600": NSSize(width: 2560, height: 1600),
]
let STANDARDFORMAT = "2880x1800"

/// Leitet alle Layoutmaße aus der Leinwandgröße ab, damit jedes von Apple
/// akzeptierte Format dieselben Proportionen erbt.
struct Layout {
    let w: CGFloat, h: CGFloat

    init(_ groesse: NSSize) { w = groesse.width; h = groesse.height }

    var rand: CGFloat          { round(w * 0.104) }
    var ecke: CGFloat          { round(w * 0.009) }
    var headlineOben: CGFloat  { round(h * 0.072) }
    var headlineGroesse: CGFloat { round(w * 0.0514) }
    var headlineMinimum: CGFloat { round(w * 0.030) }
    var sublineGroesse: CGFloat { round(w * 0.0174) }
    var sublineAbstand: CGFloat { round(h * 0.022) }
    var fensterBreite: CGFloat { round(w * 0.819) }
    var heroBreite: CGFloat    { round(w * 0.92) }
}

// MARK: - Konfiguration

struct Karte: Decodable {
    let rect: [CGFloat]
    let scale: CGFloat?
    let x: CGFloat?
    let y: CGFloat?
    let rotate: CGFloat?
}

struct Motiv: Decodable {
    let file: String
    let theme: String
    let layout: String
    let card: Karte?
}

struct Text: Decodable {
    let headline: String
    let subline: String
}

struct Konfiguration: Decodable {
    let shots: [Motiv]
    let texts: [String: [String: Text]]
}

// Locale → Ordner der Rohaufnahmen. Bleibt bei einer Sprache trivial, hält aber
// die Stelle offen, an der weitere Lokalisierungen eingetragen werden.
let SPRACHE: [String: String] = ["en-US": "en"]

// MARK: - Zeichenhilfen

func verlauf(_ von: NSColor, _ nach: NSColor, in rect: NSRect, winkel: CGFloat = -90) {
    NSGradient(colors: [von, nach])?.draw(in: rect, angle: winkel)
}

/// Punktraster und ein weicher Schein hinter der Headline — gibt der leeren
/// Fläche Struktur, ohne vom Fenster abzulenken.
func hintergrund(_ p: Palette, _ l: Layout) {
    let alles = NSRect(x: 0, y: 0, width: l.w, height: l.h)
    verlauf(p.grundOben, p.grundUnten, in: alles)

    NSGraphicsContext.current?.saveGraphicsState()
    NSGradient(colors: [teal.withAlphaComponent(0.16), teal.withAlphaComponent(0)])?
        .draw(in: NSRect(x: l.w/2 - l.w*0.49, y: l.h - l.h*0.67,
                         width: l.w*0.98, height: l.h*0.78),
              relativeCenterPosition: .zero)
    NSGraphicsContext.current?.restoreGraphicsState()

    teal.withAlphaComponent(0.07).setFill()
    let schritt = round(l.w * 0.025)
    var y = schritt / 2
    while y < l.h {
        var x = schritt / 2
        while x < l.w {
            NSBezierPath(ovalIn: NSRect(x: x, y: y, width: l.w*0.0017, height: l.w*0.0017)).fill()
            x += schritt
        }
        y += schritt
    }
}

func mitSchatten(_ farbe: NSColor, radius: CGFloat, versatz: CGFloat, _ block: () -> Void) {
    NSGraphicsContext.current?.saveGraphicsState()
    let s = NSShadow()
    s.shadowColor = farbe
    s.shadowBlurRadius = radius
    s.shadowOffset = NSSize(width: 0, height: -versatz)
    s.set()
    block()
    NSGraphicsContext.current?.restoreGraphicsState()
}

/// Zeichnet das Fenster mit Schatten und runden Ecken.
func fenster(_ bild: NSImage, in rect: NSRect, ecke: CGFloat) {
    let pfad = NSBezierPath(roundedRect: rect, xRadius: ecke, yRadius: ecke)
    mitSchatten(tealTief.withAlphaComponent(0.30), radius: rect.width * 0.030,
                versatz: rect.width * 0.010) {
        NSColor.black.setFill()
        pfad.fill()
    }
    NSGraphicsContext.current?.saveGraphicsState()
    pfad.addClip()
    bild.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.current?.restoreGraphicsState()
}

/// Verdunkelt den Fuß des Fensters, damit die Headline darauf lesbar wird.
///
/// Drei Stopps statt zwei: Ein glatter Verlauf ist auf halber Höhe — genau dort,
/// wo die Headline steht — schon halb durchsichtig, und die Balken des Diagramms
/// scheinen durch die Buchstaben. Der Bereich unter dem Text bleibt deshalb fast
/// voll gedeckt und läuft erst darüber aus.
func scrim(_ rect: NSRect, ecke: CGFloat, anteil: CGFloat = 0.56) {
    let pfad = NSBezierPath(roundedRect: rect, xRadius: ecke, yRadius: ecke)
    NSGraphicsContext.current?.saveGraphicsState()
    pfad.addClip()
    let hoehe = rect.height * anteil
    NSGradient(colors: [NSColor.black.withAlphaComponent(0.97),
                        NSColor.black.withAlphaComponent(0.93),
                        NSColor.black.withAlphaComponent(0)],
               atLocations: [0.0, 0.62, 1.0], colorSpace: .deviceRGB)?
        .draw(in: NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: hoehe),
              angle: 90)
    NSGraphicsContext.current?.restoreGraphicsState()
}

func absatz(_ ausrichtung: NSTextAlignment, zeilen: CGFloat) -> NSParagraphStyle {
    let s = NSMutableParagraphStyle()
    s.alignment = ausrichtung
    s.lineHeightMultiple = zeilen
    return s
}

func hoehe(_ text: String, _ attribute: [NSAttributedString.Key: Any], breite: CGFloat) -> CGFloat {
    NSAttributedString(string: text, attributes: attribute)
        .boundingRect(with: NSSize(width: breite, height: .greatestFiniteMagnitude),
                      options: [.usesLineFragmentOrigin]).height
}

@discardableResult
func zeichne(_ text: String, attribute: [NSAttributedString.Key: Any],
             breite: CGFloat, x: CGFloat, obenBei y: CGFloat) -> CGFloat {
    let s = NSAttributedString(string: text, attributes: attribute)
    let h = hoehe(text, attribute, breite: breite)
    s.draw(with: NSRect(x: x, y: y - h, width: breite, height: h),
           options: [.usesLineFragmentOrigin])
    return h
}

/// Verkleinert die Headline, bis sie in die vorgesehene Höhe passt. Längere
/// Übersetzungen brechen das Layout dadurch nicht.
func headlineSchrift(_ text: String, _ l: Layout, maxHoehe: CGFloat,
                     breite: CGFloat) -> NSFont {
    var groesse = l.headlineGroesse
    while groesse > l.headlineMinimum {
        let f = NSFont.systemFont(ofSize: groesse, weight: .black)
        let attr: [NSAttributedString.Key: Any] = [
            .font: f, .paragraphStyle: absatz(.center, zeilen: 0.92),
            .kern: -groesse * 0.02,
        ]
        if hoehe(text, attr, breite: breite) <= maxHoehe { return f }
        groesse -= l.w * 0.004
    }
    return NSFont.systemFont(ofSize: l.headlineMinimum, weight: .black)
}

/// Setzt Headline und Subline zentriert in einen Block und meldet dessen Höhe.
@discardableResult
func textblock(_ headline: String, _ subline: String, _ p: Palette, _ l: Layout,
               obenBei y: CGFloat, maxHoehe: CGFloat,
               headlineFarbe: NSColor? = nil, sublineFarbe: NSColor? = nil) -> CGFloat {
    let breite = l.w - 2 * l.rand
    let sublineAttr: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: l.sublineGroesse, weight: .regular),
        .foregroundColor: sublineFarbe ?? p.subline,
        .paragraphStyle: absatz(.center, zeilen: 1.18),
    ]
    let sublineHoehe = hoehe(subline, sublineAttr, breite: breite)
    let font = headlineSchrift(headline, l,
                               maxHoehe: maxHoehe - sublineHoehe - l.sublineAbstand,
                               breite: breite)
    let headlineAttr: [NSAttributedString.Key: Any] = [
        .font: font, .foregroundColor: headlineFarbe ?? p.headline,
        .paragraphStyle: absatz(.center, zeilen: 0.92),
        .kern: -font.pointSize * 0.02,
    ]
    let headlineHoehe = zeichne(headline, attribute: headlineAttr,
                                breite: breite, x: l.rand, obenBei: y)
    zeichne(subline, attribute: sublineAttr, breite: breite, x: l.rand,
            obenBei: y - headlineHoehe - l.sublineAbstand)
    return headlineHoehe + l.sublineAbstand + sublineHoehe
}

/// Vergrößert einen Ausschnitt der Aufnahme zu einer schwebenden Karte.
/// `rect` ist auf 0…1 normiert und damit unabhängig von der Rohauflösung.
func highlightKarte(_ bild: NSImage, _ spec: Karte, _ p: Palette, _ l: Layout,
                    fensterBreite: CGFloat) -> NSImage {
    let (x0, y0, x1, y1) = (spec.rect[0], spec.rect[1], spec.rect[2], spec.rect[3])
    let quelle = bild.size
    // AppKit zählt von unten, die Konfiguration von oben.
    let ausschnitt = NSRect(x: x0 * quelle.width, y: (1 - y1) * quelle.height,
                            width: (x1 - x0) * quelle.width,
                            height: (y1 - y0) * quelle.height)

    let rahmen = round(l.w * 0.0045)
    let ecke = round(l.w * 0.014)
    let maxBreite = l.w - 2 * round(l.w * 0.05) - 2 * rahmen
    let breite = min((x1 - x0) * fensterBreite * (spec.scale ?? 1.3), maxBreite)
    let inhalt = NSSize(width: breite,
                        height: breite * ausschnitt.height / ausschnitt.width)

    let karte = NSImage(size: NSSize(width: inhalt.width + 2 * rahmen,
                                     height: inhalt.height + 2 * rahmen))
    karte.lockFocus()
    let ganz = NSRect(origin: .zero, size: karte.size)
    p.kartenRahmen.setFill()
    NSBezierPath(roundedRect: ganz, xRadius: ecke + rahmen, yRadius: ecke + rahmen).fill()
    NSGraphicsContext.current?.saveGraphicsState()
    let innen = NSRect(x: rahmen, y: rahmen, width: inhalt.width, height: inhalt.height)
    NSBezierPath(roundedRect: innen, xRadius: ecke, yRadius: ecke).addClip()
    bild.draw(in: innen, from: ausschnitt, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.current?.restoreGraphicsState()
    karte.unlockFocus()
    return karte
}

func zeichneKarte(_ karte: NSImage, mitte: NSPoint, drehung: CGFloat, _ l: Layout) {
    NSGraphicsContext.current?.saveGraphicsState()
    let t = NSAffineTransform()
    t.translateX(by: mitte.x, yBy: mitte.y)
    if drehung != 0 { t.rotate(byDegrees: drehung) }
    t.concat()
    let rect = NSRect(x: -karte.size.width/2, y: -karte.size.height/2,
                      width: karte.size.width, height: karte.size.height)
    mitSchatten(tealTief.withAlphaComponent(0.34), radius: l.w * 0.030,
                versatz: l.h * 0.012) {
        karte.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    }
    NSGraphicsContext.current?.restoreGraphicsState()
}

// MARK: - Layouts

/// Auftakt: Aufnahme fast formatfüllend, Headline im abgedunkelten Fuß.
func rendereHero(_ bild: NSImage, _ m: Motiv, _ t: Text, _ p: Palette, _ l: Layout) {
    let breite = l.heroBreite
    let hoeheF = breite * bild.size.height / bild.size.width
    let oben = l.h - round(l.h * 0.055)
    let rect = NSRect(x: (l.w - breite)/2, y: oben - hoeheF, width: breite, height: hoeheF)
    fenster(bild, in: rect, ecke: l.ecke)
    scrim(rect, ecke: l.ecke)
    // Auf dem Scrim gilt immer die helle Schrift, unabhängig vom Thema.
    textblock(t.headline, t.subline, p, l,
              obenBei: rect.minY + round(l.h * 0.25), maxHoehe: round(l.h * 0.19),
              headlineFarbe: creme, sublineFarbe: cremeMatt)
}

/// Headline oben, Fenster darunter — unten angeschnitten. Der Store-Klassiker.
@discardableResult
func rendereTextTop(_ bild: NSImage, _ m: Motiv, _ t: Text, _ p: Palette,
                    _ l: Layout) -> NSRect {
    let oben = l.h - l.headlineOben
    let blockHoehe = textblock(t.headline, t.subline, p, l,
                               obenBei: oben, maxHoehe: round(l.h * 0.26))
    let breite = l.fensterBreite
    let hoeheF = breite * bild.size.height / bild.size.width
    let fensterOben = oben - blockHoehe - round(l.h * 0.052)
    let rect = NSRect(x: (l.w - breite)/2, y: fensterOben - hoeheF,
                      width: breite, height: hoeheF)
    fenster(bild, in: rect, ecke: l.ecke)
    return rect
}

/// Fenster läuft oben aus dem Bild, Text steht unten — bricht den Rhythmus.
func rendereFrameTop(_ bild: NSImage, _ m: Motiv, _ t: Text, _ p: Palette, _ l: Layout) {
    let breite = l.fensterBreite
    let hoeheF = breite * bild.size.height / bild.size.width
    let oben = l.h + round(l.h * 0.075)
    let rect = NSRect(x: (l.w - breite)/2, y: oben - hoeheF, width: breite, height: hoeheF)
    fenster(bild, in: rect, ecke: l.ecke)
    textblock(t.headline, t.subline, p, l,
              obenBei: rect.minY - round(l.h * 0.055), maxHoehe: round(l.h * 0.24))
}

/// Wie text-top, davor ein vergrößerter Ausschnitt als schwebende Karte.
func rendereHighlight(_ bild: NSImage, _ m: Motiv, _ t: Text, _ p: Palette, _ l: Layout) {
    let rect = rendereTextTop(bild, m, t, p, l)
    guard let spec = m.card else { return }
    let karte = highlightKarte(bild, spec, p, l, fensterBreite: rect.width)

    // Die Karte liegt standardmäßig genau über ihrer eigenen Herkunft — in beiden
    // Achsen — und verdeckt sie dadurch. Steht sie woanders, sieht man denselben
    // Inhalt zweimal: einmal klein an seinem Platz, einmal groß daneben. Das liest
    // sich wie ein Fehler, nicht wie ein Zoom.
    let mitteX = (spec.rect[0] + spec.rect[2]) / 2
    let mitteY = (spec.rect[1] + spec.rect[3]) / 2
    var x = spec.x.map { l.w * $0 } ?? (rect.minX + mitteX * rect.width)
    let y = spec.y.map { l.h * $0 } ?? (rect.maxY - mitteY * rect.height)
    // In der Leinwand halten, sonst wird die Karte am Rand beschnitten.
    let luft = round(l.w * 0.02)
    x = min(max(x, luft + karte.size.width/2), l.w - luft - karte.size.width/2)
    zeichneKarte(karte, mitte: NSPoint(x: x, y: y), drehung: spec.rotate ?? 0, l)
}

let RENDERER: [String: (NSImage, Motiv, Text, Palette, Layout) -> Void] = [
    "hero": rendereHero,
    "text-top": { b, m, t, p, l in _ = rendereTextTop(b, m, t, p, l) },
    "frame-top": rendereFrameTop,
    "highlight": rendereHighlight,
]

// MARK: - Ablauf

func fehler(_ text: String) -> Never {
    FileHandle.standardError.write(("✘ " + text + "\n").data(using: .utf8)!)
    exit(1)
}

var nurLocale: String?
var formatName = STANDARDFORMAT
var i = 1
while i < CommandLine.arguments.count {
    let arg = CommandLine.arguments[i]
    if arg == "--format" {
        i += 1
        guard i < CommandLine.arguments.count else { fehler("--format braucht einen Wert") }
        formatName = CommandLine.arguments[i]
    } else if !arg.hasPrefix("--") {
        nurLocale = arg
    }
    i += 1
}
guard let groesse = FORMATE[formatName] else {
    fehler("Unbekanntes Format \(formatName) — bekannt: \(FORMATE.keys.sorted().joined(separator: ", "))")
}

guard let daten = try? Data(contentsOf: werkzeuge.appendingPathComponent("shots.json")),
      let konfiguration = try? JSONDecoder().decode(Konfiguration.self, from: daten)
else { fehler("shots.json fehlt oder ist fehlerhaft") }

let layout = Layout(groesse)
let locales = nurLocale.map { [$0] } ?? SPRACHE.keys.sorted()
var geschrieben = 0

for locale in locales {
    guard let sprache = SPRACHE[locale] else { fehler("Unbekannte Locale \(locale)") }
    guard let texte = konfiguration.texts[sprache] else { fehler("shots.json kennt \(sprache) nicht") }

    let ziel = ausgabe.appendingPathComponent("\(locale)/mac-\(formatName)")
    try? FileManager.default.createDirectory(at: ziel, withIntermediateDirectories: true)

    for motiv in konfiguration.shots {
        let quelle = roh.appendingPathComponent("\(sprache)/\(motiv.file).png")
        guard let bild = NSImage(contentsOf: quelle) else {
            // Kein stiller Rückfall auf eine andere Sprache: das ließe englische
            // Aufnahmen im übersetzten Store landen.
            fehler("Rohaufnahme fehlt: \(sprache)/\(motiv.file).png")
        }
        guard let text = texte[motiv.file] else { fehler("Kein Text für \(motiv.file) in \(sprache)") }
        guard let rendere = RENDERER[motiv.layout] else { fehler("Unbekanntes Layout \(motiv.layout)") }

        // Feste Pixelmaße statt NSImage.lockFocus() auf der Leinwand: Letzteres
        // verdoppelt auf einem Retina-Display die Auflösung, und App Store
        // Connect weist 5760×3600 zurück.
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(groesse.width), pixelsHigh: Int(groesse.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { fehler("Leinwand ließ sich nicht anlegen") }
        rep.size = groesse

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let p = palette(motiv.theme)
        hintergrund(p, layout)
        rendere(bild, motiv, text, p, layout)
        NSGraphicsContext.restoreGraphicsState()

        // JPEG statt PNG: Bei 2880×1800 wiegt ein PNG rund 3 MB, das Fünffache
        // davon im Repository ist es nicht wert. ASC nimmt beides, solange kein
        // Alphakanal drin ist.
        guard let jpeg = rep.representation(using: .jpeg,
                                            properties: [.compressionFactor: 0.92])
        else { fehler("Kodierung fehlgeschlagen: \(motiv.file)") }
        let pfad = ziel.appendingPathComponent("\(motiv.file).jpg")
        do { try jpeg.write(to: pfad) } catch { fehler("Schreiben fehlgeschlagen: \(error)") }
        print("  ✓ \(locale)/mac-\(formatName)/\(motiv.file).jpg — \(jpeg.count / 1024) KB · \(motiv.layout)/\(motiv.theme)")
        geschrieben += 1
    }
}

print("\(geschrieben) Bild(er) in \(groesse.width == 2880 ? "2880×1800" : formatName)")
