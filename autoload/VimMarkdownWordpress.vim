
function! VimMarkdownWordpress#pycmd(pyfunc)

    if !exists('s:login')
        let s:result = py3eval('VimWordPressInst.setup()')
        if s:result == 1
            echo 'config : section[main] in default '
            echo 'write and restert'
        else
            let s:login = 1
        endif
    endif

    if exists('s:login')
        exec('python3 VimWordPressInst.' . a:pyfunc)
    endif

endfunction

function! VimMarkdownWordpress#getSectionList()
    let l:list = py3eval('VimWordPressInst.sectionList()')
    return l:list
endfunction

function! VimMarkdownWordpress#autoPicturePreview()
    if !exists('s:autoPreview_option')
        let s:autoPreview_option = 1
    else
        if s:autoPreview_option == 0
            let s:autoPreview_option = 1
        else
            let s:autoPreview_option = 0
        endif
    endif

    if s:autoPreview_option == 1
        echo 'autoPreview on'
        augroup autoPreview
            autocmd CursorMoved <buffer> call VimMarkdownWordpress#pycmd("picture_preview()")
            autocmd BufLeave <buffer> unlet s:autoPreview_option
        augroup end
    else
        echo 'autoPreview off'
        augroup autoPreview
            autocmd!
        augroup end
        call VimMarkdownWordpress#pycmd("picture_wipe()")
    endif

endfunction

python3 << EOF
# -*- coding: utf-8 -*-

import vim
import re
import os.path
from configparser import ConfigParser

try:   
    import cv2
except ImportError:   
    try:
        vim.command("!pip install opencv-python")
        print("install : opencv-python")
        import cv2
    except:   
        print("install error : opencv-python")

try:   
    from markdown import Markdown , extensions
except ImportError:   
    try:
        vim.command("!pip install markdown")
        print("install : markdown")
        from markdown import Markdown , extensions
    except:   
        print("install error : markdown")

try:   
    from wordpress_xmlrpc import Client, WordPressPost
    from wordpress_xmlrpc.methods.posts import GetPost , GetPosts, NewPost ,EditPost
    from wordpress_xmlrpc.methods.taxonomies import GetTerms
    from wordpress_xmlrpc.compat import xmlrpc_client
    from wordpress_xmlrpc.methods.media import UploadFile 
except ImportError:   
    try:
        vim.command("!pip install python-wordpress-xmlrpc")
        print("install : python-wordpress-xmlrpc")
        from wordpress_xmlrpc import Client, WordPressPost
        from wordpress_xmlrpc.methods.posts import GetPost , GetPosts, NewPost ,EditPost
        from wordpress_xmlrpc.compat import xmlrpc_client
        from wordpress_xmlrpc.methods.media import UploadFile 
    except:   
        print("install error : python-wordpress-xmlrpc")

