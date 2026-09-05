#!/usr/bin/env bash
#
# capture.sh — Rohaufnahmen für die App-Store-Bildschirmfotos.
#
# Schreibt AppStore/screenshots/raw/en/NN_name.png. Aus denen macht
# `swift AppStore/tools/compose.swift` die fertigen 2880×1800-Bilder.
#
#     AppStore/tools/capture.sh --build   # Store-Fassung neu bauen, dann aufnehmen
#     AppStore/tools/capture.sh           # nur aufnehmen
#     AppStore/tools/capture.sh --direct  # Notnagel: aus der Direktfassung aufnehmen
#
# AUFGENOMMEN WIRD DIE STORE-FASSUNG, nicht die Direktfassung aus /Applications.
# Der Unterschied ist sichtbar: Das Menü der Direktfassung trägt „Check for
# Updates…", das der Store-Fassung nicht (`MikaScreenSnapApp.swift`, Abfrage auf
# `updateChannel.showsUpdateControls`). Ein Bild der Direktfassung zeigte im Store
# also einen Eintrag, den es dort nicht gibt. Fehlt das Store-Bundle, bricht dieses
# Skript ab, statt still auf die Direktfassung auszuweichen.
#
# `--direct` weicht bewusst darauf aus, wenn die Store-Fassung ihre Berechtigungen
# noch nicht hat. Es ist ein Notnagel und kein gleichwertiger Weg: Motiv 05 zeigt
# dann einen Menüeintrag, den die eingereichte Fassung nicht hat — Guideline 2.3
# (Accurate Metadata). Das Skript sagt das bei jedem Lauf, und
# AppStore/CHECKLISTE.md führt es als offenen Punkt vor der Einreichung.
#
# Aufgenommen wird nie der echte Schreibtisch, sondern die erzeugte Demo-Leinwand
# (`scripts/GenerateDemoCanvas.swift`), die als randloses Fenster über allem liegt.
# Der Verlaufsbrowser kommt bewusst nicht vor: Er zeigt echte Dateien.
#
# Vier der fünf Motive sind Vollbildaufnahmen, weil ihr Gegenstand ein Overlay ist
# und kein Fenster — die Bereichsauswahl, die Farblupe, das Menü. Nur der Editor
# ist ein Fenster und wird als solches aufgenommen.
#
# VORAUSSETZUNGEN, die sich nicht skripten lassen und deshalb geprüft werden:
#   * Bildschirmaufnahme und Bedienungshilfen für das aufrufende Terminal
#   * die Store-Fassung muss ihre Ersteinrichtung hinter sich haben: einmal
#     Bildschirmaufnahme erlaubt (TCC, eigener Eintrag — sie ist ein anderes
#     Binary als die Direktfassung) und einmal einen Speicherordner gewählt
#   * und sie muss VOR dieser Freigabe echt signiert sein. build-appstore.sh
#     signiert ad-hoc; TCC erkennt eine ad-hoc signierte App am CDHash, und der
#     ändert sich bei jedem Bau. Die Freigabe gilt dann der App von gestern, und
#     die neue steht als weiterer, gleichnamiger Eintrag daneben — nicht
#     unterscheidbar. Wie man das abstellt, steht in README.md unter
#     „Vor der Freigabe echt signieren"
#
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_DIR"

BAUEN=0
DIREKT=0
for arg in "$@"; do
  case "$arg" in
    --build)  BAUEN=1 ;;
    --direct) DIREKT=1 ;;
    *) echo "unbekannte Option: $arg" >&2; exit 1 ;;
  esac
done

if [ "$DIREKT" = "1" ]; then
  APP="/Applications/Mika+ScreenSnap.app"
else
  APP="$PROJECT_DIR/build-appstore/Mika+ScreenSnap.app"
fi
OUT="$PROJECT_DIR/AppStore/screenshots/raw/en"
CONTAINER="$HOME/Library/Containers/lu.daumedia.screensnap"
WORK="$(mktemp -d)"

DIRECT_WAS_RUNNING=0
if pgrep -f "/Applications/Mika\+ScreenSnap.app" >/dev/null 2>&1; then
  DIRECT_WAS_RUNNING=1
fi

aufraeumen() {
  pkill -f "$WORK/demostage" 2>/dev/null || true
  rm -rf "$WORK"
  # Die Direktfassung war vor dem Lauf da und gehört danach wieder da hin.
  if [ "$DIRECT_WAS_RUNNING" = "1" ] && ! pgrep -f "/Applications/Mika\+ScreenSnap.app" >/dev/null 2>&1; then
    open -a "/Applications/Mika+ScreenSnap.app" 2>/dev/null || true
  fi
}
trap aufraeumen EXIT

mkdir -p "$OUT"

