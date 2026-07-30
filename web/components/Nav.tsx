import Image from "next/image";
import Link from "next/link";
import { product } from "@/lib/content";
import { GithubIcon } from "./Icons";

export function Nav() {
  return (
    <header className="sticky top-0 z-50 border-b border-line/60 bg-ink/80 backdrop-blur-xl">
      <nav className="mx-auto flex h-16 max-w-6xl items-center justify-between px-5 sm:px-8">
        <Link href="/" className="flex items-center gap-2.5">
          <Image
            src="/appicon.png"
            alt=""
            width={28}
            height={28}
            className="size-7 rounded-md"
          />
          <span className="text-[15px] font-semibold tracking-tight">
            {product.name}
          </span>
        </Link>

        <div className="flex items-center gap-1 sm:gap-2">
          <a
            href="#features"
            className="hidden rounded-full px-3.5 py-2 text-sm text-muted transition hover:text-body sm:block"
          >
            Features
          </a>
          <a
            href="#shortcuts"
            className="hidden rounded-full px-3.5 py-2 text-sm text-muted transition hover:text-body sm:block"
          >
            Shortcuts
          </a>
          <a
            href="#install"
            className="hidden rounded-full px-3.5 py-2 text-sm text-muted transition hover:text-body sm:block"
          >
            Install
          </a>
          <a
            href={product.repo}
            className="rounded-full p-2 text-muted transition hover:text-body"
            aria-label="View the source on GitHub"
          >
            <GithubIcon className="size-5" />
          </a>
          <a
            href={product.download}
            className="ml-1 rounded-full bg-teal px-4 py-2 text-sm font-semibold text-[#04120C] transition hover:bg-teal-light"
          >
            Download
          </a>
        </div>
      </nav>
    </header>
  );
}
