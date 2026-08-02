# アーキテクチャ

## ディレクトリ構成

```text
lib/
├── main.dart
├── core/theme/       # 色、文字スタイル、ThemeData
├── models/           # DeliverySession、FinishInputResult
├── database/         # SQLite接続、テーブル作成、migration入口
├── repositories/     # 配達実績の保存・取得API
├── screens/          # 画面単位の UI と画面遷移
│   ├── home/
│   ├── start/
│   └── finish/
│       └── history/ settings/
├── services/         # SharedPreferences 等の外部保存処理
└── widgets/          # ボタン、情報カード、挨拶ヘッダー
```

## 各フォルダの役割

- `main.dart`：`MaterialApp` とテーマを初期化し、HomeScreen を起動する。
- `core/theme`：アプリ全体の色、文字、Material テーマを一元管理する。
- `screens`：画面の表示、入力、Navigator による遷移、画面ローカル状態を管理する。
- `models`：画面間で受け渡す型付きデータを定義する。配達開始時に生成したsessionIdをDeliverySessionからDeliveryRecordまで維持する。
- `widgets`：複数画面で利用する表示部品を共通化する。
- `services`：SharedPreferencesの設定保存と、配達中DeliverySessionの一時保存を担当する。計算設定2項目はCalculationSettingsの単一JSONとして1回で保存する。
- `database`：`delivery_profit.db`の接続、CHECK制約付きスキーマ、既存履歴を保持するmigrationを一元管理する。
- `repositories`：画面からSQLを分離し、DeliveryRecordの保存・取得とINSERT直前の検証を担当する。

## 状態管理

- 現在は外部状態管理ライブラリを使用せず、各 StatefulWidget の `setState` で管理する。
- HomeScreen が配達中フラグ、DeliverySession、期間集計を保持する。起動時は一時保存のsessionIdをRepositoryで照合し、SQLite保存済みなら配達中状態を復元しない。
- HomeScreenの期間集計はgeneration counterを保持し、await後に最新世代と一致する場合だけsetStateする。
- 画面間データは `Navigator.push` の戻り値で受け渡す。
- FinishInputScreen は入力コントローラーと保存中フラグを画面内に保持し、SQLite保存後に前回終了距離をSharedPreferencesへキャッシュする。キャッシュ欠損時はStartDistanceScreenが最新DeliveryRecordから復元する。
- 主要遷移画面は遷移中フラグを保持し、Navigator完了後のfinallyでmountedを確認して解除する。保存・削除の既存処理中フラグも多重実行防止に使用する。
- RepositoryとActiveDeliveryStorageは画面コンストラクタから差し替え可能とし、WidgetテストではFakeを使用する。

## 画面方向

Delivery Profitはスマートフォンでの片手操作性を重視するため、縦画面（Portrait）のみ対応とする。横画面（Landscape）はサポート対象外とし、UI設計・テスト・品質保証も縦画面のみを対象とする。

Flutter起動時に`SystemChrome.setPreferredOrientations`で`DeviceOrientation.portraitUp`だけを許可する。AndroidはFlutter初期描画前も横画面にならないようActivityの`screenOrientation`を`portrait`に揃える。

UI品質保証では共通Widgetテスト補助に論理画面幅360dp、411dp、480dpを定義し、各テスト後にsurface sizeと文字倍率を復元する。最小360dpではFlutterErrorを監視し、RenderFlex overflow、BoxConstraints、文字レイアウト、setState after dispose等をテスト失敗として扱う。小さい縦方向制約と文字拡大には、値のscaleDownと必要画面の縦スクロールで対応する。

## 今後の拡張方針

1. SQLiteの保存済みDeliveryRecordを日別・週別・月別集計へ接続する。
2. セッション・履歴・設定の状態を ViewModel／Notifier 等の状態管理層へ分離する。
3. 入力検証、計算ロジック、永続化を画面から分離してテスト可能にする。
4. HistoryScreen と SettingsScreen をルーティングおよび状態管理へ接続する。
5. 画面が増えた段階で名前付きルートまたは Router を導入する。
