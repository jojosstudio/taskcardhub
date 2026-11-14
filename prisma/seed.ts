import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();
async function main() {
  const teacher = await prisma.teacher.create({ data: { name: "Frau Müller" } });
  await prisma.taskcard.create({ data: { title: "Medienkompetenz im Unterricht", subject: "Deutsch", course: "EF ER GK1", topic: "Medien", url: "https://example.com/taskcard", description: "Eine Einführung in die kritische Medienanalyse.", confirmed: true, createdBy: "seed", teachers: { connect: { id: teacher.id } } } });
}
main().finally(() => prisma.$disconnect());
