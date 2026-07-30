import Image from "next/image";
import { product } from "@/lib/content";
import { DownloadButton, SecondaryLink } from "./DownloadButton";
import { AppleIcon, GithubIcon } from "./Icons";

export function Hero() {
  return (
    <section className="relative overflow-hidden">
      {/* Soft brand glow behind the headline */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 -top-40 h-[520px] opacity-60"
        style={{
          background:
            "radial-gradient(60% 60% at 50% 40%, rgba(29,158,117,0.28) 0%, rgba(29,158,117,0) 70%)",
        }}
      />

      <div className="relative mx-auto max-w-6xl px-5 pt-16 pb-10 sm:px-8 sm:pt-24">
        <div className="mx-auto max-w-3xl text-center">
          <p className="inline-flex items-center gap-2 rounded-full border border-line bg-surface/60 px-3.5 py-1.5 text-xs font-medium text-teal-lightest">
            <AppleIcon className="size-3.5" />
            Version {product.version} · Free & open source
          </p>

          <h1 className="mt-6 text-balance text-4xl font-bold leading-[1.05] tracking-tight sm:text-6xl">
            Screenshots, annotated
            <br className="hidden sm:block" />{" "}
            <span className="text-teal-light">before you switch windows</span>
          </h1>

          <p className="mx-auto mt-6 max-w-xl text-pretty text-lg leading-relaxed text-muted">
            A menu bar companion for macOS that captures, marks up, reads text,
            picks colours and measures pixels — without ever taking over your
            screen.
          </p>

          <div className="mt-9 flex flex-wrap items-center justify-center gap-3">
            <DownloadButton />
            <SecondaryLink href={product.repo}>
              <GithubIcon className="size-[18px]" />
              Source on GitHub
            </SecondaryLink>
          </div>

          <p className="mt-5 text-sm text-faint">
            {product.minimumOS} or later · {product.architecture} ·{" "}
            {product.license} licence · No account, no telemetry
          </p>
        </div>

        {/* Product shot */}
        <div className="relative mt-14 sm:mt-20">
          <div
            aria-hidden
            className="pointer-events-none absolute -inset-x-10 -top-10 bottom-0 opacity-70"
            style={{
              background:
                "radial-gradient(50% 50% at 50% 45%, rgba(93,202,165,0.18) 0%, rgba(93,202,165,0) 70%)",
            }}
          />
          <Image
            src="/shots/editor.png"
            alt="The annotation editor with a blurred credentials panel, a highlighted line of text and an arrow pointing at a metric"
            width={3296}
            height={1538}
            priority
            sizes="(max-width: 1152px) 100vw, 1152px"
            className="relative w-full"
          />
        </div>
      </div>
    </section>
  );
}
