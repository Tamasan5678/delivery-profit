# Delivery Profit V2 総合品質監査 第2回

監査日: 2026-08-02（Asia/Tokyo）  
監査方式: コード／設計書全読、既存自動テスト、実SQLite FFI、debug APK、Android Emulator主要画面、logcat  
変更方針: アプリコード・設計書・DB・履歴・SharedPreferencesは変更しない。成果物のみ新規作成。

## 1. 暫定結論

- 再現可能なP0は確認されなかった。第1回P0-1/P0-2の対策はコードと自動テストで再確認できた。
- `flutter analyze`は0件、`flutter test`は22件全成功、debug APKもビルド成功。
- EmulatorでHome、設定、履歴、履歴詳細、開始距離、目標件数、天気の主要表示・遷移に成功し、アプリ由来の重大logcatはなかった。
- 一方、リリース前に解消すべきP1を6件確認した。前回終了距離、端数丸め、SQLite健全性、期間非同期競合、主要画面の多重push、設定ロールバック失敗時の非原子性である。
- このため暫定判断は「リリース不可（P1解消・回帰テスト追加後に再判定）」とする。「バグが完全にない」とは断定しない。

## 2. テスト環境と集計

|項目|結果|
|---|---|
|ホスト|Windows / PowerShell|
|Flutter/Dart|プロジェクト現行SDK（依存更新なし）|
|Emulator|Pixel_9 AVD、1080×2424、420dpi、Android 17|
|アプリ|com.example.delivery_profit_v2、1.0.0 (1)、minSdk 24、targetSdk 36|
|確認ファイル|92（docs 17、lib Dart 26、test Dart 8を含む）＋第1回報告/P0証跡|
|実装画面数|9|
|Emulatorで再操作した画面|7（Home、設定、履歴、履歴詳細、開始距離、目標件数、天気）|
|flutter pub get|成功。upgradeなし|
|flutter analyze|成功、No issues found|
|flutter test|22/22成功|
|APK|debugビルド成功（Gradle 58.2秒）|
|git diff --check|終了コード0|
|Dart format確認|34ファイル中8ファイルが標準形式と差異。確認のみで未変更|
|P0/P1/P2/P3|0 / 6 / 5 / 3|

## 3. 第1回P0・主要修正の再確認

### P0-1 初回既定設定

結果: **対策済み、再発なし（自動テスト＋コード）**。

- 未保存時の正式値は燃費10.0km/L、単価170円/L。
- `hasValidCalculationSettings()`も未保存時に同じ既定値を検証する。
- clear失敗注入Widgetテスト内の実保存経路で、DeliveryRecordへ10.0/170が格納されることを確認。
- SettingsScreenの表示も10.0を確認。Emulatorには既存単価157円が保存済みだったため、完全な新規端末UI保存は既存データ保護のため行っていない。
- 結果画面・履歴詳細は保存済みDeliveryRecordを使用し、現在設定で再計算しない。

### P0-2 保存済みsessionIdの一時データ復活・重複

結果: **対策済み、再発なし（Widget＋実SQLite FFI）**。

- Home起動時に一時sessionIdをRepositoryで照合し、SQLite保存済みなら復元しない。
- clear再試行が失敗しても通常モードへ進むWidgetテストが成功。
- session_id UNIQUE INDEXを実SQLiteで確認。
- 同一sessionIdの再INSERTは件数を増やさず既存IDを返し、異なるsessionIdは保存できる。
- migration失敗時にversion、列、既存3行がrollbackされるテストが成功。

### migration

結果: **FFI範囲は合格、Android実DBでのv1→v2再実行は未確認**。

- v1旧履歴3件、同一開始時刻2件、全カラム保持、legacy ID補完、一意性、UNIQUE INDEX、空／欠落sessionId拒否、rollback、migration後CRUD、再open保持を確認。
- Emulator上の既存DBファイル（28,672 bytes）は保持しており、削除・差し替え・v1へのdowngradeはしていない。
- Android上で安全に別パッケージ／別DBを用意する監査ハーネスがないため、Android実SQLite migrationの再現は未確認。

### 設定保存・ロールバック

結果: **通常成功と第2書込false時のrollbackは合格。rollback処理自体の失敗はP1-6**。

- 範囲は燃費1.0～50.0（0.1刻み）、単価100～300（1円刻み）。
- 既存保存値は起動時に上書きされない。
- 第2書込がfalseのテストでは元の2値へ戻り、画面も元値を維持してエラー表示する。
- 過去履歴は保存済み設定・燃料費・利益を表示するため、現在設定変更では変化しない。

## 4. 問題一覧

