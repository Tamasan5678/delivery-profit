# Portraitレスポンシブ検証レポート

実施日: 2026-08-02  
環境: Windows / Flutter debug / Android Emulator `emulator-5554`

## 結果概要

| 項目 | 結果 |
|---|---|
| `flutter pub get` | 成功 |
| `flutter analyze` | No issues found |
| `flutter test --reporter expanded` | 73件成功、失敗0 |
| `flutter build apk --debug` | 成功 |
| `git diff --check` | exit code 0 |
| 360dp Widgetテスト | 成功 |
| 411dp Widgetテスト | 成功 |
| 480dp Widgetテスト | 成功 |
| 360dp・文字倍率2.0 | 成功 |
| RenderFlex／制約例外 | 修正後0件 |

既存テストは作業開始時点で65件あり、追加したレスポンシブテスト8件を含む73件が成功した。

## 再現と修正

修正前の診断では次を再現した。

1. 360x640dpのHome上段2カードで、それぞれ右方向へ15pxのRenderFlex overflow。
2. 360x640dp・文字倍率2.0のWeatherScreenで、下方向へ41pxのRenderFlex overflow。

InfoCardの見出しを制約内で最大2行にし、数値を必要時のみscaleDownした。WeatherScreenは通常の縦配置を保ったままスクロール可能にした。修正後、同じ診断と正式テストはいずれも例外0件で成功した。

## 画面テスト範囲

360x640、411x891、480x960の各論理サイズで以下を描画し、Flutter例外、ErrorWidget、主要操作への到達を確認した。

- HomeScreen通常モード、配達中モード、日／週／月切替、長い正負数値
- StartDistanceScreen（前回距離、変更、次へ）
- TargetCountScreen（2桁、次へ）
- WeatherScreen（天気、開始）
- FinishInputScreen（時間、売上、件数、距離、保存）
- DailyResultScreen（全指標、ホームへ戻る）
- HistoryScreen（0件、複数件、カード）
- HistoryDetailScreen（全項目、削除）
- SettingsScreen（燃費、単価、保存）
- 6桁距離のScrollPicker BottomSheet（決定／キャンセル）
- 履歴削除確認Dialog（削除／キャンセル）

TargetSalesScreenと独立した保存前確認画面は実装に存在しない。入力用BottomSheetは共通Widgetのため、6桁距離ピッカーを全3幅で代表確認し、既存テストで時間・売上・件数・設定ピッカーも回帰確認した。

## 数値耐性

- 0円
- 999,999円
- -999,999円
- 1,000,000円
- 99件
- 23時間55分
- 999,999km
- 50.0km/L
- 300円/L
- 0.50L／件
- 1,600円／時間

保存範囲は変更せず、表示コンポーネントの耐性だけをFakeデータで確認した。

## 文字・表示サイズ

- 文字サイズ最大相当: 360x640dp、`TextScaler.linear(2.0)`で全主要画面と主要ボタンへの到達を確認し、レイアウト例外0件。
- 表示サイズ最大相当: 最小論理幅360dp条件で確認。Android端末設定そのものの「最大」プリセット操作は未実施。

## Emulator

- 720x1280 / 320dpi（360dp）
- 1080x2424 / 420dpi（約411dp）
- 1440x2880 / 480dpi（480dp）

各条件でcold相当のforce-stop後に起動しHomeを表示。Homeスクリーンショットを保存した。重大ログ検索ではFATAL EXCEPTION、E/flutter、Unhandled Exception、RenderFlex overflow、setState after dispose、BoxConstraintsを検出しなかった。既存データを保持する`install -r`を使用し、DB、履歴、SharedPreferencesの消去・保存・削除操作は行っていない。

## 回帰

全73件成功により、SQLite保存、sessionId重複防止、設定JSON、前回終了距離、配達中復元、期間集計と競合防止、多重push防止、履歴CRUD、月次集計、古いデータ保持の既存テストに回帰は検出されなかった。

## 未確認事項・残るP2

- iOSプロジェクトが存在しないためInfo.plistおよびiPhone実機は未確認。
- Emulatorで開始から保存・結果・履歴までの一連操作は、本番相当データを変更しない制約から実施せず、Widget/Fakeテストで確認した。
- Androidの表示サイズ「最大」プリセットそのものは未確認。論理幅360dpと文字倍率2.0の組み合わせで代替確認した。
- 360x640dpのHomeは情報量が多く、下部指標を見るにはスクロールが必要。操作不能やoverflowではないが、将来の小型端末UX改善候補。
