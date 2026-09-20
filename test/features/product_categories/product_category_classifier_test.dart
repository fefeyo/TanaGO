import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/product_categories/domain/product_category_classifier.dart';

void main() {
  const classifier = ProductCategoryClassifier();

  test('classifies common grocery names', () {
    expect(classifier.classify('牛乳'), 'dairy');
    expect(classifier.classify('豚こま 300g'), 'meat');
    expect(classifier.classify('しょうゆ'), 'seasonings');
    expect(classifier.classify('箱ティッシュ'), 'daily_goods');
    expect(classifier.classify('冷凍うどん'), 'frozen');
  });

  test('normalizes spaces and separators', () {
    expect(classifier.classify('  牛 乳  '), 'dairy');
    expect(classifier.classify('トイレット・ペーパー'), 'daily_goods');
  });

  test('does not guess unknown products', () {
    expect(classifier.classify('いつものやつ'), isNull);
  });

  test('does not match ambiguous short words inside another product', () {
    expect(classifier.classify('水菜'), isNull);
  });
}
