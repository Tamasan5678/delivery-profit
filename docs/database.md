# データ設計

## 現在のモデル

### DeliverySession

配達中状態を HomeScreen に渡すための一時モデル。

| フィールド | 型 | 必須 | 内容 |
|---|---|---:|---|
| targetCount | int | 必須 | 目標配達件数 |
| weather | String | 必須 | 選択した天気 |

Navigatorの戻り値として受け渡し、配達中のみSharedPreferencesへ一時保存する。

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
- PreferencesService は開始距離、終了距離、目標件数、目標売上に加え、平均燃費（`average_fuel_efficiency`、既定値10.0km/L）とガソリン単価（`gasoline_price`、既定値170円/L）を SharedPreferences へ保存する。
- SettingsScreen で保存した平均燃費とガソリン単価は、HomeScreen と本日の配達結果画面の利益計算に使用する。

## SQLite

### 基本情報

- DB名：`delivery_profit.db`
- DBバージョン：3
- 操作経路：画面から直接SQLを実行せず、DeliveryRepositoryを使用する。
- 日時：UTCのmillisecondsSinceEpochをINTEGERで保存する。表示および日・週・月の境界は端末のローカル時刻を使用する。

### delivery_records

1回の配達開始から終了までを1行として保存する。同日に複数回配達した場合も別行とする。

| カラム | 型 | 制約・内容 |
|---|---|---|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| session_id | TEXT | NOT NULL、配達開始時に生成するセッション固有ID、UNIQUE INDEX |
| started_at_utc_ms | INTEGER | NOT NULL、配達開始UTCミリ秒 |
| finished_at_utc_ms | INTEGER | NOT NULL、配達終了UTCミリ秒 |
| start_distance_km | REAL | NOT NULL、開始走行距離 |
| target_count | INTEGER | 目標件数 |
| weather | TEXT | 天気 |
| online_minutes | INTEGER | NOT NULL、オンライン時間合計（分） |
| sales_yen | INTEGER | NOT NULL、売上 |
| delivery_count | INTEGER | 配達件数 |
| travel_distance_km | REAL | NOT NULL、走行距離 |
| fuel_efficiency_km_per_liter | REAL | NOT NULL、配達終了時の平均燃費 |
| fuel_price_yen_per_liter | INTEGER | NOT NULL、配達終了時のガソリン単価 |
| fuel_used_liters | REAL | NOT NULL、ガソリン使用量 |
| fuel_cost_yen | INTEGER | NOT NULL、ガソリン代 |
| profit_yen | INTEGER | NOT NULL、利益 |
| created_at_utc_ms | INTEGER | NOT NULL、作成UTCミリ秒 |

`finished_at_utc_ms`に期間検索用インデックスを作成する。期間検索は開始以上・終了未満の半開区間とし、終了日時の降順で返す。

### 方針

- 配達終了時点の燃費、単価、使用量、ガソリン代、利益を固定保存し、設定変更後も過去利益を再計算しない。
- DBバージョン2でsession_idを追加する。version 1の既存行には開始UTCミリ秒と行IDから安全なlegacy IDを補完し、履歴を保持したままUNIQUE INDEXを作成する。
- 同一sessionIdのINSERTはDBで拒否し、Repositoryは既存行を取得して保存済みとして安全に扱う。
- DBバージョン3でdelivery_recordsをCHECK制約付きスキーマへ移行し、既存履歴を保持したまま、負数、非有限値、日時逆転、燃費・単価範囲外、利益不整合を拒否する。Model、Repository、SQLiteの3段階で同じ保存値を検証する。
- ガソリン代は計算後に整数へ丸めて保存値を確定し、利益は必ず`売上 - 保存するガソリン代`として保存する。履歴と期間集計は保存済みガソリン代・利益を使用し、現在設定から再計算しない。
- SQLiteから本日・今週・今月の全セッションを取得し、保存済み実績値の期間合計から集計する。
- 履歴画面は終了日時の新しい順で一覧表示し、詳細画面の確認操作から対象1件だけを削除する。

## 配達中一時データ

- SharedPreferencesキー：`active_delivery_is_active`、`active_delivery_session_id`、`active_delivery_started_at_utc_ms`、`active_delivery_start_distance_km`、`active_delivery_target_count`、`active_delivery_weather`。
- 配達開始確定時に保存し、完了実績のSQLite INSERT成功後にinactive化して各項目を削除する。INSERT失敗時は保持する。
- 欠損、不正型、未来の開始日時、負の距離、空の天気など復元不能な値は通常モードへ戻し、一時データを安全に無効化する。
- 起動時はsessionIdをSQLiteと照合し、保存済みなら一時データ削除が再度失敗しても配達中へ復元しない。

## 計算設定の既定値

- 平均燃費10.0km/L、ガソリン単価170円/Lを、未保存時にも正式な設定値として表示・検証・計算に使用する。
- 計算設定は`calculation_settings`キーのJSON 1件として保存・読込する。旧`average_fuel_efficiency`と`gasoline_price`が存在しJSONが未作成の場合、JSON保存成功後に旧キーを削除する。保存失敗時は旧キーを保持する。
