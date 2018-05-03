""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#toggle_tabs()
    """Toggle between tabs/buffers tabline."""

    if tabpagenr("$") == 1 | echo "There is only one tab." | return | endif

    if g:airline#extensions#tabline#show_tabs
        let g:airline#extensions#tabline#show_tabs = 0
        call xtabline#msg ([[ "Showing buffers", 'StorageClass' ]])
    else
        let g:airline#extensions#tabline#show_tabs = 1
        call xtabline#msg ([[ "Showing tabs", 'StorageClass' ]])
    endif

    execute "AirlineRefresh"
    doautocmd BufAdd
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#toggle_buffers()
    """Toggle buffer filtering in the tabline."""

    if g:xtabline_filtering
        let g:xtabline_filtering = 0
        let g:airline#extensions#tabline#accepted = []
        let g:airline#extensions#tabline#exclude_buffers = []
        call xtabline#msg ([[ "Buffer filtering turned off", 'WarningMsg' ]])
        doautocmd BufAdd
    else
        let g:xtabline_filtering = 1
        call xtabline#filter_buffers()
        call xtabline#msg ([[ "Buffer filtering turned on", 'StorageClass' ]])
        doautocmd BufAdd
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#restrict_cwd()
    """Ignore buffers that are outside the cwd, both upwards and downwards."""
    let t:restrict_cwd = get(t:, 'restrict_cwd', 0)

    if t:restrict_cwd
        let t:restrict_cwd = 0
        call xtabline#msg ([[ "Buffer filtering is not restricted anymore", 'StorageClass' ]])
    else
        let t:restrict_cwd = 1
        call xtabline#msg ([[ "Buffer filtering is now restricted to ", 'WarningMsg'], [ getcwd(), 'None' ]])
    endif
    doautocmd BufAdd
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#purge_buffers()
    """Remove unmodified buffers with invalid paths."""

    if !g:xtabline_filtering | echo "Buffer filtering is turned off." | return | endif
    let bcnt = 0 | let bufs = [] | let purged = [] | let accepted = t:xtl_accepted

    " include previews if not showing in tabline
    for buf in tabpagebuflist(tabpagenr())
        if index(accepted, buf) == -1 | call add(bufs, buf) | endif
    endfor

    " purge the buffer if:
    " 1. non-existant path and file unmodified
    " 2. path doesn't belong to cwd, but it has been accepted for partial match

    for buf in (accepted + bufs)
        let bufpath = fnamemodify(bufname(buf), ":p")

        if !filereadable(bufpath)
            if !getbufvar(buf, "&modified")
                let bcnt += 1 | let ix = index(accepted, buf)
                if ix >= 0 | call add(purged, remove(accepted, ix))
                else | call add(purged, buf) | endif
            endif

        elseif bufpath !~ "^".t:cwd
            let bcnt += 1 | let ix = index(accepted, buf)
            if ix >= 0 | call add(purged, remove(accepted, ix))
            else | call add(purged, buf) | endif
        endif
    endfor

    " the tab may be closed if there is one window, and it's going to be purged
    if len(tabpagebuflist()) == 1 && !empty(accepted) && index(purged, bufnr("%")) >= 0
        execute "buffer ".accepted[0] | endif

    for buf in purged | execute "silent! bdelete ".buf | endfor

    call xtabline#filter_buffers()
    let s = "Purged ".bcnt." buffer" | let s .= bcnt!=1 ? "s." : "." | echo s
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:all_buffers()
    " get all buffers
    redir => all
    silent buffers
    redir END
    let all = split(all, '\n')[2:]
    let all_ = []
    for b in all
        let b = b[:3]
        call add(all_, substitute(b, '\s', '', 'g'))
    endfor
    return all_
endfunction

