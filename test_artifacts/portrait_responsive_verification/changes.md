# 変更内容

実施日: 2026-08-02

## 対象

- Portrait UIの品質保証幅を360dp、411dp、480dpとして正式化
- 360dpで再現したHome上段InfoCardの横方向overflowを修正
- 360dpかつ文字倍率2.0で再現したWeatherScreen下端overflowを修正
- 3幅を共通条件で確認するWidgetテスト補助と回帰テストを追加

## アプリ変更

- `lib/widgets/info_card.dart`
  - 見出しを`Flexible`、最大2行に変更
  - 値を`Flexible`と`FittedBox(BoxFit.scaleDown)`で制約内へ収める
  - 色、角丸、余白、カードの意味は変更していない
- `lib/screens/start/weather_screen.dart`
  - `LayoutBuilder`、`SingleChildScrollView`、`ConstrainedBox`、`IntrinsicHeight`を組み合わせ、通常時の配置を維持しながら小型画面・文字拡大時に縦スクロール可能にした

## テスト変更

- `test/helpers/screen_size_test_helper.dart`
  - 360x640、411x891、480x960の論理サイズを共通定義
  - surface sizeと文字倍率をテスト終了時に復元
  - Flutter例外とErrorWidgetを抑制せず検出
- `test/screens/responsive_portrait_test.dart`
  - 全3幅の主要画面、Dialog、BottomSheet
  - 360dp・文字倍率2.0
  - 100万円、マイナス999,999円、99件、23時間55分、999,999km等の長い表示値

## 設計書変更

- `docs/project_rules.md`
- `docs/requirements.md`
- `docs/screen_design.md`
- `docs/architecture.md`
- `docs/changelog.md`
- `docs/decisions.md`

`README.md`と`docs/roadmap.md`は変更していない。Landscape専用コードは元から存在せず、削除はない。
