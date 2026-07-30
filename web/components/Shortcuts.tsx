import { editorShortcuts, globalShortcuts } from "@/lib/content";

function Key({ children }: { children: React.ReactNode }) {
  return (
    <kbd className="inline-block min-w-[2.5rem] rounded-md border border-line bg-surface px-2.5 py-1.5 text-center font-mono text-[13px] font-medium text-teal-lightest">
      {children}
    </kbd>
  );
}

export function Shortcuts() {
  return (
    <section
      id="shortcuts"
      className="border-t border-line/60 bg-ink-raised/40"
    >
      <div className="mx-auto max-w-6xl px-5 py-20 sm:px-8 sm:py-28">
        <div className="max-w-2xl">
          <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">
            Built for the keyboard
          </h2>
          <p className="mt-4 text-lg leading-relaxed text-muted">
            Seven global shortcuts reach every capture mode from anywhere in
            macOS. Inside the editor, each tool sits on a single letter. Every
            binding can be changed in Settings.
          </p>
        </div>

        <div className="mt-12 grid gap-10 lg:grid-cols-2 lg:gap-16">
          <div>
            <h3 className="text-sm font-semibold uppercase tracking-[0.16em] text-faint">
              Anywhere in macOS
            </h3>
            <ul className="mt-5 divide-y divide-line/70 border-y border-line/70">
              {globalShortcuts.map(([keys, action]) => (
                <li
                  key={keys}
                  className="flex items-center justify-between gap-6 py-3"
                >
                  <span className="text-[15px] text-muted">{action}</span>
                  <Key>{keys}</Key>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="text-sm font-semibold uppercase tracking-[0.16em] text-faint">
              In the editor
            </h3>
            <div className="mt-5 grid grid-cols-2 gap-x-6 gap-y-1 sm:grid-cols-3 lg:grid-cols-2">
              {editorShortcuts.map(([keys, action]) => (
                <div
                  key={keys}
                  className="flex items-center justify-between gap-3 border-b border-line/50 py-2.5"
                >
                  <span className="text-sm text-muted">{action}</span>
                  <Key>{keys}</Key>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
