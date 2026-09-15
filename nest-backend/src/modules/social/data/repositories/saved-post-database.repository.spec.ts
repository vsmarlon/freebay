import { Test } from "@nestjs/testing";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { PrismaSavedPostRepository } from "./saved-post-database.repository";

describe("PrismaSavedPostRepository", () => {
  it("orders saved rows by the stable createdAt/id keyset and applies visibility", async () => {
    const findMany = jest.fn().mockResolvedValue([]);
    const module = await Test.createTestingModule({
      providers: [
        PrismaSavedPostRepository,
        { provide: PrismaService, useValue: { savedPost: { findMany } } },
      ],
    }).compile();

    await module.get(PrismaSavedPostRepository).findSaved({
      userId: "user-1",
      limit: 2,
      cursor: {
        scope: "saved-posts",
        userId: "user-1",
        createdAt: "2026-01-01T00:00:00.000Z",
        savedPostId: "saved-1",
      },
    });

    expect(findMany).toHaveBeenCalledWith(expect.objectContaining({
      take: 3,
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      where: expect.objectContaining({
        userId: "user-1",
        OR: [
          { createdAt: { lt: new Date("2026-01-01T00:00:00.000Z") } },
          {
            createdAt: new Date("2026-01-01T00:00:00.000Z"),
            id: { lt: "saved-1" },
          },
        ],
      }),
    }));
  });
});