### R2-P1-1 前回終了距離が次回開始距離へ引き継がれない

- 重要度: P1
- 対象: `lib/screens/start/start_distance_screen.dart:19`、`lib/services/preferences_service.dart:55-71`
- 画面: 配達開始／配達終了
- 再現: 既存履歴の終了後にHomeから配達開始を開く。
- 実際: 履歴の走行距離100.0kmや保存済み終了値に関係なく106,620km固定。Emulatorでも106620を表示。
- 期待: 前回終了オドメーターを次回開始値に復元し、再起動後も維持。未存在時のみ定義済み初期値。
- 原因候補: `getEndDistance()`/`saveEndDistance()`が画面フローに接続されず、終了入力も総走行距離として扱われている。
- 影響範囲: 全配達開始。将来オドメーター差分計算を行う場合の記録信頼性。
- データ破損可能性: 中（現在の実績距離は別入力なので既存履歴を直接破損しない）。
- 再現率: 100%。
- 回避策: 毎回「変更する」で手入力。
- 修正案: 終了オドメーター仕様を確定し、完了成功後のみ保存、StartDistance初期化時に読込。負数・逆転・上限を検証。
- ログ: なし。
- スクリーンショット: `screenshots/06_start_distance.png`。

### R2-P1-2 保存丸めにより「利益 = 売上 − 保存済みガソリン代」が崩れる

- 重要度: P1
- 対象: `lib/screens/finish/finish_input_screen.dart:114-115`
- 画面: 配達終了、本日の結果、履歴詳細、集計
- 再現: ガソリン代の小数部が0.5円になる入力で保存する。
- 実際: `gasolineCost.round()`と`profit.round()`を独立計算し、保存整数の和が売上と1円ずれ得る。
- 期待: gas costを整数確定後、`profitYen = salesYen - fuelCostYen`。
- 原因候補: 丸め前doubleから2値を独立丸め。
- 影響範囲: 該当端数の全履歴、日週月合計。
- データ破損可能性: 低（履歴は保存できるが会計恒等式が不整合）。
- 再現率: 該当端数で100%。
- 回避策: なし。
- 修正案: 保存用fuelCostYenを一度算出し、profitを整数差分で算出。境界テスト追加。
- ログ/スクリーンショット: なし（コード式による確定）。

### R2-P1-3 SQLiteがsessionId以外の不正値を拒否しない

- 重要度: P1
- 対象: `lib/database/app_database.dart:32-50`、`lib/models/delivery_record.dart`、`lib/repositories/delivery_repository.dart`
- 画面: 保存、Home、履歴
- 再現: Repositoryから負数、範囲外単価、NaN/Infinity、終了<開始などを持つDeliveryRecordをINSERT。
- 実際: CREATE TABLEのCHECKは空session_idだけ。モデル／Repositoryにも包括検証がない。
- 期待: sales/count/minutes/distance/fuel値、有限性、燃費、単価範囲、日時順序等をアプリ境界とDB制約で拒否。
- 原因候補: v2変更をsessionIdだけに限定し、データ健全性migrationを未実装。
- 影響範囲: 破損データが1件でも強制castや集計結果へ波及し、Home／履歴全体が読めなくなる可能性。
- データ破損可能性: 高。
- 再現率: 不正API入力で100%。通常UIはピッカーにより多くを回避。
- 回避策: UI以外から書き込まない。
- 修正案: モデル検証、Repository fail-fast、DB CHECK、既存データ監査を伴う安全なmigration。技術例外はUIへ直接出さない。
- ログ/スクリーンショット: なし。現行FFIはsessionId制約のみ検証。

### R2-P1-4 日／週／月の非同期結果が選択順と逆転し得る

- 重要度: P1
- 対象: `lib/screens/home/home_screen.dart:84-105,234-237`
- 画面: Home期間集計
- 再現: DB応答をずらし、日→週→月または月→日→週を高速選択。
- 実際: 世代番号／選択期間の再照合がなく、古いFutureが後完了すると現在ラベルへ古い期間値をsetStateできる。`_isLoading`も先行完了でfalseになり得る。
- 期待: 最後に選択した期間の要求だけが表示とloadingを更新。
- 原因候補: `_loadSummary()`が共有 `_summaryPeriod` と共有stateへ無条件反映。
- 影響範囲: Home集計の誤表示。DB保存値自体は壊さない。
- データ破損可能性: なし。
- 再現率: DB応答順次第。コード上競合経路は確実に存在。
- 回避策: 読込完了を待ってから切り替える。
- 修正案: request generation/token、ローカルperiod capture、最新要求のみ反映するWidgetテスト。
- ログ/スクリーンショット: 今回の実データが全期間同値のため視覚再現は未取得。

