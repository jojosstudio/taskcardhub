import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { isAdmin, requireUser } from "@/lib/auth";

export async function DELETE(_: Request, { params }: { params: Promise<{ id: string }> }) {
  const userId = await requireUser();
  if (!(await isAdmin(userId))) return NextResponse.json({ error: "Adminrechte erforderlich." }, { status: 403 });
  const { id } = await params;
  await prisma.taskcard.delete({ where: { id } });
  return new NextResponse(null, { status: 204 });
}

export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const userId = await requireUser();
  if (!(await isAdmin(userId))) return NextResponse.json({ error: "Adminrechte erforderlich." }, { status: 403 });
  const { id } = await params;
  const body = await request.json() as { confirmed?: boolean };
  const card = await prisma.taskcard.update({ where: { id }, data: { confirmed: body.confirmed === true }, include: { teachers: true } });
  return NextResponse.json(card);
}
