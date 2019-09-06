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
  let Fmt = g:xtabline_settings.buffer_format
  if type(Fmt) == v:t_number && Fmt == 1
    let b = a:cnt + 1
  else
    let bufs = g:xtabline.Tabs[tabpagenr()-1].buffers.order
    let n = min([a:cnt, len(bufs)-1])
    let b = bufs[n]
  endif
  return ":\<C-U>silent! exe 'b'.".b."\<cr>"
endfun

fun! xtabline#cmds#next_buffer(nr, last) abort
  """Switch to next visible/pinned buffer."""

  if s:F.not_enough_buffers(0) | return | endif
  let accepted = s:oB()

  let ix = a:last ? (len(accepted) - 2) : index(accepted, bufnr("%"))
  let target = ix + (max([a:nr, 1]))
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

  exe "buffer " . accepted[s:most_recent]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#cmds#prev_buffer(nr, first) abort
  """Switch to previous visible/pinned buffer."""

  if s:F.not_enough_buffers(0) | return | endif
  let accepted = s:oB()

  let ix = a:first ? 1 : index(accepted, bufnr("%"))
  let target = ix - (max([a:nr, 1]))
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

  exe "buffer " . accepted[s:most_recent]
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Other commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#cmds#run(cmd, ...) abort
  let args = a:0 ? join(map(copy(a:000), 'string(v:val)'), ',') : ''
  exe "call s:".a:cmd."(".args.")"
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:cycle_mode() abort
  """Cycle the active tabline mode."""

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

  call s:F.msg ([[ "Showing " . s:v.tabline_mode, 'StorageClass' ]])

  call xtabline#update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:toggle_filtering() abort
  """Toggle buffer filtering in the tabline."""

  if s:Sets.buffer_filtering
    call s:F.msg ([[ "Buffer filtering turned off", 'WarningMsg' ]])
  else
    call s:F.msg ([[ "Buffer filtering turned on", 'StorageClass' ]])
  endif
  let s:Sets.buffer_filtering = !s:Sets.buffer_filtering
  call xtabline#update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:purge_buffers() abort
  """Remove unmodified buffers with invalid paths."""

  if !s:Sets.buffer_filtering | echo "Buffer filtering is turned off." | return | endif
  let bufs = s:oB() + s:eB() | let bcnt = 0 | let purged = []

  " include open buffers if not showing in tabline
  for buf in tabpagebuflist(tabpagenr())
    if index(bufs, buf) < 0 | call add(bufs, buf) | endif
  endfor

  for buf in bufs
    let bufpath = s:F.fullpath(bufname(buf))

    let purge =  !buflisted(buf) || !getbufvar(buf, "&modifiable") ||
          \     !filereadable(bufpath) && !getbufvar(buf, "&modified")

    if purge
      let bcnt += 1
      let ix = index(bufs, buf)
      if ix >= 0      | call add(purged, remove(bufs, ix))
      else            | call add(purged, buf) | endif
    endif
  endfor

  " the tab may be closed if there is one window, and it's going to be purged
  if len(tabpagebuflist()) == 1 && index(purged, bufnr("%")) >= 0
    for b in bufs
      if ( index(purged, b) < 0 )
        execute "buffer ".b
        break
      elseif b != bufs[-1]
        continue
      endif
      let s = "Not executing because no other valid buffers for this tab"
      return s:F.msg([[s, 'WarningMsg']])
    endfor
  endif

  for buf in purged
    execute "silent! bwipe ".buf
  endfor

  call xtabline#update()
  redraw!
  let s = "Purged ".bcnt." buffer" | let s .= bcnt!=1 ? "s." : "." | echo s
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:clean_up(bang) abort
  """Remove all invalid/not open(!) buffers in all tabs.
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
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:reopen_last_tab() abort
  """Reopen the last closed tab."""

  if empty(s:X.closed_tabs)
    call s:F.msg("No recent tabs.", 1) | return
  endif

  let s:v.tab_properties = remove(s:X.closed_tabs, -1)

  "check if the cwd must be removed from the blacklist closed_cwds
  let other_with_same_cwd = 0
  let cwd = s:v.tab_properties.cwd

  for t in s:X.Tabs
    if t.cwd == s:v.tab_properties.cwd
      let other_with_same_cwd = 1 | break | endif
  endfor

  if !other_with_same_cwd
    call remove(s:X.closed_cwds, index(s:X.closed_cwds, cwd))
  endif

  "find a valid buffer
  let has_buffer = 0
  for b in s:v.tab_properties.buffers.valid
    if buflisted(b)
      let s:v.halt = 1
      exe "$tabnew" bufname(b)
      let has_buffer = 1
      break
    endif
  endfor
  if !has_buffer
    let s:v.tab_properties = {}
    redraw!
    call s:F.msg([[ "There are no valid buffers for ", 'WarningMsg'],
          \       [ cwd, 'None']])
    return
  endif

  call s:F.change_wd(cwd)
  let s:v.halt = 0
  call xtabline#update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:lock_tab() abort
  """Lock a tab, including currently displayed buffers as valid buffers.
  let T = s:T()
  let T.locked = !T.locked
  let un = T.locked ? '' : 'un'
  if T.locked
    let T.buffers.valid = filter(T.buffers.order, 'buflisted(v:val) && filereadable(bufname(v:val))')
  endif
  redraw!
  call s:F.msg('Tab has been '.un.'locked', T.locked)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:close_buffer() abort
  """Close and delete a buffer, without closing the tab."""
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
    call s:F.msg ("There is only one tab.", 1)
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:relative_paths(bang, cnt) abort
  """Toggle between full relative path and tail only, in the bufline.
  let T = s:T()
  let minus = a:bang ? -1 : 1
  let T.rpaths = a:cnt ? a:cnt * minus
        \      : T.rpaths ? 0
        \      : s:Sets.relative_paths ? s:Sets.relative_paths : (1 * minus)
  call xtabline#update()
  if T.rpaths
    call s:F.msg ([[ "Bufferline shows relative paths [".T.rpaths."]",
          \       'StorageClass']])
  else
    call s:F.msg ([[ "Bufferline shows filename only.", 'WarningMsg']])
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tab_todo() abort
  """Open or close the Tab todo file.
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
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:move_buffer(next, cnt) abort
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
endfun

