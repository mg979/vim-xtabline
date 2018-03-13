""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" xTabline - extension for vim.airline
" Copyright (C) 2018 Gianmaria Bajo <mg1979.git@gmail.com>
" License: MIT License
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if exists("g:loaded_xtabline")
  finish
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

com! -bang -nargs=? -complete=buffer XTabBuffersOpen call fzf#vim#files(
                                    \ <q-args>, {'source': s:TabBuffers(), 'options': '--multi --prompt "Open Tab Buffer >>>  "'}, <bang>0)

com! XTabBuffersDelete call fzf#run({'source': s:TabBuffers(),
                                  \ 'sink': function('s:TabBDelete'), 'down': '30%',
                                  \ 'options': '--multi --prompt "Delete Tab Buffer >>>  "'})

com! XTabAllBuffersDelete call fzf#run({'source': s:TabAllBuffers(),
                                     \ 'sink': 'bdelete', 'down': '30%',
                                     \ 'options': '--multi --prompt "Delete Any Buffer >>>  "'})

com! XTabBookmarksLoad call fzf#run({'source': s:TabBookmarks(),
                                  \ 'sink': function('s:TabBookmarksLoad'), 'down': '30%',
                                  \ 'options': '--multi --prompt "Load Tab Bookmark >>>  "'})

com! XTabNERDBookmarks call fzf#run({'source': s:TabNERDBookmarks(),
                                  \ 'sink': function('s:TabNERDBookmarksLoad'), 'down': '30%',
                                  \ 'options': '--multi --prompt "Load NERD Bookmark >>>  "'})

com! XTabBookmarksSave call <SID>TabBookmarksSave()
com! XTabTodo call <SID>TabTodo()
com! XTabPurge call <SID>PurgeBuffers()
com! XTabReopen call <SID>ReopenLastTab()
com! XTabCloseBuffer call <SID>CloseBuffer()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:loaded_xtabline = 1
let s:most_recent = -1
let g:xtabline_filtering = 1
let g:xtabline_bufevent_update = get(g:, 'xtabline_bufevent_update', 1)
let g:xtabline_include_previews = get(g:, 'xtabline_include_previews', 1)
let g:xtabline_close_buffer_can_close_tab = get(g:, 'xtabline_close_buffer_can_close_tab', 0)

let g:xtabline_autodelete_empty_buffers = get(g:, 'xtabline_autodelete_empty_buffers', 0)
let g:xtabline_excludes = get(g:, 'xtabline_excludes', [])
let g:xtabline_alt_action = get(g:, 'xtabline_alt_action', "buffer #")
let g:xtabline_bookmaks_file  = get(g:, 'xtabline_bookmaks_file ', expand('$HOME/.vim/.XTablineBookmarks'))
let g:xtabline_append_tabs = get(g:, 'xtabline_append_tabs', '')
let g:xtabline_append_buffers = get(g:, 'xtabline_append_buffers', '')

if !exists("g:xtabline_todo_file")
    let g:xtabline_todo_file = "/.TODO"
    let g:xtabline_todo = {'path': getcwd().g:xtabline_todo_file, 'command': 'sp', 'prefix': 'below', 'size': 20, 'syntax': 'markdown'}
endif

if !filereadable(g:xtabline_bookmaks_file)
    call writefile([], g:xtabline_bookmaks_file)
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !exists('g:xtabline_disable_keybindings')
    if !hasmapto('<Plug>XTablineToggleTabs')
        map <unique> <F5> <Plug>XTablineToggleTabs
    endif
    if !hasmapto('<Plug>XTablineToggleBuffers')
        map <unique> <leader><F5> <Plug>XTablineToggleBuffers
    endif
    if !hasmapto('<Plug>XTablineSelectBuffer')
        map <unique> <leader>l <Plug>XTablineSelectBuffer
    endif
    if !hasmapto('<Plug>XTablineNextBuffer')
        map <unique> <S-PageDown> <Plug>XTablineNextBuffer
    endif
    if !hasmapto('<Plug>XTablinePrevBuffer')
        map <unique> <S-PageUp> <Plug>XTablinePrevBuffer
    endif
    if !hasmapto('<Plug>XTablineCloseBuffer')
        map <unique> <leader>Xq <Plug>XTablineCloseBuffer
    endif
    if !hasmapto('<Plug>XTablineBuffersOpen')
        map <unique> <leader>Xx <Plug>XTablineBuffersOpen
    endif
    if !hasmapto('<Plug>XTablineBuffersDelete')
        map <unique> <leader>Xd <Plug>XTablineBuffersDelete
    endif
    if !hasmapto('<Plug>XTablineAllBuffersDelete')
        map <unique> <leader>XD <Plug>XTablineAllBuffersDelete
    endif
    if !hasmapto('<Plug>XTablineBookmarksLoad')
        map <unique> <leader>Xl <Plug>XTablineBookmarksLoad
    endif
    if !hasmapto('<Plug>XTablineBookmarksSave')
        map <unique> <leader>Xs <Plug>XTablineBookmarksSave
    endif
    if !hasmapto('<Plug>XTablinePurge')
        map <unique> <leader>Xp <Plug>XTablinePurge
    endif
    if !hasmapto('<Plug>XTablineReopen')
        map <unique> <leader>Xr <Plug>XTablineReopen
    endif
    if !hasmapto('<Plug>XTablineTabTodo')
        map <unique> <leader>Xtt <Plug>XTablineTabTodo
    endif
