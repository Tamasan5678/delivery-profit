# Delivery Profit V2 総合品質監査報告

監査日: 2026-08-02  
対象: README、docs全17ファイル、lib全26 Dart、test全4 Dart（11テスト）、pubspec、Android主要設定、Git差分・未追跡物

## 結論

静的解析とAPKビルドは成功し、既存の同日エミュレータ証跡では起動・ホーム・設定・履歴表示にクラッシュはありません。一方、リリースを止めるべき重大不具合を3件、重要不具合を8件確認しました。特に「初回設定のまま保存不能」「INSERT後の一時データ消去失敗で完了セッションが復活・重複保存」「DBに重複防止がない」はデータ保存の信頼性に直結します。

## 重大（P0/P1）

### P0-1 初回起動時、表示されている既定設定のまま配達実績を保存できない

- 設定画面は既定値 10.0km/L、170円/L を表示する。
- `hasValidCalculationSettings()` はキーが実際にSharedPreferencesへ保存済みであることを要求し、キー未作成ならfalseを返す。
- FinishInputScreenはfalseの場合、SQLite INSERTを行わず設定入力を要求する。
- 再現: 新規インストール → 設定画面を一度も決定しない → 配達終了 → 保存。
- 期待: 画面に表示される有効な既定値で保存できる、または初回起動時に既定値を保存する。
- 実際: 「設定画面で平均燃費とガソリン単価を入力してください」で保存不能。
- 根拠: `preferences_service.dart:79-103`、`finish_input_screen.dart:59-67`。

### P0-2 SQLite保存後に配達中データの消去へ失敗しても成功扱いになり、再起動後に二重保存できる

- INSERT成功後の`activeDeliveryStorage.clear()`例外をログ出力だけで握りつぶし、結果画面へ進む。
- SharedPreferences側ではactiveが残り得るため、再起動すると完了済みセッションが配達中として復元される。
- 同じセッションを再度終了すると別レコードとしてINSERTされる。
- 期待: 完了済みセッションが復活しない。消去失敗時も原子的／冪等に完了状態を判別する。
- 根拠: `finish_input_screen.dart:117-130`、`active_delivery_storage.dart:77-89`。

### P1-1 重複INSERTをDBレベルで防止できない

- `delivery_records`にセッションIDや一意制約がない。
- Repositoryは常に通常INSERTで、再試行時の同一性判定がない。
- プロセス終了が「INSERT成功後～active消去前」に起きると、P0-2と同様に重複登録できる。
- `_isCompleting`は同一Widget内の連打だけを抑止し、クラッシュ／再起動／タイムアウト再試行には効かない。
- 根拠: `app_database.dart:18-39`、`delivery_repository.dart:12-20`。

## 重要（P1）

### P1-2 保存値の丸めにより `利益 != 売上 - ガソリン代` になり得る

- ガソリン代と利益を、丸め前のdoubleからそれぞれ独立に`round()`して保存する。
- 端数が0.5円となるケースで保存後の整数値が1円ずれる可能性がある。
- 期待: 保存する整数ガソリン代を確定後、`profitYen = salesYen - fuelCostYen` として会計上の恒等式を保つ。
- 根拠: `finish_input_screen.dart:112-115`。

### P1-3 設定保存失敗を検知せず画面だけ更新する

- SharedPreferencesの`setDouble`/`setInt`が返すboolを捨てている。
- SettingsScreenはawait後、成功確認なしで表示値を更新する。
- 再起動後に元値へ戻り、表示値と保存値が不一致になる可能性がある。
- 根拠: `preferences_service.dart:74-92`、`settings_screen.dart:47-65`。

### P1-4 保存済み設定値の範囲検証がない

- 画面入力範囲は燃費1.0～50.0、単価100～300だが、読み込み時はそのまま表示する。
- `hasValidCalculationSettings`も燃費>0、単価>0だけで、上限・下限を検証しない。
- 破損・旧版・外部書換えで燃費999、単価1などを利益計算へ使用できる。
- `getDouble`/`getInt`は保存型が違うと例外になり、SettingsScreenの`_loadSettings`にはcatchがない。
- 根拠: `preferences_service.dart:79-103`、`settings_screen.dart:26-33`。

### P1-5 配達中復元の検証が仕様より弱い

- targetCountは0以上のみで99以下を検証しない。
- weatherは非空だけで「晴れ・曇り・雨」に限定しない。
- `startedAt <= now`だけで異常に古い日時や、終了済みセッション識別を扱えない。
- 不正データclear自体に失敗すると毎起動で同じ不正状態を再処理する。
- 根拠: `active_delivery_storage.dart:41-72`。