# ------------------------------------------------------------------ bauen --
if [ "$BAUEN" = "1" ] && [ "$DIREKT" = "0" ]; then
  echo "==> Store-Fassung bauen"
  bash scripts/build-appstore.sh
fi

if [ ! -d "$APP" ]; then
  if [ "$DIREKT" = "1" ]; then
    echo "Die Direktfassung fehlt: $APP" >&2
  else
    cat >&2 <<'EOF'
Das Store-Bundle fehlt: build-appstore/Mika+ScreenSnap.app

    AppStore/tools/capture.sh --build

Die Direktfassung aus /Applications ist kein Ersatz — ihr Menü trägt einen
Eintrag „Check for Updates…", den die Store-Fassung nicht hat. Wer trotzdem
dorthin ausweichen muss: --direct.
EOF
  fi
  exit 1
fi

if [ "$DIREKT" = "1" ]; then
  cat >&2 <<'EOF'

  !!  --direct: aufgenommen wird die DIREKTFASSUNG.

      Motiv 05 zeigt dann den Menüeintrag „Check for Updates…", den die
      Store-Fassung nicht hat. Das Bild ist so nicht einreichbar — es
      verspricht eine Funktion, die der Store-Fassung fehlt (Guideline 2.3).
      Vor der Einreichung mit der Store-Fassung neu aufnehmen; der Punkt
      steht in AppStore/CHECKLISTE.md.

EOF
  sleep 2
fi

# ----------------------------------------------------------- Werkzeugbau --
echo "==> Hilfsprogramme übersetzen"
swiftc -O scripts/UIDriver.swift -o "$WORK/uidriver"
swiftc -O scripts/DemoStage.swift -o "$WORK/demostage"
UI="$WORK/uidriver"

echo "==> Demo-Leinwand erzeugen"
swift scripts/GenerateDemoCanvas.swift

# --------------------------------------------------------------- Neustart --
# Sauber starten, damit keine alten Overlay-Panels herumstehen. Beide Fassungen
# tragen dieselbe Kennung; es darf immer nur eine laufen, und `open` würde sonst
# die bereits laufende Direktfassung nur nach vorn holen.
echo "==> Store-Fassung starten"
osascript -e 'tell application id "lu.daumedia.screensnap" to quit' 2>/dev/null || true
sleep 1.5
# `Mika+ScreenSnap.app` als pkill-Muster trifft nichts: `+` ist im regulären
# Ausdruck ein Quantor, das Muster liest sich als »Mik« plus beliebig viele »a«.
pkill -f "Mika\+ScreenSnap\.app" 2>/dev/null || true
sleep 1.5
open "$APP"
sleep 3.5

LAEUFT="$(pgrep -lf "Mika\+ScreenSnap.app/Contents/MacOS" | head -1 || true)"
if [ "$DIREKT" = "1" ]; then
  case "$LAEUFT" in
    *Applications*) : ;;
    *) echo "Die Direktfassung läuft nicht: ${LAEUFT:-nichts}" >&2; exit 1 ;;
  esac
else
  case "$LAEUFT" in
    *build-appstore*) : ;;
    *)
      echo "Es läuft nicht die Store-Fassung, sondern: ${LAEUFT:-nichts}" >&2
      echo "Beide Fassungen tragen dieselbe Kennung — die Direktfassung muss vorher beendet sein." >&2
      exit 1 ;;
  esac
fi

# ------------------------------------------------- Ersteinrichtung prüfen --
# Nur die Store-Fassung hat einen Sandbox-Container und kann in der Einrichtung
# hängen; die Direktfassung läuft seit jeher eingerichtet.
if [ "$DIREKT" = "0" ]; then
  # Gefragt wird die Anwendung selbst, nicht ihre Einstellungsdatei. `MikaScreenSnapApp`
  # zeigt die Ersteinrichtung, sobald `hasCompletedOnboarding` fehlt **oder**
  # `CGPreflightScreenCaptureAccess()` falsch ist — der Merker allein sagt also nichts.
  # Steht das Einrichtungsfenster, ist die Fassung nicht aufnahmebereit.
  if "$UI" list "Mika+ScreenSnap" | grep -q "layer=0"; then
    cat >&2 <<'EOF'

  Die Store-Fassung ist nicht aufnahmebereit — sie zeigt ihr Einrichtungsfenster.

  Sie läuft gerade. Zwei Schritte lassen sich nicht skripten, weil macOS
  synthetische Eingaben auf den Berechtigungsdialogen nicht zulässt:

    1. Bildschirmaufnahme erlauben. Systemeinstellungen › Datenschutz &
       Sicherheit › Bildschirm- & Systemtonaufnahme.

       ACHTUNG, hier liegt eine Falle: Dort steht **ein** Eintrag namens
       „Mika+ScreenSnap", und der gehört der Direktfassung aus /Applications.
       Beide Fassungen tragen dieselbe Bundle-Kennung; solange die Direktfassung
       installiert ist, bekam die Store-Fassung in einem Versuch am 2026-09-05
       keinen eigenen Eintrag — auch nicht, nachdem „Grant Access" im
       Einrichtungsfenster `CGRequestScreenCaptureAccess()` ausgelöst hatte.
       Den vorhandenen Schalter umzulegen hilft der Store-Fassung nicht: Sie
       zeigt danach weiter ihr Einrichtungsfenster.

       Was in diesem Versuch NICHT geholfen hat: die Fassung echt zu signieren,
       `tccutil reset ScreenCapture lu.daumedia.screensnap`, und die
       Direktfassung vorübergehend aus /Applications wegzuschieben. Wer das
       löst, trägt den Weg hier ein.
    2. Im Einrichtungsfenster einen Ordner für die Bildschirmfotos wählen. Die
       Sandbox kennt keinen Weg nach ~/Pictures, den die Anwendung selbst nehmen
       dürfte.

  Danach dieses Skript erneut aufrufen.