endif

nnoremap <unique> <script> <Plug>XTablineToggleTabs <SID>ToggleTabs
nnoremap <silent> <SID>ToggleTabs :call <SID>ToggleTabs()<cr>

nnoremap <unique> <script> <Plug>XTablineToggleBuffers <SID>ToggleBuffers
nnoremap <silent> <SID>ToggleBuffers :call <SID>ToggleBuffers()<cr>

nnoremap <unique> <script> <Plug>XTablineSelectBuffer <SID>SelectBuffer
nnoremap <silent> <expr> <SID>SelectBuffer g:xtabline_changing_buffer ? "\<C-c>" : ":<C-u>call <SID>SelectBuffer(v:count)\<cr>"

nnoremap <unique> <script> <Plug>XTablineNextBuffer <SID>NextBuffer
nnoremap <silent> <SID>NextBuffer :call <SID>NextBuffer()<cr>

nnoremap <unique> <script> <Plug>XTablinePrevBuffer <SID>PrevBuffer
nnoremap <silent> <SID>PrevBuffer :call <SID>PrevBuffer()<cr>

nnoremap <unique> <script> <Plug>XTablineCloseBuffer <SID>CloseBuffer
nnoremap <silent> <SID>CloseBuffer :call <SID>CloseBuffer()<cr>

nnoremap <unique> <script> <Plug>XTablineBuffersOpen <SID>TabBuffersOpen
nnoremap <silent> <SID>TabBuffersOpen :XTabBuffersOpen<cr>

nnoremap <unique> <script> <Plug>XTablineBuffersDelete <SID>TabBuffersDelete
nnoremap <silent> <SID>TabBuffersDelete :XTabBuffersDelete<cr>

nnoremap <unique> <script> <Plug>XTablineAllBuffersDelete <SID>TabAllBuffersDelete
nnoremap <silent> <SID>TabAllBuffersDelete :XTabAllBuffersDelete<cr>

nnoremap <unique> <script> <Plug>XTablineBookmarksLoad <SID>TabBookmarksLoad
nnoremap <silent> <SID>TabBookmarksLoad :XTabBookmarksLoad<cr>

nnoremap <unique> <script> <Plug>XTablineBookmarksSave <SID>TabBookmarksSave
nnoremap <silent> <SID>TabBookmarksSave :XTabBookmarksSave<cr>

nnoremap <unique> <script> <Plug>XTablinePurge <SID>PurgeBuffers
nnoremap <silent> <SID>PurgeBuffers :XTabPurge<cr>

nnoremap <unique> <script> <Plug>XTablineReopen <SID>ReopenLastTab
nnoremap <silent> <SID>ReopenLastTab :XTabReopen<cr>

nnoremap <unique> <script> <Plug>XTablineTabTodo <SID>TabTodo
nnoremap <silent> <SID>TabTodo :XTabTodo<cr>

