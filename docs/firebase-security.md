# Firebase 接続とセキュリティ

## 実装と境界

本番 Provider は Firebase Auth / Firestore、ユニットテストは InMemory override を使用する。
AuthRepository の匿名ログインは同時呼出しを1つにまとめる。bootstrap が完了してから authStateChanges を購読し、その UID の users と household を監視する。サインアウト・UID 変更時は前の世帯の購読を解除する。起動時エラー画面から再試行できる。

ルート探索や経路線は追加していない。未購入カテゴリによる棚ハイライトは既存実装を維持。

## データと Rules

- `users/{uid}`: 本人だけ get。世帯への所属登録は member 作成と同一の原子的書き込みでのみ許可。
- `households/{id}`: メンバーだけ get。世帯全体の検索は不可。名前の変更は owner のみ。
- `members/{uid}`: メンバーだけ read。本人が owner として世帯を新規作成するか、有効な招待コードを持って member として参加する場合のみ create。役割変更・削除は禁止。
- `householdInvites/{code}`: 認証済みの完全一致 get のみ。内容は householdId だけ。一覧検索は禁止。新規世帯作成と同じトランザクションで登録する。
- `shoppingLists/active/items`: 同世帯のメンバーが共有編集。追加者・作成日時は変更不可。購入者の偽装、購入状態と日時の不整合を拒否。
- `stores` / `mapObjects`: 同世帯のメンバーだけ。型・カテゴリ・マップ境界を検証。店舗削除は `deleting: true` → 棚を400件ずつ削除 → 店舗削除。削除中・削除後の店舗へ棚を書き込めない。中断時は店舗削除を再実行できる。
- それ以外のパスは拒否。全 authenticated user に世帯を公開する許可は設けていない。

Rules の getAfter で user・member・household・invite の整合を検証する。購入・棚編集は Repository のトランザクションで最新値に変更を適用し、削除済みデータを再作成しない。

世帯移動・退会機能は現在 UI にないため、一人一世帯を維持する。別世帯への再参加をエラーにし、同一世帯への再参加は role/joinedAt を変更しない。店舗は既存 UI に合わせて全メンバーが削除できる。

招待コードは `TANA-` + 32桁のランダム16進数（UUID v4、122 random bits）。手入力よりコピー共有を推奨。知っている認証ユーザーが参加できる bearer secret として扱う。期限・招待取り消し・試行回数制限は未実装。短いコード、期限や失効、監査、レート制限が必要な場合は callable Cloud Functions + App Check を次段階で導入し、そこで本人 UID を検証して Admin SDK で参加処理を実行する。

## Firebase Console と公開前の作業

1. `tanago-77c59` の Authentication → Sign-in method → 匿名を有効化。
2. Cloud Firestore データベースが作成済みであることを確認。
3. **旧アプリを止めたメンテナンス中に既存データをバックアップし、旧招待コードを移行する。** 新 Rules は旧4文字コードによる参加や旧アプリの household 検索を拒否する。
4. 移行後、新アプリと Rules をセットで公開。認証済みの既存メンバーは移行後も従来の UID で利用できる。家族には新コードを共有する。
5. CLI で `npx firebase deploy --only firestore:rules --project tanago-77c59`、または Console の Rules に `firestore.rules` を反映する。本作業ではデプロイしていない。

Firebase Storage の設定は不要。現在のクエリではカスタム複合インデックスは不要（通常の単一フィールドインデックスは維持）。Anonymous Auth の端末データ消去・アプリ再インストール等で UID を失うと同じ owner に戻れないため、継続利用前にアカウント連携も検討する。

### 旧招待コードの移行

管理者の Application Default Credentials が必要。サービスアカウント鍵をリポジトリに保存しない。

```sh
npm ci
# デフォルトは読み取り監査と dry run。招待コードはログに出力しない。
node scripts/migrate-invites.cjs --project tanago-77c59
# バックアップ後、メンテナンス時間内に適用。
node scripts/migrate-invites.cjs --project tanago-77c59 --apply
```

users の所属先、members、createdByUid/owner に矛盾があれば変更前に停止する。旧実装で複数世帯の membership が残った場合や owner が member に上書きされた場合は、管理者が所属先を判断し修復してから再実行する。自動的に所属や権限を推測して削除しない。移行は1世帯ごとに atomic で、途中で中断しても再実行可能。世帯名、商品、棚、既存メンバーは変更しない。

## 検証

```sh
flutter pub get
dart format .
flutter analyze
flutter test
npm ci
npm run test:rules
```

Rules テストは `demo-tanago` のローカル Firestore Emulator のみを使用する。Node.js 22/24 と CLI 対応の Java（21以上推奨）が必要。Flutter テストは Firebase.initializeApp を実行しない。Rules テストはJS SDKによるアクセス契約の検証であり、Android/iOS上でのFirestoreプラグイン動作の検証を代替しない。実機で2つのUIDを使い「作成 → 招待 → 商品共有 → 棚編集 → 購入 → 店舗削除」を確認する。

参考: [Firestore Rules の条件と getAfter](https://firebase.google.com/docs/firestore/security/rules-conditions)、[Rules とクエリ](https://firebase.google.com/docs/firestore/security/rules-query)、[トランザクションとアクセス回数上限](https://firebase.google.com/docs/firestore/manage-data/transactions)。

## 現在の制限

- 世帯作成/参加と購入・棚編集は Firestore transaction を使用するためオンラインが必要。オフライン書き込みキューや保存失敗時の画面案内は次の改善対象。
- 同一フィールドを複数人が変更した場合の編集意図の統合までは行わない。異なるフィールドの上書きを防ぎ、トランザクション上の順序で処理する。
- 本番デプロイ、既存データ移行、Android/iOS実機の2ユーザー同期検証はこの変更では実施していない。
- 検証環境は Flutter 3.38.5 / Dart 3.10.4、Node 25.1.0 / Java 25。CLI の一部依存は Node 22/24 を対象とするため、再現用にはそれらの LTS を推奨。npm audit には開発用 CLI の推移依存で moderate が残る（high/critical は更新で解消）。Flutter アプリに npm 依存は組み込まれない。

## 店内マップの編集と拡張

- ドラッグは端末内でプレビューし、指を離した時だけ移動を保存する。同じ棚の保存は順番に処理し、Firestore の古いスナップショットで新しい移動を巻き戻さない。
- 保存失敗時は位置を戻してエラーを表示する。キャンセルされたドラッグは保存しない。
- 店舗の `mapWidth` / `mapHeight` を編集・買い物画面の両方で使用する。既存店舗の初期値は 12 × 16。
- 世帯メンバーは店舗のマップを最大 100 × 100 まで拡張できる。縮小を拒否し、配置済みの棚が範囲外にならないようにする。削除中の店舗は拡張できない。
- 編集画面の「移動・拡大」で画面のパン・ピンチ操作に切り替える。オフにすると空きマスへの配置と棚のドラッグができる。拡大・縮小・全体表示ボタンは両モードで使用できる。
