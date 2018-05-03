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

fun! xtabline#fzf#colors()
    if &t_Co == 256 && !empty(get(g:, 'xtabline_fzf_colors', {}))
        let s:ansi = g:xtabline_fzf_colors
    elseif &t_Co == 256
        let s:ansi = {'black': 234, 'red': 196, 'green': 41, 'yellow': 229, 'blue': 63, 'magenta': 213, 'cyan': 159}
    elseif &t_Co == 16
        let s:ansi = {'black': 0, 'red': 9, 'green': 10, 'yellow': 11, 'blue': 12, 'magenta': 13, 'cyan': 14}
    else
        let s:ansi = {'black': 0, 'red': 1, 'green': 2, 'yellow': 3, 'blue': 4, 'magenta': 5, 'cyan': 6}
    endif

    for s:color_name in keys(s:ansi)
        execute "function! s:".s:color_name."(str, ...)\n"
                    \ "  return s:ansi(a:str, get(a:, 1, ''), '".s:color_name."')\n"
                    \ "endfunction"
    endfor
endfun
call xtabline#fzf#colors()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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

fun! s:sep()
    return exists('+shellslash') && &shellslash ? '\' : '/'
endfun

function! s:pad(t, n)
    if len(a:t) > a:n
        return a:t[:(a:n-1)]."…"
    else
        let spaces = a:n - len(a:t)
        let spaces = printf("%".spaces."s", "")
        return a:t.spaces
    endif
endfunction






""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" fzf functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#tab_buffers()
    """Open a list of buffers for this tab with fzf.vim."""

    let current = bufnr("%") | let alt = bufnr("#")
    let l = sort(map(copy(t:xtl_accepted), 's:format_buffer(v:val)'))

    "put alternate buffer last (but current will go after it)
    if alt != -1 && index(t:xtl_accepted, alt) >= 0
        call insert(l, remove(l, index(l, s:format_buffer(alt))))
    endif

    "put current buffer last
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
    let bookmarks = ["Name\t\t\tDescription\t\t\t\t\tBuffers\t\tWorking Dirctory"]
    let json = json_decode(readfile(g:xtabline_bookmaks_file)[0])

    for bm in keys(json)
        let desc = has_key(json[bm], 'description')? json[bm].description : ''
        let line = s:yellow(s:pad(bm, 20))."\t".s:cyan(s:pad(desc, 40))."\t".len(json[bm].buffers)." Buffers\t".json[bm].cwd
        call add(bookmarks, line)
    endfor
    return bookmarks
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#tab_bookmarks_load(...)
    """Load a tab bookmark."""
    let json = json_decode(readfile(g:xtabline_bookmaks_file)[0])

    for bm in a:000
        let name = json[substitute(bm, '\(\w*\)\s*\t.*', '\1', '')]
        let cwd = expand(name['cwd'], ":p")

        if isdirectory(cwd)
            tabnew | let newbuf = bufnr("%")
            exe "cd ".cwd
            let t:cwd = cwd
            if empty(name['buffers']) | continue | endif
        else
            call xtabline#msg(name['name'].": invalid bookmark.", 1) | continue
        endif

        "add buffers
        for buf in name['buffers'] | execute "badd ".buf | endfor

        "load the first buffer
        execute "edit ".name['buffers'][0]

        " purge the empty buffer that was created
        execute "bdelete ".newbuf
    endfor
    doautocmd BufAdd
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#tab_bookmarks_delete(...)
    """Delete a tab bookmark."""
    let json = json_decode(readfile(g:xtabline_bookmaks_file)[0])

    for bm in a:000
        let name = substitute(bm, '\(\w*\)\s*\t.*', '\1', '')
        call remove(json, name)
    endfor

    "write the file
    call writefile([json_encode(json)],g:xtabline_bookmaks_file)
    call xtabline#msg ([[ "Tab bookmark ", 'WarningMsg' ],
                       \[ name, 'Type' ],
                       \[ " deleted.", 'WarningMsg' ]])
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#tab_bookmarks_save()
    """Create an entry and add it to the bookmarks file."""

    if !g:xtabline_filtering
        call xtabline#msg("Activate buffer filtering first.", 1) | return | endif

    let json = json_decode(readfile(g:xtabline_bookmaks_file)[0])

    "get name
    let s = fnamemodify(t:cwd, ':t')
    let name = input("Enter a name for this bookmark:  ", s, "file_in_path")
    if empty(name) | call xtabline#msg("Bookmark not saved.", 1) | return | endif

    let json[name] = {}

    "get description
    let json[name].description = input("Enter an optional short description for this bookmark:  ")

    " get cwd
    let t:cwd = getcwd()
    let json[name].cwd = t:cwd

    " get buffers
    let bufs = []
    let current = 0
    if buflisted(bufnr("%")) && index(t:xtl_accepted, bufnr("%"))
        let current = bufnr("%")
        call add(bufs, bufname(current))
    endif
    for buf in range(1, bufnr("$"))
        if index(t:xtl_accepted, buf) >= 0 && (buf != current)
            call add(bufs, fnameescape(bufname(buf)))
        endif
    endfor
    let json[name].buffers = bufs

    "write the file
    call writefile([json_encode(json)], g:xtabline_bookmaks_file)
    call xtabline#msg("\tTab bookmark saved.", 0)
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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sessions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:desc_string(s, n, sfile)
    let active_mark = (a:s == v:this_session) ? s:green(" [%]  ") : '      '
    let description = get(a:sfile, a:n, '')
    let spaces = 30 - len(a:n)
    let spaces = printf("%".spaces."s", "")
    let pad = empty(active_mark) ? '     ' : ''
    let time = system('date=`stat -c %Y '.fnameescape(a:s).'` && date -d@"$date" +%Y.%m.%d')[:-2]
    return s:yellow(a:n).spaces."\t".s:cyan(time).pad.active_mark.description
