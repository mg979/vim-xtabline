""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" fzf commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X = g:xtabline
let s:F = g:xtabline.Funcs
let s:v = g:xtabline.Vars
let s:Sets = g:xtabline_settings

let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:B =  { -> s:X.Buffers             }       "customized buffers
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tab buffers {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#tab_buffers()
  """Open a list of buffers for this tab with fzf.vim."""

  let current = bufnr("%") | let alt = bufnr("#")
  let l = sort(map(copy(s:vB()), 's:format_buffer(v:val)'))

  "put alternate buffer last (but current will go after it)
  if alt != -1 && index(s:vB(), alt) >= 0
    call insert(l, remove(l, index(l, s:format_buffer(alt))))
  endif

  "put current buffer last
  call insert(l, remove(l, index(l, s:format_buffer(current))))
  return l
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#bufdelete(name)
  let current = bufnr('%')
  if len(a:name) < 2
    return
  endif
  let b = matchstr(a:name, '^.*]')
  let b = substitute(b[1:], ']', '', '')
  if b != current
    execute 'silent! bdelete '.b
    execute 'buffer '.current
  else
    call xtabline#cmds#run('close_buffer')
  endif
  call xtabline#update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tabs overview {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#tablist()
  let lines = []
  for tab in range(tabpagenr("$"))
    let T = g:xtabline.Tabs[tab]
    let bufs = len(T.buffers.valid)
    " let icon = empty(T.icon) ? s:Sets.tab_icon[0] : T.icon
    let line = s:yellow(s:pad(tab+1, 5))."\t".
          \    s:green(s:pad(bufs, 5))."\t".
          \    s:green(s:pad(empty(T.vimrc) ? "no" : "yes", 5))."\t\t".
          \    s:cyan(s:pad(T.name, 20))."\t".
          \    s:pad(s:short_cwd(T.cwd, &columns<150), &columns/2)
    call add(lines, line)
  endfor
  call add(lines, "Tab\tBufs\tVimrc?\t\tName\t\t\tWorking Directory")
  return reverse(lines)
endfun

fun! xtabline#fzf#tabopen(line)
  let tab = a:line[0:(match(a:line, '\s')-1)]
  exe "normal!" tab."gt"
endfun

fun! s:short_cwd(cwd, h)
  if !a:h
    return fnamemodify(a:cwd, ":~")
  else
    let H = fnamemodify(a:cwd, ":~")
    if s:v.winOS
      let H = tr(H, '\', '/')
    endif
    while len(split(H, '/')) > a:h+1
      let H = substitute(H, '/\([^/]\)[^/]*', '°\1', "")
    endwhile
    return tr(H, '°', '/')
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Saved tabs {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#tabs()
  let json = json_decode(readfile(s:Sets.bookmarks_file)[0])

  let bookmarks = &columns > 99 ?
        \ ["Name\t\t\tDescription\t\t\t\tBuffers\t\tWorking Directory"] :
        \ ["Name\t\t\tBuffers\t\tWorking Directory"]

  for bm in keys(json)
    let desc = has_key(json[bm], 'description')? json[bm].description : ''
    if &columns > 99
      let line = s:yellow(s:pad(bm, 19))."\t".
            \    s:cyan(s:pad(desc, 39))."\t".
            \    len(json[bm].buffers) . " Buffers\t" . json[bm].cwd
    else
      let line = s:yellow(s:pad(bm, 19))."\t".
            \    len(json[bm].buffers) . " Buffers\t" . json[bm].cwd
    endif
    call add(bookmarks, line)
  endfor
  return bookmarks
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:abort_load(name, fzf_line, error_type)
  let s:v.halt = 0
  if a:error_type == 'buffers'
    call s:F.msg ([[ a:name, 'Type' ],
          \[ ": no saved buffers. Remove entry?\t", 'WarningMsg' ]])
  else
    call s:F.msg ([[ a:name, 'Type' ],
          \[ ": invalid directory. Remove entry?\t", 'WarningMsg' ]])
  endif
  if nr2char(getchar()) == 'y'
    call xtabline#fzf#tab_delete(a:fzf_line)
  endif
endfun

fun! xtabline#fzf#tab_load(...)
  """Load a saved tab."""
  let json = json_decode(readfile(s:Sets.bookmarks_file)[0])
  let s:v.halt = 1

  for bm in a:000
    let name = substitute(bm, '\(\w*\)\s*\t.*', '\1', '')
    let saved = json[name]
    let cwd = s:F.fullpath(saved['cwd'])

    if isdirectory(cwd) && empty(saved.buffers)        "no valid buffers
      call s:abort_load(name, bm, 'buffers') | return
    elseif !isdirectory(cwd)                           "invalid directory
      call s:abort_load(name, bm, 'dir')     | return
    endif

    "tab properties defined here will be applied by new_tab(), run by autocommand
    let s:v.tab_properties = {'cwd': cwd, 'dirs': [cwd]}
    let T = s:v.tab_properties
    for prop in keys(saved)
      if prop ==? 'buffers' || prop ==? 'description'   | continue | endif
      let T[prop] = saved[prop]
    endfor

    $tabnew | let newbuf = bufnr("%")
    cd `=cwd`

    "add buffers
    for buf in saved['buffers']
      execute "badd ".buf
      if get(T, 'locked', 0)
        call add(T.buffers.valid, bufnr("%"))
      endif
    endfor

    "load the first buffer
    execute "edit ".saved['buffers'][0]

    " purge the empty buffer that was created
    execute "bwipe ".newbuf
  endfor
  let s:v.halt = 0
  call xtabline#update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#tab_delete(...)
  """Delete a saved tab."""
  let json = json_decode(readfile(s:Sets.bookmarks_file)[0])

  for bm in a:000
    let name = substitute(bm, '\(\w*\)\s*\t.*', '\1', '')
    call remove(json, name)
  endfor

  "write the file
  call writefile([json_encode(json)],s:Sets.bookmarks_file)
  call s:F.msg ([[ "Tab bookmark ", 'WarningMsg' ],
        \[ name, 'Type' ],
        \[ " deleted.", 'WarningMsg' ]])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#tab_save()
  """Create an entry and add it to the saved tabs file."""

  if !s:v.filtering
    call s:F.msg("Activate buffer filtering first.", 1) | return | endif

  let json = json_decode(readfile(s:Sets.bookmarks_file)[0])
  let T = s:T()

  " get name
  let s = !empty(T.name)? T.name : fnamemodify(T.cwd, ':t')
  let name = input("Enter a name for this bookmark:  ", s, "file_in_path")
  if empty(name) | call s:F.msg("Bookmark not saved.", 1) | return | endif

  let json[name] = {}

  " get description
  let json[name].description = input("Enter an optional short description for this bookmark:  ")

  " set tab properties
  let json[name].cwd = T.cwd
  let json[name].name = T.name
  let json[name].locked = T.locked
  let json[name].vimrc = T.vimrc
  let json[name].depth = T.depth
  if has_key(T, 'icon') | let json[name].icon = T.icon | endif

  if T.locked
    let json[name].valid_buffers = T.buffers.valid
  endif

  " get buffers
  let bufs = []
  let current = 0
  if buflisted(bufnr("%")) && index(s:vB(), bufnr("%"))
    let current = bufnr("%")
    call add(bufs, bufname(current))
  endif
  for buf in s:oB()
    if index(s:vB(), buf) >= 0 && (buf != current)
      call add(bufs, fnameescape(bufname(buf)))
    endif
  endfor
  let json[name].buffers = bufs

  " write the file
  call writefile([json_encode(json)], s:Sets.bookmarks_file)
  call s:F.msg("\tTab bookmark saved.", 0)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sessions {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:lastmod = { f -> str2nr(system('date -r '.f.' +%s')) }

fun! s:desc_string(s, n, sfile, color)
  let active_mark = (a:s ==# v:this_session) ? a:color ? s:green(" [%]  ") : " [%]  " : '      '
  let description = get(a:sfile, a:n, '')
  let spaces = 30 - len(a:n)
  let spaces = printf("%".spaces."s", "")
  let pad = empty(active_mark) ? '     ' : ''
  if !s:v.winOS
    let time = system('date=`stat -c %Y '.fnameescape(a:s).'` && date -d@"$date" +%Y.%m.%d')[:-2]
  else
    let time = ''
  endif
  if a:color
    return s:yellow(a:n).spaces."\t".s:cyan(time).pad.active_mark.description
  else
    return a:n.spaces."\t".time.pad.active_mark.description
  endif
endfun

fun! xtabline#fzf#sessions_list(...)
  let data = a:0 ? [] : ["Session\t\t\t\tTimestamp\tDescription"] | let sfile = {}
  let sfile = json_decode(readfile(s:Sets.sessions_data)[0])
  let sessions = split(globpath(expand(s:Sets.sessions_path, ":p"), "*"), '\n')

  "remove __LAST__ session
  let last = expand(s:Sets.sessions_path, ":p").s:F.sep().'__LAST__'
  let _last = index(sessions, last)
  if _last >= 0 | call remove(sessions, _last) | endif

  if !s:v.winOS
    "sort sessions by last modfication time
    let times = {}
    for s in sessions
      let t = s:lastmod(s)
      "prevent key overwriting
      while has_key(times, t) | let t += 1 | endwhile
      let times[t] = s
    endfor

    let ord_times = map(keys(times), 'str2nr(v:val)')
    let ord_times = reverse(sort(ord_times, 'n'))
    let ordered = map(ord_times, 'times[v:val]')

    "readd __LAST__ if found
    if _last >= 0 | call add(ordered, last) | endif
  else
    let ordered = sessions
  endif

  for s in ordered
    let n = fnamemodify(expand(s), ':t:r')
    let description = s:desc_string(s, n, sfile, !a:0)
    call add(data, description)
  endfor
  return data
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#session_load(file)

  " abort if there are unsaved changes
  for b in range(1, bufnr("$"))
    if getbufvar(b, '&modified')
      call s:F.msg("Some buffer has unsaved changes. Aborting.", 1)
      return
    endif | endfor

  "-----------------------------------------------------------

  let session = a:file
  if match(session, "\t") | let session = substitute(session, " *\t.*", "", "") | endif
  let file = expand(s:Sets.sessions_path.s:F.sep().session, ":p")

  if !filereadable(file)     | call s:F.msg("Session file doesn't exist.", 1) | return | endif
  if file ==# v:this_session | call s:F.msg("Session is already loaded.", 1)  | return | endif

  "-----------------------------------------------------------
  " confirm session unloading

  if get(s:Sets, 'unload_session_ask_confirm', 1)
    call s:F.msg ([[ "Current session will be unloaded.", 'WarningMsg' ],
          \[ " Confirm (y/n)? ", 'Type' ]])

    if nr2char(getchar()) !=? 'y'
      call s:F.msg ([[ "Canceled.", 'WarningMsg' ]]) | return | endif
  endif

  "-----------------------------------------------------------
  " upadate and pause Obsession

  if ObsessionStatus() == "[$]"
    exe "silent Obsession ".fnameescape(g:this_obsession)
    silent Obsession
  endif

  "-----------------------------------------------------------
  " unload current session and load new one

  execute "silent! %bdelete"
  execute "source ".fnameescape(file)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#session_delete(file)

  let session = a:file
  if match(session, "\t")
    let session = substitute(session, " *\t.*", "", "") | endif
  let file = expand(s:Sets.sessions_path.s:F.sep().session, ":p")

  if !filereadable(file)
    call s:F.msg("Session file doesn't exist.", 1) | return | endif

  "-----------------------------------------------------------

  call s:F.msg ([[ "Selected session will be deleted.", 'WarningMsg' ],
        \[ " Confirm (y/n)? ", 'Type' ]])

  if nr2char(getchar()) !=? 'y'
    call s:F.msg ([[ "Canceled.", 'WarningMsg' ]]) | return | endif

  "-----------------------------------------------------------

  if file == v:this_session | silent Obsession!
  else                      | silent exe "!rm ".file | endif

  redraw!
  call s:F.msg ([[ "Session ", 'WarningMsg' ],
        \[ file, 'Type' ],
        \[ " has been deleted.", 'WarningMsg' ]])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#session_save(...)
  let data = json_decode(readfile(s:Sets.sessions_data)[0])

  let defname = a:0 || empty(v:this_session)
        \ ? '' : fnamemodify(v:this_session, ":t")
  let defdesc = get(data, defname, '')
  let name = !a:0 || empty(a:1)
        \ ? input('Enter a name for this session:   ', defname) : a:1

  if !empty(name)
    let data[name] = input('Enter an optional description:   ', defdesc)
    call s:F.msg("\nConfirm (y/n)\t", 0)
    if nr2char(getchar()) ==? 'y'
      if a:0
        "update and pause Obsession, then clean buffers
        if ObsessionStatus() == "[$]"
          exe "silent Obsession ".fnameescape(g:this_obsession)
          silent Obsession | endif
        execute "silent! %bdelete"
      endif
      call writefile([json_encode(data)], s:Sets.sessions_data)
      let file = expand(s:Sets.sessions_path.s:F.sep().name, ":p")
      silent execute "Obsession ".fnameescape(file)
      call s:F.msg("Session '".file."' has been saved.", 0)
      return
    endif
  endif
  call s:F.msg("Session not saved.", 1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#update_sessions_file()
  let sfile = readfile(s:Sets.sessions_data)
  let json = {}

  for key in sfile
    let json[key] = sfile[key]
  endfor
  call writefile([json_encode(json)], s:Sets.sessions_data)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#update_bookmarks_file()
  let bfile = readfile(s:Sets.bookmarks_file)
  let json = {}

  for line in bfile
    let line = eval(line)
    let name = line['name']
    call remove(line, 'name')
    let json[name] = line
    let json[name]['description'] = ""
  endfor
  call writefile([json_encode(json)], s:Sets.bookmarks_file)
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Misc commands {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#cmds()
  """Run any XTabline command with fzf or finder."""
  redraw!
  let input = map(copy(s:cmds), 'v:val[0]')
  if !exists('g:loaded_fzf') || !g:loaded_fzf
    let res = xtabline#finder#open(input, 'Command ', 0)
    if !empty(res)
      call xtabline#fzf#run(res[0])
    endif
    return
  endif
  call fzf#vim#files('', {
        \ 'source': input,
        \ 'sink': function('xtabline#fzf#run'), 'down': '30%',
        \ 'options': '--no-multi --no-preview --ansi --prompt "Command >>>  "'})
endfun

fun! xtabline#fzf#run(cmd)
  let i = 0
  for cmd in map(copy(s:cmds), 'v:val[0]')
    if a:cmd == cmd
      exe s:cmds[i][1]
      break
    endif
    let i += 1
  endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#tab_nerd_bookmarks()
  let bfile = readfile(g:NERDTreeBookmarksFile)
  let bookmarks = []
  "skip last emty line
  for line in bfile[:-2]
    let b = substitute(line, '^.\+ ', "", "")
    call add(bookmarks, b)
  endfor
  return bookmarks
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#fzf#tab_nerd_bookmarks_load(...)
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
  call xtabline#update()
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_color(attr, ...)
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
endfun

fun! s:csi(color, fg)
  let prefix = a:fg ? '38;' : '48;'
  if a:color[0] == '#'
    return prefix.'2;'.join(map([a:color[1:2], a:color[3:4], a:color[5:6]], 'str2nr(v:val, 16)'), ';')
  endif
  return prefix.'5;'.a:color
endfun

fun! s:ansi(str, group, default, ...)
  let fg = s:get_color('fg', a:group)
  let bg = s:get_color('bg', a:group)
  let color = s:csi(empty(fg) ? s:ansi[a:default] : fg, 1) .
        \ (empty(bg) ? '' : s:csi(bg, 0))
  return printf("\x1b[%s%sm%s\x1b[m", color, a:0 ? ';1' : '', a:str)
endfun

fun! xtabline#fzf#colors()
  if &t_Co == 256 && !empty(get(g:, 'xtabline_fzf_colors', {}))
    let s:ansi = s:Sets.fzf_colors
  elseif &t_Co == 256
    let s:ansi = {'black': 234, 'red': 196, 'green': 41, 'yellow': 229, 'blue': 63, 'magenta': 213, 'cyan': 159}
  elseif &t_Co == 16
    let s:ansi = {'black': 0, 'red': 9, 'green': 10, 'yellow': 11, 'blue': 12, 'magenta': 13, 'cyan': 14}
  else
    let s:ansi = {'black': 0, 'red': 1, 'green': 2, 'yellow': 3, 'blue': 4, 'magenta': 5, 'cyan': 6}
  endif

  for s:color_name in keys(s:ansi)
    execute "fun! s:".s:color_name."(str, ...)\n"
          \ "  return s:ansi(a:str, get(a:, 1, ''), '".s:color_name."')\n"
          \ "endfun"
  endfor
endfun
call xtabline#fzf#colors()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:strip(str)
  return substitute(a:str, '^\s*\|\s*$', '', 'g')
endfun

fun! s:format_buffer(b)
  let name = bufname(a:b)
  let name = empty(name) ? '[No Name]' : fnamemodify(name, ":~:.")
  let flag = a:b == bufnr('')  ? s:blue('%', 'Conditional') :
        \ (a:b == bufnr('#') ? s:magenta('#', 'Special') : ' ')
  let modified = getbufvar(a:b, '&modified') ? s:red(' [+]', 'Exception') : ''
  let readonly = getbufvar(a:b, '&modifiable') ? '' : s:green(' [RO]', 'Constant')
  let extra = join(filter([modified, readonly], '!empty(v:val)'), '')
  return s:strip(printf("[%s] %s\t%s\t%s", s:yellow(a:b, 'Number'), flag, name, extra))
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:pad(t, n)
  if len(a:t) > a:n
    return a:t[:(a:n-1)]."…"
  else
    let spaces = a:n - len(a:t)
    let spaces = printf("%".spaces."s", "")
    return a:t.spaces
  endif
endfun

let s:cmds = [
      \['Reopen last tab',               "XTabReopen"],
      \['Close buffer',                  "XTabCloseBuffer"],
      \['Pin buffer',                    "XTabPinBuffer"],
      \['List tabs',                     "XTabListTabs"],
      \['List buffers',                  "XTabListBuffers"],
      \['Delete tab buffers',            "XTabDeleteBuffers"],
      \['Delete global buffers',         "XTabDeleteGlobalBuffers"],
      \['Clean up buffers',              "XTabCleanUp"],
      \['Purge all hidden buffers',      "XTabCleanUp"],
      \['Tab todo',                      "XTabTodo"],
      \['Purge tab',                     "XTabPurge"],
      \['Load tab',                      "XTabLoadTab"],
      \['Save tab',                      "XTabSaveTab"],
      \['Delete tab',                    "XTabDeleteTab"],
      \['Load session',                  "XTabLoadSession"],
      \['Save session',                  "XTabSaveSession"],
      \['New session',                   "XTabNewSession"],
      \['Delete session',                "XTabDeleteSession"],
      \['Toggle custom tabs',            "XTabCustomTabs"],
      \['Toggle buffer relative paths',  "XTabRelativePaths"],
      \['Reset tab',                     "XTabResetTab"],
      \['Reset buffer',                  "XTabResetBuffer"],
      \['Buffer format',                 "XTabFormatBuffer"],
      \['Configure',                     "XTabConfig"],
      \['Tab vimrc',                     "XTabVimrc"],
      \['Git mode',                      "XTabGit"],
      \['Hide buffer',                   "normal \<Plug>(XT-Hide-Buffer)"],
      \['Toggle tabs',                   "normal \<Plug>(XT-Toggle-Tabs)"],
      \['Go to last tab',                "normal \<Plug>(XT-Last-Tab)"],
      \['Refresh tabline',               "normal \<Plug>(XT-Refresh)"],
      \['Toggle filtering',              "normal \<Plug>(XT-Toggle-Filtering)"],
      \['Working directory',             "normal \<Plug>(XT-Working-Directory)"],
      \['Toggle only current dir',       "normal \<Plug>(XT-Set-Depth)"],
      \['Cd to current directory',       "normal \<Plug>(XT-Cd-Current)"],
      \['Cd to parent directory',        "normal \<Plug>(XT-Cd-Down)"],
      \['Rename tab',                    "call feedkeys(':XTabRenameTab ', 'n')"],
      \['Rename buffer',                 "call feedkeys(':XTabRenameBuffer ', 'n')"],
      \['Change tab icon',               "call feedkeys(':XTabIcon ', 'n')"],
      \['Change buffer icon',            "call feedkeys(':XTabBufferIcon ', 'n')"],
      \['Select theme',                  "call feedkeys(':XTabTheme ', 'n')"],
      \]
