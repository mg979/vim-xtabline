""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" fzf/finder commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X = g:xtabline
let s:F = g:xtabline.Funcs
let s:v = g:xtabline.Vars
let s:Sets = g:xtabline_settings

let s:datadir = has('nvim') ? expand(stdpath('data'))
      \      : !has('win32unix') && !has('win32') ? expand('$HOME/.vim')
      \      : isdirectory(expand('$HOME/vimfiles')) ? expand('$HOME/vimfiles')
      \                                              : expand('$HOME/.vim')

let s:Sets.sessions_path  = get(s:Sets, 'sessions_path', s:datadir . '/session')
let s:Sets.sessions_data  = get(s:Sets, 'sessions_data', s:datadir . '/.XTablineSessions')
let s:Sets.bookmarks_file = get(s:Sets, 'bookmarks_file', s:datadir . '/.XTablineBookmarks')

let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab

let s:sessions_path = { -> s:F.fulldir(s:Sets.sessions_path) }
let s:use_finder    = !exists('g:loaded_fzf') || get(s:Sets, 'use_builtin_finder', 0)
let s:lastmodified  = { f -> str2nr(system(s:date_command.' -r '.f.' +%s')) }
let s:obsession     = { -> exists('g:loaded_obsession') }

" date and stat commands. In macOS, the corresponding ones of GNU version should be used.
let s:date_command = has('mac') ? 'gdate' : 'date'
let s:stat_command = has('mac') ? 'gstat' : 'stat'

" fzf/finder functions  {{{1

" If fzf is loaded and not using built-in finder, then define fzf functions

if exists('g:loaded_fzf') && !s:use_finder
  if $TERM !~ "256color"
    highlight! xt_fzf1 ctermfg=1 ctermbg=8 guifg=#E12672 guibg=#565656
    highlight! xt_fzf2 ctermfg=252 ctermbg=238 guifg=#D9D9D9 guibg=#565656
  else
    highlight! xt_fzf1 ctermfg=161 ctermbg=238 guifg=#E12672 guibg=#565656
    highlight! xt_fzf2 ctermfg=252 ctermbg=238 guifg=#D9D9D9 guibg=#565656
  endif

  fun! s:fzf_statusline(prompt) abort
    augroup xt_fzf
      au!
      exe 'au FileType fzf setlocal statusline=%#xt_fzf1#\ >\ %#xt_fzf2#' . escape(a:prompt, ' ')
    augroup END
  endfun

  fun! xtabline#fzf#list_buffers()
    call s:fzf_statusline("Open Tab Buffer")
    call fzf#run({
          \ 'source': s:tab_buffers(),
          \ 'sink': { line -> execute('b '.matchstr(line, '^\s*\[\zs\d\+\ze\]')) },
          \ 'down': '30%',
          \ 'options': '--ansi --multi'})
    au! xt_fzf | aug! xt_fzf
  endfun

  fun! xtabline#fzf#list_tabs()
    call s:fzf_statusline("Go to Tab")
    call fzf#run({
          \ 'source': s:tablist(), 'sink': function('s:tabopen'), 'down': '30%',
          \ 'options': '--ansi --header-lines=1 --no-preview'})
    au! xt_fzf | aug! xt_fzf
  endfun

  fun! xtabline#fzf#closed_tabs()
    call s:fzf_statusline("Reopen Tab")
    call fzf#run({
          \ 'source': s:closed_tabs_list(), 'sink': function('s:tabreopen'), 'down': '30%',
          \ 'options': '--ansi --header-lines=1 --no-preview'})
    au! xt_fzf | aug! xt_fzf
  endfun

  fun! xtabline#fzf#delete_buffers()
    call s:fzf_statusline("Delete Tab Buffer")
    call fzf#run({
          \ 'source': s:tab_buffers(),
          \ 'sink': function('s:bufdelete'), 'down': '30%',
          \ 'options': '--ansi --multi --no-preview'})
    au! xt_fzf | aug! xt_fzf
  endfun

  fun! xtabline#fzf#load_session()
    if s:mac_no_gnu() | return | endif
    call s:fzf_statusline("Load Session")
    call fzf#run({
          \ 'source': s:sessions_list(),
          \ 'sink': function('s:session_load'), 'down': '30%',
          \ 'options': '--ansi --header-lines=1 --no-preview'})
    au! xt_fzf | aug! xt_fzf
  endfun

  fun! xtabline#fzf#delete_session()
    if s:mac_no_gnu() | return | endif
    call s:fzf_statusline("Delete Session")
    call fzf#run({
          \ 'source': s:sessions_list(),
          \ 'sink': function('s:session_delete'), 'down': '30%',
          \ 'options': '--ansi --header-lines=1 --no-multi --no-preview'})
    au! xt_fzf | aug! xt_fzf
  endfun

  fun! xtabline#fzf#load_tab()
    call s:fzf_statusline("Load Tab Bookmark")
    call fzf#run({
          \ 'source': s:tabs(),
          \ 'sink': function('s:tab_load'), 'down': '30%',
          \ 'options': '--ansi --header-lines=1 --multi --no-preview'})
    au! xt_fzf | aug! xt_fzf
  endfun

  fun! xtabline#fzf#delete_tab()
    call s:fzf_statusline("Delete Tab Bookmark")
    call fzf#run({
          \ 'source': s:tabs(),
          \ 'sink': function('s:tab_delete'), 'down': '30%',
          \ 'options': '--ansi --header-lines=1 --multi --no-preview'})
    au! xt_fzf | aug! xt_fzf
  endfun

  fun! xtabline#fzf#nerd_bookmarks()
    call s:fzf_statusline("Load NERD Bookmark")
    call fzf#run({
          \ 'source': s:tab_nerd_bookmarks(),
          \ 'sink': function('s:tab_nerd_bookmarks_load'), 'down': '30%',
          \ 'options': '--ansi --multi --no-preview'})
    au! xt_fzf | aug! xt_fzf
  endfun

