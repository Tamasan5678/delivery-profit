# Delivery Profit V2 リリース前総合品質監査

実施日: 2026-08-02  
監査範囲: P2、P3、UI品質、操作性、Androidリリース設定、Google Play公開準備  
方針: 監査のみ。アプリコード、設計書、既存DB、履歴、SharedPreferencesは変更・削除していない。

## 総合判定

- P0: 0件
- P1: 0件
- P2: 8件
- P3: 5件
- `flutter analyze`: 成功（No issues found）
- `flutter test`: 49件中49件成功
- Release APK: 成功（47.2 MB、実サイズ49,536,374 bytes）
- Release AAB: 成功（46.9 MB、実サイズ49,161,632 bytes）
- 公開判定: **現状のままGoogle Playへ公開不可**
- 現時点の完成度: **78%**

P0・P1に相当する再現可能な回帰は、今回確認した範囲では検出しなかった。公開不可の主因は、`com.example`のApplication ID、debug証明書によるrelease署名、未完成のストア素材・法務情報、小型画面で再現したRenderFlex overflowである。

## テスト環境

- Windows / PowerShell
- Flutter SDK（プロジェクトの現行環境）
- Android Emulator: Pixel 9相当、1080×2424、density 420
- UIバリエーション: 720×1280、font scale 2.0、1440×3200
- SQLite性能: `sqflite_common_ffi`による監査専用一時DB
- Android解決値: minSdk 24、targetSdk 36、versionName 1.0.0、versionCode 1

## 主要結果

### UI

- 標準・大型画面のHome主要カードは正常表示。
- 720×1280でHome上段2カードに各15pxの横方向RenderFlex overflowを再現。
- 720×1280かつfont scale 2.0では見出し・説明が大きく折り返され、初期表示で情報カードが画面外になる。スクロールは可能だが情報密度と操作性が低下。
- アプリはlight themeのみで、dark theme/themeModeを定義していない。ダークモード対応は未実装。
- 起動時はFlutter標準ロゴの白いスプラッシュで、製品ブランドになっていない。
- 横画面はエミュレーター停止のため実機確認できず。`WeatherScreen`は固定ColumnとSpacerでスクロールを持たず、横画面・最大文字でoverflowするリスクが高い。

### SQLite・性能

- 100件全件読込: 約6.7 ms
- 500件全件読込: 約7.7 ms
- 500件期間検索: 約6.9 ms
- 500件時DBサイズ: 81,920 bytes
- index: `idx_delivery_records_finished_at`、UNIQUE `idx_delivery_records_session_id`を確認。
- 明確なN+1クエリは検出しなかった。
- 履歴一覧はLIMIT/ページングなしで全行を読み込み、全モデルへ変換する。件数増加時のメモリ・初期表示負荷が残る。
- StartDistanceのフォールバックも最新1件のために全履歴を読む。
- Homeは週/月選択時に期間集計と当日集計を逐次実行する。正当な2読込だが並列化余地がある。

### Android

- Application ID / namespace: `com.example.delivery_profit_v2`（公開用として不適切）
- 表示名: `delivery_profit_v2`（雛形名）
- version: 1.0.0+1
- minSdk: 24、targetSdk: 36
- release署名: Android Debug証明書（公開不可）
- debug署名: Debug証明書
- Adaptive Icon: 未構成（`mipmap-anydpi-v26`なし、foreground未設定）
- Splash: Flutter雛形の白背景・Flutterロゴ
- backup/data extraction policy: Manifestに明示なし
- 不要な危険権限: release manifestでは検出なし
- INTERNET: main/releaseにはなし。debug/profileのみ。
- network security config / cleartext方針: 明示なし
- Proguard / shrinkResources / minifyEnabled / R8: release用の明示設定なし
- Release APK/AAB自体は生成成功。

### 設計書整合

実装済みSQLite、履歴、日週月集計、設定保存、開始フローがREADME、project_rules、roadmap、requirements、screen_design、navigation、architecture、database、changelogの一部で未実装・将来予定として残っている。空の設計書も8件ある。今回は指示どおり変更していない。

## 指摘一覧

### P2-01 公開用Android識別子・署名が未設定

- 対象: `android/app/build.gradle.kts`、`AndroidManifest.xml`
- 実際: `com.example.delivery_profit_v2`、表示名`delivery_profit_v2`、releaseがdebug署名。
- 期待: 確定した逆DNS ID、製品名、保護されたrelease key / Play App Signing。
- 影響: Google Play本番公開不可。後からApplication IDを変えると別アプリ扱い。
- 再現率: 100%
- 修正案: 公開IDと表示名を確定し、keystore情報をリポジトリ外で管理してrelease signingを構成。

### P2-02 小型画面・最大文字でレスポンシブ崩れ

- 対象: HomeScreen、InfoCard、横画面リスクのあるWeatherScreen
- 再現: 720×1280でHomeを開く。
- 実際: 上段2カードが各15px右overflow。font scale 2.0で初期情報量が大幅に低下。
- 期待: overflowなし、文字切れなし、主要操作へ到達可能。
- 影響: 小型端末・アクセシビリティ利用者。
- データ破損: なし
- 回避策: 標準表示サイズまたは縦長端末。
- 修正案: 2列を幅に応じ1列化、タイトルTextをFlexible化、固定Column画面をScrollView化。
- 証跡: `screenshots/05_small_ready.png`、`06_small_font2_ready.png`

