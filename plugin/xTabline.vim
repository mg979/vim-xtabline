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

com! XTabBuffersOpen call fzf#run({'source': s:TabBuffers(),
                                \ 'sink': 'vs', 'down': '30%',
                                \ 'options': '--multi --reverse'})

com! XTabBuffersDelete call fzf#run({'source': s:TabBuffers(),
                                  \ 'sink': function('s:TabBDelete'), 'down': '30%',
                                  \ 'options': '--multi --reverse'})

com! XTabAllBuffersDelete call fzf#run({'source': s:TabAllBuffers(),
                                     \ 'sink': 'bdelete', 'down': '30%',
                                     \ 'options': '--multi --reverse'})

com! XTabBookmarksLoad call fzf#run({'source': s:TabBookmarks(),
                                  \ 'sink': function('s:TabBookmarksLoad'), 'down': '30%',
                                  \ 'options': '--multi --reverse'})

com! XTabNERDBookmarks call fzf#run({'source': s:TabNERDBookmarks(),
                                  \ 'sink': function('s:TabNERDBookmarksLoad'), 'down': '30%',
                                  \ 'options': '--multi --reverse'})

com! XTabBookmarksSave call <SID>TabBookmarksSave()
com! XTabTodo call <SID>TabTodo()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:loaded_xtabline = 1
let s:most_recent = -1
let g:xtabline_filtering = 1
let g:airline#extensions#tabline#show_tabs = 1

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
    if !hasmapto('<Plug>XTablineBuffersOpen')
        map <unique> <leader>BB <Plug>XTablineBuffersOpen
    endif
    if !hasmapto('<Plug>XTablineBuffersDelete')
        map <unique> <leader>BD <Plug>XTablineBuffersDelete
    endif
    if !hasmapto('<Plug>XTablineAllBuffersDelete')
        map <unique> <leader>BA <Plug>XTablineAllBuffersDelete
    endif
    if !hasmapto('<Plug>XTablineBookmarksLoad')
        map <unique> <leader>BL <Plug>XTablineBookmarksLoad
    endif
    if !hasmapto('<Plug>XTablineBookmarksSave')
        map <unique> <leader>BS <Plug>XTablineBookmarksSave
    endif
    if !hasmapto('<Plug>XTablineTabTodo')
        map <unique> <leader>TT <Plug>XTablineTabTodo
    endif
endif

nnoremap <unique> <script> <Plug>XTablineToggleTabs <SID>ToggleTabs
nnoremap <SID>ToggleTabs :call <SID>ToggleTabs()<cr>

nnoremap <unique> <script> <Plug>XTablineToggleBuffers <SID>ToggleBuffers
nnoremap <SID>ToggleBuffers :call <SID>ToggleBuffers()<cr>

nnoremap <unique> <script> <Plug>XTablineSelectBuffer <SID>SelectBuffer
nnoremap <expr> <SID>SelectBuffer g:xtabline_changing_buffer ? "\<C-c>" : ":<C-u>call <SID>SelectBuffer(v:count)\<cr>"

nnoremap <unique> <script> <Plug>XTablineNextBuffer <SID>NextBuffer
nnoremap <SID>NextBuffer :call <SID>NextBuffer()<cr>

nnoremap <unique> <script> <Plug>XTablinePrevBuffer <SID>PrevBuffer
nnoremap <SID>PrevBuffer :call <SID>PrevBuffer()<cr>

nnoremap <unique> <script> <Plug>XTablineBuffersOpen <SID>TabBuffersOpen
nnoremap <SID>TabBuffersOpen :XTabBuffersOpen<cr>

nnoremap <unique> <script> <Plug>XTablineBuffersDelete <SID>TabBuffersDelete
nnoremap <SID>TabBuffersDelete :XTabBuffersDelete<cr>

nnoremap <unique> <script> <Plug>XTablineAllBuffersDelete <SID>TabAllBuffersDelete
nnoremap <SID>TabAllBuffersDelete :XTabAllBuffersDelete<cr>

