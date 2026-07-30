import Image from "next/image";

type Props = {
  eyebrow: string;
  title: string;
  body: string;
  points: string[];
  image: { src: string; alt: string; width: number; height: number };
  reversed?: boolean;
  frameless?: boolean;
};

export function Showcase({
  eyebrow,
  title,
  body,
  points,
  image,
  reversed = false,
  frameless = false,
}: Props) {
  return (
    <section className="border-t border-line/60">
      <div className="mx-auto grid max-w-6xl items-center gap-12 px-5 py-20 sm:px-8 sm:py-24 lg:grid-cols-2 lg:gap-16">
        <div className={reversed ? "lg:order-2" : undefined}>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-teal">
            {eyebrow}
          </p>
          <h2 className="mt-4 text-3xl font-bold tracking-tight sm:text-4xl">
            {title}
          </h2>
          <p className="mt-4 text-lg leading-relaxed text-muted">{body}</p>
          <ul className="mt-7 space-y-3">
            {points.map((point) => (
              <li key={point} className="flex gap-3 text-[15px] text-body">
                <svg
                  className="mt-1 size-4 shrink-0 text-teal"
                  viewBox="0 0 16 16"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={2}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden
                >
                  <path d="M3 8.5 6.5 12 13 4.5" />
                </svg>
                <span className="text-muted">{point}</span>
              </li>
            ))}
          </ul>
        </div>

        <div
          className={`relative ${reversed ? "lg:order-1" : ""} ${
            frameless ? "flex justify-center" : ""
          }`}
        >
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0 opacity-60"
            style={{
              background:
                "radial-gradient(50% 50% at 50% 50%, rgba(29,158,117,0.16) 0%, rgba(29,158,117,0) 70%)",
            }}
          />
          <Image
            src={image.src}
            alt={image.alt}
            width={image.width}
            height={image.height}
            sizes="(max-width: 1024px) 100vw, 560px"
            className={`relative ${frameless ? "w-auto max-h-[420px]" : "w-full"}`}
          />
        </div>
      </div>
    </section>
  );
}
