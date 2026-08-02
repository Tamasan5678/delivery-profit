# サイクル1：保存データ整合性 テスト報告

実施日: 2026-08-02  
対象: 指定された保存データ整合性P1 5項目のみ

## 結果

|確認|結果|
|---|---|
|flutter pub get|成功、依存更新なし|
|flutter analyze|成功、No issues found|
|flutter test|34件すべて成功|
|git diff --check|終了コード0|
|flutter build apk --debug|成功|
|既存DB／履歴削除|なし|
|実SharedPreferences消去|なし|

## P1修正結果

### 1. ガソリン代の丸め順序

合格。0.5円境界を含め、ガソリン代をintへ確定後に利益を算出する。テストケースでは未丸め50.5円を51円として保存し、売上100円から利益49円を算出した。

### 2. 利益計算の統一

合格。新規保存は`profitYen = salesYen - fuelCostYen`。DeliveryRecordとSQLiteも同じ恒等式を要求する。結果、履歴、Home集計は保存済みfuelCostYen/profitYenを利用する。

### 3. 3段階検証

合格。

1. DeliveryRecord constructor/validate
2. DeliveryRepository.insertDeliveryRecord直前
3. SQLite version 3 CHECK制約

の順で検証する。

### 4. 不正値拒否

合格。負の売上・件数・時間・距離・燃料量・燃料代、NaN、Infinity、空sessionId、重複sessionId、終了<開始、燃費0以下／50超、単価100未満／300超、利益不整合を拒否する。

負の利益は、売上より正当な保存ガソリン代が大きい場合に成立する計算結果であるため、恒等式が一致する限り許容する。入力値や費用の負数は許容しない。

### 5. CalculationSettings単一JSON

合格。保存はsetString 1回。JSONがあれば旧キーを読まない。旧キーmigrationはJSON保存成功後だけ削除し、保存失敗時は旧値を保持する。破損・欠損JSONは既定値へフォールバックする。

## migration

- DB version 1の旧履歴3件をversion 3へmigration。
- 同一開始時刻を含むlegacy sessionId補完とUNIQUEを維持。
- 全既存カラム値を保持。
- CHECK制約付きテーブルへコピー。
- migration失敗時はversion 1、既存3件、旧スキーマへrollback。
- テストは専用FFI一時DBのみを使用し、既存ユーザーDBには触れていない。

## 例外表示

DatabaseException注入時、ログには技術情報を残すが、画面には「保存に失敗しました。もう一度お試しください」だけを表示し、CHECK/SQL文言を表示しないことをWidgetテストで確認した。

## 残るP1（今回の対象外）

- 前回終了距離が次回開始距離へ引き継がれない。
- 日／週／月切替の非同期競合。
- 主要遷移ボタンの多重push防止不足。

## 次サイクル推奨

次は前回終了距離の正式な値定義（終了オドメーターかセッション走行距離か）を設計で確定したうえで、保存成功後の永続化と次回開始値への復元を修正することを推奨する。期間競合・遷移guardは別サイクルとして扱う。

本サイクルでは次サイクルのコード変更を行っていない。

