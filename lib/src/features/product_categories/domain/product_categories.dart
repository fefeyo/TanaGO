import 'product_category.dart';

const productCategories = <ProductCategory>[
  ProductCategory(id: 'produce', name: '野菜・果物'),
  ProductCategory(id: 'meat', name: '精肉'),
  ProductCategory(id: 'seafood', name: '鮮魚'),
  ProductCategory(id: 'dairy', name: '乳製品・卵'),
  ProductCategory(id: 'frozen', name: '冷凍食品'),
  ProductCategory(id: 'bakery', name: 'パン'),
  ProductCategory(id: 'snacks', name: 'お菓子'),
  ProductCategory(id: 'beverages', name: '飲料'),
  ProductCategory(id: 'dry_goods', name: '乾物・麺類'),
  ProductCategory(id: 'seasonings', name: '調味料'),
  ProductCategory(id: 'prepared_food', name: '惣菜'),
  ProductCategory(id: 'daily_goods', name: '日用品'),
];

ProductCategory? productCategoryById(String? id) {
  if (id == null) {
    return null;
  }

  for (final category in productCategories) {
    if (category.id == id) {
      return category;
    }
  }
  return null;
}
