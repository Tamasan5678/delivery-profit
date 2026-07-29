# アーキテクチャ

## ディレクトリ構成

```text
lib/
├── main.dart
├── core/theme/       # 色、文字スタイル、ThemeData
├── models/           # DeliverySession、FinishInputResult
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
- `models`：画面間で受け渡す型付きデータを定義する。
- `widgets`：複数画面で利用する表示部品を共通化する。
- `services`：SharedPreferences など永続化手段へのアクセスを担当する。

## 状態管理

- 現在は外部状態管理ライブラリを使用せず、各 StatefulWidget の `setState` で管理する。
- HomeScreen が配達中フラグ、DeliverySession、当日集計を保持する。
- 画面間データは `Navigator.push` の戻り値で受け渡す。
- FinishInputScreen は入力コントローラーと保存中フラグを画面内に保持する。
- アプリ再起動後も状態を維持するアプリケーション層の状態管理は未実装。

## 今後の拡張方針

1. Repository 層と SQLite データソースを追加する。
2. セッション・履歴・設定の状態を ViewModel／Notifier 等の状態管理層へ分離する。
3. 入力検証、計算ロジック、永続化を画面から分離してテスト可能にする。
4. HistoryScreen と SettingsScreen をルーティングおよび状態管理へ接続する。
5. 画面が増えた段階で名前付きルートまたは Router を導入する。
