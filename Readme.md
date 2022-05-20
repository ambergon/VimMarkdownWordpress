# VimMarkdownWordpress
vimからwordpressをmarkdown記法を使って記事の新規作成・編集が可能になるプラグインです<br />
vimrepressをリスペクトして制作されています。<br />
windows10/python3環境での使用を想定しています。<br />

## 設定
起動時に自動的に`~/.vimMarkdownWordpress`が生成されます<br />

```
##全体にかかわる設定

[core]
markdown_extension = extra,nl2br,
blog_list_num = 100
set_filetype = markdown
picture_autopreview = 0
picture_width       = 500
```

- markdown_extensions<br />
    markdownの拡張機能をpipで取り込んでいるならば<br />
    module名の追記をすることで有効化できます。<br />
    fence_codeなどを追加するとテーブルの記入が快適になります。<br />
- blog_list_num
    記事一覧を表示する際の一度に読み込む記事の数です。<br />
- set_filetype
    記事を編集時に専用のバッファを記事IDごとに開きます。<br />
    この際に`set filetype`を指定しますが、専用のハイライトなどを用意したい場合はこちらで指定してください。<br />
- picture_autopreview
    1を設定すると自動で画像のプレビューを表示します
- picture_width
    プレビューする画像サイズを指定します。

```
##サイトごとの設定

[main]
user = user_name
password = wordpress_password
url = https://your_homepage_url/xmlrpc.php
```

- `[main]`はデフォルトで読み込むセクション名になっています。<br />
    新しいセクション名を作成して複数のサイトを管理することも可能です。<br />
- url
    xmlrpc.phpまでのパスを記載してください。local環境のwordpressにアクセスする場合はhttp://~になるかと思います。<br />



## Command
- BlogList<br />
    blog_list_numの数だけ記事一覧を出力します。<br />
    ---- More List ---- で`<enter>`:追加の記事を同じ数だけ出力します。<br />
    記事ID TITILE行     で`<enter>`:記事を開きます。<br />
    また記事を開かずに別のバッファを開いた場合、Listバッファのみ自動で閉じます。<br />
- BlogNew<br />
    新規で記事を作成するためのテンプレートバッファを開きます。<br />
- BlogSave `[draft|publish]`<br />
    引数を渡さない場合はdraftとして扱います
    テンプレートから情報を読み出し記事を保存します。<br />
- BlogOpen `<POST_ID>`<br />
    IDの記事を開き編集可能の状態になります。<br />
- BlogSwich `<Sectio_name>`<br />
    指定したセクションを読み込み別のサイトに切り替えます。<br />
    vim script`CompSwich`のlistを編集するとtabで補完してくれるようになります。<br />
- BlogUpload `<file_path>`<br />
    画像ファイルをwordpressにアップロードしてhtmlタグを現在のカーソルの一行下に挿入します<br />
    ディレクトリを指定すると専用のバッファを開きます。

- BlogTest<br />
    現在表示されているバッファをhtmlにコンバートして新しいバッファに出力します。

## BlogUpload [dir or file]
dirを指定した場合専用のバッファを開きます。

<C-a>:自動プレビューの切り替え

<C-d>:プレビューウィンドウの削除

<C-p>:現在カーソルがあるファイルのプレビュー。

<enter>:カーソル下のファイルを選択してアップロードします。
    

## Requirements
python3
```
pip install markdown
pip install python-wordpress-xmlrpc
pip install opencv-python
```

## License
MIT - license

## Author
ambergon 
[twitter](https://twitter.com/Sc_lFoxGon)
