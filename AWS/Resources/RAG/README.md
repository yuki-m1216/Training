apply順

embed_doc -> vector_database -> answer_user_query -> fe

https://dev.classmethod.jp/articles/pyenv-and-poetry/
https://qiita.com/ShotaDeguchi/items/d2e08c135f2eebaa624b#pyenv--pyenv-win
https://python-poetry.org/docs/managing-environments/#powershell
https://qiita.com/ksato9700/items/b893cf1db83605898d8a#3-%E4%BB%AE%E6%83%B3%E7%92%B0%E5%A2%83%E3%81%AE%E3%82%BB%E3%83%83%E3%83%88%E3%82%A2%E3%83%83%E3%83%97

使用するpythonのバージョン取得

```ps
pyenv install --list
pyenv install 3.10.5
```

pyenvでpythonバージョンを指定

```ps
pyenv local 3.10.5
python --version
```

poetryの初期化
質問はデフォルト(enter)で可

```ps
poetry init
```

poetry環境のインストール

```ps
poetry install
または
poetry install --no-root
```

Poetry環境をVSCodeに認識させる
https://qiita.com/yadgg/items/cce8aabc0921c2b5b22e

仮想環境のアクティブ

```ps
Invoke-Expression (poetry env activate)
```

仮想環境から抜ける

```ps
deactivate
```

パッケージ追加と削除

```ps
poetry add <package-name>
poetry remove <package-name>
```

layerコマンド

```ps
poetry run pip install --upgrade -r requirements.txt -t ./layer/python
```

```ps
poetry run pip install `
--platform manylinux2014_x86_64 `
--implementation cp `
--python-version 3.10 `
--only-binary=:all: `
--upgrade `
-r requirements.txt -t ./layer/python
```
