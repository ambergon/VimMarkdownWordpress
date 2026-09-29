


if !has("python3")
    finish
endif
if exists('g:loaded_VimMarkdownWordpress')
    finish
endif
let g:loaded_VimMarkdownWordpress = 1



function! VimMarkdownWordpress#CompSave(lead, line, pos )
    let l:matches = []
    for file in [ "publish" , "Publish" , "draft" , "Draft" ]
        if file =~? '^' . strpart(a:lead,0)
            echo add(l:matches,file)
        endif
    endfor
    return l:matches
endfunction



command! -nargs=0                                                       BlogList   call VimMarkdownWordpress#pycmd('BlogList(<f-args>)')
command! -nargs=? -complete=customlist,VimMarkdownWordpress#CompSave    BlogSave   call VimMarkdownWordpress#pycmd('BlogSave(<f-args>)')

command! -nargs=0                                                       BlogNew    call VimMarkdownWordpress#pycmd('BlogTemplate()')
command! -nargs=1                                                       BlogOpen   call VimMarkdownWordpress#pycmd('BlogOpen(<f-args>)')
"command! -nargs=1 -complete=customlist,CompSwitch                       BlogSwitch call VimMarkdownWordpress#pycmd('readConfig(<f-args>)')
"command! -nargs=1 -complete=file                                        BlogUpload call VimMarkdownWordpress#pycmd('blogPictureUploadCheck(<f-args>)')
command! -nargs=0                                                       BlogTest   call VimMarkdownWordpress#pycmd('BlogTest(<f-args>)')
command! -nargs=1 -complete=file                                        BlogMedia  call VimMarkdownWordpress#pycmd('BlogMedia(<f-args>)')

augroup wordpress
    autocmd BufEnter VimWordpress://[0-9]* cabbrev w W
    autocmd BufLeave VimWordpress://[0-9]* cunabbrev w
    autocmd BufEnter VimWordpress://[0-9]* command! -buffer -nargs=0 W                  call VimMarkdownWordpress#pycmd('BlogSave(<f-args>)')
    autocmd BufEnter VimWordpress://NewPost cabbrev w W
    autocmd BufLeave VimWordpress://NewPost cunabbrev w
    autocmd BufEnter VimWordpress://NewPost command! -buffer -nargs=0 W                  call VimMarkdownWordpress#pycmd('BlogSave(<f-args>)')
endfunction
"function! CompSwitch(lead, line, pos )
"    let l:list = VimMarkdownWordpress#getSectionList()
"    let l:matches = []
"    for file in l:list
"        if file =~? '^' . strpart(a:lead,0)
"            echo add(l:matches,file)
"        endif
"    endfor
"    return l:matches

























"augroup END
