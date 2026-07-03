import { Entity } from '@/shared/core/entity';

export interface ProductProps {
  id?: string;
  title: string;
  description?: string;
  price: number;
  condition: string;
  categoryId: string;
  sellerId: string;
  images?: { url: string; order: number }[];
  status?: string;
  createdAt?: Date;
}

export class ProductModel extends Entity {
  readonly title: string;
  readonly description?: string;
  readonly price: number;
  readonly condition: string;
  readonly categoryId: string;
  readonly sellerId: string;
  readonly images: { url: string; order: number }[];
  readonly status: string;
  readonly createdAt?: Date;

  private constructor(props: ProductProps) {
    super(props as unknown as Record<string, unknown>);
    this.title = props.title;
    this.description = props.description;
    this.price = props.price;
    this.condition = props.condition;
    this.categoryId = props.categoryId;
    this.sellerId = props.sellerId;
    this.images = props.images ?? [];
    this.status = props.status ?? 'ACTIVE';
    this.createdAt = props.createdAt;
  }

  static create(props: ProductProps): ProductModel {
    return new ProductModel(props);
  }
}
