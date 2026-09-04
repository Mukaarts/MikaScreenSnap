// StoreAssetTests.swift
// MikaScreenSnapTests
//
// Checks the package under AppStore/ against what App Store Connect expects.
//
// A test rather than a script: character limits are the commonest reason a submission
// bounces, and `swift test` runs anyway. Lengthen a text and you find out here, not in
// the form.
//
// Adapted from Mika+Grid, which took it from Mika+FileScope. Four checks had to differ
// and two are new; the reason is written where each one sits.
//
// Everything here runs without a network and without a running app.

import XCTest
import AppKit

final class StoreAssetTests: XCTestCase {

    // MARK: - Paths

    /// Project root derived from this file's path, so the working directory does not matter.
    private static let projectRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // project root

    private var appStore: URL { Self.projectRoot.appendingPathComponent("AppStore") }

    private func text(_ field: String, locale: String = "en-US") throws -> String {
        try String(contentsOf: appStore.appendingPathComponent("metadata/\(locale)/\(field)"),
                   encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func source(_ path: String) throws -> String {
        try String(contentsOf: Self.projectRoot.appendingPathComponent(path), encoding: .utf8)
    }

    /// Localisations set up in App Store Connect.
    private let locales = ["en-US"]

    private let screenshotFormat = "mac-2880x1800"
    private let screenshotSize = NSSize(width: 2880, height: 1800)

    /// The one plist. ABWEICHUNG from both models, which keep a separate `Info-MAS.plist`
    /// for the store: here both editions read from this file and the store bundle is
    /// derived from it by deleting the two Sparkle keys (`project.yml`, post-build phase).
    /// Checking a second plist would mean checking a file that does not exist.
    private var infoPlistPath: String { "Resources/Info.plist" }

    // MARK: - Metadata

    func testMetadataStaysWithinAppStoreConnectLimits() throws {
        // Apple counts characters, not bytes.
        let limits: [String: Int] = [
            "name.txt": 30,
            "subtitle.txt": 30,
            "promotional_text.txt": 170,
            "description.txt": 4000,
            "keywords.txt": 100,
            "release_notes.txt": 4000,
        ]
        for locale in locales {
            for (field, limit) in limits.sorted(by: { $0.key < $1.key }) {
                let content = try text(field, locale: locale)
                XCTAssertFalse(content.isEmpty, "\(locale)/\(field) is empty")
                XCTAssertLessThanOrEqual(content.count, limit,
                    "\(locale)/\(field): \(content.count) characters, \(limit) allowed")
            }
        }
    }

    func testKeywordsWasteNoneOfTheBudget() throws {
        for locale in locales {
            let keywords = try text("keywords.txt", locale: locale)
            // A space after the comma counts against the 100 characters without improving
            // the search.
            XCTAssertFalse(keywords.contains(", "),
                "\(locale)/keywords.txt: a space after a comma spends budget for nothing")
            XCTAssertFalse(keywords.contains(",,"), "\(locale)/keywords.txt: empty keyword")
        }
    }

    /// Naming a competitor in the listing is a well-worn rejection. README and the website
    /// may compare freely; the store may not, and the way from there to here is short.
    func testMetadataNamesNoForeignProduct() throws {
        let foreign = ["CleanShot", "Shottr", "Snagit", "Skitch", "Monosnap",
                       "Xnapper", "Lightshot", "Greenshot", "Droplr"]
        for locale in locales {
            for field in ["keywords.txt", "description.txt", "subtitle.txt",
                          "promotional_text.txt", "release_notes.txt"] {
                let content = try text(field, locale: locale)
                for name in foreign {
                    XCTAssertFalse(content.contains(name),
                        "\(locale)/\(field) names the foreign product »\(name)«")
                }
            }
        }
    }

    func testTheThreeURLsAreSetAndAbsolute() throws {
        for locale in locales {
            for field in ["support_url.txt", "marketing_url.txt", "privacy_url.txt"] {
                let url = try text(field, locale: locale)
                XCTAssertTrue(url.hasPrefix("https://"),
                              "\(locale)/\(field): \(url) is not an https address")
            }
            // Apple opens the privacy address. It has to reach the privacy page, not the
            // front page.
            let privacy = try text("privacy_url.txt", locale: locale)
            XCTAssertTrue(privacy.hasSuffix("/privacy"),
                          "\(locale)/privacy_url.txt does not point at /privacy")
        }
    }

    func testNoPlaceholderWasLeftBehind() throws {
        let suspicious = ["TODO", "TBD", "XXX", "Lorem ipsum", "PLACEHOLDER"]
        for locale in locales {
            let folder = appStore.appendingPathComponent("metadata/\(locale)")
            for file in try FileManager.default.contentsOfDirectory(
                at: folder, includingPropertiesForKeys: nil) where file.pathExtension == "txt" {
                let content = try String(contentsOf: file, encoding: .utf8)
                for marker in suspicious {
                    XCTAssertFalse(content.localizedCaseInsensitiveContains(marker),
                        "\(locale)/\(file.lastPathComponent) contains »\(marker)«")
                }
            }
        }
    }

    // MARK: - Agreement with the bundle

    func testStoreNameMatchesTheBundle() throws {
        let plist = try source(infoPlistPath)
        XCTAssertEqual(try plistValue("CFBundleName", in: plist), try text("name.txt"),
                       "name.txt differs from CFBundleName in \(infoPlistPath)")
    }

    func testDescriptionNamesTheMinimumSystem() throws {
        let plist = try source(infoPlistPath)
        let version = try plistValue("LSMinimumSystemVersion", in: plist)
        let major = version.split(separator: ".").first.map(String.init) ?? version
        XCTAssertTrue(try text("description.txt").contains("macOS \(major)"),
            "\(infoPlistPath) requires macOS \(version), the description says something else")
    }

    /// NEW, and the counterpart to Mika+Grid's companion-shortcut check: two things about
    /// this edition have to be said *before* the download, and the promotional text is
    /// editable without review, so it cannot carry them. They belong in the description,
    /// in the part the store shows before it collapses the rest.
    func testDescriptionCarriesTheHonestyBlockEarly() throws {
        let description = try text("description.txt")
        guard let hit = description.range(of: "BEFORE YOU DOWNLOAD") else {
            XCTFail("description.txt has no »BEFORE YOU DOWNLOAD« block")
            return
        }
        let before = description.distance(from: description.startIndex, to: hit.lowerBound)
        XCTAssertLessThan(before, 700,
            "the honesty block starts after \(before) characters — the store has collapsed by then")

        // The folder question and the fact that nothing carries over. Both are in the
        // CHANGELOG as shipped behaviour; a listing that omits them oversells.
        XCTAssertTrue(description.contains("folder"),
                      "the block does not mention the folder the setup asks for")
        XCTAssertTrue(description.localizedCaseInsensitiveContains("nothing comes with you"),
                      "the block does not say that nothing carries over from the direct download")
    }

    func testEntitlementsPromiseNoNetworkTheDescriptionDenies() throws {
        let entitlements = try source("Resources/MikaScreenSnap-AppStore.entitlements")
        XCTAssertFalse(entitlements.contains("network.client"),
            "the description says »makes no network connection at all« — the entitlements say otherwise")
    }

    /// NEW, out of Mika+FileScope's real rejection on 2026-09-01 (guideline 2.1(a)): with
    /// `read-only` the powerbox does not open the panel at all — no error, the feature
    /// just looks dead. First-run setup is the only place this app asks for a folder, so
    /// the whole write path hangs on this one word.
    func testEntitlementsLetTheChosenFolderBeWrittenTo() throws {
        let entitlements = try source("Resources/MikaScreenSnap-AppStore.entitlements")
        XCTAssertTrue(entitlements.contains("com.apple.security.files.user-selected.read-write"),
                      "without read-write access the save folder cannot be written to")
        XCTAssertFalse(entitlements.contains("com.apple.security.files.user-selected.read-only"),
                      "read-only stops the powerbox from opening the panel at all (guideline 2.1(a))")
    }

    /// NEW, out of the same rejection (guideline 5.1.1(ii)): a purpose string that does not
    /// say what for, or that opens with one of Apple's stock non-answers, is a documented
    /// reason to bounce. This app asks for exactly one permission, so there is one string
    /// to get right.
    func testTheUsageDescriptionIsFitForReview() throws {
        let plist = try source(infoPlistPath)
        let purpose = try plistValue("NSScreenCaptureUsageDescription", in: plist)
        XCTAssertGreaterThan(purpose.count, 80,
                             "NSScreenCaptureUsageDescription is too short to explain anything")
        XCTAssertTrue(purpose.contains("Mika+ScreenSnap"),
                      "the purpose string does not name the app the dialog is about")
        for stockPhrase in ["would like to access", "needs access", "requires access"] {
            XCTAssertFalse(purpose.localizedCaseInsensitiveContains(stockPhrase),
                           "the purpose string opens with »\(stockPhrase)« and explains nothing")
        }
    }

    // MARK: - Screenshots

    func testEveryScreenshotHasThePromisedSizeAndNoAlpha() throws {
        for locale in locales {
            let folder = appStore.appendingPathComponent("screenshots/\(locale)/\(screenshotFormat)")
            let files = try FileManager.default
                .contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "jpg" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            XCTAssertFalse(files.isEmpty, "\(locale): no screenshots")

            for file in files {
                guard let rep = NSImageRep(contentsOf: file) else {
                    XCTFail("\(file.lastPathComponent) could not be read")
                    continue
                }
                XCTAssertEqual(NSSize(width: rep.pixelsWide, height: rep.pixelsHigh),
                               screenshotSize,
                               "\(file.lastPathComponent): \(rep.pixelsWide)×\(rep.pixelsHigh)")
                // App Store Connect rejects images carrying an alpha channel.
                XCTAssertFalse(rep.hasAlpha, "\(file.lastPathComponent) has an alpha channel")
            }
        }
    }

    func testEveryShotHasItsOwnRawCaptureAndText() throws {
        struct Card: Decodable { let rect: [CGFloat] }
        struct Shot: Decodable { let file: String; let theme: String; let layout: String; let card: Card? }
        struct Copy: Decodable { let headline: String; let subline: String }
        struct Configuration: Decodable { let shots: [Shot]; let texts: [String: [String: Copy]] }

        let data = try Data(contentsOf: appStore.appendingPathComponent("tools/shots.json"))
        let config = try JSONDecoder().decode(Configuration.self, from: data)

        XCTAssertFalse(config.shots.isEmpty, "shots.json names no shot")
        let knownLayouts: Set = ["hero", "text-top", "frame-top", "highlight"]
        let knownThemes: Set = ["light", "dark"]

        for shot in config.shots {
            XCTAssertTrue(knownLayouts.contains(shot.layout),
                          "\(shot.file): compose.swift knows no layout »\(shot.layout)«")
            XCTAssertTrue(knownThemes.contains(shot.theme),
                          "\(shot.file): unknown theme »\(shot.theme)«")
            if shot.layout == "highlight" {
                XCTAssertNotNil(shot.card, "\(shot.file): layout highlight without »card«")
                XCTAssertEqual(shot.card?.rect.count, 4, "\(shot.file): »rect« needs four values")
            }
            // A missing raw capture must not fall back to another language silently — that
            // would put English pictures into a translated store.
            for (language, copy) in config.texts {
                let raw = appStore
                    .appendingPathComponent("screenshots/raw/\(language)/\(shot.file).png")
                XCTAssertTrue(FileManager.default.fileExists(atPath: raw.path),
                              "raw capture missing: \(language)/\(shot.file).png")
                XCTAssertNotNil(copy[shot.file],
                                "shots.json: no text for \(shot.file) in \(language)")
            }
        }
    }

    /// Two identical raw captures are not a theoretical case: it happened while building
    /// Mika+Grid's package, and again at Mika+FileScope. Here the risk is the same — the
    /// four overlay shots are all full-screen captures of the same demo canvas, so a step
    /// that quietly did nothing leaves two files that differ in nothing at all.
    func testNoTwoShotsShareACapture() throws {
        let folder = appStore.appendingPathComponent("screenshots/raw/en")
        let files = try FileManager.default
            .contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "png" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var seen: [Data: String] = [:]
        for file in files {
            let bytes = try Data(contentsOf: file)
            if let other = seen[bytes] {
                XCTFail("\(file.lastPathComponent) is byte-identical to \(other)")
            }
            seen[bytes] = file.lastPathComponent
        }
    }

    // MARK: - What the questionnaires promise

    /// The age rating and the privacy entry both rest on "no network access". Adding a
    /// `URLSession` makes both of them quietly untrue.
    ///
    /// ABWEICHUNG from Mika+Grid, which excludes its direct-build target from this walk.
    /// Here there is one `Sources/` tree for both editions, so the walk covers all of it —
    /// recursively, because `Tools/`, `Onboarding/` and `Preferences/` are subfolders and a
    /// flat pass would miss most of the files.
    func testTheStoreEditionSourcesKnowNoNetworkAccess() throws {
        var checked = 0
        var sparkleImporters: [String] = []
        let root = Self.projectRoot.appendingPathComponent("Sources")
        guard let walk = FileManager.default.enumerator(at: root,
                                                        includingPropertiesForKeys: nil) else {
            XCTFail("Sources/ could not be walked")
            return
        }
        for case let file as URL in walk where file.pathExtension == "swift" {
            checked += 1
            let content = try String(contentsOf: file, encoding: .utf8)
            for forbidden in ["URLSession", "WKWebView", "NSURLConnection"] {
                XCTAssertFalse(content.contains(forbidden), """
                    \(file.lastPathComponent) names \(forbidden). AppStore/ALTERSFREIGABEN.md \
                    and the privacy entry both say the store edition makes no connections — \
                    check both.
                    """)
            }
            if content.contains("import Sparkle") { sparkleImporters.append(file.lastPathComponent) }
        }
        // An empty walk would be a green test that says nothing.
        XCTAssertGreaterThan(checked, 30, "only \(checked) files walked — are the paths still right?")

        // Sparkle is the one dependency that could open a connection, and the store edition
        // must not compile it in. `Package.swift` drops it when MIKA_APPSTORE is set; this
        // checks the other half — that no call site survives the flag.
        XCTAssertEqual(sparkleImporters, ["SparkleUpdater.swift"],
                       "Sparkle is imported outside SparkleUpdater.swift: \(sparkleImporters)")
        let updater = try source("Sources/SparkleUpdater.swift")
        guard let guardStart = updater.range(of: "#if !APPSTORE"),
              let importLine = updater.range(of: "import Sparkle") else {
            XCTFail("SparkleUpdater.swift is no longer wrapped in #if !APPSTORE")
            return
        }
        XCTAssertLessThan(guardStart.lowerBound, importLine.lowerBound,
                          "the Sparkle import sits outside the #if !APPSTORE guard")
        XCTAssertTrue(updater.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("#endif"),
                      "the #if !APPSTORE guard does not reach the end of the file")
    }

    func testTheAgeRatingAgreesAcrossBothDocuments() throws {
        let ratings = try String(
            contentsOf: appStore.appendingPathComponent("ALTERSFREIGABEN.md"), encoding: .utf8)
        let basics = try String(
            contentsOf: appStore.appendingPathComponent("APP_STORE_CONNECT.md"), encoding: .utf8)

        XCTAssertTrue(ratings.contains("**Ergebnis: 4+**"), "ALTERSFREIGABEN.md names no result")
        XCTAssertTrue(basics.contains("4+"), "APP_STORE_CONNECT.md names no age rating")
        // Both files are kept by hand; a contradiction would otherwise surface in the form.
        for step in ["9+", "13+", "16+", "18+"] {
            XCTAssertFalse(basics.contains("Altersfreigabe | \(step)"),
                           "APP_STORE_CONNECT.md says \(step), ALTERSFREIGABEN.md says 4+")
        }
    }

    /// If the category in App Store Connect differs from `LSApplicationCategoryType`, the
    /// upload bounces with error 90242. Nobody here can read what stands in ASC — but the
    /// documentation has to name the same value as the bundle.
    func testTheBundleCategoryIsDocumented() throws {
        let plist = try source(infoPlistPath)
        let category = try plistValue("LSApplicationCategoryType", in: plist)
        XCTAssertFalse(category.isEmpty,
                       "LSApplicationCategoryType is missing — the upload bounces with 90242")
        let basics = try String(
            contentsOf: appStore.appendingPathComponent("APP_STORE_CONNECT.md"), encoding: .utf8)
        XCTAssertTrue(basics.contains(category),
                      "APP_STORE_CONNECT.md does not name »\(category)« — error 90242 on upload")
    }

    // MARK: - Tool

    private func plistValue(_ key: String, in plist: String) throws -> String {
        guard let keyRange = plist.range(of: "<key>\(key)</key>"),
              let start = plist.range(of: "<string>", range: keyRange.upperBound..<plist.endIndex),
              let end = plist.range(of: "</string>", range: start.upperBound..<plist.endIndex)
        else {
            XCTFail("\(key) is missing from the plist")
            return ""
        }
        return String(plist[start.upperBound..<end.lowerBound])
    }
}
