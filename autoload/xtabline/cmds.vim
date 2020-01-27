""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:X    = g:xtabline
let s:F    = s:X.Funcs
let s:v    = s:X.Vars
let s:Sets = g:xtabline_settings

let s:T    =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:B    =  { -> s:X.Buffers             }       "customized buffers
let s:vB   =  { -> s:T().buffers.valid     }       "valid buffers for tab
let s:eB   =  { -> s:T().buffers.extra     }       "extra buffers for tab
let s:oB   =  { -> s:T().buffers.order     }       "ordered buffers for tab

let s:scratch =  { nr -> index(['nofile','acwrite','help'], getbufvar(nr, '&buftype')) >= 0 }
let s:badpath =  { nr -> !filereadable(bufname(nr)) && !getbufvar(nr, "&mod") }
let s:pinned  =  { b  -> index(s:X.pinned_buffers, b) }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Select buffers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:most_recent = -1

fun! xtabline#cmds#select_buffer(cnt) abort
  " Select buffer with count. {{{1
  if s:v.tabline_mode == 'tabs'
    return 'gt'
  elseif s:v.tabline_mode == 'arglist'
    let bufs = argv()
    let n = min([a:cnt, len(bufs)-1])
    return ":\<C-U>silent! buffer ".bufs[n]."\<cr>"
  endif
  let Fmt = g:xtabline_settings.buffer_format
  if type(Fmt) == v:t_number && Fmt == 1
    let b = a:cnt + 1
  else
    let n = min([a:cnt, len(s:oB())-1])
    let b = s:oB()[n]
  endif
  return ":\<C-U>silent! buffer ".b."\<cr>"
endfun "}}}

