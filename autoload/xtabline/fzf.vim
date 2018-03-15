""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" fzf functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#tab_buffers()
    """Open a list of buffers for this tab with fzf.vim."""

    return map(copy(t:accepted), 'bufname(v:val)')
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#tab_all_buffers()
    """Open a list of all buffers with fzf.vim."""

    let listed = []
    for buf in range(1, bufnr("$"))
        if buflisted(buf) | call add(listed, buf) | endif
    endfor
    return map(listed, 'bufname(v:val)')
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#tab_nerd_bookmarks()
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

function! xtabline#fzf#tab_nerd_bookmarks_load(...)
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
    call xtabline#refresh_tabline()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#tab_bookmarks()
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

function! xtabline#fzf#tab_bookmarks_load(...)
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

function! xtabline#fzf#tab_bookmarks_save()
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

function! xtabline#fzf#tab_delete(...)

    for buf in a:000
        execute "silent! bdelete ".buf
        let ix = index(t:accepted, bufnr(buf))
        call remove(t:accepted, ix)
        call xtabline#filter_buffers()
    endfor
endfunction


