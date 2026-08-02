# サイクル2 テスト報告

実施日: 2026-08-02

## 結果

| 確認 | 結果 |
|---|---|
| flutter pub get | 成功。依存更新・追加なし |
| flutter analyze | 成功。No issues found |
| flutter test | 49/49成功（既存34件 + 追加15件） |
| flutter build apk --debug | 成功 |
| git diff --check | 終了コード0 |
| Emulator | `install -r`成功、既存データを消去せずcold起動成功、Homeスクリーンショット取得 |
| logcat | 再起動後の対象パターンにアプリ重大エラーなし |

## 前回終了距離

- SharedPreferencesへの保存・再読込を確認。
- SQLite保存成功後に開始距離と今回走行距離の和を保存することを確認。
- 距離キャッシュ失敗時もSQLite INSERTが1回だけで、結果画面へ安全に進むことを確認。
- キャッシュ欠損時に最新DeliveryRecordから復元することを確認。
- 保存済み距離を開始画面へ初期表示し、手動変更できることを確認。
- 初回値なしでは現行既定値106,620kmを維持することを確認。
- 履歴削除後も保存済み車両距離を優先し、過去値へ巻き戻らないことを確認。

## 日／週／月競合

- 日の遅延応答より週を先に完了させ、遅い日応答が週表示を上書きしないことを確認。
- 月→日→週の要求を逆順に完了し、最後に選択した週だけを表示することを確認。
- 最新要求完了後にローディングが残らないことを確認。
- dispose後に遅延応答を完了してもsetState例外がないことを確認。

## 多重操作

- Home配達開始、StartDistance次へ、履歴カードのコールバックを同期的に2回実行し、Navigator pushが1回であることを確認。
- FinishInput保存を2回実行し、INSERTが1回であることを確認。
- 履歴削除開始と確認を2回実行し、ダイアログとDELETEが各1回であることを確認。
- Settingsの決定を2回実行し、設定保存が1回であることを確認。
- WeatherとFinishInputの既存処理中フラグ、TargetCount、DailyResult、Home配達終了・履歴・設定のguardは静的確認と全Widget回帰テストで確認した。

## 回帰

- 既存34件を含む全49件が成功した。
- SQLite migration失敗ログ、保存失敗ログ、active delivery clear失敗ログは意図的な異常系テストによるもの。全テストの最終結果は成功。
- debug APKをEmulatorへ上書きインストールし、既存アプリデータを消去せず起動できた。
- 今回の3件以外の仕様、計算式、DBスキーマ、依存関係は変更していない。

## 未確認

- Emulator上で全対象ボタンを人手で高速連打する一連の操作は、既存履歴・配達状態を不用意に変更しないため未実施。同期2回コールバックのWidgetテストで主要経路を確認した。
- SharedPreferences書込を端末実機で強制失敗させる試験は未実施。注入した失敗コールバックでSQLiteの二重保存防止を確認した。

## 成果物

- `flutter_pub_get.txt`
- `flutter_analyze.txt`
- `flutter_test.txt`
- `git_diff_check.txt`
- `build_result.txt`
- `logcat_filtered.txt`
- `logs/logcat_raw.txt`
- `screenshots/home.png`

