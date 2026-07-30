import Image from "next/image";
import Link from "next/link";
import { product } from "@/lib/content";
import { GithubIcon } from "./Icons";

export function Footer() {
  return (
    <footer className="mt-auto border-t border-line/60">
      <div className="mx-auto flex max-w-6xl flex-col gap-6 px-5 py-10 sm:flex-row sm:items-center sm:justify-between sm:px-8">
        <div className="flex items-center gap-3">
          <Image
            src="/appicon.png"
            alt=""
            width={32}
            height={32}
            className="size-8 rounded-lg"
          />
          <div>
            <p className="text-sm font-semibold tracking-tight">
              {product.name}
            </p>
            <p className="text-xs text-faint">
              Version {product.version} · {product.license} licence
            </p>
          </div>
        </div>

        <nav className="flex flex-wrap items-center gap-x-6 gap-y-2 text-sm text-muted">
          <a href={product.releases} className="transition hover:text-body">
            Releases
          </a>
          <Link href="/privacy" className="transition hover:text-body">
            Privacy
          </Link>
          <a
            href={product.repo}
            className="inline-flex items-center gap-2 transition hover:text-body"
          >
            <GithubIcon className="size-4" />
            GitHub
          </a>
        </nav>
      </div>
    </footer>
  );
}