### P2-03 起動が約6.1～7.2秒でスプラッシュが長い

- 対象: main初期化、Home初期読込、Splash
- 実際: 標準cold start `TotalTime=6098ms`。画面条件別で約7.1秒。起動中はFlutter標準ロゴ。
- 期待: ブランドを保ちながら体感待ち時間を短縮。
- 原因候補: Flutter/Emulator cold start、SQLite・SharedPreferences・Home集計の逐次初期化。
- 修正案: 起動計測をprofile実機で分解し、独立I/Oの並列化、ブランドスプラッシュを検討。

### P2-04 履歴全件読込でスケールしない

- 対象: DeliveryRepository、HistoryScreen、StartDistanceScreen
- 実際: 履歴はLIMITなし、100/500件とも全件モデル化。StartDistanceの最新値フォールバックも全履歴取得。
- 期待: 最新順ページング、最新1件専用クエリ。
- 影響: 長期利用時の初期表示・メモリ・スクロール性能。
- データ破損: なし
- 修正案: LIMIT/OFFSETまたはカーソル式ページングとlatest query。

### P2-05 Android公開品質設定が未完成

- 対象: icon、splash、Manifest、Gradle
- 実際: Adaptive Iconなし、雛形Splash、backup方針なし、minify/shrink/R8設定なし。
- 期待: ブランドアイコン・Splash、バックアップ対象の明示、release最適化方針を決定。
- 影響: 見栄え、復元時のローカルデータ整合、APKサイズ・難読化。

### P2-06 Google Play提出素材・申告が未準備

- 実際: Feature Graphic、ストア用スクリーンショット、短文/詳細説明、プライバシーポリシー、データ安全性、年齢区分、問い合わせ先、著作権表記を確認できない。
- 期待: Play Console提出前に全項目を用意し、アプリ実態と一致させる。
- 影響: 審査提出不能または差戻し。

### P2-07 設計書が実装状態と矛盾

- 対象: READMEおよびdocs群
- 実際: 実装済み機能が未実装・将来予定として残り、8ファイルが空。
- 期待: リリース版の機能、DB version、画面遷移、保存方式と一致。
- 影響: 保守、審査資料、回帰判断を誤る。

### P2-08 日付集計のタイムゾーン意味が端末設定依存

- 対象: DeliveryRecord日時保存、期間集計
- 実際: UTC絶対時刻を保存し、端末の現在タイムゾーンで日週月境界を生成するため、端末TZ変更後に過去記録の所属日が変わり得る。
- 期待: 製品仕様として「記録時ローカル日」か「現在TZで再解釈」かを確定。
- 影響: 海外移動・TZ手動変更時の集計表示。

### P3-01 ダークモード未対応

- light theme固定。対応予定の有無とストア説明上の扱いを明示する。

### P3-02 Homeの期間と「今日」の情報階層が曖昧

- 日週月タブを切り替えても上段は今日、下段は選択期間であり、初見で範囲を誤認しやすい。期間ラベルと見出しを強化する。

### P3-03 「利益が分かる」価値訴求が弱い

- 利益値は表示されるが、売上→ガソリン代→利益の因果がHomeで一目にならず、PR文「あなたは、この配達の利益、分かりますか？」への導線がない。
- 提案: Home最上部を利益ヒーロー表示にし、売上・燃料費・利益の3段内訳、前回/期間比較、開始前の短い問いかけを追加候補とする。新機能ではなく次期UI提案。

### P3-04 未使用・古い資産/APIが残る

- `assets/icons/`指定に対して実フォルダなし、結果の一部や互換APIなど未使用要素が残る。削除は今回未実施。

### P3-05 アクセシビリティ仕上げが不足

- font scale 2.0のレイアウト最適化、アイコン/絵文字のsemantics、色コントラストの定量確認が未完了。

## 未確認項目

- 横画面実操作: 設定変更時にエミュレーターが停止したため未確認。端末設定は標準状態へ復元済み。
- 履歴100件・500件の端末UIスクロールFPS: 既存DBを変更しない制約により未投入。監査専用FFI DBのSQL性能のみ測定。
- 削除を伴う履歴操作: 既存履歴を保護するため今回未実施。
- Play Console内の実アカウント設定、連絡先、コンテンツレーティング回答: ローカルリポジトリから確認不能。
- release実機のprofile計測: APK/AABビルドとemulator cold startまで。

## 優先順位

1. 公開Application ID・表示名・release署名を確定。
2. Homeの小型画面overflowと最大文字・横画面を修正し、端末マトリクスで再試験。
3. Adaptive Icon、ブランドSplash、backup方針を整備。
4. プライバシーポリシー、Data safety、ストア説明、Feature Graphic、スクリーンショット等を作成。
5. 起動性能をprofile実機で分解し、履歴ページングを導入。
6. 設計書を現行実装へ同期し、タイムゾーン仕様を確定。

## 結論

コア機能は静的解析・49件の自動テスト・releaseビルドを通過しており、今回の範囲でP0/P1回帰はない。一方、公開識別子/署名とPlay提出準備が未完了で、小型画面に再現可能なP2表示崩れがあるため、**現時点では一般公開不可**。これらを解消し、横画面・最大文字・大量履歴の端末再監査後に公開判定を更新する。