fun! s:move_buffer_to(cnt, ...) abort
  """Move buffer in the bufferline to a new position."""
  let b = bufnr("%")
  let oB = s:oB()
  let max = len(oB) - 1
  let nr = (max([a:cnt, 1])) - 1
  let i = index(oB, b)

  if i < 0 || i == nr          | return
  elseif i == max && nr >= max | return | endif

  let new = min([nr, max])
  call remove (oB, i)
  if new < max
    call insert(oB, b, new)
  else
    call add(oB, b)
  endif
  call xtabline#update()
endfun

fun! s:hide_buffer(new) abort
  """Move buffer to the last position, then select another one."""
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
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:rename_tab(label) abort
  """Rename the current tab.
  let s:X.Tabs[tabpagenr()-1].name = a:label
  call xtabline#update()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:rename_buffer(label) abort
  """Rename the current buffer.
  let B = s:F.set_buffer_var('name', a:label)
  if empty(B) | return | endif
  call xtabline#update()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_icon(ico) abort
  """Get current icon for this tab."""
  let I = get(s:Sets, 'icons', {})
  if index(keys(I), a:ico) >= 0
    return I[a:ico]
  elseif strchars(a:ico) == 1
    return a:ico
  else
    call s:F.msg ([[ "Invalid icon.", 'WarningMsg']])
    return
  endif
endfun

fun! s:tab_icon(...) abort
  """Set an icon for this tab."""
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
endfun

