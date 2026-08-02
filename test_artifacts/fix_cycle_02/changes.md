# サイクル2 変更内容

実施日: 2026-08-02

## 修正したP1

1. 前回終了距離が次回開始距離へ引き継がれない
2. 日／週／月切替の非同期競合
3. 主要遷移ボタンの多重push防止不足

## 実装

- 終了距離を `開始時総走行距離 + 今回走行距離` と定義した。
- DeliveryRecordのSQLite保存成功後、結果画面へ進む前に既存SharedPreferencesキー `end_distance` へ整数で保存する。
- 距離キャッシュ失敗時もSQLite INSERTを再実行しない。次回開始時にキャッシュが欠損していれば、終了日時降順の最新DeliveryRecordから復元する。
- SharedPreferencesの終了距離が存在する場合はSQLite履歴より優先し、履歴削除では更新・巻き戻しを行わない。
- HomeScreenの期間読込へgeneration counterを追加し、最新リクエストだけが集計、エラー、ローディング状態を更新する。
- Home、開始距離、目標件数、履歴一覧へ遷移中フラグを追加した。
- Weather、FinishInputの既存フラグを維持し、DailyResult、HistoryDetail、Settings、共通スクロールピッカーにも多重操作防止を追加した。

## 今回変更したファイル

- `lib/services/preferences_service.dart`
- `lib/screens/finish/finish_input_screen.dart`
- `lib/screens/finish/daily_result_screen.dart`
- `lib/screens/home/home_screen.dart`
- `lib/screens/start/start_distance_screen.dart`
- `lib/screens/start/target_count_screen.dart`
- `lib/screens/history/history_screen.dart`
- `lib/screens/history/history_detail_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/widgets/scroll_picker_bottom_sheet.dart`
- `test/screens/cycle_02_regression_test.dart`
- `test/screens/settings_screen_test.dart`
- `docs/requirements.md`
- `docs/screen_design.md`
- `docs/architecture.md`
- `docs/changelog.md`
- `docs/decisions.md`

README.md、docs/project_rules.md、docs/roadmap.mdは変更していない。既存DB、履歴、SharedPreferencesの消去も行っていない。

