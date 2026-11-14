import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Taskcard Hub",
    short_name: "Taskcard Hub",
    description: "Die unabhängige Taskcard-Sammlung",
    start_url: "/",
    display: "standalone",
    background_color: "#f7f8f5",
    theme_color: "#1f6b51",
    icons: [{ src: "/icon.svg", sizes: "any", type: "image/svg+xml", purpose: "any" }],
  };
}
