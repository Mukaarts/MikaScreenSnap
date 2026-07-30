import type { Metadata } from "next";
import Link from "next/link";
import { Nav } from "@/components/Nav";
import { Footer } from "@/components/Footer";
import { product } from "@/lib/content";

export const metadata: Metadata = {
  title: `Privacy — ${product.name}`,
  description:
    "Mika+ScreenSnap collects nothing. Screenshots stay on your Mac and the app has no backend.",
};

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mt-10">
      <h2 className="text-xl font-semibold tracking-tight">{title}</h2>
      <div className="mt-3 space-y-3 text-[15px] leading-relaxed text-muted">
        {children}
      </div>
    </section>
  );
}

export default function Privacy() {
  return (
    <>
      <Nav />
      <main className="flex-1">
        <div className="mx-auto max-w-2xl px-5 py-16 sm:px-8 sm:py-24">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-teal">
            Privacy
          </p>
          <h1 className="mt-4 text-4xl font-bold tracking-tight">
            What the app knows about you
          </h1>
          <p className="mt-4 text-lg leading-relaxed text-muted">
            Nothing. {product.name} has no account system, no analytics and no
            backend to send anything to. This page explains exactly what that
            means.
          </p>

          <Section title="Your screenshots">
            <p>
              Captures are held in memory while you edit them and written to a
              folder you choose on your own Mac. Nothing is uploaded, and the
              app has no code that would be able to do so — you can verify this
              in the{" "}
              <a
                href={product.repo}
                className="text-teal-light underline underline-offset-4 hover:text-teal-lightest"
              >
                source
              </a>
              .
            </p>
            <p>
              Text recognised through OCR and colours sampled with the picker
              are processed on-device using Apple&apos;s Vision framework and
              placed on your clipboard. They are never transmitted.
            </p>
          </Section>

          <Section title="Analytics">
            <p>
              There are none. No usage statistics, no crash reporting, no
              identifiers, no cookies inside the app.
            </p>
          </Section>

          <Section title="The one network connection">
            <p>
              To check for updates, the app asks GitHub for a small release feed
              at{" "}
              <code className="rounded bg-surface px-1.5 py-0.5 font-mono text-[13px] text-teal-lightest">
                raw.githubusercontent.com
              </code>
              . That request tells GitHub your IP address and the app version,
              in the same way visiting any web page would. Sparkle&apos;s
              optional system profiling is not enabled, so no hardware or usage
              details are attached. Downloading an update fetches a file from
              GitHub Releases.
            </p>
          </Section>

          <Section title="Permissions the app asks for">
            <p>
              Only Screen &amp; System Audio Recording, which macOS requires
              before any app may read the contents of your display. It is used
              solely to take the screenshot you asked for.
            </p>
          </Section>

          <Section title="This website">
            <p>
              The site is a set of static pages hosted on Vercel. It sets no
              cookies and runs no analytics or tracking scripts. Vercel records
              standard server request logs, which include IP addresses, as part
              of operating the hosting service.
            </p>
          </Section>

          <Section title="Changes">
            <p>
              If any of this ever changes, it will change here first, and the
              commit history of the repository will show exactly when and why.
            </p>
          </Section>

          <p className="mt-12 border-t border-line/70 pt-6 text-sm text-faint">
            Questions? Open an issue on{" "}
            <a
              href={product.repo}
              className="text-teal-light underline underline-offset-4 hover:text-teal-lightest"
            >
              GitHub
            </a>{" "}
            or head{" "}
            <Link
              href="/"
              className="text-teal-light underline underline-offset-4 hover:text-teal-lightest"
            >
              back to the overview
            </Link>
            .
          </p>
        </div>
      </main>
      <Footer />
    </>
  );
}
