# GLB_ARViewer

`GLB_ARViewer` は、GLBモデルをiPhone上でAR表示し、写真・動画で記録できる iOS アプリです。

## 主な機能

- GLBファイルの読み込み（`glb` のみ選択可能）
- AR空間への3Dモデル表示
- モデル操作
  - 移動
  - 回転
  - 拡大・縮小
- 自動回転トグル
- 写真撮影・保存
- 動画撮影・保存
- モデル一覧
  - 一覧表示
  - 左スワイプ削除
  - 長押しで名前変更
- How to Use / Settings シート
- 下部バー上のAdMobバナー表示（Home / List）

## 動作環境

- macOS
- Xcode 26.2 以降
- iOS 18.6 以降（プロジェクト設定）
- 実機推奨（ARKit利用のため）

## 依存パッケージ

- [GLTFSceneKit](https://github.com/magicien/GLTFSceneKit)
- [Google Mobile Ads SDK for iOS (Swift Package)](https://github.com/googleads/swift-package-manager-google-mobile-ads)

## セットアップ

1. リポジトリをクローン
2. `GLB_ARViewer.xcodeproj` をXcodeで開く
3. Signing & Capabilities で Team を設定
4. 実機を選択してビルド・実行

## AdMobについて

現在は動作確認用に Google のテストID を使用しています。

- App ID: `ca-app-pub-3940256099942544~1458002511`
- Banner Ad Unit ID: `ca-app-pub-3940256099942544/2934735716`

本番配布時は必ず自分のAdMob IDへ差し替えてください。

## 使い方（概要）

1. Home画面で `Open 3D Model` を押してGLBファイルを選択
2. AR画面でモデルを確認・操作
3. 必要に応じて写真/動画を保存
4. 一度表示したモデルは List から再選択可能

## 注意事項

- AR表示品質は端末センサー状態・環境光に影響されます。
- カメラ権限が未許可の場合、AR表示は利用できません。
- 録画/保存には端末の空き容量が必要です。

