"if !has("python3")
"    finish
"endif
"if exists('g:loaded_VimMarkdownWordpress')
"    finish
"endif
"let g:loaded_VimMarkdownWordpress = 1


command! -nargs=0                                   BlogList   call VimMarkdownWordpress#PyCMD('VimWordPressInst.blogList(<f-args>)')
command! -nargs=? -complete=customlist,CompSave     BlogSave   call VimMarkdownWordpress#PyCMD('VimWordPressInst.blogSave(<f-args>)')

command! -nargs=0                                   BlogNew    call VimMarkdownWordpress#PyCMD('VimWordPressInst.blogNew()')
command! -nargs=1                                   BlogOpen   call VimMarkdownWordpress#PyCMD('VimWordPressInst.blogOpen(<f-args>)')
command! -nargs=1 -complete=customlist,CompSwitch   BlogSwitch call VimMarkdownWordpress#PyCMD('VimWordPressInst.readConfig(<f-args>)')
command! -nargs=1 -complete=file                    BlogUpload call VimMarkdownWordpress#PyCMD('VimWordPressInst.blogPictureUpload(<f-args>)')

function! CompSave(lead, line, pos )
    let l:matches = []
    for file in [ "publish" , "Publish" , "draft" , "Draft" ]
        if file =~? '^' . strpart(a:lead,0)
            echo add(l:matches,file)
        endif
    endfor
    return l:matches
endfunction

function! CompSwitch(lead, line, pos )
    let l:list = VimMarkdownWordpress#getSectionList()
    let l:matches = []
    for file in l:list
        if file =~? '^' . strpart(a:lead,0)
            echo add(l:matches,file)
        endif
    endfor
    return l:matches
endfunction

