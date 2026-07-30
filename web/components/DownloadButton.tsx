import { product } from "@/lib/content";
import { DownloadIcon } from "./Icons";

type Props = { className?: string; label?: string };

export function DownloadButton({ className = "", label }: Props) {
  return (
    <a
      href={product.download}
      className={`group inline-flex items-center gap-2.5 rounded-full bg-teal px-6 py-3.5 text-[15px] font-semibold text-[#04120C] transition hover:bg-teal-light ${className}`}
    >
      <DownloadIcon className="size-[18px] transition-transform group-hover:translate-y-0.5" />
      {label ?? `Download for macOS`}
    </a>
  );
}

export function SecondaryLink({
  href,
  children,
  className = "",
}: {
  href: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <a
      href={href}
      className={`inline-flex items-center gap-2 rounded-full border border-line px-5 py-3.5 text-[15px] font-medium text-body transition hover:border-teal/50 hover:text-teal-lightest ${className}`}
    >
      {children}
    </a>
  );
}
