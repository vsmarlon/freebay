import { Prisma, StoryAudience, StoryMediaType } from "@prisma/client";
import { ArrayMaxSize, ArrayNotEmpty, ArrayUnique, IsArray, IsEnum, IsOptional, IsString, IsUUID, MaxLength } from "class-validator";

export enum StoryTextStyle {
  CLASSIC = "classic",
  STRONG = "strong",
  EDITORIAL = "editorial",
  COMPACT = "compact",
}

export const STORY_CAPTION_MAX_LENGTH = 500;
export const STORY_TEXT_BLOCKS_PAYLOAD_MAX_LENGTH = 100_000;
export const STORY_TEXT_BLOCK_MAX_COUNT = 10;
export const STORY_TEXT_MAX_LENGTH = 200;

export class CreateStoryMultipartDTO {
  @IsOptional()
  @IsEnum(StoryAudience)
  audience?: StoryAudience;

  @IsOptional()
  @IsString()
  @MaxLength(STORY_CAPTION_MAX_LENGTH)
  caption?: string;

  @IsOptional()
  @IsString()
  @MaxLength(STORY_TEXT_BLOCKS_PAYLOAD_MAX_LENGTH)
  textBlocks?: string;
}

export class SaveStoryHighlightDTO {
  @IsString()
  @MaxLength(40)
  title: string;

  @IsArray()
  @ArrayNotEmpty()
  @ArrayMaxSize(50)
  @ArrayUnique()
  @IsUUID('4', { each: true })
  storyIds: string[];

  @IsUUID('4')
  coverStoryId: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isStoryTextStyle(value: unknown): value is StoryTextStyle {
  return (
    typeof value === "string" &&
    Object.values(StoryTextStyle).some((style) => style === value)
  );
}

export interface StoryTextBlock {
  id: string;
  text: string;
  x: number;
  y: number;
  scale: number;
  rotation: number;
  color: number;
  style: StoryTextStyle;
  zIndex: number;
}

export interface CreateStoryInput {
  userId: string;
  imageUrl: string;
  mediaType?: StoryMediaType;
  audience?: StoryAudience;
  caption?: string;
  textBlocks?: Prisma.InputJsonValue;
}

export interface CreateStoryOutput {
  id: string;
  userId: string;
  imageUrl: string;
  mediaType: StoryMediaType;
  audience: StoryAudience;
  caption: string | null;
  textBlocks: StoryTextBlock[];
  expiresAt: Date;
  createdAt: Date;
  user: {
    id: string;
    displayName: string;
    avatarUrl: string | null;
    isVerified: boolean;
  };
}

export interface GroupedStory {
  user: { id: string; displayName: string; avatarUrl: string | null };
  stories: {
    id: string;
    imageUrl: string;
    mediaType: "IMAGE" | "VIDEO";
    audience: StoryAudience;
    caption: string | null;
    textBlocks: StoryTextBlock[];
    createdAt: Date;
    expiresAt: Date;
    viewsCount: number;
  }[];
}

export function parseStoryTextBlocks(
  value: unknown,
): { value: StoryTextBlock[] } | { error: string } {
  let parsed: unknown = value;
  if (typeof value === "string") {
    if (value.length > STORY_TEXT_BLOCKS_PAYLOAD_MAX_LENGTH) {
      return { error: "textBlocks excede o tamanho máximo permitido" };
    }
    try {
      parsed = JSON.parse(value) as unknown;
    } catch {
      return { error: "textBlocks deve ser um JSON válido" };
    }
  }
  if (parsed === undefined || parsed === null || parsed === "") {
    return { value: [] };
  }
  if (!Array.isArray(parsed) || parsed.length > STORY_TEXT_BLOCK_MAX_COUNT) {
    return { error: "textBlocks deve ser uma lista com no máximo 10 itens" };
  }

  const ids = new Set<string>();
  const blocks: StoryTextBlock[] = [];
  for (const item of parsed) {
    if (typeof item !== "object" || item === null || Array.isArray(item)) {
      return { error: "Cada bloco de texto deve ser um objeto" };
    }
    if (!isRecord(item)) {
      return { error: "Cada bloco de texto deve ser um objeto" };
    }
    const block = item;
    const id = typeof block.id === "string" ? block.id.trim() : "";
    const text = typeof block.text === "string" ? block.text.trim() : "";
    if (!id || ids.has(id))
      return { error: "IDs de texto devem ser únicos e não vazios" };
    if (text.length < 1 || text.length > STORY_TEXT_MAX_LENGTH)
      return { error: "Cada texto deve ter entre 1 e 200 caracteres" };
    ids.add(id);

    const numeric = (key: string): number | null => {
      const candidate = block[key];
      return typeof candidate === "number" && Number.isFinite(candidate)
        ? candidate
        : null;
    };
    const x = numeric("x");
    const y = numeric("y");
    const scale = numeric("scale");
    const rotation = numeric("rotation");
    const color = numeric("color");
    const zIndex = numeric("zIndex");
    const style = typeof block.style === "string" ? block.style : "";
    if (x === null || x < 0 || x > 1 || y === null || y < 0 || y > 1) {
      return { error: "A posição do texto deve estar entre 0 e 1" };
    }
    if (
      scale === null ||
      scale < 0.5 ||
      scale > 3 ||
      rotation === null ||
      rotation < -Math.PI ||
      rotation > Math.PI
    ) {
      return { error: "Escala ou rotação do texto inválida" };
    }
    if (
      color === null ||
      !Number.isInteger(color) ||
      color < 0 ||
      color > 0xffffffff
    ) {
      return { error: "A cor do texto deve ser um ARGB válido" };
    }
    if (!isStoryTextStyle(style)) {
      return { error: "Estilo de texto não suportado" };
    }
    if (zIndex === null || !Number.isInteger(zIndex)) {
      return { error: "A ordem dos textos deve ser um inteiro" };
    }
    blocks.push({
      id,
      text,
      x,
      y,
      scale,
      rotation,
      color,
      style,
      zIndex,
    });
  }
  const zIndexes = new Set(blocks.map((block) => block.zIndex));
  if (zIndexes.size !== blocks.length)
    return { error: "A ordem dos textos deve ser única" };
  return { value: blocks.sort((a, b) => a.zIndex - b.zIndex) };
}

export function canonicalStoryTextBlocks(value: unknown): StoryTextBlock[] {
  const parsed = parseStoryTextBlocks(value);
  return "value" in parsed ? parsed.value : [];
}
