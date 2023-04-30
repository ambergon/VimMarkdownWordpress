# VimMarkdownWordpress
vimからwordpressをmarkdown記法を使って記事の新規作成・編集が可能になるプラグインです<br />
vimrepressをリスペクトして制作されています。<br />
windows10/python3環境での使用を想定しています。<br />


## 環境詳細
Windows10
VIM 9.0
Python 3.11.3


## 設定
起動時に自動的に`~/.vimMarkdownWordpress`が生成されます<br />

```
##全体にかかわる設定

[core]
MarkdownExtension    = extra,nl2br,fenced_code,attr_list,
BlogListNum         = 100
SetFileType         = markdown
```

- MarkdownExtension<br />
    markdownの拡張機能をpipで取り込んでいるならば<br />
    module名の追記をすることで有効化できます。<br />
    fence_codeなどを追加するとテーブルの記入が快適になります。<br />
- BlogListNum<br />
    記事一覧を表示する際の一度に読み込む記事の数です。<br />
- SetFileType<br />
    記事を編集時に専用のバッファを記事IDごとに開きます。<br />
    この際に`set filetype`を指定しますが、専用のハイライトなどを用意したい場合はこちらで指定してください。<br />
```
##サイトごとの設定

[main]
user = user_name
password = wordpress_password
url = https://your_homepage_url/xmlrpc.php
```

- mainセクション<br />
    `[main]`はデフォルトで読み込むセクション名になっています。<br />
- url<br />
    xmlrpc.phpまでのパスを記載してください。local環境のwordpressにアクセスする場合はhttp://~になるかと思います。<br />



## Command
- BlogList<br />
    BlogListNumの数だけ記事一覧を出力します。<br />
    ---- More List ---- で`<enter>`:追加の記事を同じ数だけ出力します。<br />
    記事ID TITILE行     で`<enter>`:記事を開きます。<br />
    また記事を開かずに別のバッファを開いた場合、Listバッファのみ自動で閉じます。<br />
- BlogTemplate<br />
    新規で記事を作成するためのテンプレートバッファを開きます。<br />
- BlogSave `[draft|publish]`<br />
    引数を渡さない場合はdraftとして扱います
    テンプレートから情報を読み出し記事を保存します。<br />
- BlogOpen `<POST_ID>`<br />
    IDの記事を開き編集可能の状態になります。<br />
- BlogMedia `<file_path>`<br />
    画像ファイルをwordpressにアップロードしてhtmlタグを現在のカーソルの一行下に挿入します<br />

- BlogTest<br />
    現在表示されているバッファをhtmlにコンバートして新しいバッファに出力します。


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