if get(g:, 'xtabline_cd_commands', 0)
    map <unique> <leader>cdc <Plug>XTablineCdCurrent
    map <unique> <leader>cdd <Plug>XTablineCdDown1
    map <unique> <leader>cd2 <Plug>XTablineCdDown2
    map <unique> <leader>cd3 <Plug>XTablineCdDown3
    map <unique> <leader>cdh <Plug>XTablineCdHome
    nnoremap <unique> <script> <Plug>XTablineCdCurrent :cd %:p:h<cr>:doautocmd BufAdd<cr>:pwd<cr>
    nnoremap <unique> <script> <Plug>XTablineCdDown1   :cd %:p:h:h<cr>:doautocmd BufAdd<cr>:pwd<cr>
    nnoremap <unique> <script> <Plug>XTablineCdDown2   :cd %:p:h:h:h<cr>:doautocmd BufAdd<cr>:pwd<cr>
    nnoremap <unique> <script> <Plug>XTablineCdDown3   :cd %:p:h:h:h:h<cr>:doautocmd BufAdd<cr>:pwd<cr>
    nnoremap <unique> <script> <Plug>XTablineCdHome    :cd ~<cr>:doautocmd BufAdd<cr>:pwd<cr>
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>ToggleTabs()
    """Toggle between tabs/buffers tabline."""

    if tabpagenr("$") == 1 | echo "There is only one tab." | return | endif

    if g:airline#extensions#tabline#show_tabs
        let g:airline#extensions#tabline#show_tabs = 0
        echo "Showing buffers"
    else
        let g:airline#extensions#tabline#show_tabs = 1
        echo "Showing tabs"
    endif

    execute "AirlineRefresh"
    "call airline#extensions#tabline#buflist#invalidate()
    doautocmd BufAdd
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>ToggleBuffers()
    """Toggle buffer filtering in the tabline."""

    if g:xtabline_filtering
        let g:xtabline_filtering = 0
        let g:airline#extensions#tabline#accepted = []
        let g:airline#extensions#tabline#excludes = copy(g:xtabline_excludes)
        doautocmd BufAdd
        "call s:RefreshTabline()
    else
        let g:xtabline_filtering = 1
        call s:FilterBuffers()
        doautocmd BufAdd
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>PurgeBuffers()
    """Remove unmodified buffers with invalid paths."""

    if !g:xtabline_filtering | echo "Buffer filtering is turned off." | return | endif
    let bcnt = 0 | let bufs = [] | let purged = []

    " include previews if not showing in tabline
    for buf in tabpagebuflist(tabpagenr())
        if index(t:accepted, buf) == -1 | call add(bufs, buf) | endif
    endfor

    " purge the buffer if:
    " 1. non-existant path and file unmodified
    " 2. path doesn't belong to cwd, but it has been accepted for partial match

    for buf in (t:accepted + bufs)
        let bufpath = fnamemodify(bufname(buf), ":p")

        if !filereadable(bufpath)
            if !getbufvar(buf, "&modified")
                let bcnt += 1 | let ix = index(t:accepted, buf)
                if ix >= 0 | call add(purged, remove(t:accepted, ix))
                else | call add(purged, buf) | endif
            endif

        elseif bufpath !~ "^".t:cwd
            let bcnt += 1 | let ix = index(t:accepted, buf)
            if ix >= 0 | call add(purged, remove(t:accepted, ix))
            else | call add(purged, buf) | endif
        endif
    endfor

    " the tab may be closed if there is one window, and it's going to be purged
    if len(tabpagebuflist()) == 1 && !empty(t:accepted) && index(purged, bufnr("%")) >= 0
        execute "buffer ".t:accepted[0] | endif

    for buf in purged | execute "silent! bdelete ".buf | endfor

    call s:FilterBuffers()
    let s = "Purged ".bcnt." buffer" | let s .= bcnt!=1 ? "s." : "." | echo s
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>ReopenLastTab()
    """Reopen the last closed tab."""

    if !exists('s:most_recently_closed_tab')
        echo "No recent tabs." | return | endif

    let tab = s:most_recently_closed_tab
    tabnew
    let empty = bufnr("%")
    let t:cwd = tab['cwd']
    cd `=t:cwd`
    let t:name = tab['name']
    for buf in tab['buffers'] | execute "badd ".buf | endfor
    execute "edit ".tab['buffers'][0]
    execute "bdelete ".empty
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:FilterBuffers(...)
    """Filter buffers so that only the ones within the tab's cwd will show up.

    " 'accepted' is a list of buffer numbers, for quick access.
    " 'excludes' is a list of paths, it will be used by Airline to hide buffers."""

    if !g:xtabline_filtering | return | endif

    let g:airline#extensions#tabline#accepted = []
    let g:airline#extensions#tabline#excludes = copy(g:xtabline_excludes)
    let t:accepted = g:airline#extensions#tabline#accepted
    let s:excludes = g:airline#extensions#tabline#excludes
    let previews = g:xtabline_include_previews

    " bufnr(0) is the alternate buffer
    for buf in range(1, bufnr("$"))

        if !buflisted(buf) | continue | endif

        " get the path
        let path = expand("#".buf.":p")

        " confront with the cwd
        if !previews && path =~ "^".getcwd()
            call add(t:accepted, buf)
        elseif previews && path =~ getcwd()
            call add(t:accepted, buf)
        elseif bufname(buf) != ''
            call add(s:excludes, path)
        elseif a:000 == [] && g:xtabline_autodelete_empty_buffers
            " buffer tabline breaks if there are empty 'paths'.
            " if there are problems, this can be just skipped.
            " since it seems useful, for now we're deleting
            " these temporary and empty buffers. This will happen
            " only when the function is called without arguments.
            execute "silent! bdelete ".buf
        endif
    endfor

    call s:RefreshTabline()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Close(buf)
    if !getbufvar(a:buf, 'modified') | execute("silent! bdelete ".a:buf) | call s:FilterBuffers() | endif