else " using built-in finder instead

  silent! call xtabline#finder#open()
  let s:Find = funcref('xtabline#finder#open')
  fun! xtabline#fzf#list_buffers()
    let b = s:Find(s:tab_buffers(), 'Open Tab Buffer')
    if b != '' | exe 'e' fnameescape(b) | endif
  endfun

  fun! xtabline#fzf#list_tabs()
    let T = s:Find(s:tablist(), 'Open Tab')
    if T != '' | call s:tabopen(T) | endif
  endfun

  fun! xtabline#fzf#closed_tabs()
    let T = s:Find(s:closed_tabs_list(), "Reopen Tab")
    if T != '' | call s:tabreopen(T) | endif
  endfun

  fun! xtabline#fzf#delete_buffers()
    let bufs = s:Find(s:tab_buffers(), 'Delete Tab Buffer', {'multi':1})
    for b in bufs | exe 'bd' bufnr(b) | endfor
  endfun

  fun! xtabline#fzf#load_session()
    if s:mac_no_gnu() | return | endif
    let t = '      '
    let header = printf("Session%s%s%s%sTimestamp%sDescription",t,t,t,t,t)
    let s = s:Find(s:sessions_list(1), header)
    if s != '' | call s:session_load(s) | endif
  endfun

  fun! xtabline#fzf#delete_session()
    if s:mac_no_gnu() | return | endif
    let t = '    '
    let header = printf("Session%s%s%s%sTimestamp%sDescription",t,t,t,t,t)
    let s = s:Find(s:sessions_list(1), header)
    if s != '' | call s:session_delete(s) | endif
  endfun

  fun! xtabline#fzf#load_tab()
    let T = s:Find(s:tabs(), 'Load Tab Bookmark')
    if T != '' | call s:tab_load(T) | endif
  endfun

  fun! xtabline#fzf#delete_tab()
    let T = s:Find(s:tabs(), 'Delete Tab Bookmark')
    if T != '' | call s:tab_delete(T) | endif
  endfun

  fun! xtabline#fzf#nerd_bookmarks()
    let T = s:Find(s:tab_nerd_bookmarks(), 'Load Nerd Bookmark')
    if T != '' | call s:tab_nerd_bookmarks_load(T) | endif
  endfun
endif "}}}



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" List tab buffers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tab_buffers() abort
  " Open a list of buffers for this tab. {{{1
  let bufs = s:vB()

  if empty(bufs) | return [] | endif

  let current = bufnr("%") | let alt = bufnr("#")
  let l = sort(map(copy(bufs), 's:format_buffer(v:val)'))

  "put alternate buffer last (but current will go after it)
  if alt != -1 && index(bufs, alt) >= 0
    call insert(l, remove(l, index(l, s:format_buffer(alt))))
  endif

  "put current buffer last
  call insert(l, remove(l, index(l, s:format_buffer(current))))
  return l
