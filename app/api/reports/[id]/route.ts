import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { isAdmin, requireUser } from "@/lib/auth";

export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const userId = await requireUser();
  if (!(await isAdmin(userId))) return NextResponse.json({ error: "Adminrechte erforderlich." }, { status: 403 });
  const { id } = await params;
  const body = await request.json() as { status?: string; adminNote?: string };
  if (!["open", "in_review", "resolved", "dismissed"].includes(body.status ?? "")) return NextResponse.json({ error: "Ungültiger Status." }, { status: 400 });
  const report = await prisma.report.update({ where: { id }, data: { status: body.status, adminNote: body.adminNote?.trim() || null }, include: { taskcard: { select: { id: true, title: true, url: true } } } });
  return NextResponse.json(report);
}
