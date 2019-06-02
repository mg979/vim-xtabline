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

fun! xtabline#cmds#next_buffer(nr, last)
  """Switch to next visible/pinned buffer."""

  if s:F.not_enough_buffers(0) | return | endif
  let accepted = s:oB()

  let ix = a:last ? (len(accepted) - 2) : index(accepted, bufnr("%"))
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
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#cmds#prev_buffer(nr, first)
  """Switch to previous visible/pinned buffer."""

  if s:F.not_enough_buffers(0) | return | endif
  let accepted = s:oB()

  let ix = a:first ? 1 : index(accepted, bufnr("%"))
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
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Other commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#cmds#run(cmd, ...)
  if a:0 == 1
    let args = string(a:1)
  elseif a:0
    let args = []
    for arg in a:000
      call add(args, arg)
    endfor
    let args = string(args)
  else
    let args = ''
  endif
  exe "call s:".a:cmd."(".args.")"
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:toggle_tabs()
  """Toggle between tabs/buffers tabline."""

  if tabpagenr("$") == 1
    call s:F.msg ("There is only one tab.", 1)
  elseif s:v.showing_tabs
    let s:v.showing_tabs = 0
    call s:F.msg ([[ "Showing buffers", 'StorageClass' ]])
    call s:plugins_toggle_tabs()
  else
    let s:v.showing_tabs = 1
    call s:F.msg ([[ "Showing tabs", 'StorageClass' ]])
    call s:plugins_toggle_tabs()
  endif

  call xtabline#update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:toggle_buffers()
  """Toggle buffer filtering in the tabline."""

  if s:v.filtering
    call s:F.msg ([[ "Buffer filtering turned off", 'WarningMsg' ]])
  else
    call s:F.msg ([[ "Buffer filtering turned on", 'StorageClass' ]])
  endif
  let s:v.filtering = !s:v.filtering
  call s:plugins_toggle_buffers()
  call xtabline#update()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tree(cnt)
  let tree = systemlist('tree -d -L '.a:cnt.' '.getcwd())

  if !empty(tree) && len(tree) > s:Sets.depth_tree_size
    let tree = tree[:s:Sets.depth_tree_size] + ['...'] + [tree[-1]]
  endif

  return empty(tree) ? ['', 'None'] : ["\n\n".join(tree, "\n"), 'Type']
endfun

fun! s:depth(cnt)
  """Set tab filtering depth, toggle filtering with bang."""
  let cnt = a:cnt | let T = s:T()

  let current_dir_only  = !cnt && T.depth < 0
  let full_cwd          = !cnt && !current_dir_only
  let T.depth           = cnt ? cnt : current_dir_only ? 0 : -1
  let T.dirs[0]         = T.depth == 0 ? s:F.fullpath(bufname("%"), ":p:h") : T.cwd

  call xtabline#update()

  let tree = !cnt || !executable('tree') || s:v.winOS ? ['', 'None'] : s:tree(cnt)

  if current_dir_only
    let show_dir = T.depth == 0 ? fnamemodify(bufname("%"), ":p:h") : getcwd()
    call s:F.msg ([[ "Buffer filtering is now restricted to ", 'WarningMsg'],
          \[ show_dir, 'None'],
          \[ " alone", 'WarningMsg']])

  elseif full_cwd
    call s:F.msg ([[ "Buffer filtering is now restricted to ", 'Type'],
          \[ getcwd(), 'None'],
          \[ " and all subdirectories", 'Type']])
  else
    call s:F.msg ([[ "Buffer filtering is now restricted to ", 'WarningMsg'],
          \[ cnt, 'None'],
          \[ " directories below ", 'WarningMsg'],
          \[ getcwd(), 'None' ], tree])
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:purge_buffers()
  """Remove unmodified buffers with invalid paths."""

  if !s:v.filtering | echo "Buffer filtering is turned off." | return | endif
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

fun! s:clean_up(bang)
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