nnoremap <unique> <script> <Plug>XTablineBookmarksLoad <SID>TabBookmarksLoad
nnoremap <SID>TabBookmarksLoad :XTabBookmarksLoad<cr>

nnoremap <unique> <script> <Plug>XTablineBookmarksSave <SID>TabBookmarksSave
nnoremap <SID>TabBookmarksSave :XTabBookmarksSave<cr>

nnoremap <unique> <script> <Plug>XTablineTabTodo <SID>TabTodo
nnoremap <SID>TabTodo :XTabTodo<cr>


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>ToggleTabs()
    """Toggle between tabs/buffers tabline."""

    if tabpagenr("$") == 1
        echo "There is only one tab."
        return
    endif

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

function! s:FilterBuffers(...)
    """Filter buffers so that only the ones within the tab's cwd will show up.

    " 'accepted' is a list of buffer numbers, for quick access.
    " 'excludes' is a list of paths, it will be used by Airline to hide buffers."""

    if !g:xtabline_filtering
        return
    endif

    let g:airline#extensions#tabline#accepted = []
    let g:airline#extensions#tabline#excludes = copy(g:xtabline_excludes)
    let s:accepted = g:airline#extensions#tabline#accepted
    let s:excludes = g:airline#extensions#tabline#excludes

    " bufnr(0) is the alternate buffer
    for buf in range(1, bufnr("$"))

        if !buflisted(buf)
            continue
        endif

        " get the path
        let path = expand("#".buf.":p")

        " confront with the cwd
        if path =~ getcwd()
            call add(s:accepted, buf)
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

function! <SID>NextBuffer()
    """Switch to next visible buffer."""

    if s:NotEnoughBuffers() || !g:xtabline_filtering
        return
    endif

    let ix = index(s:accepted, bufnr("%"))

    if bufnr("%") == s:accepted[-1]
        " last buffer, go to first
        let s:most_recent = s:accepted[0]

    elseif ix == -1
        " not in index, go back to most recent
        if s:most_recent == -1
            let s:most_recent = s:accepted[0]
        endif
    else
        let s:most_recent = s:accepted[ix + 1]
    endif

    execute "buffer " . s:most_recent
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>PrevBuffer()
    """Switch to previous visible buffer."""

    if s:NotEnoughBuffers() || !g:xtabline_filtering
        return
    endif

    let ix = index(s:accepted, bufnr("%"))

    if bufnr("%") == s:accepted[0]
        " first buffer, go to last
        let s:most_recent = s:accepted[-1]

    elseif ix == -1
        " not in index, go back to most recent
        if s:most_recent == -1
            let s:most_recent = s:accepted[0]
        endif
    else
        let s:most_recent = s:accepted[ix - 1]
    endif

    execute "buffer " . s:most_recent
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>SelectBuffer(nr)
    """Switch to visible buffer in the tabline with [count]."""

    if a:nr == 0
        execute g:xtabline_alt_action
        return
    endif

    if (a:nr > len(s:accepted)) || s:NotEnoughBuffers()
        return
    else
        let g:xtabline_changing_buffer = 1
        execute "buffer ".s:accepted[a:nr - 1]
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

    "fun! Format(nr)
        "return "[".a:nr."]".repeat(" ", 5 - len(a:nr)).bufname(a:nr)
    "endfunction

    return map(copy(s:accepted), 'bufname(v:val)')
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TabAllBuffers()
    """Open a list of all buffers with fzf.vim."""

    let listed = []
    for buf in range(1, bufnr("$"))
        if buflisted(buf)
            call add(listed, buf)
        endif
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
            if line['name'] !=# bm
                continue
            endif

            let cwd = expand(line['cwd'], ":p")
            if isdirectory(cwd)
                tabnew
                exe "cd ".cwd
                if empty(line['buffers'])
                    continue
                endif
            else
                echo line['name'].": invalid bookmark."
                continue
            endif

            "add buffers
            for buf in line['buffers']
                execute "badd ".buf
            endfor

            "load the first buffer
            execute "edit ".line['buffers'][0]
        endfor
    endfor
    call s:RefreshTabline()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>TabBookmarksSave()
    """Create an entry and add it to the bookmarks file."""

    if !g:xtabline_filtering
        echo "Activate tab filtering first."
    endif

    let entry = {}

    " get cwd
    try
        let entry['cwd'] = t:cwd
        let entry['name'] = input("Enter an optional name for this bookmark:  ", t:cwd, "file_in_path")
    catch
        echo "Cwd for this tab hasn't been set, aborting."
        return
    endtry

    if entry['name'] == ""
        echo "Bookmark not saved."
        return
    endif

    " get buffers
    let bufs = []
    let current = 0
    if buflisted(bufnr("%"))
        let current = bufnr("%")
        call add(bufs, bufname(current))
    endif
    for buf in range(1, bufnr("$"))
        if index(s:accepted, buf) >= 0 && (buf != current)
            call add(bufs, bufname(buf))
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
        execute "bdelete ".buf
        let ix = index(s:accepted, bufnr(buf))
        call remove(s:accepted, ix)
        call s:RefreshTabline()
    endfor
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:NotEnoughBuffers()
    """Just return if there aren't enough buffers."""

    if len(s:accepted) < 2
        if !len(s:accepted)
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