endfun "}}}

fun! s:bufdelete(name) abort
  " Delete a buffer.  {{{1
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
  call xtabline#update(1)
endfun "}}}



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tabs overview
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tablist() abort
  " Generate a formatted list of currently open tabs {{{1
  let lines = []
  for tab in range(tabpagenr("$"))
    let T = g:xtabline.Tabs[tab]
    let bufs = len(T.buffers.valid)
    let line = s:yellow(s:pad(tab+1, 5))."\t".
          \    s:green(s:pad(bufs, 5))."\t".
          \    s:cyan(s:pad(T.name, 20))."\t".
          \    (&columns<150 ? s:F.short_cwd(tab+1, 1) : fnamemodify(T.cwd, ":~"))
    call add(lines, line)
  endfor
  call add(lines, "Tab\tBufs\tName\t\t\tWorking Directory")
  return reverse(lines)
endfun

if s:use_finder
  fun! s:tablist() abort
    let lines = []
    for tab in range(tabpagenr("$"))
      let T = g:xtabline.Tabs[tab]
      let bufs = len(T.buffers.valid)
      let line = s:pad(tab+1, 5)."\t" . s:pad(T.name, 20)."\t".
            \    (&columns<150 ? s:F.short_cwd(tab+1, 1) : fnamemodify(T.cwd, ":~"))
      call add(lines, line)
    endfor
    return reverse(lines)
  endfun
endif "}}}

fun! s:closed_tabs_list() abort
  " Generate a formatted list of currently open tabs {{{1
  let lines = []
  let [rng, tabs] = [range(len(g:xtabline.closed_tabs)), g:xtabline.closed_tabs]

  for tab in rng
    let T = tabs[tab]
    let bufs = len(T.buffers.valid)
    let line = s:yellow(s:pad(tab+1, 5))."\t".
          \    s:green(s:pad(bufs, 5))."\t".
          \    s:cyan(s:pad(T.name, 20))."\t".
          \    (&columns<150 ? s:F.short_cwd(tab+1, 1) : fnamemodify(T.cwd, ":~"))
    call add(lines, line)
  endfor
  call add(lines, "Tab\tBufs\tName\t\t\tWorking Directory")
  return reverse(lines)
endfun

if s:use_finder
  fun! s:closed_tabs_list() abort
    let lines = []
    let [rng, tabs] = [range(len(g:xtabline.closed_tabs)), g:xtabline.closed_tabs]

    for tab in rng
      let T = tabs[tab]
      let bufs = len(T.buffers.valid)
      let line = s:pad(tab+1, 5)."\t" . s:pad(T.name, 20)."\t".
            \    (&columns<150 ? s:F.short_cwd(tab+1, 1) : fnamemodify(T.cwd, ":~"))
      call add(lines, line)
    endfor
    return reverse(lines)
  endfun
endif "}}}

fun! s:tabopen(line) abort
  " Open the selected tab. {{{1
  let tab = a:line[0:(match(a:line, '\s')-1)]
  exe "normal!" tab."gt"
  call xtabline#update(1)
endfun "}}}

fun! s:tabreopen(line) abort
  " Open the selected tab. {{{1
  let tab = a:line[0:(match(a:line, '\s')-1)]
  call add(g:xtabline.closed_tabs, remove(g:xtabline.closed_tabs, tab - 1))
  XTabReopen
endfun "}}}



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Saved tabs
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tabs() abort
  " Generate a formatted list of saved tabs. {{{1
  let json = json_decode(s:bm_file()[0])

  let bookmarks = s:use_finder ? [] : &columns > 99 ?
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
endfun "}}}

