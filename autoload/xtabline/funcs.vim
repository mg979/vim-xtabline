fun! xtabline#funcs#init() abort
  let s:X = g:xtabline
  let s:v = s:X.Vars
  let s:Sets = g:xtabline_settings

  let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
  let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
  let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab
  return s:Funcs
endfun

let s:Funcs = {}
let s:Funcs.wins    = {   -> tabpagebuflist(tabpagenr()) }
let s:Funcs.has_win = { b -> index(s:Funcs.wins(), b) >= 0 }
let s:Funcs.is_repo = { t -> isdirectory(t.cwd . s:v.slash . '.git') }

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.delay(time, func) abort
  """Call a function with a timer."""
  " if exists('g:SessionLoad') || s:v.halt | return | endif
  let s:delayed_func = a:func
  call timer_start(a:time, self._delay)
endfun

fun! s:Funcs._delay(timer) abort
  exe "call" s:delayed_func
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.msg(txt, ...) abort
  """Print a message with highlighting."""
  if type(a:txt) == v:t_string
    exe "echohl" a:0 && a:1? "WarningMsg" : "Label"
    echon a:txt | echohl None
    return
  endif

  for txt in a:txt
    exe "echohl ".txt[1]
    echon txt[0]
    echohl None
  endfor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.set_buffer_var(var, ...) abort
  """Init buffer variable in Tabs dict to 0 or a given value.
  """Return buffer dict if successful."""
  let B = bufnr('%') | let bufs = s:X.Buffers | let val = a:0 ? a:1 : 0

  if !self.is_tab_buffer(B)
    return self.msg ([[ "Invalid buffer.", 'WarningMsg']]) | endif

  if has_key(bufs, B) | let bufs[B][a:var] = val
  else                | let bufs[B] = {a:var: val, 'path': expand("%:p")}
  endif
  return bufs[B]
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.fullpath(path, ...) abort
  """OS-specific modified path."""
  let path = expand(a:path)
  let path = empty(path) ? a:path : path        "expand can fail
  let mod = a:0 ? a:1 : ":p"
  let path = s:v.winOS ?
        \tr(fnamemodify(path, mod), '\', '/') : fnamemodify(path, mod)
  return resolve(path)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.sep() abort
  """OS-specific directory separator."""
  return s:v.winOS ? '\' : '/'
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.todo_path() abort
  return fnameescape(getcwd().self.sep().s:Sets.todo.file)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.tab_buffers() abort
  """Return a list of buffers names for this tab."""
  return map(copy(s:vB()), 'bufname(v:val)')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.add_ordered(buf, ...) abort
  """Add a buffer to the Tab.buffers.ordere list.
  let [ b, bufs, first, i ] = [ a:buf, s:oB(), a:0, index(s:oB(), a:buf) ]

  " if the buffer goes first, remove it from the list if present
  if i >= 0 && first | call remove(bufs, i) | endif

  " if the buffer doesn't go first, only add it if not present
  if first      | call insert(bufs, b, 0)
  elseif i < 0  | call add(bufs, b)
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.uniq(list) abort
  """Make sure an element appears only once in the list.
  let [ i, max ] = [ 0, len(a:list)-2 ]
  while i <= max
    let extra = index(a:list, a:list[i], i+1)
    if extra > 0
      call remove(a:list, extra)
      let max -= 1
    else
      let i += 1
    endif
  endwhile
  return a:list
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.is_tab_buffer(...) abort
  """Verify that the buffer belongs to the tab."""
  return (index(s:vB(), a:1) != -1)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.all_valid_buffers(...) abort
    """Return all valid buffers for all tabs."""
  let valid = []
  for i in range(tabpagenr('$'))
    if a:0
      call extend(valid, s:X.Tabs[i].buffers.order)
    else
      call extend(valid, s:X.Tabs[i].buffers.valid)
    endif
  endfor
  return valid
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.all_open_buffers() abort
    """Return all open buffers for all tabs."""
  let open = []
  for i in range(tabpagenr('$')) | call extend(open, tabpagebuflist(i + 1)) | endfor
  return open
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Shortened paths

fun! s:Funcs.short_cwd(tabnr, h, ...) abort
  let path = a:0 ? a:1 : s:X.Tabs[a:tabnr-1].cwd

  if !a:h
    return fnamemodify(path, ":t")
  else
    let H = fnamemodify(path, ":~")
    if s:v.winOS | let H = tr(H, '\', '/')
  endif

  let splits = split(H, '/')
  if len(splits) > a:h
    let [ head, tail ] = [splits[:-(a:h+1)], splits[-(a:h):]]
    call map(head, "substitute(v:val, '\\(.\\).*', '\\1', '')")
    let H = join(head + tail, '/')
  endif
  if s:v.winOS
    let H = tr(H, '/', '\')
  endif
  return H
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.short_path(bnr, h) abort
  if empty(bufname(a:bnr))
    return ''
  endif
  let H = fnamemodify(bufname(a:bnr), ":~:.")
  if s:v.winOS
    let H = tr(H, '\', '/')
  endif
  if match(H, '/') < 0
    return H
  endif
  let [ is_root, splits ] = [ H[:0] == '/', split(H, '/') ]
  let [ head, tail ] = [splits[:-(a:h+1)], splits[-(a:h):]]
  call map(head, "substitute(v:val, '\\(.\\).*', '\\1', '')")
  let H = join(head + tail, '/')
  if is_root
    let H = '/' . H
  elseif s:v.winOS
    let H = tr(H, '/', '\')
  endif
  return H
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.bdelete(buf) abort
  """Delete buffer if unmodified and not pinned."""
  if index(s:X.pinned_buffers, a:buf) >= 0
    call self.msg("Pinned buffer has not been deleted.", 1)

  elseif s:T().locked && index(s:T().buffers.valid, a:buf) >= 0
    call remove(s:T().buffers.valid, index(s:T().buffers.valid, a:buf))

  elseif getbufvar(a:buf, '&ft') == 'nofile'
    exe "silent! bwipe ".a:buf
    call xtabline#update()

  elseif !getbufvar(a:buf, '&modified')
    exe "silent! bdelete ".a:buf
    call xtabline#update()
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.not_enough_buffers(pinned) abort
  """Just return if there aren't enough buffers."""
  let bufs = a:pinned ? s:v.pinned_buffers : s:oB()
  let pin  = a:pinned ? ' pinned ' : ' '

  if len(bufs) < 2
    if empty(bufs)
      call self.msg ([[ "No available".pin."buffers for this tab.", 'WarningMsg' ]])
    elseif index(bufs, bufnr("%")) == -1
      return
    else
      call self.msg ([[ "No other available".pin."buffers for this tab.", 'WarningMsg' ]])
    endif
    return 1
  endif
