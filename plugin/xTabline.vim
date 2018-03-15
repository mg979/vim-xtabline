""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" xTabline - extension for vim.airline
" Copyright (C) 2018 Gianmaria Bajo <mg1979.git@gmail.com>
" License: MIT License
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if exists("g:loaded_xtabline")
  finish
endif

let g:loaded_xtabline = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

com! -bang -nargs=? -complete=buffer XTabBuffersOpen call fzf#vim#files(
                                    \ <q-args>, {'source': xtabline#fzf#tab_buffers(),
                                    \ 'options': '--multi --prompt "Open Tab Buffer >>>  "'}, <bang>0)

com! XTabBuffersDelete call fzf#run({'source': xtabline#fzf#tab_buffers(),
                                  \ 'sink': function('xtabline#fzf#tab_delete'), 'down': '30%',
                                  \ 'options': '--multi --prompt "Delete Tab Buffer >>>  "'})

com! XTabAllBuffersDelete call fzf#run({'source': xtabline#fzf#tab_all_buffers(),
                                     \ 'sink': 'bdelete', 'down': '30%',
                                     \ 'options': '--multi --prompt "Delete Any Buffer >>>  "'})

com! XTabBookmarksLoad call fzf#run({'source': xtabline#fzf#tab_bookmarks(),
                                  \ 'sink': function('xtabline#fzf#tab_bookmarks_load'), 'down': '30%',
                                  \ 'options': '--multi --prompt "Load Tab Bookmark >>>  "'})

com! XTabNERDBookmarks call fzf#run({'source': xtabline#fzf#tab_nerd_bookmarks(),
                                  \ 'sink': function('xtabline#fzf#tab_nerd_bookmarks_load'), 'down': '30%',
                                  \ 'options': '--multi --prompt "Load NERD Bookmark >>>  "'})

com! XTabBookmarksSave call xtabline#fzf#tab_bookmarks_save()
com! XTabTodo call xtabline#tab_todo()
com! XTabPurge call xtabline#purge_buffers()
com! XTabReopen call xtabline#reopen_last_tab()
com! XTabCloseBuffer call xtabline#close_buffer()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:xtabline_filtering                  = 1
let g:xtabline_map_prefix                 = '<leader>X'
let g:xtabline_bufevent_update            = get(g:, 'xtabline_bufevent_update', 1)
let g:xtabline_include_previews           = get(g:, 'xtabline_include_previews', 1)
let g:xtabline_close_buffer_can_close_tab = get(g:, 'xtabline_close_buffer_can_close_tab', 0)

let g:xtabline_autodelete_empty_buffers   = get(g:, 'xtabline_autodelete_empty_buffers', 0)
let g:xtabline_excludes                   = get(g:, 'xtabline_excludes', [])
let g:xtabline_alt_action                 = get(g:, 'xtabline_alt_action', "buffer #")
let g:xtabline_bookmaks_file              = get(g:, 'xtabline_bookmaks_file ', expand('$HOME/.vim/.XTablineBookmarks'))
let g:xtabline_append_tabs                = get(g:, 'xtabline_append_tabs', '')
let g:xtabline_append_buffers             = get(g:, 'xtabline_append_buffers', '')

if !exists("g:xtabline_todo_file")
    let g:xtabline_todo_file = "/.TODO"
    let g:xtabline_todo = {'path': getcwd().g:xtabline_todo_file, 'command': 'sp', 'prefix': 'below', 'size': 20, 'syntax': 'markdown'}
endif

if !filereadable(g:xtabline_bookmaks_file)
    call writefile([], g:xtabline_bookmaks_file)
endif

call xtabline#init_vars()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists('g:xtabline_disable_keybindings')
    call xtabline#maps#init()
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" TabPageCd
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" tabpagecd - Turn :cd into :tabpagecd, to use one tab page per project
" expanded version by mg979
" Copyright (C) 2012-2013 Kana Natsuno <http://whileimautomaton.net/>
" Copyright (C) 2018 Gianmaria Bajo <mg1979.git@gmail.com>
" License: MIT License

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:InitCwds()
    if !exists('g:xtab_cwds') | let g:xtab_cwds = [] | endif

    while len(g:xtab_cwds) < tabpagenr("$")
        call add(g:xtab_cwds, getcwd())
    endwhile
    let s:state = 1
    let t:cwd = getcwd()
    call xtabline#filter_buffers()
endfunction

function! XTablineUpdateObsession()
    let string = 'let g:xtab_cwds = '.string(g:xtab_cwds).' | call XTablineUpdateObsession()'
    if !exists('g:obsession_append')
        let g:obsession_append = [string]
    else
        call filter(g:obsession_append, 'v:val !~# "^let g:xtab_cwds"')
        call add(g:obsession_append, string)
    endif
endfunction

function! s:OnBufEvent()
    if g:xtabline_bufevent_update | call xtabline#filter_buffers(1) | endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Do(action)
    let arg = a:action
    if !s:state | call s:InitCwds() | return | endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    if arg == 'new'

        call insert(g:xtab_cwds, getcwd(), tabpagenr()-1)

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    elseif arg == 'enter'

        let t:cwd =g:xtab_cwds[tabpagenr()-1]

        cd `=t:cwd`
        let g:xtabline_todo['path'] = t:cwd.g:xtabline_todo_file
        call xtabline#filter_buffers()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    elseif arg == 'leave'

        let t:cwd = getcwd()
        let g:xtab_cwds[tabpagenr()-1] = t:cwd

        if !exists('t:name') | let t:name = t:cwd | endif
        let s:most_recent_tab = {'cwd': t:cwd, 'name': t:name, 'buffers': xtabline#fzf#tab_buffers()}

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    elseif arg == 'close'

        let g:most_recently_closed_tab = copy(s:most_recent_tab)

        if tabpagenr() == tabpagenr("$")
            call remove(g:xtab_cwds, tabpagenr())
        else
            call remove(g:xtab_cwds, tabpagenr()-1) | endif
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    call XTablineUpdateObsession()
endfunction

augroup plugin-xtabline
    autocmd!

    autocmd VimEnter  * let s:state = 0
    autocmd TabNew    * call s:Do('new')
    autocmd TabEnter  * call s:Do('enter')
    autocmd TabLeave  * call s:Do('leave')
    autocmd TabClosed * call s:Do('close')

    autocmd BufEnter  * let g:xtabline_changing_buffer = 0
    autocmd BufAdd,BufDelete,BufWrite * call s:OnBufEvent()

augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
