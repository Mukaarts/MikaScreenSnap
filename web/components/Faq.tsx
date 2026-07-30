import { faqs } from "@/lib/content";

export function Faq() {
  return (
    <section className="border-t border-line/60 bg-ink-raised/40">
      <div className="mx-auto max-w-3xl px-5 py-20 sm:px-8 sm:py-28">
        <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
          Questions, answered
        </h2>

        <div className="mt-10 divide-y divide-line/70 border-y border-line/70">
          {faqs.map((faq) => (
            <details key={faq.question} className="group py-1">
              <summary className="flex cursor-pointer list-none items-center justify-between gap-6 py-4 text-[15px] font-medium tracking-tight transition hover:text-teal-lightest">
                {faq.question}
                <svg
                  className="size-4 shrink-0 text-faint transition-transform duration-200 group-open:rotate-45"
                  viewBox="0 0 16 16"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={1.8}
                  strokeLinecap="round"
                  aria-hidden
                >
                  <path d="M8 3v10M3 8h10" />
                </svg>
              </summary>
              <p className="pb-5 pr-10 text-[15px] leading-relaxed text-muted">
                {faq.answer}
              </p>
            </details>
          ))}
        </div>
      </div>
    </section>
  );
}
