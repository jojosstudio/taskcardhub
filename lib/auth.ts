import { auth, currentUser } from "@clerk/nextjs/server";
import { ADMIN_EMAILS } from "@/config/admins";

export async function requireUser() {
  const { userId } = await auth();
  if (!userId) throw new Error("UNAUTHORIZED");
  return userId;
}

export async function isAdmin(userId: string) {
  const { sessionClaims } = await auth();
  const claimsMetadata = sessionClaims?.metadata as { role?: string; isAdmin?: boolean } | undefined;
  if (claimsMetadata?.role === "admin" || claimsMetadata?.isAdmin === true) return true;

  const user = await currentUser();
  if (!user || user.id !== userId) return false;
  const metadata = user.publicMetadata as { role?: string; isAdmin?: boolean };
  if (metadata.role === "admin" || metadata.isAdmin === true) return true;

  const primaryEmail = user.emailAddresses.find(
    (email) => email.id === user.primaryEmailAddressId,
  )?.emailAddress.toLowerCase();
  const adminEmails = (process.env.ADMIN_EMAILS ?? "")
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
  return Boolean(primaryEmail && (adminEmails.includes(primaryEmail) || ADMIN_EMAILS.includes(primaryEmail as typeof ADMIN_EMAILS[number])));
}
