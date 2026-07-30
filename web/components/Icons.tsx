import type { IconName } from "@/lib/content";

type Props = { name: IconName; className?: string };

/**
 * Small stroke icon set drawn inline — keeps the page free of an icon
 * dependency and lets every glyph inherit the current text colour.
 */
export function Icon({ name, className = "size-5" }: Props) {
  const common = {
    className,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: 1.6,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
    "aria-hidden": true,
  };

  switch (name) {
    case "capture":
      return (
        <svg {...common}>
          <path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2" />
          <circle cx="12" cy="12" r="3" />
        </svg>
      );
    case "pen":
      return (
        <svg {...common}>
          <path d="M12 19l7-7a2.5 2.5 0 0 0-3.5-3.5l-7 7L7 20z" />
          <path d="M4 20h3" />
        </svg>
      );
    case "text":
      return (
        <svg {...common}>
          <path d="M4 7V5h16v2M9 19h6M12 5v14" />
        </svg>
      );
    case "droplet":
      return (
        <svg {...common}>
          <path d="M12 3s6 6.2 6 10a6 6 0 0 1-12 0c0-3.8 6-10 6-10z" />
        </svg>
      );
    case "ruler":
      return (
        <svg {...common}>
          <path d="M3 15.5 15.5 3 21 8.5 8.5 21z" />
          <path d="M7 11.5l2 2M10.5 8l2 2M14 4.5l2 2" />
        </svg>
      );
    case "pin":
      return (
        <svg {...common}>
          <path d="M12 17v5" />
          <path d="M9 3h6l-1 6 3 3v2H7v-2l3-3z" />
        </svg>
      );
    case "clock":
      return (
        <svg {...common}>
          <circle cx="12" cy="12" r="8.5" />
          <path d="M12 7.5V12l3 2" />
        </svg>
      );
    case "sliders":
      return (
        <svg {...common}>
          <path d="M4 7h10M18 7h2M4 17h4M12 17h8" />
          <circle cx="16" cy="7" r="2" />
          <circle cx="10" cy="17" r="2" />
        </svg>
      );
  }
}

export function AppleIcon({ className = "size-5" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M16.4 12.7c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.15-2.8.85-3.5.85-.7 0-1.85-.83-3.05-.81-1.55.02-3 .9-3.8 2.3-1.63 2.82-.42 7 1.16 9.3.78 1.12 1.7 2.38 2.9 2.34 1.17-.05 1.61-.76 3.02-.76 1.4 0 1.8.76 3.03.73 1.25-.02 2.04-1.14 2.8-2.27.88-1.3 1.25-2.57 1.27-2.63-.03-.01-2.43-.93-2.45-3.7zM14.1 5.6c.64-.78 1.07-1.85.95-2.93-.92.04-2.03.61-2.69 1.38-.59.69-1.11 1.79-.97 2.84 1.02.08 2.07-.52 2.71-1.29z" />
    </svg>
  );
}

export function DownloadIcon({ className = "size-5" }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
    >
      <path d="M12 3v12M7.5 10.5 12 15l4.5-4.5M4 19h16" />
    </svg>
  );
}

export function GithubIcon({ className = "size-5" }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 2C6.48 2 2 6.48 2 12c0 4.42 2.87 8.17 6.84 9.5.5.09.68-.22.68-.48v-1.7c-2.78.6-3.37-1.34-3.37-1.34-.45-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.9 1.53 2.34 1.09 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.56-1.11-4.56-4.94 0-1.09.39-1.98 1.03-2.68-.1-.25-.45-1.27.1-2.64 0 0 .84-.27 2.75 1.02a9.5 9.5 0 0 1 5 0c1.91-1.29 2.75-1.02 2.75-1.02.55 1.37.2 2.39.1 2.64.64.7 1.03 1.59 1.03 2.68 0 3.84-2.34 4.68-4.57 4.93.36.31.68.92.68 1.85v2.74c0 .27.18.58.69.48A10 10 0 0 0 22 12c0-5.52-4.48-10-10-10z" />
    </svg>
  );
}
