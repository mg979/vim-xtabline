fun! xtabline#funcs#init()
  let s:X = g:xtabline
  let s:v = s:X.Vars
  let s:Sets = g:xtabline_settings

  let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
  let s:B =  { -> s:X.Buffers             }       "customized buffers
  let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
  return s:Funcs
endfun

let s:Funcs = {}
let s:Funcs.wins    = {   -> tabpagebuflist(tabpagenr()) }
let s:Funcs.has_win = { b -> index(s:Funcs.wins(), b) >= 0 }

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.buffers_order() dict
  """Current ordered list of valid buffers."""
  return s:T().buffers.order
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.delay(time, func) dict
  """Call a function with a timer."""
  " if exists('g:SessionLoad') || s:v.halt | return | endif
  let s:delayed_func = a:func
  call timer_start(a:time, self._delay)
endfun

fun! s:Funcs._delay(timer) dict
  exe "call" s:delayed_func
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.msg(txt, ...) dict
  """Print a message with highlighting."""
  if type(a:txt) == v:t_string
    exe "echohl" a:1? "WarningMsg" : "Label"
    echon a:txt | echohl None
    return | endif

  for txt in a:txt
    exe "echohl ".txt[1]
    echon txt[0]
    echohl None
  endfor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.set_buffer_var(var, ...) dict
  """Init buffer variable in Tabs dict to 0 or a given value.
  """Return buffer dict if successful."""
  let B = bufnr('%') | let bufs = s:B() | let val = a:0 ? a:1 : 0

  if !self.is_tab_buffer(B)
    return self.msg ([[ "Invalid buffer.", 'WarningMsg']]) | endif

  if has_key(bufs, B) | let bufs[B][a:var] = val
  else                | let bufs[B] = {a:var: val, 'path': expand("%:p")}
  endif
  return bufs[B]
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.clean_up_buffer_dict() dict
  """Remove customized buffer entries, if buffers are not valid anymore.
  let bufs = s:B()

  for b in keys(bufs)
    if !bufexists(b) || bufs[b].special
      unlet bufs[b]
    endif
  endfor

  for tab in s:X.Tabs
    let tab.buffers.extra = []
  endfor
  call xtabline#update_obsession()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.fullpath(path, ...) dict
  """OS-specific modified path."""
  let path = expand(a:path)
  let path = empty(path) ? a:path : path        "expand can fail
  let mod = a:0 ? a:1 : ":p"
  let path = s:v.winOS ?
        \tr(fnamemodify(path, mod), '\', '/') : fnamemodify(path, mod)
  return resolve(path)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.sep() dict
  """OS-specific directory separator."""
  return s:v.winOS ? '\' : '/'
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.todo_path() dict
  return getcwd().self.sep().s:Sets.todo.file
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.within_depth(path, depth) dict
  """If tab uses depth, verify if the path can be accepted."""

  if a:depth < 0 | return 1 | endif

  let basedir = self.fullpath(a:path, ":p:h")
  let diff = substitute(basedir, s:T().use_dir, '', '')

  "the number of dir separators in (basedir - cwd) must be < depth
  "but if depth == 0 (only root dir), only accept an empty diff
  return !a:depth ? empty(diff) : count(diff, '/') < a:depth
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Funcs.tab_buffers() dict
  """Return a list of buffers names for this tab."""
  return map(copy(s:vB()), 'bufname(v:val)')
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.is_tab_buffer(...) dict
  """Verify that the buffer belongs to the tab."""
  return (index(s:vB(), a:1) != -1)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.all_valid_buffers(...) dict
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

fun! s:Funcs.all_open_buffers() dict
    """Return all open buffers for all tabs."""
  let open = []
  for i in range(tabpagenr('$')) | call extend(open, tabpagebuflist(i + 1)) | endfor
  return open
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.bdelete(buf) dict
  """Delete buffer if unmodified."""
  if index(s:X.pinned_buffers, a:buf) >= 0
    call self.msg("Pinned buffer has not been deleted.", 1)

  elseif s:T().locked && index(s:T().buffers.valid, a:buf) >= 0
    call remove(s:T().buffers.valid, index(s:T().buffers.valid, a:buf))

  elseif getbufvar(a:buf, '&ft') == 'nofile'
    exe "silent! bwipe ".a:buf
    call xtabline#filter_buffers()

  elseif !getbufvar(a:buf, '&modified')
    exe "silent! bdelete ".a:buf
    call xtabline#filter_buffers()
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.find_suitable_cwd(...) dict
  """Look for a VCS dir below current directory."""
  let s = self.sep() | let l:Found = { d -> isdirectory(d.s.'.git') }

  let f = a:0 ? a:1 : expand("%")
  let h = ":p:h"
  for i in range(5)
    let dir = fnamemodify(f, h)
    if l:Found(dir) | return self.fullpath(dir) | endif
    let h .= ":h"
  endfor
  return self.fullpath(getcwd())
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Funcs.not_enough_buffers(pinned) dict
  """Just return if there aren't enough buffers."""
  let bufs = a:pinned ? s:v.pinned_buffers : self.buffers_order()
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
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.refresh_tabline() dict
  if s:v.showing_tabs
    set tabline=%!xtabline#render#tabs()
  else
    set tabline=%!xtabline#render#buffers()
  endif
endfun

