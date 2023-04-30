
python3 << EOF
# -*- coding: utf-8 -*-
import vim
import re
import markdown
from configparser import ConfigParser
import os
from wordpress_xmlrpc import Client, WordPressPost
from wordpress_xmlrpc.methods.posts import GetPost , GetPosts , NewPost , EditPost
from wordpress_xmlrpc.methods.taxonomies import GetTerms

class PythonClass:
    wp = ""
    md = markdown.Markdown()
    BufferName = 'VimWordpress:/'

    MarkdownExtension   = []
    #読み込む最大数。
    BlogListNum         = 100
    MoreList            = "---- More List ----"
    #FileType
    FileType            = ""

    META_ME              = "[Meta] Dont touch =========="
    META_ID              = "ID              :"
    META_CUSTOM_FIELD_ID = "Custom_Field_ID :"
    META_YOU             = "[Meta] You  touch =========="
    META_TITLE           = "Title           :"
    META_CATEGORY        = "Category        :"
    META_TAGS            = "Tags            :"
    META_END             = "[Content] =================="

    CUSTOM_FIELD_KEY = "mkd_text"

    def __init__( self ):
        print( "init" )
        ConfigPath = os.path.expanduser("~") + "/" + ".vimMarkdownWordpress"

        if not os.path.exists( ConfigPath ):
            WriteConfig( ConfigPath )

        Config = ConfigParser()
        Config.read( ConfigPath )
        CoreSection = ConfigParser()
        CoreSection = Config[ "core" ]
        BlogSection = ConfigParser()
        BlogSection = Config[ "main" ]

        ##login
        self.wp = Client( BlogSection[ "url" ] , BlogSection[ "user" ] , BlogSection[ "password" ])

        ##BlogList
        self.BlogListNum    = CoreSection[ "BlogListNum" ]
        self.FileType       = CoreSection[ "SetFileType" ]

        ##MarkdownExtension
        #要素を取得しリスト化
        self.MarkdownExtension = CoreSection[ "MarkdownExtension" ].replace(" ","").split(",")
        #空を処分
        self.MarkdownExtension = list(filter( None , self.MarkdownExtension))
        self.md = markdown.Markdown( extensions = self.MarkdownExtension )


    #設定ファイルが存在しなければ。
    def WriteConfig( self , ConfigPath ):
        config = ConfigParser()
        config["core"] = { 
                "MarkdownExtension"  : "extra,nl2br,"   ,
                "BlogListNum"        : "100"            ,
                "SetFileType"        : "markdown"       ,
                }
        config["main"] = { 
                "user"      : "user_name"           ,
                "password"  : "wordpress_password"  ,
                "url"       : "https://your_homepage_url/xmlrpc.php" ,
                }
        with open( ConfigPath , "w" ) as ConfigText:
            config.write( ConfigText )


    #現在表示しているバッファの内容を
    #横のバッファでマークダウン化したものを表示。
    def BlogTest( self ):
        text = ""
        for line in vim.current.buffer[:]:
            text = text + line + "\n"

        vim.command( ":vs " + self.BufferName + "Test" )
        vim.command( "setl buftype=nowrite"            )
        vim.command( "setl encoding=utf-8"             )
        vim.command( "setl syntax=blogsyntax"          )
        html = self.md.convert( str(text) )
        for line in html.splitlines():
            vim.current.buffer.append( line )
        del vim.current.buffer[0]


    def BlogTemplate( self , PostID = "" , FieldID = "" , TITLE = "" , CATE = "" , TAG = "" , FieldText = ""):
        #新しいファイルを開く
        if( PostID == "" ):
            vim.command( ':e '   + self.BufferName + "NewPost" )
        else:
            vim.command( ':e '   + self.BufferName + str(PostID) )

        vim.command('setl buftype=nowrite' )
        vim.command("setl encoding=utf-8")
        vim.command('setl syntax=blogsyntax')
        vim.command('setl filetype=' + self.FileType )

        del vim.current.buffer[:]
        vim.current.buffer.append( self.META_ME                             )
        vim.current.buffer.append( self.META_ID              + str(PostID)  )
        vim.current.buffer.append( self.META_CUSTOM_FIELD_ID + FieldID      )
        vim.current.buffer.append( self.META_YOU                            )
        vim.current.buffer.append( self.META_TITLE           + TITLE        )
        vim.current.buffer.append( self.META_CATEGORY        + CATE         )
        vim.current.buffer.append( self.META_TAGS            + TAG          )
        vim.current.buffer.append( self.META_END                            )
        #送られてきたテキストがあれば追加。
        for line in FieldText :
            #文末の空白を除去
            line = re.sub( ' +$' , '' , line )
            vim.current.buffer.append( line )

        del vim.current.buffer[0]
        return


    def BlogList( self ):
        args  = { "number" : self.BlogListNum , "offset" : 0 , }
        Posts = self.wp.call( GetPosts ( args ))

        vim.command( ":e " + self.BufferName + "List" )
        #vim.command( ":vs " + self.BufferName + "List" )

        #bufferが隠れたら削除
        vim.command( "setl bufhidden=delete" )
        #削除時に保存するか聞かない
        vim.command( "setl buftype=nowrite" )
        vim.command( "map <silent><buffer><enter>   :py3 VimMarkdownWordPressInst.BlogOpen()<cr>" )
        #下記の形式でバッファに書き出す。
        #ID [publish] TITLE
        for Post in Posts:
            vim.current.buffer.append( Post.id + " [" + Post.post_status + "] " + Post.title )

        #一行目を削除
        del vim.current.buffer[0]
        #規定の行を末尾に。
        #これをenterしたときにさらに読み込めるように。
        vim.current.buffer.append( self.MoreList )


    def BlogListAdd( self ):
        #現在の行数分、最新投稿を取り除く。
        offset = len( vim.current.buffer ) - 1
        BlogArgs = { "number" : self.BlogListNum , "offset" : offset }
        Posts = self.wp.call(GetPosts( BlogArgs ))
        #List追加
        for Post in Posts:
            vim.current.buffer.append( Post.id + ' [' + Post.post_status + '] ' + Post.title )
        #最後の行/MoreListを削除
        del vim.current.buffer[offset]
        vim.current.buffer.append( self.MoreList )


    def BlogOpen( self , PostID = 0 ):
        #Listの再読み込み
        #BlogListBuffer && current.line MoreList
        if( PostID == 0 and vim.current.line == self.MoreList ):
            self.BlogListAdd()
            return
            
        #BlogListBuffer && IDから始まる行。
        if( PostID == 0):
            line = vim.current.line.split()
            #空白行処理
            if( len( line ) == 0 ):
                print( 'line is none' )
                return
            PostID = line[0]
        Post = self.wp.call( GetPost( PostID ) )

        #custom_fieldが存在しない場合
        if( len( Post.custom_fields ) == 0 ):
            print( 'not wiritten by this plugin' )
            return

        #CustomField一覧をチェック
        for CustomField in Post.custom_fields:
            #key = mkd_textが存在する
            if( self.CUSTOM_FIELD_KEY in CustomField.values() ):
                #新しいファイルを開く
                vim.command( ':e '   + self.BufferName + str( PostID ))
                del vim.current.buffer[:]

                #削除時に保存するか聞かない
                vim.command( "setl buftype=nowrite"           )
                vim.command( "setl encoding=utf-8"            )
                vim.command( "setl syntax=blogsyntax"         )
                vim.command( "setl filetype=" + self.FileType )

                ##WPは内部的にカテゴリとタグを混同していたような気がする。
                #記事事に正常にタグとカテゴリーを取得しなおすのが難しかった記憶。
                #カテゴリ一覧をリスト
                Categories =[]
                CategoriesRaw = self.wp.call( GetTerms("category") )
                for tag in CategoriesRaw:
                    Categories.append( str( tag ) )

                #同名のカテゴリが存在するならcate/無ければtag
                PostTags     = ""
                PostCate     = ""
                #タグにマッチするカテゴリが存在した場合、それをカテゴリとする。
                for One in Post.terms:
                    PostTag = str( One )
                    if PostTag in Categories:
                        PostCate = PostCate + PostTag + ","
                    else:
                        PostTags = PostTags + PostTag + ","

                FieldText = CustomField['value'].splitlines()
                self.BlogTemplate( PostID , CustomField["id"] , Post.title , PostCate , PostTags , FieldText )
                break



    #適当なテキストを保存できるように使用。
    def BlogSave( self , STATUS="draft" ):
        POST_ID         = vim.current.buffer[1].replace(self.META_ID , ""              )
        CUSTOM_FIELD_ID = vim.current.buffer[2].replace(self.META_CUSTOM_FIELD_ID , "" )
        TITLE           = vim.current.buffer[4].replace(self.META_TITLE , ""           )
        CATEGORY        = vim.current.buffer[5].replace(self.META_CATEGORY , "" ).split( "," )
        TAG             = vim.current.buffer[6].replace(self.META_TAGS , "" ).split( "," )
        #空の要素を削除する
        TAG      = list(filter( None , TAG ) )
        #CATEGORY.replace(' ','')
        CATEGORY = list(filter( None , CATEGORY ) )

        Post = WordPressPost()
        Post.title = TITLE
        Post.terms_names = None
        #カテゴリを指定しない場合はカテゴリもタグの変化しない
        if( CATEGORY != "" ):
            Post.terms_names ={
                "category" : CATEGORY ,
                "post_tag" : TAG   ,
                }
        if( STATUS =="publish" or STATUS == "Publish" or STATUS == "PUBLISH" ):
            Post.post_status = "publish"
        else:
            Post.post_status = "draft"

        MarkdownText   = ""
        text = vim.current.buffer[8:]

        for line in text:
            MarkdownText = MarkdownText + line + "\n"

        Post.content = self.md.convert( MarkdownText )
        CustomField = []

        #新規記事
        if( POST_ID == "" ):
            CustomField.append({
                "key"    : self.CUSTOM_FIELD_KEY ,
                "value"  : MarkdownText ,
                })
            Post.custom_fields = CustomField
            NewPostID = self.wp.call( NewPost( Post ) )
            print( NewPostID )

            vim.current.buffer[1] = self.META_ID + NewPostID
            ##ID類をセットしなおす。
            #関数名に干渉するからNewPostは駄目よ。
            newPost = WordPressPost()
            newPost = self.wp.call( GetPost( NewPostID ) )
            for array in newPost.custom_fields:
                if( self.CUSTOM_FIELD_KEY in array.values() ):
                    vim.current.buffer[2] = self.META_CUSTOM_FIELD_ID + array["id"]
                    vim.command( ":file "   + self.BufferName + NewPostID )
                    break
        #編集
        else:
            CustomField.append({
                "id"    : CUSTOM_FIELD_ID ,
                "key"   : self.CUSTOM_FIELD_KEY ,
                "value" : MarkdownText ,
                })
            Post.custom_fields = CustomField
            self.wp.call(EditPost( POST_ID , Post ))
        
        print('done')




    #別のプラグインから連携させるのが一番賢い気がする。
    def BlogMedia( self , FilePath = './' ):
        if not os.path.exists( FilePath ):
            print( 'not found file' )
            return
            
        #ディレクトリ時、処理をしないように。
        if os.path.isdir( FilePath ):
            print( "this path is dir" )
            return

        FileName = os.path.basename( FilePath )
        FileExtension = os.path.splitext( FileName)[1]
        file_type = ''

        if( FileExtension in [ '.jpeg' , '.jpg' , '.JPG' ] ):
            file_type = 'image/jpeg'
        if( FileExtension == '.png' ):
            file_type = 'image/png'
        if( FileExtension == '.gif' ):
            file_type = 'image/gif'

        #methods/media/uploadFileに引数が書いてある
        data = {
                'name' : FileName ,
                'type' : file_type ,
                }

        with open( FilePath , 'rb' ) as img:
            data[ 'bits' ] = xmlrpc_client.Binary( img.read() )
        Response = self.wp.call(UploadFile( data ))

        Cursor = vim.current.window.Cursor 
        MediaText = '<a href="' + Response['url'] + '">' + '<img title="' + Response['title'] + '" alt="' + Response['title'] + '" src="' + Response['url'] + '" class="aligncenter" /></a>'
        vim.current.buffer.append( MediaText , Cursor[0] )




#修正するmodule
from wordpress_xmlrpc.base import XmlrpcMethod
#修正に必要module
from wordpress_xmlrpc.compat import dict_type
import collections.abc
def FIXED_process_result(self, raw_result):
    if self.results_class and raw_result:
        if isinstance(raw_result, dict_type):
            return self.results_class(raw_result)
        elif isinstance(raw_result, collections.abc.Iterable): 
            return [self.results_class(result) for result in raw_result]
    return raw_result
#メソッドの置き換え。
XmlrpcMethod.process_result = FIXED_process_result


VimMarkdownWordPressInst = PythonClass()
EOF



let s:VimMarkdownWordpress = "VimMarkdownWordPressInst"
function! VimMarkdownWordpress#pycmd(pyfunc)
    let s:x = py3eval( s:VimMarkdownWordpress . "." . a:pyfunc )
endfunction


