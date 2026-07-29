# 変更履歴

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
