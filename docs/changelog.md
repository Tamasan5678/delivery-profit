# 変更履歴

## 2026-08

- Portrait UIの最低品質基準を360dp、標準411dp、大型480dpとして正式化。InfoCardのタイトルをFlexible化し全数値を必要時scaleDown、WeatherScreenを縦スクロール可能にして、3幅・最大文字相当・長い数値・Dialog・BottomSheetのWidgetテストを追加。
- スマートフォンでの片手操作性を重視し、対応画面方向を縦画面（Portrait）のみに正式化。Flutter起動時をPortraitUpへ固定し、Android Activityもportraitへ統一。横画面はUI設計・テスト・品質保証の対象外とした。
- 前回終了距離を開始時総走行距離と今回走行距離の和としてSQLite保存後に保持し、次回開始画面へ復元。欠損時の最新実績復元と、履歴削除で巻き戻さない方針を追加。
- HomeScreenの日・週・月読込へgeneration counterを追加し、高速切替時の古い応答が表示とローディング状態を上書きしないよう修正。
- 配達開始・終了、開始フロー、履歴、結果、設定等の主要操作へ処理中フラグを追加・再利用し、多重push・INSERT・DELETE・設定保存を防止。
- ガソリン代を先に整数へ丸め、利益を売上から保存ガソリン代を引いて算出する方式へ統一。
- DeliveryRecord、Repository、SQLite version 3 CHECK制約の3段階検証を追加し、既存履歴を保持するmigrationと不正値拒否テストを追加。
- 平均燃費とガソリン単価をCalculationSettingsの単一JSONへ統合し、旧2キーからの初回migration、破損JSON、保存失敗テストを追加。
- 計算設定の未保存時も画面と同じ既定値を正式値として使用し、設定保存失敗時は表示を維持して通知するよう修正。
- 平均燃費とガソリン単価を一組で保存し、片方の保存失敗時に変更前の2値へ戻す処理とエラー注入テストを追加。
- テスト専用FFI SQLiteでversion 1 DBを再現し、version 2 migration、既存履歴保持、session_id補完、UNIQUE制約、migration後CRUD、失敗時ロールバックを検証するテストを追加。
- 配達開始時のsessionId、SQLite version 2 migration、session_id UNIQUE INDEXを追加し、保存済み一時セッションの復元と重複INSERTを防止。
- 履歴詳細画面、確認ダイアログ付き単件削除、削除後の履歴・Home集計再読込を追加。
- 配達中セッションをSharedPreferencesへ一時保存し、アプリ起動時に復元する処理を追加。SQLite保存成功後のみ一時データを無効化する。
- 旧Counter用widget_test.dartを現行Home・履歴仕様とFake依存へ更新し、配達中保存と境界計算のテストを追加。
- SQLiteの本日復元、同日複数セッション合算、月曜始まりの週別集計、月別集計をHomeScreenへ接続。
- 保存済みの利益・燃料実績を期間合計し、期間全体の件数・時間から平均値と時給を算出する処理を追加。
- HistoryScreenをHomeScreenから開き、終了日時の新しい順で配達実績を一覧表示する処理を追加。
- SQLite保存基盤（delivery_profit.db、delivery_records、DeliveryRecord、DeliveryRepository）を追加。
- 配達終了時点の設定・計算結果を固定保存し、保存成功時のみ本日の配達結果画面へ進む処理を追加。
- UTCミリ秒の日時保存、合計分によるオンライン時間保存、期間検索API、保存失敗時の再試行と二重保存防止を追加。
- SettingsScreen に平均燃費とガソリン単価のスクロール入力を追加し、SharedPreferences の保存値を利益計算へ接続。
- DeliveryCalculator に時給（利益 ÷ オンライン時間）を追加し、本日の配達結果画面と HomeScreen の日別出力へ常時表示。
- 時給は利益、時給、平均利益、平均走行距離、平均配達時間、平均消費ガソリンの順で表示。週別・月別は期間合計から算出する方針を追加。
- FinishInputScreen の保存後に「本日の配達結果画面」を表示し、そこから HomeScreen 通常モードへ戻る遷移へ変更。
- 結果画面に利益、平均利益／件、平均走行距離／件、平均配達時間／件、平均消費ガソリン／件を追加。
- HomeScreen の日別走行距離表示を平均走行距離／件へ統一。週別・月別も期間合計から1件当たり平均を算出する方針を明記。
- 結果画面の端末戻る操作で FinishInputScreen に戻らないよう、保存時に画面を置き換える方式を採用。

## 2026-07

- HomeScreen を通常モード／配達中モードの状態切替方式として整理。
- StartDistanceScreen、TargetCountScreen、WeatherScreen による配達開始フローを追加。
- FinishInputScreen を追加し、オンライン時間・売上・件数・距離の入力を可能にした。
- DeliverySession を導入し、目標件数と天気を配達中状態として受け渡すようにした。
- FinishInputResult を導入し、配達終了結果を HomeScreen へ返すようにした。
- 未入力・不正数値時の SnackBar バリデーションを追加。
- 配達終了画面から戻った場合に配達中状態を維持する遷移を整理。
- 共通ウィジェット（挨拶ヘッダー、情報カード、主要ボタン、オプションボタン）を利用。
- PreferencesService に開始距離、終了距離、目標件数、目標売上の保存・取得 API を追加。

## 未完了として把握している事項

- 開始距離・目標件数の編集 UI と保存処理。
- SQLite 履歴保存および履歴画面との接続。
- 利益計算、分析、CSV 出力、バックアップ、グラフ表示。
