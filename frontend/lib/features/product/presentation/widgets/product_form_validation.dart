abstract final class ProductFormValidation {
  static const minTitleLength = 3;
  static const maxTitleLength = 100;
  static const minDescriptionLength = 10;
  static const maxDescriptionLength = 5000;

  static bool isTitleValid(String value) =>
      value.length >= minTitleLength && value.length <= maxTitleLength;

  static bool isDescriptionValid(String value) =>
      value.length >= minDescriptionLength &&
      value.length <= maxDescriptionLength;

  static bool isPriceValid(int cents) => cents > 0;
}