### R2-P1-5 主要遷移の多重push防止が不足

- 重要度: P1
- 対象: `home_screen.dart:139-186`、`start_distance_screen.dart:60-75`、`target_count_screen.dart:74-89`、`history_screen.dart:29-38`
- 画面: Home、開始距離、目標件数、履歴
- 再現: 配達開始、次へ、配達終了、履歴カード、設定等を高速連打。
- 実際: Weather開始、終了保存、削除には一部フラグがあるが、列挙箇所には遷移中フラグがない。今回のADB二連打では再現しなかったが、コード上はイベント受付を抑止しない。
- 期待: 遷移中は無効化し、失敗／戻り後に再操作可能。
- 原因候補: 共通ボタンが常時有効でFuture開始前にguardを立てない。
- 影響範囲: 画面スタック、開始フロー、複数読込。保存はUNIQUEと`_isCompleting`で二重INSERTを軽減。
- データ破損可能性: 低～中。
- 再現率: 端末・フレームタイミング依存。
- 回避策: 1回タップ後に遷移完了まで待つ。
- 修正案: 各遷移に同期guardとdisabled UIを導入し、高速タップWidgetテストを追加。
- ログ: Navigator例外なし。
- スクリーンショット: `screenshots/11_double_start_after_one_back.png`（今回の二連打は正常Home復帰）。

### R2-P1-6 ロールバック書込も失敗すると設定2項目の原子性を保証できない

- 重要度: P1
- 対象: `lib/services/preferences_service.dart:129-166`
- 画面: 設定
- 再現: 第1項目保存成功、第2項目失敗に加え、復元用の第1項目書込／removeも失敗させる。
- 実際: SharedPreferencesにtransactionはなく、復元結果falseを呼出元へ区別して返さない。復元がthrowすると後続項目を復元しない場合もある。
- 期待: 失敗後に必ず両方元値、または永続化方式上保証不能であることを仕様化し安全な一括形式を用いる。
- 原因候補: 2キー逐次書込＋best-effort rollback。
- 影響範囲: 稀なI/O障害時の設定不一致、再起動後の表示／計算。
- データ破損可能性: 中（設定のみ、履歴固定値は不変）。
- 再現率: rollback障害注入時100%。現行テストは第2書込false＋復元成功のみ。
- 回避策: 保存失敗後に設定を再確認・再保存。
- 修正案: 2値を1つのJSON/recordキーとして保存するか、世代付きcommit方式を採用。rollback自体の失敗テスト追加。
- ログ/スクリーンショット: なし。

### R2-P2-1 配達中復元の値域検証がUI仕様より弱い

- 重要度: P2
- 対象: `lib/services/active_delivery_storage.dart:54-66`
- 画面: Home配達中復元
- 再現: targetCount=100、weather=`台風`をテスト用SharedPreferencesへ保存してload。
- 実際: 件数は0以上、天気は非空なら復元する。
- 期待: 件数0～99、天気は晴れ／曇り／雨。
- 原因候補: 完全性検証のみでドメイン検証不足。
- 影響範囲: 外部書換え・旧版破損時の配達中表示。
- データ破損可能性: 低。再現率: 100%。回避策: 通常UIだけを使用。
- 修正案: ドメイン値域をstorage/model境界で検証。
- ログ/スクリーンショット: なし。

### R2-P2-2 SharedPreferences型破損で設定画面の非同期読込例外を処理しない

- 重要度: P2
- 対象: `preferences_service.dart:106-171`、`settings_screen.dart:35-43`
- 画面: 設定
- 再現: 燃費キーへString等の異型をテスト専用に保存し設定を開く。
- 実際: `getDouble`/`getInt`と`_loadSettings`にcatchがなく、非同期例外になり得る。
- 期待: 不正型を安全に拒否し、正式既定値またはエラーUIへフォールバック。
- 原因候補: generic `get`を使う検証と型別getterが分離。
- 影響範囲: 設定画面。データ破損可能性: なし。再現率: 異型時100%。
- 回避策: SharedPreferencesを外部変更しない。
- 修正案: 型安全な読込結果を1回で返し、画面でcatch／通知。
- ログ/スクリーンショット: なし。

### R2-P2-3 Androidリリース設定が雛形

