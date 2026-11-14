import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { isAdmin, requireUser } from "@/lib/auth";

export async function POST(request: Request) {
  const userId = await requireUser();
  const body = await request.json() as { type?: string; taskcardId?: string };
  if (!body.type || !["page_view", "taskcard_view", "taskcard_open"].includes(body.type)) {
    return NextResponse.json({ error: "Ungültiges Analytics-Event." }, { status: 400 });
  }
  await prisma.analyticsEvent.create({ data: { type: body.type, taskcardId: body.taskcardId, userId } });
  return new NextResponse(null, { status: 204 });
}

export async function GET() {
  const userId = await requireUser();
  if (!(await isAdmin(userId))) return NextResponse.json({ error: "Adminrechte erforderlich." }, { status: 403 });
  const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const [events, taskcards, reports, users, unconfirmed] = await Promise.all([
    prisma.analyticsEvent.findMany({ where: { createdAt: { gte: since } }, include: { taskcard: { select: { id: true, title: true, subject: true } } }, orderBy: { createdAt: "desc" } }),
    prisma.taskcard.count(),
    prisma.report.count({ where: { status: "open" } }),
    prisma.analyticsEvent.findMany({ where: { createdAt: { gte: since } }, distinct: ["userId"], select: { userId: true } }),
    prisma.taskcard.findMany({ where: { confirmed: false }, include: { teachers: true }, orderBy: { createdAt: "desc" } }),
  ]);
  const taskcardUsage = events.filter((event) => event.taskcardId && (event.type === "taskcard_view" || event.type === "taskcard_open")).reduce<Record<string, { id: string; title: string; subject: string; views: number; opens: number }>>((result, event) => {
    if (!event.taskcard) return result;
    const current = result[event.taskcard.id] ?? { ...event.taskcard, views: 0, opens: 0 };
    if (event.type === "taskcard_view") current.views += 1;
    if (event.type === "taskcard_open") current.opens += 1;
    result[event.taskcard.id] = current;
    return result;
  }, {});
  return NextResponse.json({
    totals: { taskcards, openReports: reports, activeUsers: users.length, pageViews: events.filter((event) => event.type === "page_view").length, linkOpens: events.filter((event) => event.type === "taskcard_open").length },
    taskcardUsage: Object.values(taskcardUsage).sort((a, b) => (b.views + b.opens) - (a.views + a.opens)).slice(0, 10),
    unconfirmed,
  });
}
