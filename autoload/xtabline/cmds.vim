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
  if s:not_enough_buffers() | return | endif
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
  if s:not_enough_buffers() | return | endif
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
  " Command entry point. "{{{1
  let args = a:0 ? join(map(copy(a:000), 'string(v:val)'), ',') : ''
  exe "call s:".a:cmd."(".args.")"
endfun " }}}


fun! s:change_mode(mode) abort
  " Cycle the active tabline mode. "{{{1
  if !empty(a:mode)
    if a:mode == s:v.tabline_mode
      return
    elseif index(['tabs', 'buffers', 'arglist'], a:mode) >= 0
      let modes = [a:mode]
    else
      return s:F.msg('[xtabline] wrong mode', 1)
    endif
  else
    let modes = copy(s:Sets.tabline_modes)
  endif

  " only allow arglist, if the arglist isn't empty and files are valid
  let nargs = len(filter(argv(), 'filereadable(v:val)'))
  if !nargs && index(modes, 'arglist') >= 0
    call remove(modes, index(modes, 'arglist'))
    if empty(modes)
      return s:F.msg('[xtabline] arglist is empty', 1)
    endif
  endif

  if empty(modes)
    return
  endif

  let current = index(modes, s:v.tabline_mode) + 1
  if current == len(modes)
    let s:v.tabline_mode = modes[0]
  else
    let s:v.tabline_mode = modes[current]
  endif

  call s:F.msg([[ "Showing " . s:v.tabline_mode, 'StorageClass' ]])

  call xtabline#update(1)
endfun "}}}


fun! s:toggle_filtering() abort
  " Toggle buffer filtering in the tabline. "{{{1
  if s:Sets.buffer_filtering
    call s:F.msg([[ "Buffer filtering turned off", 'WarningMsg' ]])
  else
    call s:F.msg([[ "Buffer filtering turned on", 'StorageClass' ]])
  endif
  let s:Sets.buffer_filtering = !s:Sets.buffer_filtering
  for T in s:X.Tabs
    let T.refilter = 1
  endfor
  call xtabline#update()
endfun "}}}


fun! s:purge_buffers() abort
  " Remove unmodified buffers with invalid paths. "{{{1
  call xtabline#filter_buffers()

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
  call xtabline#filter_buffers()

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
  call xtabline#update(1)
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
    buffer #
    call s:F.bdelete(current)

  elseif ( tbufs > 1 ) || ( tbufs && !s:F.is_tab_buffer(current) )
    execute "normal \<Plug>(XT-Prev-Buffer)"
    call s:F.bdelete(current)

  elseif getbufvar(current, '&modified')
    call s:F.msg("Not deleting because of unsaved changes", 1)

  elseif tabpagenr() > 1 || tabpagenr("$") != tabpagenr()
    call s:F.bdelete(current)

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

  call xtabline#update(1)

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
      execute b.'bdelete'
      return
    endif
  endfor
  let todo = extend({
        \"command": 'split',
        \"file":    ".TODO",
        \"syntax":  'markdown',
        \}, get(s:Sets, 'todo', {}))
  let s:v.buffer_properties = { 'name': 'TODO', 'special': 1 }
  execute todo.command fnameescape(getcwd() . '/' . todo.file)
  execute "setf" todo.syntax
  let b:xtab_todo = 1
  nnoremap <silent><nowait> <buffer> gq :update<bar>bdelete<cr>
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
  call xtabline#update(1)
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
  call xtabline#update(1)
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
  call xtabline#update(1)
endfun "}}}


fun! s:name_tab(label) abort
  " Rename the current tab. "{{{1
  if empty(a:label) | return | endif
  let s:X.Tabs[tabpagenr()-1].name = a:label
  call xtabline#update()
endfun "}}}


fun! s:name_buffer(label) abort
  " Rename the current buffer. "{{{1
  if empty(a:label) | return | endif
  let B = s:F.set_buffer_var(bufnr(''), 'name', a:label)
  if &buftype != ''
    let B.special = 1
  endif
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
    call s:F.msg([[ "Invalid icon.", 'WarningMsg']])
    return ''
  endif
endfun "}}}


fun! s:tab_icon(bang, icon) abort
  " Set an icon for this tab. "{{{1
  let T = s:T()
  let T.icon = a:bang ? '' : s:get_icon(a:icon)
  call xtabline#update()
endfun "}}}


fun! s:buffer_icon(bang, icon) abort
  " Set an icon for this buffer. "{{{1
  let icon = a:bang ? '' : s:get_icon(a:icon)
  call s:F.set_buffer_var(bufnr(''), 'icon', icon)
  call xtabline#update()
endfun "}}}


fun! s:toggle_pin_buffer(...) abort
  " Pin this buffer, so that it will be shown in all tabs. Optionally rename. "{{{1
  let B = bufnr('%') | let i = s:pinned(B)

  if a:0 && match(a:1, "\S") >= 0
    call s:F.set_buffer_var(B, 'name', a:1)
  elseif i < 0 && s:invalid_buffer(B)
    return
  endif

  if i >= 0
    call remove(s:X.pinned_buffers, i)
  else
    call add(s:X.pinned_buffers, B)
  endif
  call xtabline#update(1)
endfun "}}}


fun! s:reset_tab(...) abort
  " Reset the tab and its cwd. "{{{1
  let s:X.Tabs[tabpagenr()-1] = xtabline#tab#new({'cwd': getcwd()})
  call xtabline#update(1)
endfun "}}}


fun! s:reset_buffer(...) abort
  " Reset the buffer to a pristine state. "{{{1
  let B = s:B() | let n = bufnr("%")
  if has_key(B, n) | unlet B[n] | endif
  call xtabline#update()
endfun "}}}


fun! s:reset_all(...) abort
  " Reset all buffers and tabs, removing customizations. "{{{1
  let s:X.Buffers = {}
  let s:X._buffers = {}
  let s:X.Tabs = []
  call xtabline#tab#check_all()
  call xtabline#filter_buffers()
  call xtabline#update()
endfun "}}}


fun! s:toggle_tab_names() abort
  " Toggle between custom icon/name and short path/folder icons. "{{{1
  let s:v.user_labels = !s:v.user_labels
  call xtabline#update()
endfun "}}}


fun! s:goto_last_tab() abort
  " Go back to the previously opened tab. "{{{1
  if !exists('s:v.last_tabn')
    return s:F.msg('[xtabline] no last tab', 1)
  endif
  let this = tabpagenr()
  exe "normal!" s:v.last_tabn."gt"
  let s:v.last_tabn = this
endfun "}}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:invalid_buffer(b) abort
  " {{{1
  if !s:F.is_tab_buffer(a:b)
    call s:F.msg([[ "Invalid buffer.", 'WarningMsg']])
    return 1
  endif
endfun " }}}

fun! s:not_enough_buffers() abort
  "{{{1
  let bufs = s:oB()
  if len(bufs) < 2
    if empty(bufs)
      call s:F.msg([[ "No available buffers for this tab.", 'WarningMsg' ]])
      return v:true
    elseif index(bufs, bufnr("%")) >= 0
      call s:F.msg([[ "No other available buffers for this tab.", 'WarningMsg' ]])
      return v:true
    endif
  endif
  return v:false
endfun "}}}


" vim: et sw=2 ts=2 sts=2 fdm=marker