fun! xtabline#cmds#next_buffer(nr, last) abort
  " Switch to next visible/pinned buffer. "{{{1
  if s:F.not_enough_buffers(0) | return | endif
  let max = min([len(s:oB()) - 1, s:Sets.recent_buffers - 1])
  let nr = a:nr > max + 1 ? a:nr % (max + 1) : a:nr ? a:nr : 1

  if a:last
    let target = max - 1
  else
    let current = index(s:oB(), bufnr("%"))
    if current >= 0
      let target = current + nr
    else
      let target = nr - 1
    endif
    if target > max
      let target = current - max + nr - 1
    endif
  endif

  exe "buffer " . s:oB()[target]
endfun "}}}

fun! xtabline#cmds#prev_buffer(nr, first) abort
  " Switch to previous visible/pinned buffer. "{{{1
  if s:F.not_enough_buffers(0) | return | endif
  let max = min([len(s:oB()) - 1, s:Sets.recent_buffers - 1])
  let nr = a:nr > max + 1 ? a:nr % (max + 1) : a:nr ? a:nr : 1

  if a:first
    let target = 0
  else
    let current = index(s:oB(), bufnr("%"))
    if current >= 0
      let target = current - nr
    else
      let target = nr - 1
    endif
  endif

  exe "buffer " . s:oB()[target]
endfun "}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Other commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#cmds#run(cmd, ...) abort
  let args = a:0 ? join(map(copy(a:000), 'string(v:val)'), ',') : ''
  exe "call s:".a:cmd."(".args.")"
endfun

fun! s:cycle_mode() abort
  " Cycle the active tabline mode. "{{{1

  let modes = copy(s:Sets.tabline_modes)

  " only allow arglist as mode, if the arglist isn't empty
  let nargs = len(map(argv(), 'bufnr(v:val)'))
  if !nargs && index(modes, 'arglist') >= 0
    call remove(modes, index(modes, 'arglist'))
  endif

  let current = index(modes, s:v.tabline_mode) + 1
  if current == len(modes)
    let s:v.tabline_mode = modes[0]
  else
    let s:v.tabline_mode = modes[current]
  endif

  call s:F.msg([[ "Showing " . s:v.tabline_mode, 'StorageClass' ]])

  call xtabline#update()
endfun "}}}

fun! s:toggle_filtering() abort
  " Toggle buffer filtering in the tabline. "{{{1

  if s:Sets.buffer_filtering
    call s:F.msg([[ "Buffer filtering turned off", 'WarningMsg' ]])
  else
    call s:F.msg([[ "Buffer filtering turned on", 'StorageClass' ]])
  endif
  let s:Sets.buffer_filtering = !s:Sets.buffer_filtering
  call xtabline#update()
endfun "}}}

fun! s:purge_buffers() abort
  " Remove unmodified buffers with invalid paths. "{{{1

  let bcnt = 0
  let purged = []

  for buf in tabpagebuflist(tabpagenr())
    if          !buflisted(buf)
          \ ||  !getbufvar(buf, "&modifiable")
          \ || (!filereadable(expand('#'.buf.':p')) && !getbufvar(buf, "&modified"))
      call add(purged, buf)
    endif
  endfor

  " the tab could be closed if there is one window, prevent it
  if len(tabpagebuflist()) == 1 && index(purged, bufnr("%")) >= 0
    let s = "No other valid buffers for this tab."
    return s:F.msg([[s, 'WarningMsg']])
  endif

  for buf in purged
    if execute("bwipe ".buf) == ''
      let bcnt += 1
    endif
  endfor

  call xtabline#update()
  redraw!
  let s = "Purged ".bcnt." buffer" | let s .= bcnt!=1 ? "s." : "." | echo s
endfun "}}}

fun! s:clean_up(bang) abort
  " Remove all invalid/not open(!) buffers in all tabs. "{{{1

  let valid  = s:F.all_valid_buffers()
  let active = s:F.all_open_buffers()
  let ok     = a:bang? active : valid + active

  let nr = 0
  for b in range(1, bufnr('$'))
    if buflisted(b)
      if s:scratch(b) || s:badpath(b) ||
            \index(ok, b) < 0 && !getbufvar(b, '&modified')
        execute "silent! bdelete ".string(b)
        let nr += 1
      endif
    endif
  endfor

  let s = "Cleaned ".nr." buffer" | let s .= nr!=1 ? "s." : "."
  call s:F.msg([[s, 'WarningMsg']])
endfun "}}}

fun! s:reopen_last_tab() abort
  " Reopen the last closed tab. "{{{1

  if empty(s:X.closed_tabs)
    call s:F.msg("No recent tabs.", 1) | return
  endif

  let tab = remove(s:X.closed_tabs, -1)
  let s:v.tab_properties = tab

  " ensure list isn't empty
  let tab.buffers.valid = get(tab.buffers, 'valid', [-1])

  for good_buf in tab.buffers.valid
    if buflisted(good_buf)
      break
    endif
    let s:v.tab_properties = {}
    redraw!
    return s:F.msg([[ "There are no valid buffers for ", 'WarningMsg'],
          \         [ tab.cwd, 'None']])
  endfor

  if buflisted(s:v.tab_properties.active_buffer)
    exe "$tabnew" fnameescape(bufname(tab.active_buffer))
  else
    exe "$tabnew" fnameescape(bufname(good_buf))
  endif
  if tab.wd_cmd == 2
    lcd `=tab.cwd`
  elseif tab.wd_cmd == 1
    tcd `=tab.cwd`
  endif
  call xtabline#update()
endfun "}}}

fun! s:lock_tab() abort
  " Lock a tab, including currently displayed buffers as valid buffers. "{{{1

  let T = s:T()
  let T.locked = !T.locked
  let un = T.locked ? '' : 'un'
  if T.locked
    let T.buffers.valid = filter(T.buffers.order, 'buflisted(v:val) && filereadable(bufname(v:val))')
  endif
  redraw!
  call s:F.msg('Tab has been '.un.'locked', T.locked)
endfun "}}}

fun! s:close_buffer() abort
  " Close and delete a buffer, without closing the tab. "{{{1

  let current = bufnr("%") | let alt = bufnr("#") | let tbufs = len(s:vB())

  if s:F.is_tab_buffer(alt)
    execute "buffer #" | call s:F.bdelete(current)

  elseif ( tbufs > 1 ) || ( tbufs && !s:F.is_tab_buffer(current) )
    execute "normal \<Plug>(XT-Prev-Buffer)" | call s:F.bdelete(current)

  elseif !s:Sets.close_buffer_can_close_tab
    call s:F.msg("Last buffer for this tab.", 1)

  elseif getbufvar(current, '&modified')
    call s:F.msg("Not closing because of unsaved changes", 1)

  elseif tabpagenr() > 1 || tabpagenr("$") != tabpagenr()
    call s:F.bdelete(current)

  elseif s:Sets.close_buffer_can_quit_vim
    quit

  else
    call s:F.msg("There is only one tab.", 1)
  endif
endfun "}}}

fun! s:paths_style(bang, cnt) abort
  " Change paths displaying format. "{{{1
  " without a count, toggle between 0 and (+1 * -bang)

  let T = s:T()

  " find out which setting we're going to change
  let format = s:v.tabline_mode == 'tabs'
        \    ? s:Sets.current_tab_paths : s:Sets.buffers_paths

  " find out the new value
  let format = a:cnt                   ? a:cnt
        \    : a:bang && format == 1   ? 1
        \    : !a:bang && format == -1 ? 1
        \    : format                  ? 0 : 1

  let format = format * (a:bang ? -1 : 1)

  " update back the right setting with the new value
  if s:v.tabline_mode == 'tabs'
    let s:Sets.current_tab_paths = format
  else
    let s:Sets.buffers_paths = format
  endif

  call xtabline#update()

  if format
    call s:F.msg([["Tabline shows paths with format [".format."]", 'StorageClass']])
  else
    call s:F.msg([["Tabline shows filename only.", 'WarningMsg']])
  endif
endfun "}}}

fun! s:tab_todo() abort
  " Open or close the Tab todo file. "{{{1

  for b in tabpagebuflist()
    if getbufvar(b, 'xtab_todo', 0)
      if getbufvar(b, '&modified')
        let w = index(tabpagebuflist(), b) + 1
        exe w.'wincmd w'
        update
      endif
      execute b.'bw!'
      return
    endif
  endfor
  let todo = s:Sets.todo
  let s:v.buffer_properties = { 'name': 'TODO', 'special': 1 }
  execute todo['command'] s:F.todo_path()
  execute "setf" todo['syntax']
  let b:xtab_todo = 1
  nnoremap <silent><nowait> <buffer> \q :update<bar>bwipeout<cr>
endfun "}}}

fun! s:move_buffer(next, cnt) abort
  " Move buffer by [count] steps. {{{1
  let b = bufnr("%") | let max = len(s:oB()) - 1 | let nr = (max([a:cnt, 1]))

  " cannot move a buffer that is not valid for this tab
  if index(s:vB(), b) < 0
    return s:F.msg("Not possible to move this buffer.", 1)
  endif

  let i = index(s:oB(), b)

  if a:next
    let new_index = (i + nr) >= max ? max : i + nr
  else
    let new_index = (i - nr) < 0 ? 0 : i - nr
  endif
  call insert(s:oB(), remove(s:oB(), i), new_index)
  call xtabline#update()
endfun "}}}

fun! s:move_buffer_to(cnt, ...) abort
  " Move buffer in the bufferline to a new position. "{{{1

  let b = bufnr("%")
  let oB = s:oB()
  let max = len(oB) - 1
  let nr = (max([a:cnt, 1])) - 1
  let i = index(oB, b)

  if i < 0 || i == nr          | return
  elseif i == max && nr >= max | return | endif

  let new = min([nr, max])
  call remove(oB, i)
  if new < max
    call insert(oB, b, new)
  else
    call add(oB, b)
  endif
  call xtabline#update()
endfun "}}}

fun! s:hide_buffer(new) abort
  " Move buffer to the last position, then select another one. "{{{1

  let b = bufnr("%") | let oB = s:oB() | let max = len(oB) - 1
  let i = index(oB, b)
  call s:move_buffer_to(1000)
  if index(s:T().buffers.recent, b) < 0
    return
  else
    call remove(s:T().buffers.recent, index(s:T().buffers.recent, b))
  endif

  "if hiding, the buffer that will be selected
  "new in this case is the wanted buffer
  let new = a:new > i ?  a:new-2 : a:new
  let then_select = new >= 0 ?  oB[new] : oB[0]

  silent! exe 'b'.then_select
  call xtabline#update()
endfun "}}}

fun! s:rename_tab(label) abort
  " Rename the current tab. "{{{1

  let s:X.Tabs[tabpagenr()-1].name = a:label
  call xtabline#update()
endfun "}}}

fun! s:rename_buffer(label) abort
  " Rename the current buffer. "{{{1

  let B = s:F.set_buffer_var('name', a:label)
  if empty(B) | return | endif
  call xtabline#update()
endfun "}}}

fun! s:get_icon(ico) abort
  " Get current icon for this tab. "{{{1

  let I = get(s:Sets, 'icons', {})
  if index(keys(I), a:ico) >= 0
    return I[a:ico]
  elseif strchars(a:ico) == 1
    return a:ico
  else
    return s:F.msg([[ "Invalid icon.", 'WarningMsg']])
  endif
endfun "}}}

fun! s:tab_icon(...) abort
  " Set an icon for this tab. "{{{1

  let [ bang, icon ] = [ a:1, a:2 ]
  let T = s:T()
  if bang
    let T.icon = ''
  else
    let icon = s:get_icon(icon)
    if !empty(icon)
      let T = s:T()
      let T.icon = icon
    endif
  endif
  call xtabline#update()
endfun "}}}

fun! s:buffer_icon(...) abort
  " Set an icon for this buffer. "{{{1

  let [ bang, icon ] = [ a:1, a:2 ]
  let B = s:F.set_buffer_var('icon')
  if empty(B) | return | endif

  if bang
    let B.icon = ''
  else
    let icon = s:get_icon(icon)
    if !empty(icon)
      let B.icon = icon
    endif
  endif
  call xtabline#update()
endfun "}}}

fun! s:toggle_pin_buffer(...) abort
  " Pin this buffer, so that it will be shown in all tabs. Optionally rename. "{{{1

  let B = bufnr('%') | let i = s:pinned(B)

  if a:0 && match(a:1, "\S") >= 0
    if empty(s:F.set_buffer_var('name', a:1)) | return | endif
  elseif i < 0 && s:invalid_buffer(B)         | return | endif

  if i >= 0
    call remove(s:X.pinned_buffers, i)
  else
    call add(s:X.pinned_buffers, B)
  endif
  call xtabline#update()
endfun "}}}

fun! s:move_tab(...) abort
  " Move a tab to a new position. "{{{1

  let max = tabpagenr("$") - 1 | let arg = a:1

  let forward = arg[0] == '+' || empty(arg)
  let backward = arg[0] == '-'
  let bottom = arg[0] == '$'
  let first = arg[0] == '0'

  if ! (forward || backward || bottom || first)
    return s:F.msg('Wrong arguments.', 1)
  endif

  "find destination index
  let current = tabpagenr() - 1
  let dest    = forward?  ( (current + 1) < max ? current + 1 : max ) :
        \ backward? ( (current - 1) > 0   ? current - 1 : 0 ) :
        \ bottom? max : 0

  "rearrange tabs dicts
  let this_tab = copy(s:T())
  call remove(s:X.Tabs, current)
  call insert(s:X.Tabs, this_tab, dest)

  "define command range
  let dest    = dest == max ? '$' :
        \ dest == 0   ? '0' :
        \ forward? '+' :
        \ backward? '-' :
        \ bottom? '$' : '0'

  exe dest . "tabmove"
  call xtabline#update()
endfun "}}}

fun! s:format_buffer() abort
  " Specify a custom format for this buffer. "{{{1

  let och = &ch
  set ch=2

  let n = bufnr("%")
  if s:invalid_buffer(n) | return | endif

  let fmt = s:Sets.buffer_format
  let default = type(fmt) == v:t_string ? fmt : ' n I< l +'

  let has_format = has_key(s:B(), n) && has_key(s:B()[n], 'format')
  let current = has_format? s:B()[n].format : default

  echohl Label   | echo "Current  │"
  echohl Special | echon current
  echohl Label   | let new = input("New      │", current)
  echohl None

  if !empty(new) | call s:F.set_buffer_var('format', new)
  else           | call s:F.msg([[ "Canceled.", 'WarningMsg' ]])
  endif

  let &ch = och
  call xtabline#update()
endfun "}}}

fun! s:reset_tab(...) abort
  " Reset the tab to a pristine state. "{{{1

  let cwd = a:0? fnamemodify(expand(a:1), :p) : s:F.find_root_dir()
  let s:X.Tabs[tabpagenr()-1] = xtabline#tab#new({'cwd': cwd})
  call s:F.auto_change_dir(cwd)
endfun "}}}

fun! s:reset_buffer(...) abort
  " Reset the buffer to a pristine state. "{{{1

  let B = s:B() | let n = bufnr("%")
  if has_key(B, n) | unlet B[n] | endif
  call xtabline#update()
endfun "}}}

fun! s:toggle_tab_names() abort
  " Toggle between custom icon/name and short path/folder icons. "{{{1

  let s:v.custom_tabs = !s:v.custom_tabs
  call xtabline#update()
endfun "}}}

fun! s:goto_last_tab() abort
  " Go back to the previously opened tab. "{{{1

  let this = tabpagenr() - 1
  let n = index(s:X.Tabs, s:v.last_tab)
  exe "normal!" (n + 1)."gt"
  let s:v.last_tab = s:X.Tabs[this]
endfun "}}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:invalid_buffer(b) abort
  if !s:F.is_tab_buffer(a:b)
    call s:F.msg([[ "Invalid buffer.", 'WarningMsg']])
    return 1
  endif
endfun

" vim: et sw=2 ts=2 sts=2 fdm=marker
