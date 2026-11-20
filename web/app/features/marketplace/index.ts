import { myProductsApi } from './api';

export async function loadShareableProducts() {
  const { products } = await myProductsApi.list();
  return products.map(({ id, title, price, images }) => ({
    id,
    title,
    price,
    imageUrl: images[0]?.url ?? null,
  }));
}
