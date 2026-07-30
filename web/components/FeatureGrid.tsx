import { features } from "@/lib/content";
import { Icon } from "./Icons";

export function FeatureGrid() {
  return (
    <section id="features" className="mx-auto max-w-6xl px-5 py-20 sm:px-8 sm:py-28">
      <div className="max-w-2xl">
        <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Everything a screenshot needs, in one pass
        </h2>
        <p className="mt-4 text-lg leading-relaxed text-muted">
          The editor opens the moment you capture. Mark it up, pull the text out
          of it, sample a colour, then copy or save — all before the thought
          leaves your head.
        </p>
      </div>

      <ul className="mt-12 grid gap-px overflow-hidden rounded-2xl border border-line bg-line sm:grid-cols-2 lg:grid-cols-4">
        {features.map((feature) => (
          <li
            key={feature.title}
            className="group bg-ink-raised p-6 transition-colors hover:bg-surface"
          >
            <span className="inline-flex size-10 items-center justify-center rounded-xl bg-teal/12 text-teal-light transition group-hover:bg-teal/20">
              <Icon name={feature.icon} className="size-5" />
            </span>
            <h3 className="mt-4 text-[15px] font-semibold tracking-tight">
              {feature.title}
            </h3>
            <p className="mt-2 text-sm leading-relaxed text-muted">
              {feature.body}
            </p>
          </li>
        ))}
      </ul>
    </section>
  );
}