- 重要度: P2（リリース前必須）
- 対象: `android/app/build.gradle.kts:8-32`、`AndroidManifest.xml:3`
- 画面: インストール名／配布
- 実際: namespace/applicationId=`com.example.delivery_profit_v2`、label=`delivery_profit_v2`、releaseがdebug署名。TODOも残る。
- 期待: 固有ID、製品名、release keystoreと安全な秘密管理。backup方針も明示。
- 原因候補: Flutter雛形のまま。
- 影響範囲: ストア公開、更新互換性、ブランド。データ破損可能性: package変更時は既存データを別アプリ扱いにする危険あり。
- 再現率: 100%。回避策: debug配布のみ。
- 修正案: リリースID／署名／移行方針を確定して別作業で設定。
- ログ: installed package 1.0.0(1), min24,target36。スクリーンショット: なし。

### R2-P2-4 設計書間・実装間に古い記述が残る

- 重要度: P2
- 対象: README、project_rules、requirements、database、architecture、changelog、roadmapほか
- 実際: READMEはSQLiteを将来予定、project_rulesは現在メモリ／将来SQLite、databaseはDB version 1・Home再起動で消失、architectureは日週月接続を今後扱い、changelog未完了にSQLite／利益計算、roadmapは実装済み設定・SQLite・履歴・週月・復元を未実装扱い。
- 期待: DB v2、sessionId、migration、設定一括保存、期間定義、現行遷移を一致させる。
- 原因候補: P0/P1修正後の部分更新。
- 影響範囲: 保守・次回変更判断。データ破損可能性: 間接的。
- 再現率: 100%。回避策: 実装とdecisions/changelogを併読。
- 修正案: P1解消後に正本を決めて一括同期。
- ログ/スクリーンショット: なし。

### R2-P2-5 履歴は全件一括読込で大量件数に比例して遅くなる

- 重要度: P2
- 対象: `delivery_repository.dart:46-54`、`history_screen.dart:43-52`
- 画面: 履歴
- 実際: LIMIT／ページングなしで全行取得・全モデル化。
- 期待: 十分な件数で性能基準を満たすか、ページング。
- 原因候補: MVP実装。
- 影響範囲: 長期利用者。データ破損可能性: なし。再現率: 件数依存。
- 回避策: 履歴件数を抑える（削除は不可逆なので推奨しない）。
- 修正案: keyset paginationと性能テスト。
- ログ: 現在1件では問題なし。スクリーンショット: `screenshots/04_history.png`。

### R2-P3-1 Dart標準formatとの差異が8ファイル

- 重要度: P3
- 対象: core/theme 3件、main、greeting_header、info_card、option_button、primary_button
- 実際: `dart format --output=none --set-exit-if-changed lib test`終了1、34中8差異。
- 期待: CI方針に応じて統一。
- 影響／破損: 動作影響なし。修正案: 別途formatのみの変更として扱う。

### R2-P3-2 空設計書と未使用asset宣言

- 重要度: P3
- 対象: docsの日本語名8空ファイル、`pubspec.yaml`の`assets/icons/`
- 実際: 空ファイルが残り、icons配下に対象ファイルなし。buildは成功。
- 期待: 正本統合または意図の明記。
- 影響／破損: 保守性のみ。

### R2-P3-3 未使用・重複気味のAPI／データ

- 重要度: P3
- 対象: `DailyResultScreen.result`、PreferencesServiceの開始／終了距離・目標件数・目標売上API
- 実際: resultは保持のみ、複数APIは現行画面から未接続。
- 期待: 次の仕様確定時に接続または整理。
- 影響／破損: 現在なし。古いCounter本体コードや重複クラスは未検出。

## 5. 機能別監査結果

|領域|結果|
|---|---|
|初回設定10.0/170|合格（自動）。新規端末UIは既存データ保護で未実施|
|重複保存防止|合格（UNIQUE＋Repository冪等）|
|保存済み一時データ復活防止|合格（clear失敗注入含む）|
|配達中復元|基本項目・未来日・負距離・欠損は実装確認。件数上限／天気enumはP2|
|migration|FFI合格。Android実v1→v2は未確認|
|設定範囲・刻み|実装一致|
|設定rollback|通常の部分失敗は合格。rollback失敗はP1|
|開始フロー|通常遷移、距離pickerキャンセル、目標、天気3種選択をEmulator確認|
|前回距離|不合格、P1|
|終了入力|picker範囲／キャンセル／0値はコード確認。Emulator保存は既存データ保護で未実施|
|指定計算例|10L、2,000円、8,000円、1,600円/h、400円/件、5km/件、15分/件、0.50L/件で一致|
|丸め恒等式|不合格、P1|
|SQLite健全性|sessionIdのみ合格、その他P1|
|結果画面|保存済みrecord基準、スクロール、入力へ戻らない構造を確認。Emulator未操作|
|日週月境界|DateTime半開区間はコード上正しい。複数期間の専用境界テスト不足|
|期間全体平均|保存済み合計から計算し、日平均の単純平均ではない|
|期間競合|不合格、P1|
|ボタン連打|ADBの配達開始二連打では再現なし。ただしguard欠如、P1|
|履歴|一覧・詳細の値一致、降順SQL、スクロール、削除確認実装。削除は既存データ保護のためEmulator未実行。Widget削除成功|
|画面崩れ|標準1080×2424の7画面でなし。最大文字はEmulator切断で未完了|
|ライフサイクル|cold restart後DB復元は確認。配達中／保存中／ダイアログ中の全状態は未確認|
|起動性能|cold Displayed/Fully drawn 5.578秒。前回約7.5秒より約1.9秒改善|
|logcat|アプリ由来重大エラーなし|

