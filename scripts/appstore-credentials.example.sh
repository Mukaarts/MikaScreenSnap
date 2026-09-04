# Example credentials for the Mac App Store build. Copy to appstore-credentials.sh
# (git-ignored) and fill in — or better, export these in your shell profile and never
# create the file at all.
#
# NOTHING REAL BELONGS IN THIS REPOSITORY. `git log -p` finds what was deleted, and
# anything that was ever pushed counts as compromised: rotate it, do not remove it.
#
# The certificates themselves stay in the keychain and are never files here:
#   - "Apple Distribution: <name> (<TEAMID>)"        signs the .app
#   - "3rd Party Mac Developer Installer: <name>"    signs the .pkg
# Both are created in the Apple Developer account, downloaded once, and double-clicked
# into the keychain.

# Team the App Store record belongs to. Note that this project currently has two:
# 8C9HV4CHBN (Apple Development) and CWJM4J4HFN (Developer ID Application, used for the
# DMG). Which one owns the store listing has to be settled before the first upload.
export MIKA_TEAM_ID="XXXXXXXXXX"

# Signing identities, exactly as `security find-identity -v -p codesigning` prints them.
export MIKA_APP_IDENTITY="Apple Distribution: Your Name (XXXXXXXXXX)"
export MIKA_INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Your Name (XXXXXXXXXX)"

# App Store Connect API key for uploading, created at
# appstoreconnect.apple.com -> Users and Access -> Integrations.
# The .p8 file belongs OUTSIDE this folder — ~/.appstoreconnect/private_keys/ is where
# xcrun looks for it by default.
export MIKA_ASC_KEY_ID="XXXXXXXXXX"
export MIKA_ASC_ISSUER_ID="00000000-0000-0000-0000-000000000000"
