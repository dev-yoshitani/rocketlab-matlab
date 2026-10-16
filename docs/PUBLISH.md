# GitHubへ公開する

このフォルダは、公開対象のソースと架空デモだけを収めた版です。
作業用プロジェクトのフォルダや履歴を追加でコピーしないでください。

## 公開前の確認

1. `Start.bat`からアプリを開き、デモを計算します。
2. [検証記録](VERIFICATION.md)で、確認済みの環境と範囲を確認します。
3. `python tools/check_public.py`で公開対象を点検します。
4. READMEの説明とスクリーンショットが、同梱の架空デモに対応しているか確認します。

## GitHub Desktopで公開する

ZIPを展開したフォルダの場合は、先にその場所にGitHub Desktopでローカルリポジトリを作成します。
作業済みの公開用フォルダには、公開対象だけの初期コミットを用意しています。

1. GitHub Desktopの`File`から`Add local repository`を選び、このフォルダを追加します。
2. `Publish repository`を押します。
3. リポジトリ名を入力します。例は`rocketlab-matlab`です。
4. 一般公開する場合は`Keep this code private`のチェックを外します。
5. 公開先のアカウントを確認して`Publish Repository`を押します。

手順は[ローカルリポジトリの追加](https://docs.github.com/en/desktop/adding-and-cloning-repositories/adding-a-repository-from-your-local-computer-to-github-desktop)と[既存プロジェクトの公開](https://docs.github.com/en/desktop/adding-and-cloning-repositories/adding-an-existing-project-to-github-using-github-desktop)に基づきます。
GitHubへの送信は、この操作を行った時点で発生します。

このソースはMIT Licenseで提供します。
実測データ、借用資料、製品本体を追加する場合は、それぞれの利用条件と公開範囲を確認してください。
