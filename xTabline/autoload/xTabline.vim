""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" xTabline - extension for vim.airline
" Copyright (C) 2018 Gianmaria Bajo <mg1979.git@gmail.com>
" License: MIT License

if exists("g:loaded_xtabline")
  finish
endif

let s:xtabline_bookmaks_file = expand('$HOME/.vim/.XTablineBookmarks')
function! s:TabBookmarks()
    let bfile = readfile(g:NERDTreeBookmarksFile)
    let bookmarks = []
    "skip last emty line
    for line in bfile[:-2]
        let b = substitute(line, '^.\+ ', "", "")
        call add(bookmarks, b)
    endfor
    return bookmarks
endfunction

if !filereadable(s:xtabline_bookmaks_file)
    call writefile([], s:xtabline_bookmaks_file)
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands

"com! XTablineToggleTabs call s:ToggleTabs()

"com! XTablineNextBuffer call s:NextBuffer()

"com! XTablinePrevBuffer call s:PrevBuffer()

"com! XTablineSelectBuffer call s:SelectBuffer(v:count1)

com! TabBuffersOpen call fzf#run({'source': s:TabBuffers(),
                                \ 'sink': 'vs', 'down': '30%',
                                \ 'options': '--multi --reverse'})

com! TabBuffersDelete call fzf#run({'source': s:TabBuffers(),
                                  \ 'sink': 'bdelete', 'down': '30%',
                                  \ 'options': '--multi --reverse'})

com! TabBookmarks call fzf#run({'source': s:TabBookmarks(),
                              \ 'sink': 'XTablineBookmarksLoad', 'down': '30%',
                              \ 'options': '--multi --reverse'})

com! TabNERDBookmarks call fzf#run({'source': s:TabNERDBookmarks(),
                                  \ 'sink': 'XTablineNERDBookmarksLoad', 'down': '30%',
                                  \ 'options': '--multi --reverse'})

com! -nargs=* XTablineBookmarksLoad call s:TabBookmarksLoad(<f-args>)
com! -nargs=* XTablineNERDBookmarksLoad call s:TabNERDBookmarksLoad(<f-args>)

com! TabBookmarksSave call s:TabBookmarksSave()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables

let g:loaded_xtabline = 1
let s:most_recent = -1
let g:xtabline_filtering = 1
let g:xtabline_excludes = []
let g:xtabline_alt_action = "buffer #"
let g:xtabline_append_tabs = ''
let g:xtabline_append_buffers = ''
let g:airline#extensions#tabline#show_tabs = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings

