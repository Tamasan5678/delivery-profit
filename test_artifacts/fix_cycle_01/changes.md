# サイクル1：保存データ整合性 変更内容

## 対象P1

1. ガソリン代を先に整数へ丸める。
2. 利益を`売上 - 保存ガソリン代`へ統一する。
3. DeliveryRecord、Repository、SQLiteの3段階検証を追加する。
4. 負数、非有限値、日時逆転、空・重複sessionId、範囲外設定、利益不整合を拒否する。
5. 計算設定を単一JSON保存へ変更し、旧2キーを安全にmigrationする。

## 実装

### 計算

- DeliveryCalculatorのガソリン代と利益を保存単位のintへ変更。
- ガソリン使用量 → 未丸めガソリン代 → int丸め → 利益の順に固定。
- 利益は必ず`sales - gasolineCost`。
- 保存済み集計はDeliveryTotalsのfuelCostYen/profitYenをそのまま使用し、現在設定から再計算しない。
- FinishInputScreen、DailyResultScreen、History、Homeは同じ保存済み整数値を使用。

### Model / Repository / SQLite

- DeliveryRecord生成時にvalidateを必ず実行。
- RepositoryのINSERT直前にもvalidateを再実行。
- DB versionを2から3へ更新。
- version 3 migrationは制約付き一時テーブルへ既存行をコピーし、成功後だけ旧テーブルと置換。
- sales、件数、時間、距離、燃費、単価、燃料量、燃料代、日時、sessionId、利益恒等式へCHECKを追加。
- sessionId UNIQUE INDEXを維持。
- migration途中の失敗はSQLite transactionによりrollbackし、既存DBを削除しない。
- 保存例外はFinishInputScreenで汎用日本語メッセージへ変換し、SQL文言を画面へ表示しない。

### CalculationSettings JSON

- 新規`CalculationSettings`モデルを追加。
- SharedPreferences正本キーを`calculation_settings`へ統一。
- JSON形式: `{"fuelEfficiency":10.0,"fuelPrice":170}`。
- 保存はsetString 1回、読込はJSON 1回。
- JSONが未作成の場合だけ旧`average_fuel_efficiency`、`gasoline_price`を読む。
- 旧値が有効ならJSON保存を1回行い、成功後だけ旧キーを削除。
- JSON保存失敗時は旧キーを保持し、既存設定値をそのまま利用。
- 破損JSON、欠損JSON、型不正、範囲外は正式既定値10.0/170へ安全にフォールバック。

## 変更ファイル

### アプリ

- `lib/models/calculation_settings.dart`（新規）
- `lib/models/delivery_record.dart`
- `lib/services/preferences_service.dart`
- `lib/services/delivery_calculator.dart`
- `lib/repositories/delivery_repository.dart`
- `lib/database/app_database.dart`
- `lib/screens/finish/finish_input_screen.dart`
- `lib/screens/finish/daily_result_screen.dart`
- `lib/screens/settings/settings_screen.dart`

### テスト

- `test/models/delivery_record_test.dart`
- `test/repositories/delivery_repository_test.dart`
- `test/services/delivery_calculator_test.dart`
- `test/services/preferences_service_test.dart`
- `test/screens/settings_screen_test.dart`
- `test/widget_test.dart`

### 設計書

- `docs/architecture.md`
- `docs/changelog.md`
- `docs/database.md`
- `docs/decisions.md`
- `docs/requirements.md`

`README.md`、`docs/project_rules.md`、`docs/roadmap.md`は変更していない。

## テスト追加・更新

- Model: 空sessionId、負数、NaN、Infinity、日時逆転、利益不整合。
- Calculator: 0.5円境界でガソリン代51円、利益49円となり1円ずれないこと。
- Saved calculator: 保存済みfuelCost/profitを再計算せず使用。
- Repository/SQLite: v1→v3履歴保持、CRUD、UNIQUE、各CHECK、NaN/Infinity、rollback。
- Preferences: JSON 1回保存、JSON読込、旧キーmigration、旧キー削除、migration保存失敗、通常保存失敗、破損JSON、欠損JSON。
- Settings widget: 旧キーがJSONへ移行され、保存失敗時に表示値を維持。
- Finish widget: DatabaseExceptionのSQL文言を表示せず、安全な保存失敗メッセージだけを表示。

## 保護事項

- 既存未コミット変更を保持。
- 既存DB、履歴、実SharedPreferencesを削除・初期化していない。
- git reset/clean/restore/checkout/commit/pushは未実行。
- 依存パッケージのupgradeは未実行。