### P1-6 開始距離と前回終了距離が永続化フローに接続されていない

- StartDistanceScreenは毎回106,620km固定で開始し、PreferencesServiceの終了距離を読まない。
- FinishInputScreenの「走行距離」はセッション走行量としてSQLiteへ保存されるだけで、終了オドメーターとしてPreferencesへ保存されない。
- 画面文言「前回終了走行距離を表示」と実装が不一致。
- 根拠: `start_distance_screen.dart:18-20,33-40`、`finish_input_screen.dart:182-190`。

### P1-7 Home期間切替に非同期競合がある

- 日／週／月を高速切替すると複数の`_loadSummary()`が並行実行される。
- リクエスト世代の確認がないため、古い要求が後から完了して現在選択中のラベルへ別期間の集計を上書きできる。
- `_isLoading`も先に完了した要求がfalseにし、後続要求中に古い値を表示し得る。
- 根拠: `home_screen.dart:67-95,211-221`。

### P1-8 主要遷移ボタンの連打で画面を複数pushできる

- Homeの配達開始／配達終了、開始距離の次へ、目標件数の次へ、下部履歴／設定に遷移中フラグがない。
- 高速連打で同じ画面が重なり、戻る順序やセッション開始フローが壊れる可能性がある。
- Weatherの開始だけは同期フラグで二重popを抑止している。
- 根拠: `home_screen.dart:122-180,311-319`、`start_distance_screen.dart:58-73`、`target_count_screen.dart:72-88`。

### P1-9 SQLite値の健全性・時系列制約がない

- NOT NULL以外のCHECK制約がなく、負数、開始>終了、範囲外件数、空天気をDBが受理する。
- RepositoryもNaN/Infinity、負値、日時順序を検証しない。
- `DeliveryRecord.fromMap`は強制cast中心で、破損・旧型データにFormat/TypeError相当が出ると一覧・Home集計全体が読めなくなる。
- 根拠: `app_database.dart:18-39`、`delivery_record.dart:51-71`。

## 中（P2）

### P2-1 起動が遅い

- 同日logcatでActivityのDisplayed/Fully drawnは+7.465秒。
- Homeは配達中復元とSQLite日集計を直列実行し、双方完了まで全画面ローディング。
- クラッシュや無限ロードではないが、低速端末では体感品質が悪化する。
- 根拠: `home_screen.dart:51-64`、`logs/startup_logcat.txt`。

### P2-2 履歴大量データで全件読込・全モデル化する

- SQLにLIMIT／ページングがなく、全件を一括取得してListViewへ渡す。
- Widget自体は遅延構築だが、DB読込とモデル生成のメモリ・待ち時間は履歴件数に比例する。
- 根拠: `delivery_repository.dart:33-41`。

### P2-3 Android製品設定が雛形のまま

- applicationId/namespaceが`com.example.delivery_profit_v2`。
- application labelも`delivery_profit_v2`で製品表示名と不一致。
- releaseがdebug署名を使用する。
- ストア配布不可／既存製品IDとの不一致リスク。
- 根拠: `android/app/build.gradle.kts:8-31`、`AndroidManifest.xml:3-6`。

### P2-4 仕様書間に多数の矛盾・古い記述がある

- READMEはSQLiteを「今後追加予定」とするが実装済み。
- project_rulesは「現在はメモリ管理／将来SQLite」とする。
- databaseはHome集計が再起動で失われる、FinishInputResult距離がintのみ等の古い説明を残す。
- changelogの「未完了」にSQLite・利益計算が残る。
- requirements/roadmapにも実装済み機能が未実装として残る。
- 空の設計書が8件ある（DB設計、TODO、画面設計、画面遷移図、開発ルール、開発履歴、計算式、命名規則）。

### P2-5 日付境界は端末タイムゾーン変更時に集計所属が変わる

- UTC保存とローカル半開区間検索自体は正しい。
- ただし過去レコードの所属日を「現在の端末タイムゾーン」で決めるため、旅行・設定変更後に日／週／月の所属が変わる。
- 配達時タイムゾーンを固定保存する仕様がないため、仕様判断が必要。

### P2-6 日／週／月の見出しが弱く、上部カードは期間切替と無関係

- 上部4カードは常に「今日」、下部のみ日／週／月切替。動作上は整合するが、スクロール位置によって現在期間と数値の関係を誤認しやすい。

## 軽微（P3）

