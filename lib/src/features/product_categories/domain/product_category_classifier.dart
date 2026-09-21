class ProductCategoryClassifier {
  const ProductCategoryClassifier();

  String? classify(String productName) {
    final normalized = _normalize(productName);
    if (normalized.isEmpty) {
      return null;
    }

    for (final rule in _rules) {
      if (rule.exactKeywords.contains(normalized) ||
          rule.containsKeywords.any(normalized.contains)) {
        return rule.categoryId;
      }
    }

    return null;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s　・･_-]+'), '');
  }
}

class _CategoryRule {
  const _CategoryRule(
    this.categoryId, {
    this.containsKeywords = const [],
    this.exactKeywords = const [],
  });

  final String categoryId;
  final List<String> containsKeywords;
  final List<String> exactKeywords;
}

const _rules = <_CategoryRule>[
  _CategoryRule(
    'dairy',
    containsKeywords: [
      '牛乳',
      'ミルク',
      '卵',
      'たまご',
      '玉子',
      'ヨーグルト',
      'チーズ',
      'バター',
      '生クリーム',
    ],
  ),
  _CategoryRule(
    'meat',
    containsKeywords: [
      '豚こま',
      '豚肉',
      '豚バラ',
      '豚ロース',
      '牛肉',
      '牛こま',
      '鶏肉',
      '鶏もも',
      '鶏むね',
      'ひき肉',
      '挽肉',
      'ベーコン',
      'ハム',
      'ウインナー',
      'ソーセージ',
    ],
  ),
  _CategoryRule(
    'seafood',
    containsKeywords: [
      '鮭',
      'サーモン',
      'まぐろ',
      'マグロ',
      '刺身',
      'さば',
      'サバ',
      'あじ',
      'アジ',
      'ぶり',
      'ブリ',
      'えび',
      'エビ',
      'いか',
      'イカ',
      'たこ',
      'タコ',
    ],
  ),
  _CategoryRule(
    'produce',
    containsKeywords: [
      'キャベツ',
      'レタス',
      '白菜',
      '玉ねぎ',
      'たまねぎ',
      'じゃがいも',
      'にんじん',
      '人参',
      '大根',
      'ねぎ',
      'ネギ',
      'トマト',
      'きゅうり',
      'ピーマン',
      'なす',
      'バナナ',
      'りんご',
      'みかん',
      'いちご',
    ],
  ),
  _CategoryRule(
    'seasonings',
    exactKeywords: ['塩', '酢'],
    containsKeywords: [
      'しょうゆ',
      '醤油',
      'みそ',
      '味噌',
      '砂糖',
      'みりん',
      '料理酒',
      'マヨネーズ',
      'ケチャップ',
      'ドレッシング',
      'ソース',
      'こしょう',
      '胡椒',
    ],
  ),
  _CategoryRule(
    'bakery',
    containsKeywords: [
      '食パン',
      'ロールパン',
      'クロワッサン',
      'ベーグル',
      'パン',
    ],
  ),
  _CategoryRule('frozen', containsKeywords: ['冷凍', 'アイス']),
  _CategoryRule(
    'beverages',
    exactKeywords: ['水', 'お茶', '麦茶', '緑茶', '紅茶'],
    containsKeywords: ['コーヒー', 'ジュース', '炭酸', 'スポーツドリンク'],
  ),
  _CategoryRule(
    'dry_goods',
    exactKeywords: ['米', 'お米'],
    containsKeywords: [
      'パスタ',
      'スパゲッティ',
      'うどん',
      'そば',
      '蕎麦',
      'そうめん',
      'ラーメン',
      '海苔',
      'のり',
    ],
  ),
  _CategoryRule(
    'snacks',
    containsKeywords: [
      'チョコ',
      'クッキー',
      'ビスケット',
      'ポテトチップス',
      'せんべい',
      '煎餅',
      'グミ',
      'キャンディ',
      '飴',
    ],
  ),
  _CategoryRule(
    'prepared_food',
    containsKeywords: [
      '弁当',
      'お弁当',
      '惣菜',
      'コロッケ',
      '唐揚げ',
      'からあげ',
      '天ぷら',
      '寿司',
    ],
  ),
  _CategoryRule(
    'daily_goods',
    containsKeywords: [
      'ティッシュ',
      'トイレットペーパー',
      'キッチンペーパー',
      'ラップ',
      'アルミホイル',
      '洗剤',
      'スポンジ',
      'ゴミ袋',
      'ごみ袋',
    ],
  ),
];
