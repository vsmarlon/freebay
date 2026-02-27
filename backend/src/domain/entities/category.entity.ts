export interface CategoryEntity {
  id: string;
  name: string;
  slug: string;
  parentId: string | null;
  createdAt: Date;
  updatedAt: Date;
  children?: CategoryEntity[];
}
