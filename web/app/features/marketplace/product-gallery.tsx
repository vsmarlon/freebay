import { useI18n } from '../../core/locale';
import { mediaUrl } from '../../core/media';
import { ImageCarousel } from './image-carousel';
import type { ProductSummary } from './types';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': pt };

// ImageCarousel is copy- and URL-agnostic; this seam feeds it the product gallery
// contract (media URLs + localized labels) so the route keeps only page layout.
export function ProductGallery({ product }: { product: ProductSummary }) {
  const { t } = useI18n(catalogs);
  return (
    <ImageCarousel
      images={product.images.map((image) => ({
        id: image.id ?? image.url,
        url: mediaUrl(image.url),
      }))}
      alt={(index) => t('product.imageAlt', { title: product.title, index: index + 1 })}
      label={t('product.gallery')}
      noImage={t('product.noImage')}
      previousLabel={t('product.previousImage')}
      nextLabel={t('product.nextImage')}
      imageLabel={(index) =>
        t('product.imageOf', { index: index + 1, total: product.images.length })
      }
      openLabel={(index) => t('product.openImage', { index: index + 1 })}
      closeLabel={t('common.close')}
    />
  );
}