"function! <SID>XTablineAppend()
    """"Append a custom element to the tabline (default none)."""

    "if g:airline#extensions#tabline#show_tabs
        "return g:xtabline_append_tabs
    "else
        "return g:xtabline_append_buffers
    "endif
"endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" TabPageCd
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" tabpagecd - Turn :cd into :tabpagecd, to use one tab page per project
" expanded version by mg979
" Copyright (C) 2012-2013 Kana Natsuno <http://whileimautomaton.net/>
" Copyright (C) 2018 Gianmaria Bajo <mg1979.git@gmail.com>
" License: MIT License

function! s:InitCwds(new)
    if !exists('g:xtab_cwds')
        let g:xtab_cwds = []
    endif
    if a:new
        call insert(g:xtab_cwds, getcwd(), tabpagenr()-1)
    else
        while len(g:xtab_cwds) < tabpagenr("$")
            call add(g:xtab_cwds, getcwd())
        endwhile
    endif
    call s:Update()
endfunction

function! s:Update()
    let g:obsession_append = 'let g:xtab_cwds = '.string(g:xtab_cwds)
endfunction

function! s:TabEnterCommands()
    try
        let t:cwd = g:xtab_cwds[tabpagenr()-1]
    catch
        return
    endtry

    cd `=t:cwd`
    let g:xtabline_todo['path'] = t:cwd.g:xtabline_todo_file
    call s:FilterBuffers()
endfunction

function! s:TabLeaveCommands()
    let t:cwd = getcwd()
    let g:xtab_cwds[tabpagenr()-1] = t:cwd
    call s:Update()
endfunction

function! s:TabClosedCommands()
    if tabpagenr() == tabpagenr("$")
        call remove(g:xtab_cwds, tabpagenr())
    else
        call remove(g:xtab_cwds, tabpagenr()-1)
    endif
    call s:Update()
endfunction

augroup plugin-xtabline
    autocmd!

    autocmd VimEnter  * call s:InitCwds(0)
    autocmd TabNew    * call s:InitCwds(1)
    autocmd TabEnter  * call s:TabEnterCommands()
    autocmd TabLeave  * call s:TabLeaveCommands()
    autocmd TabClosed * call s:TabClosedCommands()

    autocmd BufEnter  * let g:xtabline_changing_buffer = 0
    autocmd BufAdd,BufDelete,BufWrite * call s:FilterBuffers(1)

augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
