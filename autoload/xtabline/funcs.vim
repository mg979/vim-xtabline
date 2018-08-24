fun! xtabline#funcs#init()
  let s:X = g:xtabline
  let s:v = s:X.Vars
  let s:Tabs = s:X.Tabs
  let s:Sets = g:xtabline_settings

  let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
  let s:B =  { -> s:X.Buffers             }       "customized buffers
  let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
  return s:Funcs
endfun

let s:Funcs = {}
let s:Funcs.wins        = { -> tabpagebuflist(tabpagenr()) }
let s:Funcs.fullpath    = { p -> fnamemodify(expand(p), ":p") }
let s:Funcs.invalid     = { b -> !buflisted(b) || getbufvar(b, "&buftype") == 'quickfix' }

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.check_tabs() dict
  """Create or remove tab dicts if necessary. Rearrange tabs list if order is wrong."""
  while len(s:Tabs) < tabpagenr("$") | call add(s:Tabs, xtabline#new_tab_dict()) | endwhile
  while len(s:Tabs) > tabpagenr('$') | call remove(s:Tabs, -1)                   | endwhile
  call self.check_this_tab()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.check_this_tab() dict
  """Ensure all dict keys are present."""
  let s:X.Tabs[tabpagenr()-1] = extend(self.tab_template(), s:T())
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.airline_enabled() dict
  """Check if Airline tabline must be used."""
  return exists('g:loaded_airline') &&
        \exists('g:airline#extensions#tabline#enabled') &&
        \g:airline#extensions#tabline#enabled
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.buffers_order() dict
  """Current ordered list of valid buffers."""
  return s:Funcs.airline_enabled() ? s:vB() : s:T().buffers.order
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

fun! s:Funcs.update_buffers() dict
  let valid = s:vB()
  let order = self.buffers_order()

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
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.clean_up_buffer_dict(...) dict
  """Remove customized buffer entries, if buffers are not valid anymore.
  let bufs = s:B()
  let l:Invalid = { b -> !bufexists(b)                  ||
                      \  has_key(bufs[b], 'special')    ||
                      \  bufs[b].path !=# expand("#".b.":p") }

  "called on BufDelete for a single buffer
  if a:0 && !bufexists(a:1) && has_key(bufs, a:1)
    unlet bufs[a:1]
    let i = index(sbufs, a:1)
    if i > 0 | call remove(sbufs, i) | endif
    return
  endif

  for b in keys(bufs)
    if l:Invalid(b)
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
               \ 'depth':   -1,
               \ 'rpaths':  0,
               \ 'icon':    '',
               \}, mod)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.within_depth(path, depth) dict
  """If tab uses depth, verify if the path can be accepted."""

  if a:depth < 0 | return 1 | endif

  let basedir = fnamemodify(a:path, ":p:h")
  let diff = substitute(basedir, getcwd(), '', '')

  "the number of dir separators in (basedir - cwd) must be <= depth
  return count(diff, self.sep()) <= a:depth
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

fun! s:Funcs.all_valid_buffers() dict
    """Return all valid buffers for all tabs."""
  let valid = []
  for i in range(tabpagenr('$')) | call extend(valid, s:X.Tabs[i].buffers.valid) | endfor
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
    if l:Found(dir) | return dir | endif
    let h .= ":h"
  endfor
  return fnamemodify(f, ":p:h")
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

fun! s:Funcs.force_update() dict
  """Airline is stubborn and wants au BufAdd."""
  call xtabline#filter_buffers()
  if self.airline_enabled()
    doautocmd BufAdd
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Funcs.refresh_tabline() dict
  """Invalidate old Airline tabline and force redraw."""
  if self.airline_enabled()
    let g:airline#extensions#tabline#exclude_buffers = s:T().exclude
    call airline#extensions#tabline#buflist#invalidate() | endif
  if s:v.showing_tabs
    set tabline=%!xtabline#render#tabs()
  else
    set tabline=%!xtabline#render#buffers()
  endif
endfunction

