# Portrait Only 対応変更

実施日: 2026-08-02

## 実装

- `lib/main.dart`
  - Flutter binding初期化後、`runApp`より前に`SystemChrome.setPreferredOrientations`をawaitするよう変更。
  - 許可方向は`DeviceOrientation.portraitUp`だけ。
  - `portraitDown`、`landscapeLeft`、`landscapeRight`は許可していない。
- `android/app/src/main/AndroidManifest.xml`
  - MainActivityへ`android:screenOrientation="portrait"`を追加。
  - Androidの起動直後からFlutter初期描画後までPortraitUpと一致する設定にした。

## Landscapeコード調査

以下を全コードから検索した。

- Landscape専用Widget
- Landscape専用レイアウト／分岐
- `OrientationBuilder`
- `MediaQuery.orientation`
- `SystemChrome.setPreferredOrientations`
- `screenOrientation`

既存のLandscape対応コードは存在しなかったため、削除したコードはない。`MediaQuery.paddingOf`はモーダル下端のSafeArea余白取得であり、画面方向分岐ではないため維持した。

## 設計書

更新したファイルは指定された次の5件だけ。

- `docs/requirements.md`
- `docs/architecture.md`
- `docs/screen_design.md`
- `docs/changelog.md`
- `docs/decisions.md`

次の文言を正式仕様として記載した。

> Delivery Profitはスマートフォンでの片手操作性を重視するため、縦画面（Portrait）のみ対応とする。横画面（Landscape）はサポート対象外とし、UI設計・テスト・品質保証も縦画面のみを対象とする。

README.md、docs/project_rules.md、docs/roadmap.mdは今回変更していない。

## テスト

- `test/services/device_orientation_test.dart`
  - 起動設定が`SystemChrome.setPreferredOrientations`へPortraitUpだけを渡すことを検証。
- `test/screens/portrait_layout_test.dart`
  - 1080×2424 Portraitで主要9画面を表示。
  - ErrorWidgetおよびRenderFlex例外がないことを検証。

## iPhone

このプロジェクトの`.metadata`はAndroidプラットフォームだけを登録しており、`ios/`ディレクトリと`Runner/Info.plist`が存在しない。存在しないiOSプロジェクトを部分的に生成するとビルド可能な構成にならないため、今回はInfo.plistを新規作成していない。

iPhone対応を追加する際は、完全なiOSプラットフォームを生成した上で、iPhone用`UISupportedInterfaceOrientations`を`UIInterfaceOrientationPortrait`だけにし、Xcode/iPhone Simulatorまたは実機で確認する必要がある。iPadは今回の対象外。
