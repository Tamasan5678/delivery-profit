# データ設計

## 現在のモデル

### DeliverySession

配達中状態を HomeScreen に渡すための一時モデル。

| フィールド | 型 | 必須 | 内容 |
|---|---|---:|---|
| targetCount | int | 必須 | 目標配達件数 |
| weather | String | 必須 | 選択した天気 |

現在は Navigator の戻り値としてメモリ上で受け渡し、永続化しない。

### FinishInputResult

配達終了画面から HomeScreen に渡す実績結果。

| フィールド | 型 | 必須 | 内容 |
|---|---|---:|---|
| onlineTime | String | 必須 | オンライン時間（例 8:00） |
| sales | int | 必須 | 売上（円） |
| deliveryCount | int | 必須 | 配達件数 |
| distance | int | 必須 | 走行距離（km） |

## 現在の保存状況

- HomeScreen の集計値は State に保持され、アプリ終了・再起動で失われる。
- PreferencesService は開始距離、終了距離、目標件数、目標売上の SharedPreferences API を提供するが、現行画面フローとの接続は未完了。

## SQLite 化の想定

### delivery_sessions

配達単位の開始・終了情報を保存する主テーブル。

| カラム | 型 | 制約・内容 |
|---|---|---|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| started_at | TEXT | 開始日時（ISO 8601） |
| finished_at | TEXT | 終了日時、未完了時 NULL |
| start_distance_km | INTEGER | 開始メーター値 |
| end_distance_km | INTEGER | 終了メーター値、未入力時 NULL |
| target_count | INTEGER | 目標件数 |
| weather | TEXT | 天気 |
| online_time | TEXT | オンライン時間 |
| sales | INTEGER | 売上（円） |
| delivery_count | INTEGER | 配達件数 |
| created_at | TEXT | 作成日時 |
| updated_at | TEXT | 更新日時 |

### settings（任意）

目標売上など、日々の配達実績ではない設定値を保存する。キー・値方式または専用カラム方式を採用する。

### 方針

- 金額・件数・距離は整数で保存する。
- 日時は UTC または端末タイムゾーンを明示した ISO 8601 文字列に統一する。
- 完了前セッションを保存し、再起動後に配達中状態を復元できるようにする。
- DB アクセスは Repository 層に閉じ込め、画面から直接 SQL を発行しない。
