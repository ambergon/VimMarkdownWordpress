
function! s:PyCMD(pyfunc)
    exec('python3 ' . a:pyfunc)
endfunction

function! CompSave(lead, line, pos )
  return ['draft' , 'publish']
endfunction

function! CompSwitch(lead, line, pos )
  return ['main' , '']
endfunction


python3 << EOF
# -*- coding: utf-8 -*-

import vim

#import time
#print( time.time() )
import os.path
from configparser import ConfigParser
from markdown import Markdown , extensions

#pip install python-wordpress-xmlrpc
from wordpress_xmlrpc import Client, WordPressPost
from wordpress_xmlrpc.methods.posts import GetPost , GetPosts, NewPost ,EditPost

#画像up関係
from wordpress_xmlrpc.compat import xmlrpc_client
from wordpress_xmlrpc.methods.media import UploadFile 


class VimWordPress:

    BUFFER_NAME = 'VimWordpress://'
    PLUGIN_KEY = 'mkd_text'
    MORE_LIST = '---- More List ----'
    BLOG_LIST_NUM = 100

    META_ME              = '[Meta] Dont touch =========='
    META_ID              = 'ID              :'
    META_CUSTOM_FIELD_ID = 'Custom_Field_ID :'
    META_YOU             = '[Meta] You  touch =========='
    META_TITLE           = 'Title           :'
    META_CATEGORY        = 'Category        :'
    META_TAGS            = 'Tags            :'
    META_END             = '[Content] =================='

    config_file = '.vimMarkdownWordpress'
    config_path = ''

    core_section= ConfigParser()
    blog_section= ConfigParser()

    wp = ''
    def __init__(self):
        root_path = os.path.expanduser("~")
        path_sep = ''
        if( os.name == 'posix' ):
            path_sep = '/'
        else:
            path_sep = "\\"
        self.config_path = root_path + path_sep + self.config_file

        #無ければ作る
        if( os.path.exists( self.config_path ) == 0 ):
            self.writeConfig()
            print( 'make file : ' + self.config_path )
            print( 'plz write this config & RESTART' )
            return
        self.readConfig()

    def writeConfig( self ):
        config = ConfigParser()
        config['core'] = { 
                'markdown_extension' : 'extra,nl2br,' ,
                'blog_list_num'      : '100' ,
                'set_filetype'      : 'markdown' ,
                }
        config['main'] = { 
                'user' : 'user_name' ,
                'password' : 'wordpress_password' ,
                'url' : 'https://your_homepage_url/xmlrpc.php' ,
                }
        with open( self.config_path , 'w' ) as config_text:
            config.write( config_text )


    #blogSwitch
    def readConfig( self, section_name = '' ):
        config = ConfigParser()
        config.read( self.config_path )
        self.core_section = config[ 'core' ]
        self.BLOG_LIST_NUM = self.core_section[ 'blog_list_num' ]
        if( section_name == '' ):
            self.blog_section = config[ 'main' ]
        else:
            if( config.has_section( section_name )):
                self.blog_section = config[ section_name ]
                print('ok change : ' + section_name )
            else:
                print( 'not exist sections : ' + section_name )
                return
        self.wp = Client( self.blog_section[ 'url' ] , self.blog_section[ 'user' ] , self.blog_section[ 'password' ])


    #引数にopen 記事ID
    def blogList( self ):

        #新しいファイルを開く
        vim.command( ':e ' + self.BUFFER_NAME + 'List' )
        #bufferが隠れたら削除
        vim.command( 'setl bufhidden=delete' )
        #削除時に保存するか聞かない
        vim.command( 'setl buftype=nowrite' )

        ##bufferにたいしてkey-bind
        #enter
        vim.command("map <silent> <buffer> <enter> :py3 VimWordPressInst.blogOpen()<cr>")


        #wordpress.pyのdefinitionから引数を確認せよ
        blog_args = { "number" : self.BLOG_LIST_NUM , "offset" : 0 , }
        blog_posts = self.wp.call(GetPosts(blog_args))

        for blog_post in blog_posts:
            X = blog_post.id + ' ' + blog_post.title 
            vim.current.buffer.append( X )

            
        #一行目を削除
        del vim.current.buffer[0]
        vim.current.buffer.append( self.MORE_LIST )

    def addList( self ):
        offset = len( vim.current.buffer ) -1

        blog_args = { "number" : self.BLOG_LIST_NUM , "offset" : offset , }
        blog_posts = self.wp.call(GetPosts(blog_args))

        for blog_post in blog_posts:
            X = blog_post.id + ' ' + blog_post.title 
            vim.current.buffer.append( X )

            
        #最後の行を削除
        del vim.current.buffer[offset]
        vim.current.buffer.append( self.MORE_LIST )



    def blogOpen( self , POST_ID = 'null' ):
        #if( vim.current.line == self.MORE_LIST ):
        if( POST_ID == 'null' and vim.current.line == self.MORE_LIST ):
            self.addList()
            return
            
        if( POST_ID == 'null' ):

            line = vim.current.line.split()
            #''
            if( len( line ) == 0 ):
                print( 'line is none' )
                return
            POST_ID = line[0]
            
        #POST_IDは数値である
        if (not POST_ID.isdecimal() ):
            print( 'POST_ID is not number' )
            return

        post = self.wp.call( GetPost( POST_ID ) )

        #custom_fieldが存在しない場合
        if( len( post.custom_fields ) == 0 ):
            print( 'not wiritten by this plugin' )
            return

        for array in post.custom_fields:
            #key = mkd_textが存在する
            if( self.PLUGIN_KEY in array.values() ):

                #新しいファイルを開く
                vim.command( ':e '   + self.BUFFER_NAME + POST_ID )
                del vim.current.buffer[:]

                #削除時に保存するか聞かない
                vim.command('setl buftype=nowrite' )
                vim.command("setl encoding=utf-8")
                vim.command('setl syntax=blogsyntax')
                vim.command('setl filetype=' + self.core_section['set_filetype'] )

                POST_TAGS     = ''
                POST_CATEGORY = ''
                tag_count = 0
                for post_tag in post.terms :
                    if( tag_count == 0 ):
                        tag_count = 1
                        POST_CATEGORY = str(post_tag)
                    else:
                        POST_TAGS = POST_TAGS + str(post_tag) + ','

                self.blogNew( POST_ID , array['id'] , post.title , POST_CATEGORY , POST_TAGS )

                ##新規記事の準備
                #vim.current.buffer.append( self.META_ME  )
                #vim.current.buffer.append( self.META_ID +  POST_ID )
                #vim.current.buffer.append( self.META_CUSTOM_FIELD_ID +  array['id'] )
                #vim.current.buffer.append( self.META_YOU )
                #vim.current.buffer.append( self.META_TITLE + post.title  )

                #vim.current.buffer.append( self.META_CATEGORY  + POST_CATEGORY )
                #vim.current.buffer.append( self.META_TAGS  + POST_TAGS )
                #vim.current.buffer.append( self.META_END  )
                #del vim.current.buffer[0]

                #mkd_textの出力
                field_lines = array['value'].splitlines()
                for field_line in field_lines :
                    vim.current.buffer.append( field_line )
                break

    def blogNew( self , POST_ID = '' , FIELD_ID = '' , TITLE = '' , CATE = '' , TAG = '' ):
        #新しいファイルを開く
        if( POST_ID == '' ):
            vim.command( ':e '   + self.BUFFER_NAME + 'NEW_POST' )
        else:
            vim.command( ':e '   + self.BUFFER_NAME + POST_ID )
        vim.command('setl buftype=nowrite' )
        vim.command("setl encoding=utf-8")
        vim.command('setl syntax=blogsyntax')
        vim.command('setl filetype=' + self.core_section[ 'set_filetype' ] )
        del vim.current.buffer[:]
        vim.current.buffer.append( self.META_ME  )
        vim.current.buffer.append( self.META_ID +  POST_ID )
        vim.current.buffer.append( self.META_CUSTOM_FIELD_ID +  FIELD_ID )
        vim.current.buffer.append( self.META_YOU )
        vim.current.buffer.append( self.META_TITLE + TITLE )
        vim.current.buffer.append( self.META_CATEGORY  + CATE )
        vim.current.buffer.append( self.META_TAGS  + TAG )
        vim.current.buffer.append( self.META_END  )
        del vim.current.buffer[0]
        return

    def blogSave( self , STATUS='draft' ):
        POST_ID         = vim.current.buffer[1].replace(self.META_ID,'')
        CUSTOM_FIELD_ID = vim.current.buffer[2].replace(self.META_CUSTOM_FIELD_ID,'')
        TITLE           = vim.current.buffer[4].replace(self.META_TITLE,'')
        CATEGORY        = vim.current.buffer[5].replace(self.META_CATEGORY,'')
        TAG             = vim.current.buffer[6].replace(self.META_TAGS,'').split(',')
        #空の要素を削除する
        TAG = list(filter( None , TAG))

        post = WordPressPost()
        post.title = TITLE

        CATEGORY.replace(' ','')
        post.terms_names = None
        #カテゴリを指定しない場合はカテゴリもタグの変化しない
        if( CATEGORY != ''):
            post.terms_names ={
                'category' : [ CATEGORY ] ,
                'post_tag' : TAG   ,
                }

        if( STATUS =='publish' or STATUS == 'Publish' or STATUS == 'PUBLISH' ):
            post.post_status = 'publish'
        else:
            post.post_status = 'draft'

        contents        = vim.current.buffer[8:]
        markdown_text   = ''
        html_text       = ''
        for line in contents :
            markdown_text = markdown_text + line + ' \n'

        m_ext= self.core_section[ 'markdown_extension' ].replace(' ','').split(',')
        m_ext= list(filter( None , m_ext))
        md = Markdown( extensions = m_ext )
        html_text = md.convert( markdown_text )
        post.content = html_text
        custom_field = []

        if( POST_ID =='' ):
            #new
            custom_field.append({
                'key' : self.PLUGIN_KEY ,
                'value' : markdown_text ,
                })
            post.custom_fields = custom_field

            new_post_id = self.wp.call(NewPost(post))
            vim.current.buffer[1] = self.META_ID + new_post_id
            new_post = WordPressPost()
            new_post = self.wp.call( GetPost( new_post_id ) )
            for array in new_post.custom_fields:
                if( self.PLUGIN_KEY in array.values() ):
                    vim.current.buffer[2] = self.META_CUSTOM_FIELD_ID + array['id']
                    vim.command( ':file '   + self.BUFFER_NAME + new_post_id )
                    break

        else:
            #edit
            custom_field.append({
                'id'  : CUSTOM_FIELD_ID ,
                'key' : self.PLUGIN_KEY ,
                'value' : markdown_text ,
                })
            post.custom_fields = custom_field
            self.wp.call(EditPost( POST_ID , post ))

        print('done')

    def blogPictureUpload( self , file_path = 'null' ):
        if ( os.path.exists( file_path )):
            file_name = os.path.basename( file_path )
            file_extension = os.path.splitext( file_name)[1]
            file_type = ''

            if( file_extension in [ '.jpeg' , '.jpg' ] ):
                file_type = 'image/jpeg'
            if( file_extension == '.png' ):
                file_type = 'image/png'
            if( file_extension == '.gif' ):
                file_type = 'image/gif'

            #methods/media/uploadFileに引数が書いてある
            data = {
                    'name' : file_name ,
                    'type' : file_type ,
                    }
            with open( file_path , 'rb' ) as img:
                data[ 'bits' ] = xmlrpc_client.Binary( img.read() )
            response = self.wp.call(UploadFile( data ))

            cursor = vim.current.window.cursor 
            picture_text = '<a href="' + response['url'] + '">' + '<img title="' + response['title'] + '" alt="' + response['title'] + '" src="' + response['url'] + '" class="aligncenter" /></a>'
            vim.current.buffer.append( picture_text , cursor[0] )

        else:
            print( 'not found file' )

VimWordPressInst = VimWordPress()

EOF
