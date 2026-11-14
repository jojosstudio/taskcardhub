import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isPublicRoute = createRouteMatcher(["/", "/sign-in(.*)", "/sign-up(.*)", "/datenschutz", "/nutzungsbedingungen", "/manifest.webmanifest", "/icon.svg"]);

export default clerkMiddleware(async (auth, req) => {
  const isPublicRead = req.nextUrl.pathname === "/api/taskcards" && req.method === "GET";
  if (!isPublicRoute(req) && !isPublicRead) await auth.protect();
});

export const config = {
  matcher: ["/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|png|gif|svg|ico|webp)).*)", "/(api|trpc)(.*)"],
};