- DailyResultScreenの`result`引数は保持するだけで表示・計算に未使用。
- `PreferencesService`の開始距離、終了距離、目標件数、目標売上APIは現在の画面フローで未使用。
- `pubspec.yaml`に`assets/icons/`を宣言するが対象ディレクトリは存在しない。
- docsのarchitectureディレクトリ図でhistory/settingsの配置表現が実ファイル構造とずれている。
- `git diff --check`はエラーなしだが、多数ファイルにLF→CRLF警告がある。
- `.dart_tool`、`build`、`.gradle`等は通常の生成物。禁止指定の`.dart_appdata`は見つからなかった。古いCounter本体コードは見つからない。

## 計算ロジック検証

指定値（燃費10.0、単価200、売上10,000、件数20、距離100km、時間300分）を実装式へ代入した結果:

- 使用量 10.0L: 一致
- ガソリン代 2,000円: 一致
- 利益 8,000円: 一致
- 時給 1,600円/時間: 一致
- 平均利益 400円/件: 一致
- 平均走行距離 5.0km/件: 一致
- 平均配達時間 15分/件: 一致
- 平均消費ガソリン 0.50L/件: 一致

0件・0分・燃費0はゼロ除算を避ける。負利益も計算可能。保存済み期間集計は現在設定で再計算せず、保存済み燃料量・費用・利益の合計を使うためこの点は仕様一致。ただしNaN/Infinityをサービス/API境界で拒否せず、独立丸め問題はP1-2のとおり。

## DB・集計の適合状況

- DB名、version 1、delivery_records、終了日時インデックス: 一致。
- UTCミリ秒、ローカル日境界、開始以上・終了未満: 一致。
- 日は当日0:00～翌日0:00、週は月曜～翌月曜、月は1日～翌月1日: 実装式は月末・2月・うるう年・年またぎをDateTime正規化で処理可能。
- 同日複数セッション、期間全体合計から平均・時給: 一致。
- 一覧は終了日時降順、削除後は履歴再読込、Homeへ戻ると再集計: 一致。
- 実DBの初回作成、1件取得、期間検索、削除、接続競合、再起動保持を自動検証するテストは存在しない。

## 画面確認

既存の同日証跡を目視確認:

- Flutterスプラッシュ表示後、Home通常モード表示。
- 白画面、赤エラー、クラッシュ、無限ローディングなし。
- Homeに10,000円／25件／8:00、利益8,430円が表示され、履歴の同一レコードと一致。
- 設定画面に10.0km/L、157円/Lが表示。
- 履歴に日付、開始・終了、売上、利益、件数、時間、距離、天気を表示。
- ただし新規ADBアクセスは禁止されたため、今回のターンではピッカー境界、キャンセル、再起動復元、高速タップ、小型端末、詳細削除を再操作できていない。

## テスト・コマンド結果

- `flutter analyze`: 成功、No issues found（2.7秒）。
- `flutter test`: 11件存在。ただし3方式ともテスト開始前に無出力停止し、監査タイムアウト。成功／失敗は未確認。
- `flutter build apk --debug`: 既存の同日監査ログで成功（35.8秒）、APK 173,709,737 bytesを確認。
- Emulator install/start: 既存同日ログでpackage replace、force-stop、monkey起動、Activity表示を確認。アプリデータ消去ログなし。
- `git status --short`: 多数の既存変更・未追跡ファイルあり。保持済み。
- `git diff --stat`: 保存済み。
- `git diff --check`: whitespace errorなし。改行コード警告あり。
- Dart数: lib 26、test 4、合計30。テスト宣言11。
- format確認: 30ファイル中8件が標準formatと不一致（確認のみ、コードは変更していない）。

## テスト不足（優先順）

1. 初回既定設定でのFinish保存成功／失敗。
2. INSERT成功＋active clear失敗、プロセス中断、再試行の冪等性。
3. Repository/AppDatabaseの実SQLite CRUD、降順、半開区間、日週月境界、複数セッション。
4. 指定された標準計算ケースと0、負利益、端数丸め、大値、NaN/Infinity。
5. 設定の上下限、決定／キャンセル、保存失敗、不正型・範囲外値、再起動。
6. active sessionの未来／負距離／空・不正天気／件数100／型違い／clear失敗。
7. 全入力ピッカーの最小・最大・先頭ゼロ・キャンセル・小型画面。
8. 主要ボタン連打、期間高速切替、Navigator戻り値、結果画面から入力へ戻らないこと。
9. 履歴詳細全項目・単位・小数桁、削除失敗・二重削除、Home再集計。
10. 大量履歴の性能、起動時間、DB読込失敗時の再試行UI。

## 監査で変更したもの

アプリコード・設計書・既存DB・保存データは変更していない。変更対象は`test_artifacts/full_audit_20260802/`配下の監査ログと本報告のみ。Gitの既存未コミット変更は保持した。
