import { ImageResponse } from "next/og";
import { product } from "@/lib/content";

export const alt = `${product.name} — macOS screenshots, annotated in place`;
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          background:
            "linear-gradient(150deg, #07070E 0%, #0E0E18 55%, #12271F 100%)",
          padding: "72px 80px",
          fontFamily: "sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div
            style={{
              width: 44,
              height: 44,
              borderRadius: 12,
              background: "#1D9E75",
              display: "flex",
            }}
          />
          <div style={{ fontSize: 28, color: "#9FE1CB", fontWeight: 600 }}>
            {product.name}
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column" }}>
          <div
            style={{
              fontSize: 76,
              lineHeight: 1.05,
              fontWeight: 700,
              color: "#E4EFEA",
              letterSpacing: -2,
              display: "flex",
              flexDirection: "column",
            }}
          >
            <span>Screenshots, annotated</span>
            <span style={{ color: "#5DCAA5" }}>before you switch windows</span>
          </div>
          <div
            style={{
              marginTop: 28,
              fontSize: 30,
              color: "#8FA09A",
              display: "flex",
            }}
          >
            Capture · Annotate · OCR · Colour picker · Measure
          </div>
        </div>

        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 20,
            fontSize: 24,
            color: "#63736D",
          }}
        >
          <span>{product.minimumOS}+</span>
          <span>·</span>
          <span>Free & open source</span>
          <span>·</span>
          <span>v{product.version}</span>
        </div>
      </div>
    ),
    size,
  );
}