if !exists('xtabline_keybindings')
    if !hasmapto('<Plug>XTablineToggleTabs')
        map <unique> <F5> <Plug>XTablineToggleTabs
    endif
    if !hasmapto('<Plug>XTablineToggleBuffers')
        map <unique> <leader><F5> <Plug>XTablineToggleBuffers
    endif
    if !hasmapto('<Plug>XTablineNextBuffer')
        map <unique> }O <Plug>XTablineNextBuffer
    endif
    if !hasmapto('<Plug>XTablinePrevBuffer')
        map <unique> {O <Plug>XTablinePrevBuffer
    endif
    if !hasmapto('<Plug>XTablineBuffersOpen')
        map <unique> <leader>BO <Plug>XTablineBuffersOpen
    endif
    if !hasmapto('<Plug>XTablineBuffersDelete')
        map <unique> <leader>BD <Plug>XTablineBuffersDelete
    endif
    if !hasmapto('<Plug>XTablineSelectBuffer')
        map <unique> <leader>l <Plug>XTablineSelectBuffer
    endif
endif

nnoremap <unique> <script> <Plug>XTablineToggleTabs <SID>ToggleTabs
nnoremap <SID>ToggleTabs :call <SID>ToggleTabs()<cr>

nnoremap <unique> <script> <Plug>XTablineToggleBuffers <SID>ToggleBuffers
nnoremap <SID>ToggleBuffers :call <SID>ToggleBuffers()<cr>

nnoremap <unique> <script> <Plug>XTablineNextBuffer <SID>NextBuffer
nnoremap <SID>NextBuffer :call <SID>NextBuffer()<cr>

nnoremap <unique> <script> <Plug>XTablinePrevBuffer <SID>PrevBuffer
nnoremap <SID>PrevBuffer :call <SID>PrevBuffer()<cr>

nnoremap <unique> <script> <Plug>XTablineBuffersOpen <SID>TabBuffersOpen
nnoremap <SID>TabBuffersOpen :TabBuffersOpen<cr>

nnoremap <unique> <script> <Plug>XTablineBuffersDelete <SID>TabBuffersDelete
nnoremap <SID>TabBuffersDelete :TabBuffersDelete<cr>

nnoremap <unique> <script> <Plug>XTablineSelectBuffer <SID>SelectBuffer
nnoremap <expr> <SID>SelectBuffer g:xtabline_changing_buffer ? "\<C-c>" : ":<C-u>call <SID>SelectBuffer(v:count)\<cr>"

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
    "let &tabline = airline#extensions#tabline#get().<SID>XTablineAppend()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>ToggleBuffers()
    """Toggle buffer filtering in the tabline."""

    if g:xtabline_filtering
        let g:xtabline_filtering = 0
        let g:airline#extensions#tabline#accepted = []
        let g:airline#extensions#tabline#excludes = copy(g:xtabline_excludes)
        call s:RefreshTabline()
    else
        let g:xtabline_filtering = 1
        call s:FilterBuffers()
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:FilterBuffers()
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
        else
            call add(s:excludes, path)
        endif
    endfor

    call s:RefreshTabline()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>NextBuffer()
    """Switch to next visible buffer."""

    if s:NotEnoughBuffers()
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

    if s:NotEnoughBuffers()
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
" fzf functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TabBuffers()
    """Open a list of buffers for this tab with fzf.vim."""

    "fun! Format(nr)
        "return "[".a:nr."]".repeat(" ", 5 - len(a:nr)).bufname(a:nr)
    "endfunction

    return map(copy(s:accepted), 'bufname(v:val)')
endfunction

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
endfunction

function! s:TabBookmarks()
    let s:xtabline_bookmaks = []
    let bookmarks = []
    let bfile = readfile(s:xtabline_bookmaks_file)

    for line in bfile
        let line = eval(line)
        call add(s:xtabline_bookmaks, line)
        call add(bookmarks, line['name'])
    endfor
    return bookmarks
endfunction

function! s:TabBookmarksLoad(...)
    let bfile = readfile(s:xtabline_bookmaks_file)

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
endfunction

function! s:TabBookmarksSave()
    """Create an entry and add it to the bookmarks file."""

    let entry = {}

    " get cwd
    try
        let entry['cwd'] = t:cwd
        let entry['name'] = t:cwd
    catch
        echo "Cwd for this tab hasn't been set, aborting."
        return
    endtry

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
    call writefile(entry, s:xtabline_bookmaks_file, "a")
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>XTablineAppend()
    """Append a custom element to the tabline (default none)."""

    if g:airline#extensions#tabline#show_tabs
        return g:xtabline_append_tabs
    else
        return g:xtabline_append_buffers
    endif
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
    execute "AirlineRefresh"
    set tabline=%!airline#extensions#tabline#get()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" TabPageCd
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" tabpagecd - Turn :cd into :tabpagecd, to use one tab page per project
" expanded version by mg979
" Copyright (C) 2012-2013 Kana Natsuno <http://whileimautomaton.net/>
" Copyright (C) 2018 Gianmaria Bajo <mg1979.git@gmail.com>
" License: MIT License

function! s:TabEnterCommands()
    if exists('t:cwd')
        cd `=t:cwd`
    endif
    call s:FilterBuffers()
    "let &tabline = airline#extensions#tabline#get().<SID>XTablineAppend()
endfunction

function! s:TabLeaveCommands()
    let t:cwd = getcwd()
endfunction

augroup plugin-xtabline
    autocmd!

    autocmd TabEnter * call s:TabEnterCommands()
    autocmd TabLeave * call s:TabLeaveCommands()

    autocmd BufAdd,BufDelete,BufWrite * call s:FilterBuffers()
    autocmd BufEnter * let g:xtabline_changing_buffer = 0

augroup END

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