fun! s:reopen_last_tab()
  """Reopen the last closed tab."""

  if empty(s:X.closed_tabs)
    call s:F.msg("No recent tabs.", 1) | return | endif

  let s:v.tab_properties = remove(s:X.closed_tabs, -1)

  "check if the cwd must be removed from the blacklist closed_cwds
  let other_with_same_cwd = 0
  let cwd = s:v.tab_properties.cwd

  for t in s:X.Tabs
    if t.cwd == s:v.tab_properties.cwd
      let other_with_same_cwd = 1 | break | endif | endfor

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

    cd `=cwd`
    let s:v.halt = 0
    call xtabline#update()
  endfun

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:lock_tab()
    """Lock a tab, including currently displayed buffers as valid buffers.
    let T = s:T()
    let T.buffers.valid = filter(T.buffers.order, 'buflisted(v:val) && filereadable(bufname(v:val))')
    let T.locked = 1
    redraw!
    echo s:F.msg('Tab has been locked', 1)
  endfun

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:close_buffer()
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

  fun! s:relative_paths()
    """Toggle between full relative path and tail only, in the bufline.
    let T = s:T()
    let T.rpaths = !T.rpaths
    call xtabline#update()
    if T.rpaths
      call s:F.msg ([[ "Bufferline shows relative paths.", 'StorageClass']])
    else
      call s:F.msg ([[ "Bufferline shows filename only.", 'WarningMsg']])
    endif
  endfun

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:tab_todo()
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
    execute todo['command'].s:F.todo_path()
    execute "setf ".todo['syntax']
    let b:xtab_todo = 1
    nnoremap <silent><nowait> <buffer> \q :update<bar>bwipeout<cr>
  endfun

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:move_buffer(cnt, ...)
    """Move buffer in the bufferline to a new position."""
    let b = bufnr("%") | let oB = s:oB() | let max = len(oB) - 1
    let i = index(oB, b)

    if i < 0 || i == a:cnt          | return
    elseif i == max && a:cnt >= max | return | endif

    let new = min([a:cnt, max])
    call remove (oB, i)
    if new < max
      call insert(oB, b, new)
    else
      call add(oB, b)
    endif
    if !a:0 | call xtabline#update() | endif
  endfun

  fun! s:move_buffer_next()
    let b = bufnr("%") | let oB = s:oB() | let max = len(oB) - 1
    let i = index(oB, b)
    if i + 1 > max
      call s:move_buffer(0)
    else
      call s:move_buffer(i + 1)
    endif
  endfun

  fun! s:move_buffer_prev()
    let b = bufnr("%") | let oB = s:oB() | let max = len(oB) - 1
    let i = index(oB, b)
    if i - 1 < 0
      call s:move_buffer(max)
    else
      call s:move_buffer(i - 1)
    endif
  endfun

  fun! s:hide_buffer(new)
    """Move buffer to the last position, then select another one."""
    let b = bufnr("%") | let oB = s:oB() | let max = len(oB) - 1
    let i = index(oB, b)
    call s:move_buffer(1000, 1)

    "if hiding, the buffer that will be selected
    "new in this case is the wanted buffer
    let new = a:new > i ?  a:new-2 : a:new-1
    let then_select = new >= 0 ?  oB[new] : oB[0]

    silent! exe 'b'.then_select
    call xtabline#update()
  endfun
  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:rename_tab(label)
    """Rename the current tab.
    let s:X.Tabs[tabpagenr()-1].name = a:label
    call xtabline#update()
  endfun

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:rename_buffer(label)
    """Rename the current buffer.
    let B = s:F.set_buffer_var('name', a:label)
    if empty(B) | return | endif
    call xtabline#update()
  endfun

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:get_icon(ico)
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

  fun! s:tab_icon(...)
    """Set an icon for this tab."""
    let [bang, icon] = a:1
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

  fun! s:buffer_icon(...)
    """Set an icon for this buffer."""
    let [bang, icon] = a:1
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

  fun! s:toggle_pin_buffer(...)
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

  fun! s:new_tab(...)
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

  fun! s:edit_tab(...)
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

  fun! s:move_tab(...)
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

  fun! s:format_buffer()
    """Specify a custom format for this buffer."""
    let och = &ch
    set ch=2

    let n = bufnr("%")
    if s:invalid_buffer(n) | return | endif

    let has_format = has_key(s:B(), n) && has_key(s:B()[n], 'format')
    let current = has_format? s:B()[n].format : s:Sets.bufline_format
    echohl Label | echo "Current  │" | echohl Special | echon current | echohl Label

    let new = input("New      │", current) | echohl None
    if !empty(new) | call s:F.set_buffer_var('format', new)
    else           | call s:F.msg ([[ "Canceled.", 'WarningMsg' ]])
    endif

    let &ch = och
    call xtabline#update()
  endfun

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:set_cwd(...)
    """Set new working directory."""
    let [bang, cwd] = a:1
    let cwd = s:F.fullpath(cwd)

    if !bang && empty(cwd)
      call s:F.msg ([[ "Canceled.", 'WarningMsg' ]]) | return
    elseif bang
      let base = s:F.find_suitable_cwd() | echohl Label
      let cwd = input("Enter a new working directory: ", base, "file") | echohl None
    endif

    if empty(cwd)
      call s:F.msg ([[ "Canceled.", 'WarningMsg' ]])
    else
      call s:F.change_wd(cwd)
    endif
  endfun

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:reset_tab(...)
    """Reset the tab to a pristine state.
    let cwd = a:0? fnamemodify(expand(a:1), :p) : s:F.find_suitable_cwd()
    let s:X.Tabs[tabpagenr()-1] = xtabline#tab#new({'cwd': cwd})
    call s:F.change_wd(cwd)
  endfun

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:reset_buffer(...)
    """Reset the buffer to a pristine state.
    let B = s:B() | let n = bufnr("%")
    if has_key(B, n) | unlet B[n] | endif
    call xtabline#update()
  endfun

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:toggle_git()
    let T = s:T()
    if T.is_git
      let T.is_git = 0
      let T.files = []
      call s:F.msg('Tab has left git mode')
    elseif s:F.is_repo(T)
      let T.is_git = 1
      call xtabline#tab#git_files(T)
      call s:F.msg('Tab is now in git mode')
    else
      call s:F.msg('Not a git repository', 1)
    endif
    call xtabline#update()
  endfun

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:toggle_tab_names()
    """Toggle between custom icon/name and short path/folder icons."""
    let s:v.custom_tabs = !s:v.custom_tabs
    call xtabline#update()
  endfun

  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:goto_last_tab() abort
    """Go back to the previously opened tab.
    exe "normal!" (s:v.last_tab + 1)."gt"
  endfun

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  " Adjustments for other plugins
  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:plugins_toggle_tabs()
  endfun

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:plugins_toggle_buffers()
  endfun

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  " Helpers
  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  fun! s:invalid_buffer(b)
    if !s:F.is_tab_buffer(a:b)
      call s:F.msg ([[ "Invalid buffer.", 'WarningMsg']]) | return 1
    endif
  endfun