fun! s:buffer_icon(...) abort
  """Set an icon for this buffer."""
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
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:toggle_pin_buffer(...) abort
  """Pin this buffer, so that it will be shown in all tabs. Optionally rename."""
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
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:new_tab(...) abort
  """Open a new tab with optional name. CWD is $HOME.
  "args : 0 or 1 (tab name)

  let s:v.auto_set_cwd = 1
  let args = a:000[0]
  let n = args[0]? args[0] : ''
  if n > tabpagenr("$") | let n = tabpagenr("$") | endif

  if len(args) == 1
    let s:v.tab_properties = {'cwd': expand("~")}
  else
    let s:v.tab_properties = {'name': args[1], 'cwd': expand("~")}
  endif
  exe n . "tabnew"
  call xtabline#update()
  let s:v.auto_set_cwd = 0
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:edit_tab(...) abort
  """Open a new tab with optional path. Bang triggers rename.

  let s:v.auto_set_cwd = 1
  let args = a:000[0]
  let n = args[0]? args[0] : ''
  let bang = args[1]
  if n > tabpagenr("$") | let n = tabpagenr("$") | endif

  if empty(args)
    let s:v.tab_properties = {'cwd': expand("~")}
    exe n . "tabnew"
  else
    let s:v.tab_properties = {'cwd': s:F.find_suitable_cwd(args[2])}
    exe n . "tabedit" args[2]
  endif
  call xtabline#update()
  let s:v.auto_set_cwd = 0
  if bang
    call feedkeys("\<Plug>(XT-Rename-Tab)")
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:move_tab(...) abort
  """Move a tab to a new position."""
  let max = tabpagenr("$") - 1 | let arg = a:1

  let forward = arg[0] == '+' || empty(arg)
  let backward = arg[0] == '-'
  let bottom = arg[0] == '$'
  let first = arg[0] == '0'

  if ! (forward || backward || bottom || first)
    call s:F.msg('Wrong arguments.', 1) | return
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
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:format_buffer() abort
  """Specify a custom format for this buffer."""
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
  else           | call s:F.msg ([[ "Canceled.", 'WarningMsg' ]])
  endif

  let &ch = och
  call xtabline#update()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:set_cwd(...) abort
  """Set new working directory.
  let [ bang, cwd ] = [ a:1, a:2 ]
  let cwd = s:F.fullpath(cwd)

  if bang || empty(cwd)
    let base = s:F.find_suitable_cwd() | echohl Label
    let cwd = input("Enter a new working directory: ", base, "file") | echohl None
  endif

  if empty(cwd)
    call s:F.msg ([[ "Canceled.", 'WarningMsg' ]])
  else
    call s:F.verbose_change_wd(cwd)
  endif
  call xtabline#update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:set_cbd(...) abort
  """Set new base directory for buffer filtering.
  let [ bang, dir ] = [ a:1, a:2 ]

  if bang
    return s:F.change_base_dir('')
  elseif empty(dir)
    let base = s:F.find_suitable_cwd() | echohl Label
    let dir = input("Enter a new base directory: ", base, "file") | echohl None
  else
    let dir = s:F.fullpath(dir)
  endif

  if empty(dir)
    call s:F.msg ([[ "Canceled.", 'WarningMsg' ]])
  else
    call s:F.change_base_dir(dir)
  endif
  call xtabline#update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:cd(count) abort
  """Set cwd relatively to directory of current file.
  let path = ':p:h'
  for c in range(max([a:count, 0]))
    let path .= ':h'
  endfor
  let cwd = s:F.fullpath(expand("%"), path)
  if !empty(expand("%")) && empty(cwd)
    let cwd = '/'
  endif
  call s:F.verbose_change_wd(cwd)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:reset_tab(...) abort
  """Reset the tab to a pristine state.
  let cwd = a:0? fnamemodify(expand(a:1), :p) : s:F.find_suitable_cwd()
  let s:X.Tabs[tabpagenr()-1] = xtabline#tab#new({'cwd': cwd})
  call s:F.verbose_change_wd(cwd)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:reset_buffer(...) abort
  """Reset the buffer to a pristine state.
  let B = s:B() | let n = bufnr("%")
  if has_key(B, n) | unlet B[n] | endif
  call xtabline#update()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:toggle_tab_names() abort
  """Toggle between custom icon/name and short path/folder icons."""
  let s:v.custom_tabs = !s:v.custom_tabs
  call xtabline#update()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:goto_last_tab() abort
  """Go back to the previously opened tab.
  let n = index(s:X.Tabs, s:v.last_tab)
  exe "normal!" (n + 1)."gt"
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:invalid_buffer(b) abort
  if !s:F.is_tab_buffer(a:b)
    call s:F.msg ([[ "Invalid buffer.", 'WarningMsg']]) | return 1
  endif
endfun
