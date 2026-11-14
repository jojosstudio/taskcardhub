import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { auth, clerkClient, currentUser } from "@clerk/nextjs/server";
import { isAdmin, requireUser } from "@/lib/auth";

export async function GET() {
  const { userId } = await auth();
  const cards = await prisma.taskcard.findMany({ include: { teachers: true }, orderBy: { createdAt: "desc" } });
  const legacyCreatorIds = [...new Set(cards
    .filter((card) => card.createdByName.includes("@") || card.createdByName === "Unbekannter Nutzer")
    .map((card) => card.createdBy))];
  const creatorNames = new Map<string, string>();
  if (legacyCreatorIds.length) {
    const client = await clerkClient();
    await Promise.all(legacyCreatorIds.map(async (creatorId) => {
      try {
        const creator = await client.users.getUser(creatorId);
        creatorNames.set(creatorId, creator.username || creator.fullName || creator.firstName || "Unbekannter Nutzer");
      } catch {
        creatorNames.set(creatorId, "Unbekannter Nutzer");
      }
    }));
  }
  const safeCards = cards.map((card) => ({
    ...card,
    createdByName: creatorNames.get(card.createdBy) ?? card.createdByName,
  }));
  return NextResponse.json({ cards: safeCards, canManage: userId ? await isAdmin(userId) : false });
}

export async function POST(request: Request) {
  const userId = await requireUser();
  const user = await currentUser();
  const body = await request.json() as { title?: string; subject?: string; grade?: string; course?: string; topic?: string; url?: string; description?: string; teachers?: string };
  if (!body.title || !body.subject || !body.grade || !body.course || !body.topic || !body.url || !body.teachers) return NextResponse.json({ error: "Pflichtfelder fehlen." }, { status: 400 });
  try { new URL(body.url); } catch { return NextResponse.json({ error: "Ungültige URL." }, { status: 400 }); }
  const teacherNames = body.teachers.split(",").map((name) => name.trim()).filter(Boolean);
  const createdByName = user?.username || user?.fullName || user?.firstName || "Unbekannter Nutzer";
  const card = await prisma.taskcard.create({ data: { title: body.title.trim(), subject: body.subject.trim(), grade: body.grade.trim(), course: body.course.trim(), topic: body.topic.trim(), url: body.url, description: body.description?.trim() || null, createdBy: userId, createdByName, teachers: { connectOrCreate: teacherNames.map((name) => ({ where: { name }, create: { name } })) } }, include: { teachers: true } });
  return NextResponse.json(card, { status: 201 });
}
