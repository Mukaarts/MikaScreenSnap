import { product } from "@/lib/content";
import { DownloadButton } from "./DownloadButton";

const steps = [
  {
    title: "Download and drag to Applications",
    body: "Open the DMG and drop Mika+ScreenSnap into your Applications folder.",
  },
  {
    title: "Open it the first time with a right-click",
    body: "The app is not notarised by Apple yet, so Gatekeeper stops the usual double-click. Right-click the app, choose Open, and confirm. If macOS still refuses, allow it under System Settings › Privacy & Security. You only do this once.",
    warn: true,
  },
  {
    title: "Grant screen recording, then pick your shortcuts",
    body: "macOS asks for the Screen & System Audio Recording permission — that is what lets any app read the screen. A short onboarding walks you through the rest.",
  },
];

export function Install() {
  return (
    <section id="install" className="border-t border-line/60">
      <div className="mx-auto max-w-6xl px-5 py-20 sm:px-8 sm:py-28">
        <div className="grid gap-12 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)] lg:gap-16">
          <div>
            <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
              Up and running in a minute
            </h2>
            <p className="mt-4 text-lg leading-relaxed text-muted">
              Version {product.version} ships as a plain DMG on GitHub. No
              installer, no account, no background services.
            </p>
            <div className="mt-8">
              <DownloadButton />
            </div>
            <p className="mt-4 text-sm text-faint">
              Prefer to build it yourself? The full source and build scripts are
              in the{" "}
              <a
                href={product.repo}
                className="text-teal-light underline underline-offset-4 hover:text-teal-lightest"
              >
                repository
              </a>
              .
            </p>
          </div>

          <ol className="space-y-4">
            {steps.map((step, index) => (
              <li
                key={step.title}
                className={`rounded-2xl border p-5 sm:p-6 ${
                  step.warn
                    ? "border-teal/25 bg-teal/[0.06]"
                    : "border-line bg-ink-raised"
                }`}
              >
                <div className="flex gap-4">
                  <span
                    className={`flex size-7 shrink-0 items-center justify-center rounded-full text-[13px] font-semibold ${
                      step.warn
                        ? "bg-teal text-[#04120C]"
                        : "bg-surface-hi text-teal-lightest"
                    }`}
                  >
                    {index + 1}
                  </span>
                  <div>
                    <h3 className="text-[15px] font-semibold tracking-tight">
                      {step.title}
                    </h3>
                    <p className="mt-1.5 text-sm leading-relaxed text-muted">
                      {step.body}
                    </p>
                  </div>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </div>
    </section>
  );
}