class VimWordPress:

    BUFFER_NAME = 'VimWordpress:/'
    PLUGIN_KEY = 'mkd_text'
    MORE_LIST = '---- More List ----'
    BLOG_LIST_NUM = 100
    PICTURE_WIDTH = 500
    PICTURE_AUTOPREVIEW = 1

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

        #??????????????????
        if( os.path.exists( self.config_path ) == 0 ):
            self.writeConfig()
            print( 'make file : ' + self.config_path )
        self.readConfig()

    def sectionList( self ):
        config = ConfigParser()
        config.read( self.config_path )
        sections_list = config.sections()
        if "core" in sections_list:
            sections_list.remove("core")

        return sections_list


    def writeConfig( self ):
        config = ConfigParser()
        config['core'] = { 
                'markdown_extension' : 'extra,nl2br,' ,
                'blog_list_num'      : '100' ,
                'set_filetype'       : 'markdown' ,
                'picture_autopreview': '1' ,
                'picture_width'      : '500' ,
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
        self.PICTURE_WIDTH = self.core_section[ 'picture_width' ]
        self.PICTURE_AUTOPREVIEW = int( self.core_section[ 'picture_autopreview' ] )

        if( section_name == '' ):
            self.blog_section = config[ 'main' ]
        else:
            if( config.has_section( section_name )):
                self.blog_section = config[ section_name ]
                x = self.setup()
                print('ok change : ' + section_name )
            else:
                print( 'not exist sections : ' + section_name )
                return

    def setup( self ):
        if( self.blog_section[ 'url' ] == 'https://your_homepage_url/xmlrpc.php' ):
            return 1
        else:
            self.wp = Client( self.blog_section[ 'url' ] , self.blog_section[ 'user' ] , self.blog_section[ 'password' ])
            return 0


    def blogTest( self ):

        contents        = vim.current.buffer[:]

        vim.command( ':e ' + self.BUFFER_NAME + 'Test' )
        #buffer?????????????????????
        vim.command( 'setl bufhidden=delete' )
        #???????????????????????????????????????
        vim.command( 'setl buftype=nowrite' )
        vim.command('setl filetype=html')

        markdown_text   = ''
        html_text       = ''
        for line in contents :
            markdown_text = markdown_text + line + ' \n'

        m_ext= self.core_section[ 'markdown_extension' ].replace(' ','').split(',')
        m_ext= list(filter( None , m_ext))
        md = Markdown( extensions = m_ext )
        html_text = md.convert( markdown_text )

        for line in html_text.splitlines():
            vim.current.buffer.append( line )
        del vim.current.buffer[0]




    #?????????open ??????ID
    def blogList( self ):

        #??????????????????????????????
        vim.command( ':e ' + self.BUFFER_NAME + 'List' )
        #buffer?????????????????????
        vim.command( 'setl bufhidden=delete' )
        #???????????????????????????????????????
        vim.command( 'setl buftype=nowrite' )

        ##buffer???????????????key-bind
        #enter


        vim.command( 'map <silent><buffer><enter>   :call VimMarkdownWordpress#pycmd("blogOpen()")<cr>' )
        #vim.command("map <silent> <buffer> <enter> :py3 VimWordPressInst.blogOpen()<cr>")


        blog_args = { "number" : self.BLOG_LIST_NUM , "offset" : 0 , }
        blog_posts = self.wp.call(GetPosts(blog_args))

        for blog_post in blog_posts:
            X = blog_post.id + ' [' + blog_post.post_status + '] ' + blog_post.title 
            vim.current.buffer.append( X )

            
        #??????????????????
        del vim.current.buffer[0]
        vim.current.buffer.append( self.MORE_LIST )

    def addList( self ):
        offset = len( vim.current.buffer ) -1

        blog_args = { "number" : self.BLOG_LIST_NUM , "offset" : offset , }
        blog_posts = self.wp.call(GetPosts(blog_args))

        for blog_post in blog_posts:
            X = blog_post.id + ' [' + blog_post.post_status + '] ' + blog_post.title 
            vim.current.buffer.append( X )
            
        #?????????????????????
        del vim.current.buffer[offset]
        vim.current.buffer.append( self.MORE_LIST )

    def blogOpen( self , POST_ID = 0 ):

        #bloglist???????????????????????????
        if( POST_ID == 0 and vim.current.line == self.MORE_LIST ):
            self.addList()
            return
            
        #bloglist??????????????????????????????????????????num????????????????????????
        if( POST_ID == 0):
            line = vim.current.line.split()
            #''
            if( len( line ) == 0 ):
                print( 'line is none' )
                return
            POST_ID = line[0]
            
        ##POST_ID??????????????????
        #if (not POST_ID.isdecimal() ):
        #    print( 'POST_ID is not number' )
        #    return

        post = self.wp.call( GetPost( POST_ID ) )

        #custom_field????????????????????????
        if( len( post.custom_fields ) == 0 ):
            print( 'not wiritten by this plugin' )
            return

        for array in post.custom_fields:
            #key = mkd_text???????????????
            if( self.PLUGIN_KEY in array.values() ):

                #??????????????????????????????
                vim.command( ':e '   + self.BUFFER_NAME + str(POST_ID) )
                del vim.current.buffer[:]

                #???????????????????????????????????????
                vim.command('setl buftype=nowrite' )
                vim.command("setl encoding=utf-8")
                vim.command('setl syntax=blogsyntax')
                vim.command('setl filetype=' + self.core_section['set_filetype'] )

                #??????????????????????????????
                all_category =[]
                all_category_raw = self.wp.call( GetTerms("category"))
                for tags in all_category_raw:
                    all_category.append(str(tags))

                #???????????????????????????????????????
                post_tags =[]
                for post_tag in post.terms:
                    post_tags.append(str(post_tag))
                post_tags = set(post_tags)

                #??????????????????????????????????????????cate/????????????tag
                POST_TAGS     = ''
                POST_CATEGORY = ''
                for post_tag in post_tags :
                    if post_tag in all_category:
                        POST_CATEGORY = POST_CATEGORY + str(post_tag) + ','
                    else:
                        POST_TAGS = POST_TAGS + str(post_tag) + ','

                self.blogNew( POST_ID , array['id'] , post.title , POST_CATEGORY , POST_TAGS )

                #mkd_text?????????
                field_lines = array['value'].splitlines()
                for field_line in field_lines :
                    #????????????????????????
                    line = re.sub( ' +$' , '' , field_line)
                    vim.current.buffer.append( line )
                break

    def blogNew( self , POST_ID = '' , FIELD_ID = '' , TITLE = '' , CATE = '' , TAG = '' ):
        #??????????????????????????????
        if( POST_ID == '' ):
            vim.command( ':e '   + self.BUFFER_NAME + 'NEW_POST' )
        else:
            vim.command( ':e '   + self.BUFFER_NAME + str(POST_ID) )
        vim.command('setl buftype=nowrite' )
        vim.command("setl encoding=utf-8")
        vim.command('setl syntax=blogsyntax')
        vim.command('setl filetype=' + self.core_section[ 'set_filetype' ] )
        del vim.current.buffer[:]
        vim.current.buffer.append( self.META_ME  )
        vim.current.buffer.append( self.META_ID +  str(POST_ID) )
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
        CATEGORY        = vim.current.buffer[5].replace(self.META_CATEGORY,'').split(',')
        TAG             = vim.current.buffer[6].replace(self.META_TAGS,'').split(',')
        #???????????????????????????
        TAG = list(filter( None , TAG))
        #CATEGORY.replace(' ','')
        CATEGORY = list(filter( None , CATEGORY))

        post = WordPressPost()
        post.title = TITLE

        post.terms_names = None
        #??????????????????????????????????????????????????????????????????????????????
        if( CATEGORY != ''):
            post.terms_names ={
                'category' : CATEGORY ,
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





    def blogPictureUploadCheck( self , file_path = './' ):
        if os.path.exists( file_path ):
            if os.path.isdir( file_path ):
                self.openPictureDir( file_path )
            else:
                self.blogPictureUpload( file_path )
        else:
            print( 'not found file' )




    def blogPictureUpload( self , file_path ):
        file_name = os.path.basename( file_path )
        file_extension = os.path.splitext( file_name)[1]
        file_type = ''

        if( file_extension in [ '.jpeg' , '.jpg' , '.JPG' ] ):
            file_type = 'image/jpeg'
        if( file_extension == '.png' ):
            file_type = 'image/png'
        if( file_extension == '.gif' ):
            file_type = 'image/gif'

        #methods/media/uploadFile???????????????????????????
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



    def openPictureDir( self , dir ):

        #vim.command( 'enew "selectPicture"' )
        vim.command( 'leftabove vnew "selectPicture"' )
        vim.command( 'setl buftype=nowrite' )
        vim.command( 'setl bufhidden=wipe' )

        vim.command( 'map <silent><buffer> <C-p>   :call VimMarkdownWordpress#pycmd("picture_preview()")<cr>' )
        vim.command( 'map <silent><buffer> <C-a>   :call VimMarkdownWordpress#autoPicturePreview()<cr>' )
        if self.PICTURE_AUTOPREVIEW == 1:
            vim.command( "call VimMarkdownWordpress#autoPicturePreview()" )
        vim.command( 'map <silent><buffer> <C-d>   :call VimMarkdownWordpress#pycmd("picture_wipe()")<cr>' )
        vim.command( 'autocmd BufLeave <buffer>     call VimMarkdownWordpress#pycmd("picture_wipe()")')
        vim.command( 'map <silent><buffer> <enter> :call VimMarkdownWordpress#pycmd("picture_do()")<cr>' )
        self.picture_setFiles( dir )

    def picture_setFiles( self , dir ):

        #\->/
        dir = re.sub( "\\\\" , '/' , dir )
        del vim.current.buffer[:]
        ls_files = os.listdir( dir )
        for line in ls_files:
            vim.current.buffer.append( line )
        vim.current.buffer[0] = dir

    def picture_preview( self ):
        folder  = vim.current.buffer[0]
        line = vim.current.line
        path = folder + line
        if( not os.path.isdir( path ) ):
            pictures = [ 'jpg' , 'JPG' , 'png' , 'PNG' , 'gif' ]
            for extension in pictures:
                if path.endswith( '.' + extension ):
                    self.picture_open( path )
                    break

    def picture_open( self , file ):
        img = cv2.imread( file )

        width = int( self.PICTURE_WIDTH )
        h,w = img.shape[:2]
        height = round(h * (width / w ))
        img = cv2.resize( img , dsize=(width,height))
        cv2.imshow("Image" , img )

    def picture_wipe( self ):
        cv2.destroyAllWindows()

    def picture_do( self ):
        dir  = vim.current.buffer[0]
        line = vim.current.line
        if( dir == line ):
            check_back = re.sub( '(../)*' , '' , dir )
            if( check_back == '' or check_back == './' ):
                dir = dir + '../'
                self.picture_setFiles( dir )

            else:
                re_line = line[::-1]
                re_line = re.sub( '^/.+?/' , '/' , re_line , 1 )
                line = re_line[::-1]
                self.picture_setFiles( line )

        else:
            path = dir + line
            if( os.path.isdir( path ) ):
                path = path + '/'
                self.picture_setFiles( path )

            else:
                pictures = [ 'jpg' , 'JPG' , 'png' , 'PNG' , 'gif' ]
                for extension in pictures:
                    if path.endswith( '.' + extension ):
                        vim.command('hid')
                        self.blogPictureUpload( path )
                        break







VimWordPressInst = VimWordPress()

EOF