endfun

fun! s:is_tab_buffer(...)
    if a:0
        return index(t:accepted, bufnr(a:0)) != -1 | endif
    return index(t:accepted, bufnr("%")) != -1
endfun

function! <SID>CloseBuffer()
    """Close and delete a buffer, without closing the tab."""
    let current = bufnr("%") | let alt = bufnr("#") | let tabnr = tabpagenr()

    if buflisted(alt) && s:is_tab_buffer(alt)
        execute "buffer ".alt | call s:Close(current)

    elseif len(t:accepted) > 1 || (len(t:accepted) && !s:is_tab_buffer())
        call <SID>NextBuffer() | call s:Close(current)

    elseif !g:xtabline_close_buffer_can_close_tab
        return

    elseif getbufvar(current, 'modified')
        echo "Not closing because of unsaved changes"

    elseif tabnr > 1 || tabpagenr("$") != tabnr
        tabnext | silent call s:Close(current)
    else
        quit | endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>NextBuffer()
    """Switch to next visible buffer."""

    if ( s:NotEnoughBuffers() || !g:xtabline_filtering ) | return | endif

    let ix = index(t:accepted, bufnr("%"))

    if bufnr("%") == t:accepted[-1]
        " last buffer, go to first
        let s:most_recent = t:accepted[0]

    elseif ix == -1
        " not in index, go back to most recent or back to first
        if s:most_recent == -1 || index(t:accepted, s:most_recent) == -1
            let s:most_recent = t:accepted[0]
        endif
    else
        let s:most_recent = t:accepted[ix + 1]
    endif

    execute "buffer " . s:most_recent
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>PrevBuffer()
    """Switch to previous visible buffer."""

    if ( s:NotEnoughBuffers() || !g:xtabline_filtering ) | return | endif

    let ix = index(t:accepted, bufnr("%"))

    if bufnr("%") == t:accepted[0]
        " first buffer, go to last
        let s:most_recent = t:accepted[-1]

    elseif ix == -1
        " not in index, go back to most recent or back to first
        if s:most_recent == -1 || index(t:accepted, s:most_recent) == -1
            let s:most_recent = t:accepted[0]
        endif
    else
        let s:most_recent = t:accepted[ix - 1]
    endif

    execute "buffer " . s:most_recent
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>SelectBuffer(nr)
    """Switch to visible buffer in the tabline with [count]."""

    if ( a:nr == 0 || !g:xtabline_filtering ) | execute g:xtabline_alt_action | return | endif

    if (a:nr > len(t:accepted)) || s:NotEnoughBuffers() || t:accepted[a:nr - 1] == bufnr("%")
        return
    else
        let g:xtabline_changing_buffer = 1
        execute "buffer ".t:accepted[a:nr - 1]
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>TabTodo()
    let todo = g:xtabline_todo
    if todo['command'] == 'edit'
        execute "edit ".todo['path']
    else
        execute todo['prefix']." ".todo['size'].todo['command']." ".todo['path']
    endif
    execute "setlocal syntax=".todo['syntax']
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" fzf functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TabBuffers()
    """Open a list of buffers for this tab with fzf.vim."""

    return map(copy(t:accepted), 'bufname(v:val)')
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TabAllBuffers()
    """Open a list of all buffers with fzf.vim."""

    let listed = []
    for buf in range(1, bufnr("$"))
        if buflisted(buf) | call add(listed, buf) | endif
    endfor
    return map(listed, 'bufname(v:val)')
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TabNERDBookmarks()
    let bfile = readfile(g:NERDTreeBookmarksFile)
    let bookmarks = []
    "skip last emty line
    for line in bfile[:-2]
        let b = substitute(line, '^.\+ ', "", "")
        call add(bookmarks, b)
    endfor
    return bookmarks
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TabNERDBookmarksLoad(...)
    for bm in a:000
        let bm = expand(bm, ":p")
        if isdirectory(bm)
            tabnew
            exe "cd ".bm
            exe "NERDTree ".bm
        elseif filereadable(bm)
            exe "tabedit ".bm
            exe "cd ".fnamemodify(bm, ":p:h")
        endif
    endfor
    call s:RefreshTabline()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TabBookmarks()
    let s:xtabline_bookmaks = []
    let bookmarks = []
    let bfile = readfile(g:xtabline_bookmaks_file)

    for line in bfile
        let line = eval(line)
        call add(s:xtabline_bookmaks, line)
        call add(bookmarks, line['name'])
    endfor
    return bookmarks
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TabBookmarksLoad(...)
    let bfile = readfile(g:xtabline_bookmaks_file)

    for bm in a:000
        for line in bfile
            let line = eval(line)

            " not the correct entry
            if line['name'] !=# bm | continue | endif

            let cwd = expand(line['cwd'], ":p")
            if isdirectory(cwd)
                tabnew | let newbuf = bufnr("%")
                exe "cd ".cwd
                let t:cwd = cwd
                if empty(line['buffers']) | continue | endif
            else
                echo line['name'].": invalid bookmark." | continue
            endif

            "add buffers
            for buf in line['buffers'] | execute "badd ".buf | endfor

            "load the first buffer
            execute "edit ".line['buffers'][0]

            " purge the empty buffer that was created
            execute "bdelete ".newbuf
        endfor
    endfor
    doautocmd BufAdd
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>TabBookmarksSave()
    """Create an entry and add it to the bookmarks file."""

    if !g:xtabline_filtering | echo "Activate tab filtering first." | return | endif

    let entry = {}

    " get cwd
    try
        let t:cwd = getcwd()
        let entry['cwd'] = t:cwd
        let entry['name'] = input("Enter an optional name for this bookmark:  ", t:cwd, "file_in_path")
    catch
        echo "Cwd for this tab hasn't been set, aborting."
        return
    endtry

    if entry['name'] == ""
        echo "Bookmark not saved." | return | endif

    " get buffers
    let bufs = []
    let current = 0
    if buflisted(bufnr("%"))
        let current = bufnr("%")
        call add(bufs, bufname(current))
    endif
    for buf in range(1, bufnr("$"))
        if index(t:accepted, buf) >= 0 && (buf != current)
            call add(bufs, fnameescape(bufname(buf)))
        endif
    endfor
    let entry['buffers'] = bufs

    "trasform the dict to string, put in a list and append to file
    let entry = [string(entry)]
    call writefile(entry, g:xtabline_bookmaks_file, "a")
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TabBDelete(...)

    for buf in a:000
        execute "silent! bdelete ".buf
        let ix = index(t:accepted, bufnr(buf))
        call remove(t:accepted, ix)
        call s:FilterBuffers()
    endfor
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:NotEnoughBuffers()
    """Just return if there aren't enough buffers."""

    if len(t:accepted) < 2
        if index(t:accepted, bufnr("%")) == -1
            return
        elseif !len(t:accepted)
            echo "No available buffers for this tab."
        else
            echo "No other available buffers for this tab."
        endif
        return 1
    endif
endfunction

function! s:RefreshTabline()
    "set tabline=%!airline#extensions#tabline#get()
    call airline#extensions#tabline#buflist#invalidate()
    "execute "AirlineRefresh"
endfunction


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
    call s:FilterBuffers()
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
    if g:xtabline_bufevent_update | call s:FilterBuffers(1) | endif
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
        call s:FilterBuffers()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    elseif arg == 'leave'

        let t:cwd = getcwd()
        let g:xtab_cwds[tabpagenr()-1] = t:cwd

        if !exists('t:name') | let t:name = t:cwd | endif
        let s:most_recent_tab = {'cwd': t:cwd, 'name': t:name, 'buffers': s:TabBuffers()}

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    elseif arg == 'close'

        let s:most_recently_closed_tab = copy(s:most_recent_tab)

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
