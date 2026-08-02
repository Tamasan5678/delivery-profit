# Portrait固定 検証報告

実施日: 2026-08-02

## 自動テスト

### 起動方向

Platform channelを監視し、Flutter起動時設定が次の1件だけを送信することを確認した。

```text
DeviceOrientation.portraitUp
```

LandscapeLeft、LandscapeRight、PortraitDownは含まれない。

### 主要画面

1080×2424のPortrait Widgetテスト面で確認した。

| 画面 | 結果 |
|---|---|
| HomeScreen | 正常、overflowなし |
| StartDistanceScreen | 正常、overflowなし |
| TargetCountScreen | 正常、overflowなし |
| WeatherScreen | 正常、overflowなし |
| FinishInputScreen | 正常、overflowなし |
| DailyResultScreen | 正常、overflowなし |
| HistoryScreen | 正常、overflowなし |
| HistoryDetailScreen | 正常、overflowなし |
| SettingsScreen | 正常、overflowなし |

すべてErrorWidgetなし、`tester.takeException()`なし。

「目標売上」はPreferencesServiceに保存APIがあるだけで独立画面および現行開始フローが存在しないため、画面確認対象は実装済みのTargetCountScreenとFinishInputScreenの売上入力とした。

## Android Emulator

環境:

- device: emulator-5554 / sdk_gphone16k_x86_64
- package: `com.example.delivery_profit_v2`
- debug APKを`adb install -r`で上書きし、アプリデータを保持
- 通常状態: 自動回転有効、user rotation ROTATION_0

確認手順:

1. Portrait対応後のdebug APKを起動。
2. 自動回転を一時停止し、端末へROTATION_90を要求。
3. WindowManagerとActivity構成を確認。
4. 端末の自動回転設定を元へ戻す。

横回転要求中の結果:

- MainActivityがcurrent focus
- `mCurrentConfig`: `port`
- Activity bounds: `1080×2424`
- DisplayFrames: `w=1080 h=2424 r=0`
- `mRotation=ROTATION_0`
- user request: `ROTATION_90`

端末が横向きを要求してもDelivery ProfitはPortraitUpを維持した。確認後は`accelerometer_rotation=1`、`user_rotation=0`へ復元した。

## Android二重設定

- Flutter: PortraitUpのみ
- Android Activity: `screenOrientation="portrait"`

両方とも同じPortraitUpを要求しており競合しない。Manifest設定によりFlutter初期化前のActivityもPortraitとなり、Flutter設定によりアプリ実行中の許可方向もPortraitUpだけとなる。

`android:configChanges`内の`orientation|screenSize`はFlutterテンプレートのActivity再生成制御であり、横画面を許可する設定ではないため維持した。

## コマンド結果

- `flutter analyze`: No issues found
- `flutter test`: 65件中65件成功
- `flutter build apk --debug`: 成功
- APK: `build/app/outputs/flutter-apk/app-debug.apk`

テストログ中のSQLite migration失敗、SharedPreferences clear失敗、保存失敗ログは、既存の意図的失敗テストによるもの。全テストの最終結果は成功。

## 未確認事項

- iPhone: iOSプラットフォームとInfo.plistがリポジトリに存在しないため未実装・未確認。
- iPad: 指示どおり対象外。
- PortraitDown:許可していないため未確認。
- 目標売上専用画面: 現行実装に存在しない。
- 小型端末・最大文字サイズで既報のHomeカードoverflowは本対応の範囲外。標準1080×2424 Portraitでは全対象画面に例外なし。
