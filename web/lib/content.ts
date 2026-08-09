/**
 * Single source of truth for the marketing site.
 *
 * Everything here is taken from the repository — README.md, CHANGELOG.md and
 * Resources/Info.plist. When a new version ships, this file is the only one
 * that needs editing.
 */

const version = "3.4.1";
const repo = "https://github.com/daumedia/MikaScreenSnap";

export const product = {
  name: "Mika+ScreenSnap",
  tagline: "Screenshots, annotated before you even switch windows.",
  description:
    "A lightweight macOS menu bar screenshot tool with a real annotation editor, OCR, a colour picker and pixel measurement — all one keystroke away.",
  version,
  minimumOS: "macOS 14.0 (Sonoma)",
  // The shipped binary is arm64-only (verified with `lipo -info`), so the site
  // must not promise Intel support.
  architecture: "Apple silicon",
  license: "MIT",
  repo,
  releases: `${repo}/releases`,
  // Derived from version so a release only needs the constant above changed.
  download: `${repo}/releases/download/v${version}/Mika%2BScreenSnap-v${version}.dmg`,
  saveFolder: "~/Pictures/MikaScreenSnap/",
} as const;

export type Feature = {
  title: string;
  body: string;
  icon: IconName;
};

export type IconName =
  | "capture"
  | "pen"
  | "text"
  | "droplet"
  | "ruler"
  | "pin"
  | "clock"
  | "sliders";

export const features: Feature[] = [
  {
    title: "Three capture modes",
    body: "Full screen, a dragged region, or a single window — each on its own global shortcut, straight from the menu bar. Point at the window you want, or take the frontmost one outright.",
    icon: "capture",
  },
  {
    title: "Eleven annotation tools",
    body: "Arrow, rectangle, ellipse, line, freehand, text, highlight, blur, pixelate, selection and a ruler. Hold Shift to snap to 45°, squares and circles.",
    icon: "pen",
  },
  {
    title: "Text extraction",
    body: "Drag over any region and the recognised text lands on your clipboard. Handles English, German and French.",
    icon: "text",
  },
  {
    title: "Colour picker",
    body: "A magnifying loupe follows the cursor at 8× zoom. Click to copy, Shift-click to keep it in a palette, with a history of the last ten.",
    icon: "droplet",
  },
  {
    title: "Pixel measurement",
    body: "A full-screen ruler with guide lines and point-to-point or rectangle modes. Also available inside the editor — and never exported.",
    icon: "ruler",
  },
  {
    title: "Pinned screenshots",
    body: "Float any capture above every other window. Scroll to fade it, Shift-drag to resize. Pins survive a restart.",
    icon: "pin",
  },
  {
    title: "Auto-save and history",
    body: "Captures are filed away automatically. A searchable thumbnail browser is one shortcut away.",
    icon: "clock",
  },
  {
    title: "Yours to configure",
    body: "Rebind every shortcut with conflict detection, set annotation defaults, choose the output folder and format, and launch at login.",
    icon: "sliders",
  },
];

export const globalShortcuts: Array<[string, string]> = [
  ["⌃⇧⌘4", "Capture a region"],
  ["⌃⇧⌘3", "Capture the full screen"],
  ["⌃⇧⌘5", "Capture the frontmost window"],
  ["⇧⌘6", "Extract text (OCR)"],
  ["⇧⌘7", "Pick a colour"],
  ["⇧⌘8", "Measure"],
  ["⇧⌘H", "Screenshot history"],
];

export const editorShortcuts: Array<[string, string]> = [
  ["V", "Select"],
  ["A", "Arrow"],
  ["R", "Rectangle"],
  ["E", "Ellipse"],
  ["L", "Line"],
  ["F", "Freehand"],
  ["T", "Text"],
  ["H", "Highlight"],
  ["B", "Blur"],
  ["X", "Pixelate"],
  ["M", "Measure"],
  ["⌘Z", "Undo"],
  ["⌘C", "Copy & close"],
  ["⌘S", "Save & close"],
];

export type Faq = { question: string; answer: string };

export const faqs: Faq[] = [
  {
    question: "What does it cost?",
    answer:
      "Nothing. Mika+ScreenSnap is free and open source under the MIT licence. There is no account, no subscription and no telemetry.",
  },
  {
    question: "Why does macOS warn me when I open it?",
    answer:
      "The app is not yet notarised by Apple, so Gatekeeper blocks it on first launch. Right-click the app in Applications and choose Open, then confirm — or allow it under System Settings › Privacy & Security. macOS remembers your choice.",
  },
  {
    question: "Why does it need screen recording permission?",
    answer:
      "Taking a screenshot means reading the contents of your screen, which macOS gates behind the Screen & System Audio Recording permission. It is the only permission the app asks for.",
  },
  {
    question: "Where do my screenshots go?",
    answer:
      "They stay on your Mac. Captures are auto-saved to a folder you choose (Pictures by default) and nothing is ever uploaded — the app has no backend.",
  },
  {
    question: "How do updates work?",
    answer:
      "The app checks a release feed hosted on GitHub using Sparkle and can install updates in place. You can also just download the latest DMG from the releases page.",
  },
  {
    question: "Does it show up in the Dock?",
    answer:
      "No. It lives in the menu bar and stays out of the Dock and the app switcher, so it never interrupts what you are doing.",
  },
];
