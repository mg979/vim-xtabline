""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#toggle_tabs()
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
    doautocmd BufAdd
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#toggle_buffers()
    """Toggle buffer filtering in the tabline."""

    if g:xtabline_filtering
        let g:xtabline_filtering = 0
        let g:airline#extensions#tabline#accepted = []
        let g:airline#extensions#tabline#excludes = copy(g:xtabline_excludes)
        doautocmd BufAdd
    else
        let g:xtabline_filtering = 1
        call xtabline#filter_buffers()
        doautocmd BufAdd
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#purge_buffers()
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

    call xtabline#filter_buffers()
    let s = "Purged ".bcnt." buffer" | let s .= bcnt!=1 ? "s." : "." | echo s
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

    if !g:xtabline_filtering | return | endif

    let g:airline#extensions#tabline#accepted = []
    let g:airline#extensions#tabline#excludes = copy(g:xtabline_excludes)
    let t:accepted = g:airline#extensions#tabline#accepted
    let excludes = g:airline#extensions#tabline#excludes
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
            call add(excludes, path)
        elseif a:000 == [] && g:xtabline_autodelete_empty_buffers
            " buffer tabline breaks if there are empty 'paths'.
            " if there are problems, this can be just skipped.
            " since it seems useful, for now we're deleting
            " these temporary and empty buffers. This will happen
            " only when the function is called without arguments.
            execute "silent! bdelete ".buf
        endif
    endfor

    call xtabline#refresh_tabline()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Close(buf)
    if !getbufvar(a:buf, 'modified') | execute("silent! bdelete ".a:buf) | call xtabline#filter_buffers() | endif
endfun

fun! s:is_tab_buffer(...)
    if a:0
        return index(t:accepted, bufnr(a:0)) != -1 | endif
    return index(t:accepted, bufnr("%")) != -1
endfun

function! xtabline#close_buffer()
    """Close and delete a buffer, without closing the tab."""
    let current = bufnr("%") | let alt = bufnr("#") | let tabnr = tabpagenr()

    if buflisted(alt) && s:is_tab_buffer(alt)
        execute "buffer ".alt | call s:Close(current)

    elseif len(t:accepted) > 1 || (len(t:accepted) && !s:is_tab_buffer())
        call xtabline#next_buffer(1) | call s:Close(current)

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

function! xtabline#next_buffer(nr)
    """Switch to next visible buffer."""

    if ( xtabline#not_enough_buffers() || !g:xtabline_filtering ) | return | endif

    let ix = index(t:accepted, bufnr("%"))
    let target = ix + a:nr
    let total = len(t:accepted)

    if target >= total
        " over last buffer
        let s:most_recent = target - total

    elseif ix == -1
        " not in index, go back to most recent or back to first
        if s:most_recent == -1 || index(t:accepted, s:most_recent) == -1
            let s:most_recent = 0
        endif
    else
        let s:most_recent = target
    endif

    return ":buffer " . t:accepted[s:most_recent] . "\<cr>"
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#prev_buffer(nr)
    """Switch to previous visible buffer."""

    if ( xtabline#not_enough_buffers() || !g:xtabline_filtering ) | return | endif

    let ix = index(t:accepted, bufnr("%"))
    let target = ix - a:nr
    let total = len(t:accepted)

    if target < 0
        " before first buffer
        let s:most_recent = total + target

    elseif ix == -1
        " not in index, go back to most recent or back to first
        if s:most_recent == -1 || index(t:accepted, s:most_recent) == -1
            let s:most_recent = 0
        endif
    else
        let s:most_recent = target
    endif

    return ":buffer " . t:accepted[s:most_recent] . "\<cr>"
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#select_buffer(nr)
    """Switch to visible buffer in the tabline with [count]."""

    if ( a:nr == 0 || !g:xtabline_filtering ) | execute g:xtabline_alt_action | return | endif

    if (a:nr > len(t:accepted)) || xtabline#not_enough_buffers() || t:accepted[a:nr - 1] == bufnr("%")
        return
    else
        let g:xtabline_changing_buffer = 1
        execute "buffer ".t:accepted[a:nr - 1]
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
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#not_enough_buffers()
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

function! xtabline#refresh_tabline()
    call airline#extensions#tabline#buflist#invalidate()
endfunction

function! xtabline#init_vars()
    let s:most_recent = -1
endfunction