endfun




"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Working directory functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.find_suitable_cwd(...) abort
  """Look for a VCS dir below current directory."""
  let s = self.sep() | let l:Found = { d -> isdirectory(d.s.'.git') }

  let limit = get(s:Sets, 'git_dir_search_down_limit', 5)
  let f = a:0 ? a:1 : expand("%")
  let h = ":p:h"
  for i in range(limit)
    let dir = fnamemodify(f, h)
    if l:Found(dir) | return self.fullpath(dir) | endif
    let h .= ":h"
  endfor
  return self.fullpath(getcwd())
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.can_use_tcd()
  return exists(':tcd') == 2 && s:Sets.use_tab_cwd > 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.verbose_change_wd(cwd) abort
  if !isdirectory(a:cwd)
    return self.msg("Invalid directory: ".a:cwd, 1)
  endif
  call extend(s:T(), { 'cwd': a:cwd })
  call self.change_wd(a:cwd)
  call xtabline#update()
  redraw
  call self.msg ([[ "Working directory: ", 'Label' ], [ a:cwd, 'None' ]])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.change_base_dir(dir) abort
  """Set/unset the base filtering directory.
  let T = s:T()

  if empty(a:dir) && !has_key(T, 'dir')
    return self.msg('No base directory has been set yet.', 1)

  elseif empty(a:dir)
    unlet T.dir
    call self.msg('Base directory has been unset.', 0)
    return xtabline#update()

  elseif !isdirectory(a:dir)
    return  self.msg("Invalid directory: ".a:dir, 1)
  endif

  let T.dir = a:dir
  call xtabline#update()
  redraw
  call self.msg ([[ "Base directory: ", 'Label' ], [ a:dir, 'None' ]])
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.set_tab_wd() abort
  let T = s:T()
  if self.can_use_tcd()
    let T.cwd = self.fullpath(getcwd(-1, tabpagenr()))
  elseif s:Sets.use_tab_cwd
    let T.cwd = self.fullpath(getcwd())
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" change working directory, update tab cwd and session data
fun! s:Funcs.change_wd(dir) abort
  let T = s:T()

  if !isdirectory(a:dir)
    return self.msg('[xtabline] directory doesn''t exists', 1)
  endif

  if !s:Sets.use_tab_cwd
    " do nothing

  elseif self.can_use_tcd()
    " change dir if tab-local cwd is different from the expected tab cwd
    if getcwd(-1, tabpagenr()) != a:dir
      exe 'tcd' a:dir
    endif

  elseif getcwd() != a:dir
    exe 'cd' a:dir
  endif

  call self.set_tab_wd()
  call xtabline#update_this_session()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.cd_into_tab_wd() abort
  """Try to change the current directory.
  let T = s:T()
  if s:Sets.use_tab_cwd
    call self.change_wd(T.cwd)
  elseif T.cwd != getcwd()
    let T.cwd = getcwd()
  endif
endfun

