# VimMarkdownWordpress
vimからwordpressをmarkdown記法を使って記事の新規作成・編集が可能になるプラグインです
vimrepressをリスペクトして制作されています。
windows10/python3環境での使用を想定しています。

## 設定
起動時に自動的に`~/.vimMarkdownWordpress`が生成されます

```
##全体にかかわる設定

[core]
markdown_extension = extra,nl2br,
blog_list_num = 100
set_filetype = markdown
```

- markdown_extensions
    markdownの拡張機能をpipで取り込んでいるならば
    module名の追記をすることで有効化できます。
    fence_codeなどを追加するとテーブルの記入が快適になります。
- blog_list_num
    記事一覧を表示する際の一度に読み込む記事の数です。
- set_filetype
    記事を編集時に専用のバッファを記事IDごとに開きます。
    この際に`set filetype`を指定しますが、専用のハイライトなどを用意したい場合はこちらで指定してください。

```
##サイトごとの設定

[main]
user = user_name
password = wordpress_password
url = https://your_homepage_url/xmlrpc.php
```

- `[main]`はデフォルトで読み込むセクション名になっています。
    新しいセクション名を作成して複数のサイトを管理することも可能です。
- url
    xmlrpc.phpまでのパスを記載してください。local環境のwordpressにアクセスする場合はhttp://~になるかと思います。



## Command
- BlogList
    引数はありません。
    blog_list_numの数だけ記事一覧を出力します。
    ---- More List ---- で<enter>:追加の記事を同じ数だけ出力します。
    記事ID TITILE行     で<enter>:記事を開きます。
    また記事を開かずに別のバッファを開いた場合、Listバッファのみ自動で閉じます。
- BlogNew
    引数はありません。
    新規で記事を作成するためのテンプレートバッファを開きます。
- BlogSave
    引数 publish draft 無し
    テンプレートから情報を読み出し記事を保存します。
    引数を指定しない場合、draftを指定した場合は下書きとして保存されます。
    publishのみ公開状態で保存します。
- BlogOpen
    引数 記事ID
    IDの記事を開き編集可能の状態になります。
- BlogSwich 
    引数 セクション名
    指定したセクションを読み込み別のサイトに切り替えます。
    vim script`CompSwich`のlistを編集するとtabで補完してくれるようになります。
- BlogUpload
    引数 画像のpath
    画像ファイルをwordpressにアップロードしてhtmlタグを現在のカーソルの一行下に挿入します


## Requirements
python3
```
pip install markdown
pip install python-wordpress-xmlrpc
```

## License
MIT - license

## Author
ambergon 
[twitter](https://twitter.com/Sc_lFoxGon)