EOF
    # Nicht aufräumen: Die Store-Fassung soll für die Einrichtung stehen bleiben.
    DIRECT_WAS_RUNNING=0
    exit 2
  fi

  # Ein gewählter Ordner ist Voraussetzung des Speicherwegs und damit jeder Aufnahme.
  PREFS="$CONTAINER/Data/Library/Preferences/lu.daumedia.screensnap"
  if ! defaults read "$PREFS" saveLocationBookmark >/dev/null 2>&1; then
    echo "Die Store-Fassung hat noch keinen Speicherordner — Ersteinrichtung abschließen." >&2
    DIRECT_WAS_RUNNING=0
    exit 2
  fi
fi

# Die Vollbildmotive nehmen Display 1 auf. Läuft die Anwendung auf einem anderen
# Bildschirm, zeigte die Aufnahme eine leere Kulisse; die Bühne liegt ebenfalls auf
# dem Hauptbildschirm (DemoStage wählt den bei (0,0)).
buehne_auf() {
  "$WORK/demostage" installer/demo-canvas.png &
  sleep 2
}
buehne_zu() {
  pkill -f "$WORK/demostage" 2>/dev/null || true
  sleep 1
}

# Die Bedienungshilfen zeichnen nach einem Klick über synthetische Ereignisse
# einen grünen Ring an die Mausposition. Er steht sonst auf der Aufnahme.
ring_weg() {
  "$UI" move 1900 1060 >/dev/null 2>&1 || true
  sleep 0.8
}

# Wartet, bis ein Fenster auftaucht — statt fest zu schlafen.
#
# Feste Pausen haben hier nicht getragen: Auf einer belegten Maschine liegen
# zwischen einem synthetischen Ereignis und der Reaktion der Anwendung schon mal
# zehn Sekunden. Mit `sleep 3` entstanden dabei fünf Bilder der nackten Kulisse,
# und der Fehler sah aus wie ein Fehler der Anwendung.
#
#   warte_auf "<Titelteil>" [Sekunden]   → 0 wenn da, 1 wenn nicht
warte_auf() {
  local muster="$1" grenze="${2:-25}" i=0
  while [ "$i" -lt "$grenze" ]; do
    if "$UI" list "Mika+ScreenSnap" | awk -F'\t' -v m="$muster" '$5 ~ m {found=1} END {exit !found}'; then
      sleep 1   # einmal durchatmen, damit das Fenster fertig gezeichnet ist
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  return 1
}

# ============================================================ 01_annotate ==
# Aufgenommen wird über die VOLLBILD-Aufnahme, nicht über die Bereichsauswahl.
# Die Bereichsauswahl braucht ein vollständiges Ziehen samt Loslassen; genau das
# kam auf dieser Maschine nur mit Verzögerung an, und ein zu kleines Rechteck
# lässt `AreaSelectionView.mouseUp` die Auswahl stumm verwerfen, ohne die Panels
# zu schließen. Die Vollbildaufnahme braucht kein Ziehen und liefert dasselbe
# Bild: die ganze Kulisse im Editor.
echo "==> 01_annotate — Editor mit Verpixeln, Hervorheben und Pfeil"
buehne_auf
"$UI" key ctrl+shift+cmd+3
if ! warte_auf "Annotate" 30; then
  echo "    ! Editorfenster kam nicht — 01_annotate und 05_pin übersprungen" >&2
  buehne_zu
