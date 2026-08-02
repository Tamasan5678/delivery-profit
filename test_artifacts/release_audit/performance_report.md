# パフォーマンス監査報告

## 起動

- 標準Emulator cold start: `TotalTime=6098ms`, `WaitTime=6104ms`
- 小型画面条件: 約7155ms
- 小型 + font scale 2.0: 約7113ms
- 代表値: 約6.1秒、観測範囲約6.1～7.2秒
- 第1回監査約7.5秒よりは改善、第2回約5.6秒より約0.5秒悪化。ただしemulator計測で揺らぎがあり、回帰断定にはprofile実機計測が必要。

### 原因候補

- Flutter/Emulator cold start
- SQLite、SharedPreferences、active session、Home集計の初期化
- Homeの初回非同期読込
- 起動完了までFlutter雛形Splashが継続し、体感待ち時間を強調

## SQLite監査専用FFI測定

既存DBには触れず、一意名の監査専用一時DBを作成した。測定ログは`logs/sqlite_performance.txt`。

| 条件 | 結果 |
|---|---:|
| 100件全件読込 | 6,708 µs |
| 500件全件読込 | 7,677 µs |
| 500件期間検索 | 6,890 µs |
| 500件DBサイズ | 81,920 bytes |

確認index:

- `idx_delivery_records_finished_at`
- `idx_delivery_records_session_id`（UNIQUE）

## クエリ・描画

- 履歴一覧は単一クエリでありN+1ではない。
- 履歴詳細は一覧からDeliveryRecordを渡すため追加読込なし。
- 集計はSQLite集約クエリ1回。週/月表示では期間集計と当日集計の2回を逐次実行。
- HistoryScreenは全件取得・全モデル化でLIMIT/ページングなし。ListView.builderはWidget生成を遅延するがDB/モデル読込量は減らない。
- StartDistanceの最新距離フォールバックも全履歴を取得する。
- 不要なsetStateの重大ループは確認なし。Homeのrequest generationにより古い非同期結果は破棄される。

## 評価

500件までのデスクトップFFIクエリ時間は一桁msで良好。ただし端末UIで100/500件を投入したスクロールFPSは、既存データ非変更の制約により未測定。長期利用を考えると履歴ページングと最新1件専用クエリはリリース後早期に必要。起動は体感上遅く、profile実機でSQLite、preferences、first frame、fully drawnを分解計測すべき。
