# Android リリースチェックリスト

## 識別・バージョン

- [ ] Application IDを`com.example.delivery_profit_v2`から公開用IDへ変更
- [ ] namespace/package構成を公開用IDと整合
- [ ] 表示名`delivery_profit_v2`を正式製品名へ変更
- [x] versionName設定あり: 1.0.0
- [x] versionCode設定あり: 1
- [x] minSdk解決値: 24
- [x] targetSdk解決値: 36
- [x] 2026-08-31以降の新規/更新提出に必要なAPI 36を満たす

## 署名・ビルド

- [ ] release用keystoreを安全に作成・保管
- [ ] release signingConfigをdebugから分離
- [ ] Play App Signing方針を確定
- [x] Release APKビルド成功
- [x] Release AABビルド成功
- [ ] 本番署名AABを内部テストへ提出してインストール確認
- [ ] minifyEnabled / shrinkResources / R8 / Proguard方針を決定
- [ ] 難読化を有効にする場合、mapping保管と回帰試験

## UI資産

- [ ] Adaptive Icon foreground/backgroundを作成
- [ ] `mipmap-anydpi-v26`のAdaptive Iconを構成
- [ ] ブランドSplashへ置換
- [ ] 小型画面Home overflowを解消
- [ ] 横画面とfont scale 2.0を再試験
- [ ] ダークモード非対応を製品仕様として判断

## Manifest・データ保護

- [x] release manifestに危険権限なし
- [x] main/releaseにINTERNET権限なし
- [ ] `allowBackup` / `dataExtractionRules` / `fullBackupContent`方針を明示
- [ ] SQLiteとSharedPreferencesのバックアップ・復元整合を確認
- [ ] cleartext traffic / network security configを将来通信導入時に明示
- [ ] exported componentを最終manifestで確認

## 品質

- [x] `flutter analyze`: No issues found
- [x] `flutter test`: 49/49成功
- [ ] profile実機で起動時間を測定
- [ ] 履歴100件・500件の端末スクロール性能を測定
- [ ] 横画面・最大文字・表示サイズ最大を端末マトリクスで確認
- [ ] 設計書と実装を同期

## 公式要件参照

- Target API: https://support.google.com/googleplay/android-developer/answer/11926878
- App signing: https://developer.android.com/studio/publish/app-signing
