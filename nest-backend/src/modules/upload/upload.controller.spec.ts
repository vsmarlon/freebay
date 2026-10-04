import { Test, TestingModule } from "@nestjs/testing";
import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
} from "@nestjs/common";
import { readFileSync, rmSync } from "fs";
import { join } from "path";
import { UploadController, isValidContext } from "./upload.controller";
import { JwtAuthGuard } from "@/modules/auth/guards/jwt-auth.guard";

class MockJwtGuard implements CanActivate {
  canActivate(_context: ExecutionContext): boolean {
    return true;
  }
}

describe("UploadController", () => {
  let sut: UploadController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UploadController],
    })
      .overrideGuard(JwtAuthGuard)
      .useClass(MockJwtGuard)
      .compile();
    sut = module.get<UploadController>(UploadController);
  });

  it("returns a BlurHash for a successfully stored public image", async () => {
    const buffer = readFileSync(
      join(process.cwd(), "..", "frontend", "assets", "freebay-textonly.png"),
    );
    const result = await sut.upload(
      {
        mimetype: "image/png",
        buffer,
        size: buffer.length,
      } as Express.Multer.File,
      "avatar",
    );

    expect(result).toHaveProperty("blurHash", expect.any(String));
    expect(result).toHaveProperty(
      "blurHash",
      expect.stringMatching(/^.{6,}$/s),
    );
    rmSync(join(process.cwd(), result.url.replace("/uploads/", "uploads/")));
  });

  it('does not return a BlurHash for a real private image upload', async () => {
    const buffer = readFileSync(
      join(process.cwd(), "..", "frontend", "assets", "freebay-textonly.png"),
    );
    const result = await sut.upload(
      { mimetype: 'image/png', buffer, size: buffer.length } as Express.Multer.File,
      'privatepost',
    );

    expect(result.url).toMatch(/^\/media\/privatepost\/[0-9a-f-]{36}\.png$/);
    expect(result).not.toHaveProperty('blurHash');
    rmSync(join(process.cwd(), result.url.replace('/media/', 'private-uploads/')));
  });

  it("stores a chat attachment privately, never under the public /uploads root", async () => {
    const file = {
      mimetype: "image/jpeg",
      buffer: Buffer.from([0xff, 0xd8, 0xff]),
      size: 3,
    } as Express.Multer.File;

    const result = await sut.upload(file, "chat");

    expect(result.url).toMatch(/^\/media\/chat\/[0-9a-f-]{36}\.jpg$/);
    rmSync(
      join(process.cwd(), result.url.replace("/media/", "private-uploads/")),
    );
  });

  it("stores a MOV video attachment privately", async () => {
    const file = {
      mimetype: "video/quicktime",
      buffer: Buffer.from([
        0, 0, 0, 12, 0x66, 0x74, 0x79, 0x70, 0x71, 0x74, 0x20, 0x20,
      ]),
      size: 12,
    } as Express.Multer.File;

    const result = await sut.upload(file, "chat");

    expect(result.url).toMatch(/^\/media\/chat\/[0-9a-f-]{36}\.mov$/);
    rmSync(
      join(process.cwd(), result.url.replace("/media/", "private-uploads/")),
    );
  });

  it("stores a public context under /uploads", async () => {
    const file = {
      mimetype: "image/jpeg",
      buffer: Buffer.from([0xff, 0xd8, 0xff]),
      size: 3,
    } as Express.Multer.File;

    const result = await sut.upload(file, "avatar");

    expect(result.url).toMatch(/^\/uploads\/avatar\/[0-9a-f-]{36}\.jpg$/);
    rmSync(join(process.cwd(), result.url.replace("/uploads/", "uploads/")));
  });

  it("throws BadRequestException when no file", async () => {
    await expect(sut.upload(undefined, "chat")).rejects.toThrow(BadRequestException);
  });

  it("throws BadRequestException for invalid context", async () => {
    const file = { filename: "abc.jpg" } as Express.Multer.File;
    await expect(sut.upload(file, "invalid")).rejects.toThrow(BadRequestException);
  });

  it("throws BadRequestException for path-traversal context", async () => {
    const file = { filename: "abc.jpg" } as Express.Multer.File;
    await expect(sut.upload(file, "../../etc")).rejects.toThrow(BadRequestException);
  });

  describe("isValidContext", () => {
    it.each(["chat", "background", "post", "avatar", "product", "privatepost"])(
      "accepts %s",
      (context) => {
        expect(isValidContext(context)).toBe(true);
      },
    );

    it.each([
      "../../etc",
      "..",
      "chat/../../etc",
      "/absolute",
      "misc",
      "",
      undefined,
      null,
      123,
    ])("rejects %p", (context) => {
      expect(isValidContext(context)).toBe(false);
    });
  });
});