fun! s:tab_load(...) abort
  " Load a saved tab bookmark.  {{{1
  let json = json_decode(s:bm_file()[0])
  for bm in a:000
    let name = substitute(bm, '\(\w*\)\s*\t.*', '\1', '')
    let saved = json[name]
    let cwd = s:F.fulldir(saved['cwd'])
    let has_set_cd = 0

    if isdirectory(cwd) && empty(saved.buffers)        "no valid buffers
      return s:abort_load(name, bm, 'buffers')
    elseif !isdirectory(cwd)                           "invalid directory
      return s:abort_load(name, bm, 'dir')
    endif

    "tab properties defined here will be applied by new_tab(), run by autocommand
    let s:v.tab_properties = {'cwd': cwd }
    let T = s:v.tab_properties
    for prop in keys(saved)
      if prop ==? 'buffers' || prop ==? 'description'   | continue | endif
      let T[prop] = saved[prop]
    endfor

    $tabnew | let newbuf = bufnr("%")

    if cwd !=# getcwd()
      if exists(':tcd') == 2
        exe 'tcd' cwd
        let has_set_cd = 1
      else
        exe 'lcd' cwd
        let has_set_cd = 2
      endif
    endif

    if empty(filter(saved.buffers, 'filereadable(v:val)'))
      tabclose
      return s:abort_load(name, bm, 'buffers')
    endif

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

  if has_set_cd
    let cd = has_set_cd == 1 ? 'tab-local' : 'window-local'
    call s:F.msg([['[xtabline] ', 'Label'],
          \       [cd.' cwd has been set to: '.cwd, 'None']])
  endif

  call xtabline#update(1)
endfun

fun! s:abort_load(name, fzf_line, error_type) abort
  " Invalid saved tab, abort operation.
  if a:error_type == 'buffers'
    call s:F.msg([[ a:name, 'Type' ],
          \[ ": no saved buffers. Remove entry?\t", 'WarningMsg' ]])
  else
    call s:F.msg([[ a:name, 'Type' ],
          \[ ": invalid directory. Remove entry?\t", 'WarningMsg' ]])
  endif
  if nr2char(getchar()) == 'y'
    call s:tab_delete(a:fzf_line)
  endif
endfun "}}}

fun! s:tab_delete(...) abort
  " Delete a saved tab bookmark.  {{{1
  let json = json_decode(s:bm_file()[0])

  for bm in a:000
    let name = substitute(bm, '\(\w*\)\s*\t.*', '\1', '')
    call remove(json, name)
  endfor

  "write the file
  call writefile([json_encode(json)],s:Sets.bookmarks_file)
  call s:F.msg([[ "Tab bookmark ", 'WarningMsg' ],
        \[ name, 'Type' ],
        \[ " deleted.", 'WarningMsg' ]])
endfun "}}}

fun! xtabline#fzf#tab_save() abort
  " Create an entry and add it to the tab bookmarks file. {{{1

  if !s:Sets.buffer_filtering
    call s:F.msg("Activate buffer filtering first.", 1) | return | endif

  let json = json_decode(s:bm_file()[0])
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
endfun "}}}



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sessions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:sessions_list(...) abort " {{{1
  " Generate a formatted list of sessions.
  let data = a:0 ? [] : ["Session\t\t\t\tTimestamp\tDescription"]
  let sfile = json_decode(s:ss_file()[0])
  let sessions = split(globpath(s:sessions_path(), "*"), '\n')

  "remove __LAST__ session
  call filter(sessions, "v:val !~ '__LAST__'")

  if !s:v.winOS
    "sort sessions by last modfication time
    let times = {}
    for s in sessions
      let t = s:lastmodified(s)
      "prevent key overwriting
      while has_key(times, t) | let t += 1 | endwhile
      let times[t] = s
    endfor

    let ord_times = map(keys(times), 'str2nr(v:val)')
    let ord_times = reverse(sort(ord_times, 'n'))
    let ordered = map(ord_times, 'times[v:val]')
  else
    let ordered = sessions
  endif

  for s in ordered
    let n = fnamemodify(expand(s), ':t')
    let description = s:desc_string(s, n, sfile, !a:0)
    call add(data, description)
  endfor
  return data
endfun