endfunction

function! xtabline#fzf#sessions_list()
    let data = ["Session\t\t\t\tTimestamp\tDescription"] | let sfile = {}
    let sfile = json_decode(readfile(g:xtabline_sessions_data)[0])
    let sessions = split(globpath(expand(g:xtabline_sessions_path, ":p"), "*"), '\n')

    for s in sessions
        let active_mark = (s == v:this_session) ? '[%]   ' : ''
        let n = fnamemodify(expand(s), ':t:r')
        let description = s:desc_string(s, n, sfile)
        call add(data, description)
    endfor
    return data
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#session_load(file)

    " abort if there are unsaved changes
    for b in range(1, bufnr("$"))
        if getbufvar(b, '&modified')
            call xtabline#msg("Some buffer has unsaved changes. Aborting.", 1)
            return | endif | endfor

    "-----------------------------------------------------------

    let session = a:file
    if match(session, "\t") | let session = substitute(session, " *\t.*", "", "") | endif
    let file = expand(g:xtabline_sessions_path.s:sep().session, ":p")

    if !filereadable(file)    | call xtabline#msg("Session file doesn't exist.", 1) | return | endif
    if file == v:this_session | call xtabline#msg("Session is already loaded.", 1)  | return | endif

    "-----------------------------------------------------------

    call xtabline#msg ([[ "Current session will be unloaded.", 'WarningMsg' ],
                       \[ " Confirm (y/n)? ", 'Type' ]])

    if nr2char(getchar()) !=? 'y'
        call xtabline#msg ([[ "Canceled.", 'WarningMsg' ]]) | return | endif

    "-----------------------------------------------------------

    " upadate and pause Obsession
    if ObsessionStatus() == "[$]" | exe "silent Obsession ".fnameescape(g:this_obsession) | silent Obsession | endif

    execute "silent! %bdelete"
    execute "source ".fnameescape(file)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#session_delete(file)

    let session = a:file
    if match(session, "\t") | let session = substitute(session, " *\t.*", "", "") | endif
    let file = expand(g:xtabline_sessions_path.s:sep().session, ":p")

    if !filereadable(file)    | call xtabline#msg("Session file doesn't exist.", 1) | return | endif

    "-----------------------------------------------------------

    call xtabline#msg ([[ "Selected session will be deleted.", 'WarningMsg' ],
                       \[ " Confirm (y/n)? ", 'Type' ]])

    if nr2char(getchar()) !=? 'y'
        call xtabline#msg ([[ "Canceled.", 'WarningMsg' ]]) | return | endif

    "-----------------------------------------------------------

    if file == v:this_session | silent Obsession!
    else                      | silent exe "!rm ".file | endif

    call xtabline#msg ([[ "Session ", 'WarningMsg' ],
                       \[ file, 'Type' ],
                       \[ " has been deleted.", 'WarningMsg' ]])
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#fzf#session_save()
    let data = json_decode(readfile(g:xtabline_sessions_data)[0])

    let defname = empty(v:this_session) ? '' : fnamemodify(v:this_session, ":t")
    let defdesc = get(data, defname, '')
    let name = input('Enter a name for this session:   ', defname)
    if !empty(name)
        let data[name] = input('Enter an optional description:   ', defdesc)
        call xtabline#msg("\nConfirm (y/n)\t", 0)
        if nr2char(getchar()) ==? 'y'
            call writefile([json_encode(data)], g:xtabline_sessions_data)
            let file = expand(g:xtabline_sessions_path.s:sep().name, ":p")
            silent execute "Obsession ".fnameescape(file)
            call xtabline#msg("Session '".file."' has been saved.", 0)
            return
        endif
    endif
    call xtabline#msg("Session not saved.", 1)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#update_sessions_file()
    let sfile = readfile(g:xtabline_sessions_data)
    let json = {}

    for key in sfile
        let json[key] = sfile[key]
    endfor
    call writefile([json_encode(json)], g:xtabline_sessions_data)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#update_bookmarks_file()
    let bfile = readfile(g:xtabline_bookmaks_file)
    let json = {}

    for line in bfile
        let line = eval(line)
        let name = line['name']
        call remove(line, 'name')
        let json[name] = line
        let json[name]['description'] = ""
    endfor
    call writefile([json_encode(json)], g:xtabline_bookmaks_file)
endfun