else
  # Die Bühne liegt auf .floating und damit über dem Editorfenster; sie muss weg,
  # bevor der Editor Zeichenereignisse bekommen kann.
  buehne_zu
  RAHMEN=$("$UI" list "Mika+ScreenSnap" | awk -F'\t' '$5 ~ /Annotate/ {print $2; exit}')
  EX=$(echo "$RAHMEN" | cut -d, -f1); EY=$(echo "$RAHMEN" | cut -d, -f2)
  EW=$(echo "$RAHMEN" | cut -d, -f3); EH=$(echo "$RAHMEN" | cut -d, -f4)
  # Erst aktiv machen, dann zeichnen — der erste Klick geht sonst ins Fenster
  # statt in die Leinwand.
  "$UI" click $((EX + EW / 2)) $((EY + 40)); sleep 2

  # Anteile der Leinwand, damit die Züge unabhängig von der Fenstergröße sitzen.
  zug() { # zug <werkzeug> <x1%> <y1%> <x2%> <y2%>
    "$UI" key "$1"; sleep 1
    "$UI" drag $((EX + EW * $2 / 100)) $((EY + EH * $3 / 100)) \
               $((EX + EW * $4 / 100)) $((EY + EH * $5 / 100))
    sleep 3
  }
  zug x 12 52 48 60     # Zugangsdaten verpixeln
  zug h 12 44 38 47     # eine Zeile Fließtext hervorheben
  zug a 70 66 78 60     # Pfeil auf die Kennzahl

  ring_weg
  "$UI" shot "Mika+ScreenSnap" "$OUT/01_annotate.png" 400 1000

  # ========================================================== 05_pin =======
  # Das Menüleistensymbol taugt hier nicht als Motiv: Es liegt bei vielen
  # Installationen hinter einem Menüleisten-Ausblender und ist dann nicht
  # anklickbar. Das angeheftete Bild ist der bessere Tausch — und der ehrlichere:
  # Es sieht in beiden Fassungen gleich aus, während das Menü der Direktfassung
  # einen Eintrag „Check for Updates…" trägt, den die Store-Fassung nicht hat.
  echo "==> 05_pin — angeheftetes Bild über der Kulisse"
  PINRAHMEN=$("$UI" list "Mika+ScreenSnap" | awk -F'\t' '$5 ~ /Annotate/ {print $2; exit}')
  PX=$(echo "$PINRAHMEN" | cut -d, -f1); PY=$(echo "$PINRAHMEN" | cut -d, -f2)
  PW=$(echo "$PINRAHMEN" | cut -d, -f3); PH=$(echo "$PINRAHMEN" | cut -d, -f4)
  # „Pin" sitzt in der Fußleiste des Editors, links von „Copy".
  "$UI" click $((PX + PW * 60 / 100)) $((PY + PH - 12)); sleep 4

  buehne_auf
  # Das angeheftete Bild und die Bühne liegen beide auf .floating; die Bühne kam
  # zuletzt nach vorn. Ein Klick auf das Bild holt es wieder darüber.
  PINNED=$("$UI" list "Mika+ScreenSnap" | awk -F'\t' '$3 == "layer=3" {print $2; exit}')
  if [ -n "$PINNED" ]; then
    QX=$(echo "$PINNED" | cut -d, -f1); QY=$(echo "$PINNED" | cut -d, -f2)
    QW=$(echo "$PINNED" | cut -d, -f3); QH=$(echo "$PINNED" | cut -d, -f4)
    "$UI" click $((QX + QW / 2)) $((QY + QH / 2)); sleep 2
    ring_weg
    "$UI" screen-shot "$OUT/05_pin.png" 1
  else
    echo "    ! kein angeheftetes Bild gefunden — 05_pin übersprungen" >&2
  fi
  buehne_zu
fi

# ============================================================ 02_select ====
echo "==> 02_select — Bereichsauswahl im Ziehen"
buehne_auf
"$UI" key ctrl+shift+cmd+4
sleep 3
"$UI" drag-shot 300 210 1420 800 "$OUT/02_select.png" 1
sleep 2
"$UI" key escape
sleep 2

# ============================================================ 03_ocr =======
echo "==> 03_ocr — erkannter Text"
"$UI" key shift+cmd+6
sleep 3
"$UI" drag 232 430 900 640
if warte_auf "Extracted Text" 30; then
  ring_weg
  "$UI" screen-shot "$OUT/03_ocr.png" 1
  "$UI" key escape; sleep 1
else
  echo "    ! Textfenster kam nicht — 03_ocr übersprungen" >&2
  "$UI" key escape; sleep 1
fi

# ============================================================ 04_colour ====
# Braucht kein Ziehen: Die Lupe folgt dem Zeiger, ein Klick würde die Farbe
# nehmen und die Lupe schließen.
echo "==> 04_colour — Farblupe"
"$UI" key shift+cmd+7
sleep 3
"$UI" move 760 520
sleep 3
"$UI" screen-shot "$OUT/04_colour.png" 1
"$UI" key escape; sleep 1

buehne_zu

echo
echo "Rohaufnahmen in $OUT:"
ls -la "$OUT"
echo
echo "Jedes Bild ansehen, bevor komponiert wird. Danach:"
echo "    swift AppStore/tools/compose.swift"
