# 縦画面固定確認

実施日: 2026-08-02

## 実装

- Flutter: `main.dart`で`WidgetsFlutterBinding.ensureInitialized()`後、`SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`の完了を待ってから`runApp`
- Android: `MainActivity`へ`android:screenOrientation="portrait"`
- iOS: このリポジトリに`ios/`および`Info.plist`が存在しないため対象外
- Landscape専用Widget、`OrientationBuilder`、画面方向によるレイアウト分岐は存在しない

## 自動テスト

- orientation APIへPortraitUpだけが渡されることを確認
- AndroidManifestがportraitであることを確認
- LandscapeLeft、LandscapeRightを許可していないことを確認

## Emulator

- 対象: `emulator-5554`
- 360dp相当（720x1280、320dpi）でAndroidのユーザー回転をROTATION_90へ要求
- 要求中もアプリ／displayの`mRotation`は0、`mDisplayRotation`は`ROTATION_0`を維持
- 確認後、ユーザー回転と画面サイズ・密度を元へ復元

結論: Android EmulatorでLandscapeへ回転せずPortraitUpを維持した。
