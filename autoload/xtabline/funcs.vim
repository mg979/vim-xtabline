fun! xtabline#funcs#init()
  let s:X = g:xtabline
  let s:V = s:X.Vars
  let s:Tabs = s:X.Tabs
  let s:Sets = g:xtabline_settings

  let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
  let s:B =  { -> s:X.Buffers             }       "customized buffers
  let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
  let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab
  return s:Funcs
endfun

let s:Funcs = {}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.check_tabs() dict
  """Create or remove tab dicts if necessary. Rearrange tabs list if order is wrong."""
  while len(s:Tabs) < tabpagenr("$") | call add(s:Tabs, xtabline#new_tab()) | endwhile
  while len(s:Tabs) > tabpagenr('$') | call remove(s:Tabs, -1)              | endwhile
  call self.check_index()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.delay(time, func)
  """Call a function with a timer."""
  let s:delayed_func = a:func
  call timer_start(a:time, self._delay)
endfun

fun! s:Funcs._delay(timer)
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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.invalid_buffer(buf) dict
  return !buflisted(a:buf) ||
        \ getbufvar(a:buf, "&buftype") == 'quickfix'
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.set_buffer_var(var, ...) dict
  """Init buffer variable in Tabs dict to 0 or a given value.
  """Return buffer dict if successful."""
  let B = bufnr('%')
  if !self.is_tab_buffer(B)
    call self.msg ([[ "Invalid buffer.", 'WarningMsg']])
    return
  endif
  let bufs = s:B()
  if has_key(bufs, B) | let bufs[B][a:var] = a:0? a:1 : 0
  else                | let bufs[B] = {a:var: a:0? a:1 : 0, "path": expand("%:p")}
  endif
  return bufs[B]
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.update_buffers()
  let valid = s:vB()
  let order = s:oB()

  "clean up ordered buffers list
  let remove = []
  for buf in order
    if index(valid, buf) < 0
      call add(remove, buf)
    endif
  endfor

  for buf in remove
    call remove(order, index(order, buf))
  endfor

  " add missing entries in ordered list
  for buf in valid
    if index(order, buf) < 0
      call add(order, buf)
    endif
  endfor

  " remove customized buffer entries, if buffers are not valid anymore
  let bufs = s:B()
  for b in keys(bufs)
    if bufs[b].path !=# expand("#".b.":p")
      unlet bufs[b]
    endif
  endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.sep() dict
  """OS-specific directory separator."""
  return exists('+shellslash') && &shellslash ? '\' : '/'
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.todo_path() dict
  return getcwd().self.sep().s:Sets.todo.file
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.tab_template(...) dict
  let mod = a:0? a:1 : {}
  return extend({'name':    '',
               \ 'cwd':     getcwd(),
               \ 'vimrc':   {},
               \ 'locked':  0,
               \ 'depth':   0,
               \ 'icon':   '',
               \}, mod)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.within_depth(path, depth) dict
  """If tab uses depth, verify if the path can be accepted."""

  if !a:depth | return 1 | endif

  let basedir = fnamemodify(a:path, ":p:h")
  let diff = substitute(basedir, getcwd(), '', '')

  "the number of dir separators in (basedir - cwd) must be <= depth
  return count(diff, self.sep()) < a:depth
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.check_index() dict
  """Ensure the current tab has the right index in the global dict."""
  let N = tabpagenr() - 1
  if s:Tabs[N].index != N
    call insert(s:Tabs, remove(s:Tabs, s:Tabs[N].index), N)
    let i = 0
    for t in s:Tabs
      let t.index = i
      let i += 1
    endfor
  endif
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

fun! s:Funcs.all_valid_buffers()
    """Return all valid buffers for all tabs."""
  let valid = []
  for i in range(tabpagenr('$')) | call extend(valid, s:X.Tabs[i].buffers.valid) | endfor
  return valid
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.all_open_buffers()
    """Return all open buffers for all tabs."""
  let open = []
  for i in range(tabpagenr('$')) | call extend(open, tabpagebuflist(i + 1)) | endfor
  return open
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.bdelete(buf) dict
  """Delete buffer if unmodified."""
  if !getbufvar(a:buf, '&modified')
    exe "silent! bdelete ".a:buf
    call xtabline#filter_buffers()
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.find_suitable_cwd() dict
  """Look for a VCS dir below current directory."""
  let s = self.sep() | let l:Found = { d -> isdirectory(d.s.'.git') }

  let f = expand("%")
  let h = ":p:h"
  for i in range(5)
    let dir = fnamemodify(f, h)
    if l:Found(dir) | return dir | endif
    let h .= ":h"
  endfor
  return fnamemodify(f, ":p:h")
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Funcs.not_enough_buffers() dict
  """Just return if there aren't enough buffers."""
  let bufs = s:vB()

  if len(bufs) < 2
    if index(bufs, bufnr("%")) == -1
      return
    elseif !len(bufs)
      call self.msg ([[ "No available buffers for this tab.", 'WarningMsg' ]])
    else
      call self.msg ([[ "No other available buffers for this tab.", 'WarningMsg' ]])
    endif
    return 1
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Funcs.refresh_tabline() dict
  """Invalidate old Airline tabline and force redraw."""
  if exists('g:loaded_airline') && g:airline#extensions#tabline#enabled
    let g:airline#extensions#tabline#exclude_buffers = s:T().exclude
    call airline#extensions#tabline#buflist#invalidate()
  else
    set tabline=%!xtabline#render#buffers()
  endif
endfunction

