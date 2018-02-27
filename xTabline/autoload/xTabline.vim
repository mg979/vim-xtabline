""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" xTabline - extension for vim.airline
" Copyright (C) 2018 Gianmaria Bajo <mg1979.git@gmail.com>
" License: MIT License

if exists("g:loaded_xtabline")
  finish
endif
let g:loaded_xtabline = 1


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands

"com! XTablineToggleTabs call s:Toggle_tabs()

"com! XTablineNextBuffer call s:NextBuffer()

"com! XTablinePrevBuffer call s:PrevBuffer()

"com! XTablineSelectBuffer call s:SelectBuffer(v:count1)

com! TabBuffersOpen call fzf#run({'source': s:TabBuffers(),
                                \ 'sink': 'vs', 'down': '30%',
                                \ 'options': '--multi --reverse'})

com! TabBuffersDelete call fzf#run({'source': s:TabBuffers(),
                                  \ 'sink': 'bdelete', 'down': '30%',
                                  \ 'options': '--multi --reverse'})

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables

let s:most_recent = -1
let g:xtabline_excludes = []
let g:xtabline_alt_action = "buffer #"
let g:xtabline_append_tabs = ''
let g:xtabline_append_buffers = ''
let g:airline#extensions#tabline#show_tabs = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings

if !hasmapto('<Plug>XTablineToggleTabs')
    map <unique> <F5> <Plug>XTablineToggleTabs
endif
if !hasmapto('<Plug>XTablineNextBuffer')
    map <unique> }O <Plug>XTablineNextBuffer
endif
if !hasmapto('<Plug>XTablinePrevBuffer')
    map <unique> {O <Plug>XTablinePrevBuffer
endif
if !hasmapto('<Plug>XTablineSelectBuffer')
    map <unique> <leader>l <Plug>XTablineSelectBuffer
endif

nnoremap <unique> <script> <Plug>XTablineToggleTabs <SID>Toggle_tabs
nnoremap <SID>Toggle_tabs :call <SID>Toggle_tabs()<cr>

nnoremap <unique> <script> <Plug>XTablineNextBuffer <SID>NextBuffer
nnoremap <SID>NextBuffer :call <SID>NextBuffer()<cr>

nnoremap <unique> <script> <Plug>XTablinePrevBuffer <SID>PrevBuffer
nnoremap <SID>PrevBuffer :call <SID>PrevBuffer()<cr>

nnoremap <unique> <script> <Plug>XTablineSelectBuffer <SID>SelectBuffer
nnoremap <expr> <SID>SelectBuffer g:xtabline_changing_buffer ? "\<C-c>" : ":<C-u>call <SID>SelectBuffer(v:count)\<cr>"

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! <SID>Toggle_tabs()
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

function! s:FilterBuffers()
    """Filter buffers so that only the ones within the tab's cwd will show up.

    " 'accepted' is a list of buffer numbers, for quick access.
    " 'excludes' is a list of paths, it will be used by Airline to hide buffers."""

    let g:airline#extensions#tabline#accepted = []
    let g:airline#extensions#tabline#excludes = [] + g:xtabline_excludes
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

    let g:xtabline_changing_buffer = 1

    if a:nr == 0
        execute g:xtabline_alt_action
    elseif (a:nr > len(s:accepted)) || s:NotEnoughBuffers()
        return
    else
        execute "buffer ".s:accepted[a:nr - 1]
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:TabBuffers()
    """Open a list of buffers for this tab with fzf.vim."""

    "fun! Format(nr)
        "return "[".a:nr."]".repeat(" ", 5 - len(a:nr)).bufname(a:nr) 
    "endfunction

    return map(s:accepted, 'bufname(v:val)')
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
