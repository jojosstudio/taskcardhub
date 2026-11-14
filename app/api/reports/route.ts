import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { isAdmin, requireUser } from "@/lib/auth";

export async function GET() {
  const userId = await requireUser();
  if (!(await isAdmin(userId))) return NextResponse.json({ error: "Adminrechte erforderlich." }, { status: 403 });
  const reports = await prisma.report.findMany({ include: { taskcard: { select: { id: true, title: true, url: true } } }, orderBy: { createdAt: "desc" } });
  return NextResponse.json(reports);
}

export async function POST(request: Request) {
  const userId = await requireUser();
  const body = await request.json() as { taskcardId?: string; reason?: string; message?: string };
  if (!body.taskcardId || !body.reason || !body.message?.trim()) return NextResponse.json({ error: "Grund und Nachricht sind erforderlich." }, { status: 400 });
  const taskcard = await prisma.taskcard.findUnique({ where: { id: body.taskcardId }, select: { id: true } });
  if (!taskcard) return NextResponse.json({ error: "Taskcard nicht gefunden." }, { status: 404 });
  const report = await prisma.report.create({ data: { taskcardId: body.taskcardId, reporterId: userId, reason: body.reason, message: body.message.trim() } });
  return NextResponse.json(report, { status: 201 });
}
