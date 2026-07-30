import { Nav } from "@/components/Nav";
import { Hero } from "@/components/Hero";
import { FeatureGrid } from "@/components/FeatureGrid";
import { Showcase } from "@/components/Showcase";
import { Shortcuts } from "@/components/Shortcuts";
import { Install } from "@/components/Install";
import { Faq } from "@/components/Faq";
import { Footer } from "@/components/Footer";
import { DownloadButton } from "@/components/DownloadButton";
import { product } from "@/lib/content";

export default function Home() {
  return (
    <>
      <Nav />
      <main className="flex-1">
        <Hero />
        <FeatureGrid />

        <Showcase
          eyebrow="Always within reach"
          title="Lives in the menu bar, never in your way"
          body="No Dock icon, no window stealing focus, no app switcher clutter. Mika+ScreenSnap sits in the menu bar and every capture mode is one click or one shortcut away."
          points={[
            "Capture a region, the full screen, or a single window",
            "Jump straight to text extraction, the colour picker or the ruler",
            "Reach pinned captures, your colour history and the screenshot browser",
            "Optionally starts with you at login",
          ]}
          image={{
            src: "/shots/menubar.png",
            alt: "The Mika+ScreenSnap menu bar dropdown listing every capture mode with its keyboard shortcut",
            width: 592,
            height: 824,
          }}
          frameless
        />

        <Showcase
          eyebrow="Yours to shape"
          title="Every shortcut and default, configurable"
          body="A four-tab settings window covers where files go, how captures behave, which tool and colour the editor starts with, and what each global shortcut is bound to — with conflict detection built in."
          points={[
            "Rebind all seven global shortcuts, or restore the defaults",
            "Choose the output folder and PNG or JPEG with a quality setting",
            "Set the editor's default tool, stroke colour and stroke width",
            "Manage stored screenshots and reset the app from one place",
          ]}
          image={{
            src: "/shots/preferences.png",
            alt: "The settings window showing the General tab with file output and capture behaviour options",
            width: 1504,
            height: 1248,
          }}
          reversed
        />

        <Shortcuts />
        <Install />
        <Faq />

        {/* Closing call to action */}
        <section className="border-t border-line/60">
          <div className="mx-auto max-w-6xl px-5 py-20 text-center sm:px-8 sm:py-28">
            <h2 className="text-balance text-3xl font-bold tracking-tight sm:text-4xl">
              Take a screenshot worth sending
            </h2>
            <p className="mx-auto mt-4 max-w-lg text-lg leading-relaxed text-muted">
              Free, open source, and under two megabytes to download. Nothing
              leaves your Mac.
            </p>
            <div className="mt-8 flex justify-center">
              <DownloadButton label={`Download ${product.version} for macOS`} />
            </div>
            <p className="mt-4 text-sm text-faint">
              {product.minimumOS} or later · {product.architecture}
            </p>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
