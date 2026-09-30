import "dotenv/config";
import {
  PrismaClient,
  Condition,
  ProductStatus,
  PostType,
  User,
  UserRole,
} from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import { Pool } from "pg";
import * as bcrypt from "bcryptjs";

const environment = process.env.NODE_ENV;
if (environment !== "development" && environment !== "test") {
  throw new Error(
    "[Seed] Refusing to seed unless NODE_ENV is explicitly development or test.",
  );
}
const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error("[Seed] DATABASE_URL is required.");
}
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log("[Seed] Starting FreeBay database seeding...");
  // PushDevice is not seeded: provider tokens belong to real app installations.

  // 1. Categories Hierarchy
  console.log("[Seed] Seeding categories...");
  const categoriesData = [
    {
      name: "Eletrônicos",
      slug: "eletronicos",
      children: [
        { name: "Smartphones & Celulares", slug: "smartphones" },
        { name: "Notebooks & Computadores", slug: "notebooks" },
        { name: "Videogames & Consoles", slug: "videogames" },
        { name: "Áudio & Fones de Ouvido", slug: "audio" },
      ],
    },
    {
      name: "Moda & Vestuário",
      slug: "moda",
      children: [
        { name: "Roupas Masculinas", slug: "roupas-masculinas" },
        { name: "Roupas Femininas", slug: "roupas-femininas" },
        { name: "Calçados & Tênis", slug: "calcados" },
        { name: "Acessórios & Relógios", slug: "acessorios" },
      ],
    },
    {
      name: "Casa & Decoração",
      slug: "casa",
      children: [
        { name: "Móveis", slug: "moveis" },
        { name: "Eletrodomésticos", slug: "eletrodomesticos" },
        { name: "Decoração & Arte", slug: "decoracao" },
      ],
    },
    {
      name: "Esportes & Lazer",
      slug: "esportes",
      children: [
        { name: "Bicicletas & Ciclismo", slug: "bicicletas" },
        { name: "Fitness & Musculação", slug: "fitness" },
        { name: "Camping & Aventura", slug: "camping" },
      ],
    },
    {
      name: "Colecionáveis & Geek",
      slug: "colecionaveis",
      children: [
        { name: "Action Figures", slug: "action-figures" },
        { name: "Discos de Vinil", slug: "vinil" },
        { name: "Quadrinhos & Mangás", slug: "quadrinhos" },
      ],
    },
  ];

  const categoryMap = new Map<string, string>();

  for (const cat of categoriesData) {
    const parent = await prisma.category.upsert({
      where: { slug: cat.slug },
      update: { name: cat.name },
      create: { name: cat.name, slug: cat.slug },
    });
    categoryMap.set(cat.slug, parent.id);

    for (const child of cat.children) {
      const sub = await prisma.category.upsert({
        where: { slug: child.slug },
        update: { name: child.name, parentId: parent.id },
        create: { name: child.name, slug: child.slug, parentId: parent.id },
      });
      categoryMap.set(child.slug, sub.id);
    }
  }

  // 2. Demo Users
  console.log("👤 Seeding demo users...");
  const defaultPasswordHash = await bcrypt.hash("Freebay@2026", 12);

  const usersData = [
    {
      email: "admin@freebay.app",
      username: "admin",
      displayName: "FreeBay Official",
      bio: "Conta oficial da equipe de suporte e operações do FreeBay.",
      role: UserRole.ADMIN,
      isVerified: true,
      city: "São Paulo",
      state: "SP",
      avatarUrl:
        "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400",
    },
    {
      email: "marcos@freebay.app",
      username: "marcos_tech",
      displayName: "Marcos Tech Store",
      bio: "Especialista em hardware Apple e consoles. Envio em 24h com garantia.",
      role: UserRole.USER,
      isVerified: true,
      city: "São Paulo",
      state: "SP",
      avatarUrl:
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400",
    },
    {
      email: "carolina@freebay.app",
      username: "carol_vintage",
      displayName: "Carol Vintage & Curadoria",
      bio: "Peças únicas dos anos 90 e 2000 selecionadas com amor ✨",
      role: UserRole.USER,
      isVerified: true,
      city: "Curitiba",
      state: "PR",
      avatarUrl:
        "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400",
    },
    {
      email: "lucas@freebay.app",
      username: "lucas_gamer",
      displayName: "Lucas Games & Coleções",
      bio: "Colecionador vendendo itens raros de PS1, PS2, Switch e PC.",
      role: UserRole.USER,
      isVerified: false,
      city: "Rio de Janeiro",
      state: "RJ",
      avatarUrl:
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400",
    },
  ];

  const userMap = new Map<string, User>();

  for (const u of usersData) {
    const createdUser = await prisma.user.upsert({
      where: { email: u.email },
      update: {
        username: u.username,
        displayName: u.displayName,
        bio: u.bio,
        isVerified: u.isVerified,
        city: u.city,
        state: u.state,
        avatarUrl: u.avatarUrl,
      },
      create: {
        email: u.email,
        passwordHash: defaultPasswordHash,
        username: u.username,
        displayName: u.displayName,
        bio: u.bio,
        role: u.role,
        isVerified: u.isVerified,
        city: u.city,
        state: u.state,
        avatarUrl: u.avatarUrl,
      },
    });

    // Ensure wallet exists
    await prisma.wallet.upsert({
      where: { userId: createdUser.id },
      update: {},
      create: {
        userId: createdUser.id,
        availableBalance: 150000, // R$ 1.500,00
      },
    });

    userMap.set(u.username, createdUser);
  }

  // 3. Products
  console.log("🛍️ Seeding marketplace products...");
  const seedUser = (username: string): User => {
    const user = userMap.get(username);
    if (!user) throw new Error(`Seed user not found: ${username}`);
    return user;
  };
  const marcos = seedUser("marcos_tech");
  const carol = seedUser("carol_vintage");
  const lucas = seedUser("lucas_gamer");

  const productsData = [
    {
      title: "iPhone 15 Pro 128GB Titânio Natural",
      description:
        "Aparelho impecável, saúde da bateria em 98%. Acompanha caixa original e cabo USB-C trançado. Sem nenhum detalhe ou marca de uso.",
      price: 499000, // R$ 4.990,00
      condition: Condition.USED,
      categorySlug: "smartphones",
      sellerId: marcos.id,
      images: [
        "https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800",
        "https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=800",
      ],
    },
    {
      title: "Sony PlayStation 5 Slim 1TB + 2 Controles DualSense",
      description:
        "Console com 6 meses de uso, nunca aberto. Acompanha 2 controles originais e os jogos Spider-Man 2 e God of War Ragnarok.",
      price: 320000, // R$ 3.200,00
      condition: Condition.USED,
      categorySlug: "videogames",
      sellerId: lucas.id,
      images: [
        "https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800",
      ],
    },
    {
      title: "Jaqueta Biker Couro Legítimo Anos 90 Vintage",
      description:
        "Peça original garimpada na Itália. Couro pesado de alta qualidade com zíperes YKK vintage. Tamanho M/G masculino.",
      price: 45000, // R$ 450,00
      condition: Condition.USED,
      categorySlug: "roupas-masculinas",
      sellerId: carol.id,
      images: [
        "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800",
        "https://images.unsplash.com/photo-1520975916090-3105956dac38?w=800",
      ],
    },
    {
      title: "Fone de Ouvido Sony WH-1000XM5 Noise Cancelling",
      description:
        "Novo na caixa, lacrado. Melhor cancelamento de ruído do mercado com até 30 horas de autonomia de bateria.",
      price: 165000, // R$ 1.650,00
      condition: Condition.NEW,
      categorySlug: "audio",
      sellerId: marcos.id,
      images: [
        "https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=800",
      ],
    },
    {
      title: "Tênis Nike Dunk Low Retro Panda Tam 41",
      description:
        "Original na caixa com nota fiscal. Usado apenas duas vezes para fotos, sola 100% conservada sem marcas de desgaste.",
      price: 58000, // R$ 580,00
      condition: Condition.USED,
      categorySlug: "calcados",
      sellerId: carol.id,
      images: [
        "https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800",
      ],
    },
  ];

  for (const prod of productsData) {
    const categoryId = categoryMap.get(prod.categorySlug);

    const existingProduct = await prisma.product.findFirst({
      where: { title: prod.title, sellerId: prod.sellerId },
    });
    const productData = {
      title: prod.title,
      description: prod.description,
      price: prod.price,
      condition: prod.condition,
      categoryId,
      sellerId: prod.sellerId,
      status: ProductStatus.ACTIVE,
      deletedAt: null,
      quantity: 1,
    };
    const createdProduct = existingProduct
      ? await prisma.product.update({
          where: { id: existingProduct.id },
          data: productData,
        })
      : await prisma.product.create({ data: productData });

    await prisma.productImage.deleteMany({
      where: { productId: createdProduct.id },
    });
    await prisma.productImage.createMany({
      data: prod.images.map((url, idx) => ({
        productId: createdProduct.id,
        url,
        order: idx,
      })),
    });

    // Also create corresponding featured social post
    const postData = {
      userId: prod.sellerId,
      type: PostType.PRODUCT,
      content: `Novo anúncio disponível: ${prod.title}! Garanta com proteção de custódia do FreeBay.`,
      imageUrl: prod.images[0],
      deletedAt: null,
    };
    const post = createdProduct.postId
      ? await prisma.post.update({
          where: { id: createdProduct.postId },
          data: postData,
        })
      : await prisma.post.create({ data: postData });

    await prisma.product.update({
      where: { id: createdProduct.id },
      data: { postId: post.id },
    });
  }

  // 4. Social Posts & Stories
  console.log("📱 Seeding social posts & stories...");
  const existingPost = await prisma.post.findFirst({
    where: {
      userId: marcos.id,
      type: PostType.REGULAR,
      content:
        "Configuração do novo setup finalizada! Quem aí também prefere monitor ultrawide para trabalhar?",
    },
    select: { id: true },
  });
  const post1 = existingPost
    ? await prisma.post.update({
        where: { id: existingPost.id },
        data: { deletedAt: null },
      })
    : await prisma.post.create({
        data: {
          userId: marcos.id,
          type: PostType.REGULAR,
          content:
            "Configuração do novo setup finalizada! Quem aí também prefere monitor ultrawide para trabalhar?",
        },
      });

  const comment = await prisma.comment.findFirst({
    where: {
      postId: post1.id,
      userId: lucas.id,
      content: "Ficou insano demais! Qual suporte de monitor você está usando?",
    },
  });
  if (!comment) {
    await prisma.comment.create({
      data: {
        postId: post1.id,
        userId: lucas.id,
        content:
          "Ficou insano demais! Qual suporte de monitor você está usando?",
      },
    });
  }

  // Stories
  const now = new Date();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);

  const storyUrl =
    "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800";
  const existingStory = await prisma.story.findFirst({
    where: { userId: carol.id, imageUrl: storyUrl },
    select: { id: true },
  });
  const seededStory = existingStory
    ? await prisma.story.update({
      where: { id: existingStory.id },
      data: { expiresAt: tomorrow },
    })
    : await prisma.story.create({
      data: {
        userId: carol.id,
        imageUrl: storyUrl,
        expiresAt: tomorrow,
      },
    });

  const seededHighlight = await prisma.storyHighlight.findFirst({
    where: { userId: carol.id, title: 'Estilo' },
  });
  if (!seededHighlight) {
    await prisma.storyHighlight.create({
      data: {
        userId: carol.id,
        title: 'Estilo',
        coverStoryId: seededStory.id,
        stories: { create: [{ storyId: seededStory.id, position: 0 }] },
      },
    });
  }

  console.log("✅ Seeding finished successfully!");
}

main()
  .catch((e) => {
    console.error("❌ Seeding error:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
