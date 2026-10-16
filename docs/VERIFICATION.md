# 公開版の検証

検証時刻は2026/10/16 01:35:37 UTCです。
MATLAB 26.2.0.3386108 (R2026b)、Simulink、Aerospace Blocksetを使用しました。
公開版だけをMATLABのパスと現在のフォルダに設定して実行しています。

**73件成功、失敗0件、未完了0件**でした。
[テスト結果](verification/tests.csv)と[実行結果](verification/summary.json)を保存しています。

計算ソースの集約SHA-256は `fe29f1cbc61c1033240d06ca93c5d2b35bbaece96d46e745e86577f4dc2c4edc` です。
MATLABの記録値とPythonによる独立した再計算値を照合しました。

## 操作で確認したこと

- 最初の画面から架空デモを計算し、構造の結果を表示。
- mmとGPaによる入力とSIへの変換、不正な編集の拒否。
- 入力を変えた際の結果とレポートへの操作の無効化。
- レポート保存とHTMLの生成。
- Simulinkによる姿勢を含む飛行とMATLAB方程式の比較。
- 燃焼後の同一時刻の構造荷重への受渡しと、構成の編集禁止。
- 公開版にローカル資料の読込拡張がないこと。
- 初期ウィンドウが画面内に収まることと、画像の縦横比から切れがないこと。

構造荷重の最大釣合い残差は、合力 2.365616e-14 N、合モーメント 3.093036e-15 N mでした。
全機の状態は `not_evaluated` です。
架空機体の有限区間に対する検証であり、実機の飛行予測や安全性の実証を表しません。

## 画面

[最初の画面](images/home.png)、[構造の結果](images/structure.png)、[入力](images/input.png)、[部材の評価](images/checks.png)、[レポート](images/report.png)、[飛行](images/flight.png)、[小さいウィンドウ](images/home_compact.png)を保存しています。

## 再実行

MATLABで `addpath('tools'); verify_release` を実行します。
この受入検証にはSimulinkとAerospace Blocksetが必要です。
検証結果と画像は `work/release_verification` へ保存します。