## 6. 設計書整合

- `database.md`のDB version 1は実装version 2と不一致。
- `database.md`のDeliverySession表にsessionId/startDistance/startedAtが欠落。
- README、project_rules、architecture、requirements、changelog、roadmapでSQLite・履歴・週月・復元・利益計算の実装状態が相互矛盾。
- navigation/screen_design/decisionsの新規経路は比較的現行に近い。
- 期間境界の実装はローカル日／月曜始まり／月初の半開区間で設計方針と一致。
- 計算式専用文書は空。実装の丸め規則を正本化できていない。
- 空ファイル: DB設計、TODO、画面設計、画面遷移図、開発ルール、開発履歴、計算式、命名規則。
- 今回は指示どおり文書を変更していない。

## 7. Git・構成・秘密情報

- 多数の既存未コミット変更・未追跡ファイルを保持。reset/clean/restore/checkout/commit/pushは未実行。
- `docs/roadmap.md`は未追跡。
- `build`、`.dart_tool`、`.gradle`は生成物。50MB超はbuild配下native libとdebug APKのみ。
- `.dart_appdata`は未検出。
- API key、private key、password等の一般的パターンは対象ファイルから未検出。ただし秘密情報が完全に存在しない保証ではない。
- LF→CRLF警告あり。`git diff --check`は0。
- README拡張子は正常な`README.md`。

## 8. 未確認項目と理由

- Android実DB v1→v2 migration: 既存ユーザーDBを変更せず別パッケージDBを作るハーネスがない。
- Emulatorで新規初回設定→終了保存→結果→履歴: 既存SharedPreferences／履歴を保護するためapp dataを消去しなかった。
- 保存中強制終了、配達中完全終了、削除ダイアログ中rotation: 既存状態への副作用を避けた。
- 全入力境界（23:55、999999、99、最大距離）と保存: 既存DBへテスト履歴を追加しないため未実施。
- 小型／大型／表示サイズ最大: 追加AVD未用意。
- 文字サイズ最大: 2.0設定後の起動中にEmulatorプロセスが切断し、画面描画後の判定ができなかった。再起動後に2.0だったことを確認し、1.0へ復元済み。
- 意図的DB応答遅延の期間競合: 注入可能なHome repositoryテストがない。コード上の競合を報告。
- 大量履歴性能: 既存履歴を増やさず未確認。
- release APK/署名: 今回の許可コマンドはdebug buildで、設定自体がdebug署名。

## 9. 修正優先順位

1. P1-3 SQLite/model/repository健全性と安全なmigration設計。
2. P1-2 保存整数の丸め恒等式。
3. P1-1 前回終了距離の仕様確定・保存・復元。
4. P1-4 期間要求の世代管理。
5. P1-5 主要遷移guard。
6. P1-6 設定の真に原子的な保存方式。
7. P2-3 Android製品ID・署名・表示名（package変更時のデータ移行方針を先に決定）。
8. P2の復元検証、設定破損耐性、履歴性能、設計書同期。

## 10. リリース可否

暫定 **リリース不可**。P0再発や自動テスト失敗、起動不能、重大logcatは確認されていないが、保存値整合性・DB健全性・主要集計競合を含むP1が残る。P1修正後、境界・競合・実Android migration・新規インストールE2Eを追加して再監査する必要がある。

## 11. 成果物

- コマンド結果: `flutter_pub_get.txt`、`flutter_analyze.txt`、`flutter_test.txt`、`build_result.txt`
- Git: `git_status.txt`、`git_diff_stat.txt`、`git_diff_check.txt`
- ログ: `logcat_filtered.txt`、`logs/`
- 対象一覧: `checked_files.txt`
- 画面証跡: `screenshots/01_home.png`～`screenshots/12_font_scale_2_home.png`（01/12は描画待ち・未完了証跡）
