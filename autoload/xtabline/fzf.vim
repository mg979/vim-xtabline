""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" fzf helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:get_color(attr, ...)
    let gui = has('termguicolors') && &termguicolors
    let fam = gui ? 'gui' : 'cterm'
    let pat = gui ? '^#[a-f0-9]\+' : '^[0-9]\+$'
    for group in a:000
        let code = synIDattr(synIDtrans(hlID(group)), a:attr, fam)
        if code =~? pat
            return code
        endif
    endfor
    return ''
endfunction

let s:ansi = {'black': 30, 'red': 31, 'green': 32, 'yellow': 33, 'blue': 34, 'magenta': 35, 'cyan': 36}

function! s:csi(color, fg)
    let prefix = a:fg ? '38;' : '48;'
    if a:color[0] == '#'
        return prefix.'2;'.join(map([a:color[1:2], a:color[3:4], a:color[5:6]], 'str2nr(v:val, 16)'), ';')
    endif
    return prefix.'5;'.a:color
endfunction

function! s:ansi(str, group, default, ...)
    let fg = s:get_color('fg', a:group)
    let bg = s:get_color('bg', a:group)
    let color = s:csi(empty(fg) ? s:ansi[a:default] : fg, 1) .
                \ (empty(bg) ? '' : s:csi(bg, 0))
    return printf("\x1b[%s%sm%s\x1b[m", color, a:0 ? ';1' : '', a:str)
endfunction

for s:color_name in keys(s:ansi)
    execute "function! s:".s:color_name."(str, ...)\n"
                \ "  return s:ansi(a:str, get(a:, 1, ''), '".s:color_name."')\n"
                \ "endfunction"
endfor

function! s:strip(str)
    return substitute(a:str, '^\s*\|\s*$', '', 'g')
endfunction

function! s:format_buffer(b)
    let name = bufname(a:b)
    let name = empty(name) ? '[No Name]' : fnamemodify(name, ":~:.")
    let flag = a:b == bufnr('')  ? s:blue('%', 'Conditional') :
                \ (a:b == bufnr('#') ? s:magenta('#', 'Special') : ' ')
    let modified = getbufvar(a:b, '&modified') ? s:red(' [+]', 'Exception') : ''
    let readonly = getbufvar(a:b, '&modifiable') ? '' : s:green(' [RO]', 'Constant')
    let extra = join(filter([modified, readonly], '!empty(v:val)'), '')
    return s:strip(printf("[%s] %s\t%s\t%s", s:yellow(a:b, 'Number'), flag, name, extra))
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" fzf functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#tab_buffers()
    """Open a list of buffers for this tab with fzf.vim."""

    let current = bufnr("%") | let alt = bufnr("#")
    let l = sort(map(copy(t:xtl_accepted), 's:format_buffer(v:val)'))
    if alt != -1 && index(t:xtl_accepted, alt) >= 0
        call insert(l, remove(l, index(l, s:format_buffer(current))))
    endif
    call insert(l, remove(l, index(l, s:format_buffer(current))))
    return l
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#bufdelete(name)
    if len(a:name) < 2
        return
    endif
    let b = matchstr(a:name, '^.*]')
    let b = substitute(b[1:], ']', '', '')
    execute 'silent! bdelete '.b
    call xtabline#filter_buffers()
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
        if index(t:xtl_accepted, buf) >= 0 && (buf != current)
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
        let ix = index(t:xtl_accepted, bufnr(buf))
        call remove(t:xtl_accepted, ix)
        call xtabline#filter_buffers()
    endfor
endfunction


