import { CategoryEntity } from '../entities';

export interface ICategoryRepository {
  getCategoryTree(): Promise<CategoryEntity[]>;
  getAllCategories(): Promise<CategoryEntity[]>;
  getCategoryById(id: string): Promise<CategoryEntity | null>;
  createCategory(data: { name: string; slug: string; parentId?: string }): Promise<CategoryEntity>;
}