function! xtabline#clean_up(...)
    let del = [] | let all = s:all_buffers() | let ok = []

    if a:0
        for b in all
            for cwd in g:xtab_cwds
                if expand("#".b.":p") =~ cwd
                    call add(ok, b)
                endif
            endfor
        endfor
    else
        for i in range(tabpagenr('$')) | call extend(ok, tabpagebuflist(i + 1)) | endfor
        let ok = map(ok, 'string(v:val)')
    endif

    let nr = 0
    for b in all
        if index(ok, b) == -1 && bufnr("%") != b
            execute "silent! bdelete ".b
            let nr += 1
        endif
    endfor

    let s = "Cleaned ".nr." buffer" | let s .= nr!=1 ? "s." : "."
    call xtabline#msg([[s, 'WarningMsg']])
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#reopen_last_tab()
    """Reopen the last closed tab."""

    if !exists('g:most_recently_closed_tab')
        echo "No recent tabs." | return | endif

    let tab = g:most_recently_closed_tab
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

function! xtabline#filter_buffers(...)
    """Filter buffers so that only the ones within the tab's cwd will show up.

    " 'accepted' is a list of buffer numbers, for quick access.
    " 'excludes' is a list of paths, it will be used by Airline to hide buffers."""

    " disable tabline while session is loading
    if exists('g:SessionLoad') && !a:0
        let g:airline#extensions#tabline#enabled   = 0
        return
    else
        let g:airline#extensions#tabline#enabled = 1
    endif

    if !g:xtabline_filtering | return | endif

    let g:airline#extensions#tabline#exclude_buffers = []

    let t:xtl_accepted  = []
    let t:xtl_excluded  = g:airline#extensions#tabline#exclude_buffers
    let accepted        = t:xtl_accepted
    let previews        = g:xtabline_include_previews
    let t:restrict_cwd  = get(t:, 'restrict_cwd', 0)
    let cwd             = getcwd()

    " bufnr(0) is the alternate buffer
    for buf in range(1, bufnr("$"))

        if !buflisted(buf) | continue | endif

        " get the path
        let path = expand("#".buf.":p")

        " confront with the cwd
        if t:restrict_cwd && path != cwd.s:sep().fnamemodify(path, ":t")
            call add(t:xtl_excluded, buf)
        elseif !previews && path =~ "^".cwd
            call add(accepted, buf)
        elseif previews && path =~ cwd
            call add(accepted, buf)
        else
            call add(t:xtl_excluded, buf)
        endif
    endfor

    call xtabline#refresh_tabline()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:close_buffer(buf)
    if !getbufvar(a:buf, '&modified') | execute("silent! bdelete ".a:buf) | call xtabline#filter_buffers() | endif
endfun

fun! s:is_tab_buffer(...)
    return (index(t:xtl_accepted, a:1) != -1)
endfun