fun! s:desc_string(s, n, sfile, color) abort " {{{1
  let active_mark = (a:s ==# v:this_session) ?
        \ a:color ? s:green(" [%]  ") : " [%]  " : '      '
  let description = get(a:sfile, a:n, '')
  let spaces = 30 - len(a:n)
  let spaces = printf("%".spaces."s", "")
  let pad = empty(active_mark) ? '     ' : ''
  if !s:v.winOS
    let time = system('date=`'.s:stat_command.' -c %Y '.fnameescape(a:s).
          \           '` && '.s:date_command.' -d@"$date" +%Y.%m.%d')[:-2]
  else
    let time = ''
  endif
  if a:color
    return s:yellow(a:n).spaces."\t".s:cyan(time).pad.active_mark.description
  else
    return a:n.spaces."\t".time.pad.active_mark.description
  endif
endfun


fun! s:session_load(file) abort " {{{1
  " Load a session, but abort if there are unsaved changes.
  for b in range(1, bufnr("$"))
    if getbufvar(b, '&modified')
      call s:F.msg("Some buffer has unsaved changes. Aborting.", 1)
      return
    endif
  endfor

  "-----------------------------------------------------------

  let session = a:file
  if match(session, "\t") | let session = substitute(session, " *\t.*", "", "") | endif
  let file = s:sessions_path() . session
  let this = tr(v:this_session, '\', '/')

  if !filereadable(file) | call s:F.msg("Session file doesn't exist.", 1) | return | endif
  if file ==# this       | call s:F.msg("Session is already loaded.", 1)  | return | endif

  "-----------------------------------------------------------
  " confirm session unloading

  if exists('g:this_session') && get(s:Sets, 'unload_session_ask_confirm', 1) &&
        \ !s:F.confirm("Current session will be unloaded. Confirm?")
    return s:F.msg("Canceled.", 1)
  endif

  "-----------------------------------------------------------
  " unload current session and load new one

  call s:update_current_session()
  execute "silent! %bdelete"
  execute "source ".fnameescape(file)
  call xtabline#update(1)
endfun


fun! s:session_delete(file) abort " {{{1
  " Delete a session file.
  let session = a:file
  if match(session, "\t")
    let session = substitute(session, " *\t.*", "", "")
  endif
  let file = s:sessions_path() . session

  if !filereadable(file)
    return s:F.msg("Session file doesn't exist.", 1)
  endif

  if !s:F.confirm('Delete session '.session.'?') | return | endif

  if s:obsession() && file == get(g:, 'this_obsession', '')
    silent Obsession!
  else
    exe "silent !rm ".fnameescape(file)
  endif

  redraw!
  call s:F.msg([[ "Session ", 'WarningMsg' ],
        \[ file, 'None' ],
        \[ " has been deleted.", 'WarningMsg' ]])
endfun


fun! s:update_current_session() abort " {{{1
  " Update current session.
  let file = get(g:, 'this_obsession', v:this_session)
  if !filereadable(file) | return | endif

  if s:obsession()
    exe "silent Obsession ".fnameescape(file)
    silent Obsession
  elseif !empty(file)
    exe "silent mksession! ".fnameescape(file)
  endif
endfun


fun! s:save_session(file) abort " {{{1
  " Finalize session save.
  if s:obsession()
    silent execute "Obsession ".fnameescape(a:file)
  else
    silent execute "mksession! ".fnameescape(a:file)
  endif
  call s:F.msg("Session '".a:file."' has been saved.", 0)
endfun

fun! s:mac_no_gnu() "{{{1
  if has('mac') && !executable('gstat')
    echohl WarningMsg
    echo '[xtabline]'
    echohl None
    echon 'You must install GNU gstat and gdate:'
    echo "\n\tbrew install coreutils"
    return v:true
  endif
  return v:false
endfun "}}}


fun! xtabline#fzf#session_save(new_session) abort
  " Save a session. {{{1
  let sdir = s:sessions_path()
  if !isdirectory(sdir)
    if s:F.confirm('Directory '.sdir.' does not exist, create?')
      call mkdir(sdir, 'p')
    else
      return s:F.msg("Canceled.", 1)
    endif
  endif

  let data = json_decode(s:ss_file()[0])

  " get description of current session, if already registered
  let _name = a:new_session || empty(v:this_session)
        \   ? '' : fnamemodify(v:this_session, ":t")
  let _desc = get(data, _name, '')

  let _ = a:new_session ? 'the new' : 'this'
  let name = input('Enter a name for '. _ .' session: ', _name)

  if empty(name)
    return s:F.msg("Session not saved.", 1)
  endif

  let data[name] = input('Enter an optional description: ', _desc)

  let prompt = a:new_session ? 'New' : 'Save'

  if s:F.confirm(printf("%s session %s?", prompt, name))
    " saving current session with a new name, update current first
    if ( _name != '' ) && ( name !=# _name )
      call s:update_current_session()
    endif

    if a:new_session
      execute "silent! %bdelete"
      cd `=$HOME`
    endif

    call writefile([json_encode(data)], s:Sets.sessions_data)
    call s:save_session( sdir. name )

  else
    call s:F.msg("Session not saved.", 1)
  endif
endfun "}}}



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NERD commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tab_nerd_bookmarks() abort
  " List NERD bookmarks  {{{1
  if !exists('g:NERDTreeBookmarksFile')
    return
  endif
  let bfile = readfile(g:NERDTreeBookmarksFile)
  let bookmarks = []
  "skip last emty line
  for line in bfile[:-2]
    let b = substitute(line, '^.\+ ', "", "")
    call add(bookmarks, b)
  endfor
  return bookmarks
endfun "}}}

fun! s:tab_nerd_bookmarks_load(...) abort
  " Load a NERD bookmark  {{{1
  for bm in a:000
    let bm = expand(bm, ":p")
    if isdirectory(bm)
      tabnew
      call s:F.auto_change_dir(bm)
      exe "NERDTree ".bm
    elseif filereadable(bm)
      exe "tabedit ".bm
      call s:F.auto_change_dir(fnamemodify(bm, ":p:h"))
    endif
  endfor
  call xtabline#update(1)
endfun "}}}



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_color(attr, ...) abort " {{{1
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

fun! s:csi(color, fg) abort " {{{1
  let prefix = a:fg ? '38;' : '48;'
  if a:color[0] == '#'
    return prefix.'2;'.join(map([a:color[1:2], a:color[3:4], a:color[5:6]], 'str2nr(v:val, 16)'), ';')
  endif
  return prefix.'5;'.a:color
endfun

fun! s:ansi(str, group, default, ...) abort " {{{1
  let fg = s:get_color('fg', a:group)
  let bg = s:get_color('bg', a:group)
  let color = s:csi(empty(fg) ? s:ansi[a:default] : fg, 1) .
        \ (empty(bg) ? '' : s:csi(bg, 0))
  return printf("\x1b[%s%sm%s\x1b[m", color, a:0 ? ';1' : '', a:str)
endfun

fun! xtabline#fzf#colors() abort " {{{1
  if &t_Co == 256 && !empty(get(g:, 'xtabline_fzf_colors', {}))
    let s:ansi = s:Sets.fzf_colors
  elseif &t_Co == 256
    let s:ansi = {'black': 234, 'red': 196, 'green': 41, 'yellow': 229, 'blue': 63, 'magenta': 213, 'cyan': 159}
  elseif &t_Co == 16
    let s:ansi = {'black': 0, 'red': 9, 'green': 10, 'yellow': 11, 'blue': 12, 'magenta': 13, 'cyan': 14}
  else
    let s:ansi = {'black': 0, 'red': 1, 'green': 2, 'yellow': 3, 'blue': 4, 'magenta': 5, 'cyan': 6}
  endif

  if s:use_finder
    for s:color_name in keys(s:ansi)
      execute "fun! s:".s:color_name."(str, ...)\n"
            \ "  return printf('%-8s', a:str)\n"
            \ "endfun"
    endfor
  else
    for s:color_name in keys(s:ansi)
      execute "fun! s:".s:color_name."(str, ...)\n"
            \ "  return s:ansi(a:str, get(a:, 1, ''), '".s:color_name."')\n"
            \ "endfun"
    endfor
  endif
endfun
call xtabline#fzf#colors()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:strip(str) abort " {{{1
  return substitute(a:str, '^\s*\|\s*$', '', 'g')
endfun

fun! s:format_buffer(b) abort " {{{1
  if s:use_finder
    return bufname(a:b)
  endif
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

fun! s:pad(t, n) abort " {{{1
  if len(a:t) > a:n
    return a:t[:(a:n-1)]."…"
  else
    let spaces = a:n - len(a:t)
    let spaces = printf("%".spaces."s", "")
    return a:t.spaces
  endif
endfun

fun! s:bm_file() " {{{1
  if !filereadable(s:Sets.bookmarks_file)
    call writefile(['{}'], s:Sets.bookmarks_file)
    return ['{}']
  else
    return readfile(s:Sets.bookmarks_file)
  endif
endfun

fun! s:ss_file() " {{{1
  if !filereadable(s:Sets.sessions_data)
    call writefile(['{}'], s:Sets.sessions_data)
    return ['{}']
  else
    return readfile(s:Sets.sessions_data)
  endif
endfun "}}}

" vim: et sw=2 ts=2 sts=2 fdm=marker
