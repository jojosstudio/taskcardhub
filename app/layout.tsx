import { ClerkProvider } from "@clerk/nextjs";
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Taskcard Hub",
  description: "Die zentrale Taskcard-Datenbank für eure Schule",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const publishableKey = process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY;
  return (
    <html lang="de">
      <body>{publishableKey ? <ClerkProvider publishableKey={publishableKey}>{children}</ClerkProvider> : children}</body>
    </html>
  );
}