function! xtabline#close_buffer()
    """Close and delete a buffer, without closing the tab."""
    let current = bufnr("%") | let alt = bufnr("#") | let tbufs = len(t:xtl_accepted)

    if buflisted(alt) && s:is_tab_buffer(alt)
        execute "buffer #" | call s:close_buffer(current)

    elseif ( tbufs > 1 ) || ( tbufs && !s:is_tab_buffer(current) )
        execute "normal \<Plug>XTablinePrevBufferBuffer" | call s:close_buffer(current)

    elseif !g:xtabline_close_buffer_can_close_tab
        echo "Last buffer for this tab."
        return

    elseif getbufvar(current, '&modified')
        call xtabline#msg("Not closing because of unsaved changes", 1)
        return

    elseif tabpagenr() > 1 || tabpagenr("$") != tabpagenr()
        tabnext | silent call s:close_buffer(current)
    else
        quit | endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#next_buffer(nr)
    """Switch to next visible buffer."""

    if ( xtabline#not_enough_buffers() || !g:xtabline_filtering ) | return | endif
    let accepted = t:xtl_accepted

    let ix = index(accepted, bufnr("%"))
    let target = ix + a:nr
    let total = len(accepted)

    if target >= total
        " over last buffer
        let s:most_recent = target - total

    elseif ix == -1
        " not in index, go back to most recent or back to first
        if s:most_recent == -1 || index(accepted, s:most_recent) == -1
            let s:most_recent = 0
        endif
    else
        let s:most_recent = target
    endif

    return ":buffer " . accepted[s:most_recent] . "\<cr>"
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#prev_buffer(nr)
    """Switch to previous visible buffer."""

    if ( xtabline#not_enough_buffers() || !g:xtabline_filtering ) | return | endif
    let accepted = t:xtl_accepted

    let ix = index(accepted, bufnr("%"))
    let target = ix - a:nr
    let total = len(accepted)

    if target < 0
        " before first buffer
        let s:most_recent = total + target

    elseif ix == -1
        " not in index, go back to most recent or back to first
        if s:most_recent == -1 || index(accepted, s:most_recent) == -1
            let s:most_recent = 0
        endif
    else
        let s:most_recent = target
    endif

    return ":buffer " . accepted[s:most_recent] . "\<cr>"
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#select_buffer(nr)
    """Switch to visible buffer in the tabline with [count]."""

    if ( a:nr == 0 || !g:xtabline_filtering ) | execute g:xtabline_alt_action | return | endif
    let accepted = t:xtl_accepted

    if (a:nr > len(accepted)) || xtabline#not_enough_buffers() || accepted[a:nr - 1] == bufnr("%")
        return
    else
        let g:xtabline_changing_buffer = 1
        execute "buffer ".accepted[a:nr - 1]
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#tab_todo()
    let todo = g:xtabline_todo
    if todo['command'] == 'edit'
        execute "edit ".todo['path']
    else
        execute todo['prefix']." ".todo['size'].todo['command']." ".todo['path']
    endif
    execute "setlocal syntax=".todo['syntax']
    nmap <silent> <buffer> q :unmap <buffer> q<cr>:quit<cr>
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:sep()
    return exists('+shellslash') && &shellslash ? '\' : '/'
endfun

fun! xtabline#msg(txt, ...)
    if type(a:txt) == v:t_string
        exe "echohl" a:1? "WarningMsg" : "Label"
        echon a:txt | echohl None
        return | endif

    for txt in a:txt
        exe "echohl ".txt[1]
        echon txt[0]
        echohl None
    endfor
endfun

function! xtabline#tab_buffers()
    """Return a list of buffers names for this tab."""

    return map(copy(t:xtl_accepted), 'bufname(v:val)')
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#not_enough_buffers()
    """Just return if there aren't enough buffers."""

    if len(t:xtl_accepted) < 2
        if index(t:xtl_accepted, bufnr("%")) == -1
            return
        elseif !len(t:xtl_accepted)
            call xtabline#msg ([[ "No available buffers for this tab.", 'WarningMsg' ]])
        else
            call xtabline#msg ([[ "No other available buffers for this tab.", 'WarningMsg' ]])
        endif
        return 1
    endif
endfunction

function! xtabline#refresh_tabline()
    call airline#extensions#tabline#buflist#invalidate()
endfunction

function! xtabline#init_vars()
    let s:most_recent = -1
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#init_cwds()
    if !exists('g:xtab_cwds') | let g:xtab_cwds = [] | endif

    while len(g:xtab_cwds) < tabpagenr("$") | call add(g:xtab_cwds, getcwd()) | endwhile
    while len(g:xtab_cwds) > tabpagenr('$') | call remove(g:xtab_cwds, -1)    | endwhile
    let t:cwd = getcwd()
    call xtabline#filter_buffers(1)
endfunction

function! xtabline#update_obsession()
    let string = 'let g:xtab_cwds = '.string(g:xtab_cwds).' | call xtabline#update_obsession()'
    if !exists('g:obsession_append')
        let g:obsession_append = [string]
    else
        call filter(g:obsession_append, 'v:val !~# "^let g:xtab_cwds"')
        call add(g:obsession_append, string)
    endif

    call xtabline#init_cwds()
endfunction

