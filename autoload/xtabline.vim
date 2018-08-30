""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Script variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X    = g:xtabline
let s:v    = s:X.Vars
let s:F    = s:X.Funcs
let s:Sets = g:xtabline_settings

let s:v.tab_properties = {}                     "if not empty, newly created tab will inherit them
let s:v.filtering      = 1                      "whether bufline filtering is active
let s:v.custom_tabs    = 1                      "tabline shows custom names/icons
let s:v.showing_tabs   = 0                      "tabline or bufline?
let s:v.halt           = 0                      "used to temporarily halt some functions
let s:v.auto_set_cwd   = 0                      "used to temporarily allow auto cwd detection

let s:T  = { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:B  = { -> s:X.Buffers             }       "customized buffers
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:pB = { -> s:X.pinned_buffers      }       "pinned buffers list
let s:oB = { -> s:F.buffers_order()     }       "ordered buffers for tab

let s:invalid  = { b -> !buflisted(b) || getbufvar(b, "&buftype") == 'quickfix' }
let s:ready    = { -> !(exists('g:SessionLoad') || s:v.halt) }
let s:is_ma    = { b -> index(s:F.wins(), b) >= 0 && getbufvar(b, "&ma") }
let s:is_extra = { b -> buflisted(b) && index(s:T().buffers.extra, b) >= 0 }
let s:Is       = { n,s -> match(bufname(n), s) == 0 }
let s:Ft       = { n,s -> getbufvar(n, "&ft")  == s }

let s:most_recent = -1
let s:new_tab_created = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Init functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#init()
  set showtabline=2
  let s:X.Funcs = xtabline#funcs#init()
  let s:F = s:X.Funcs
  call xtabline#maps#init()

  if exists('g:loaded_webdevicons')
    let extensions = g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols
    let exact = g:WebDevIconsUnicodeDecorateFileNodesExactSymbols
    let patterns = g:WebDevIconsUnicodeDecorateFileNodesPatternSymbols
    let s:X.devicons = {'extensions': extensions, 'exact': exact, 'patterns': patterns}
  endif

  if s:F.airline_enabled() && s:Sets.override_airline
    let g:airline#extensions#tabline#enabled = 0
  elseif s:F.airline_enabled()
    let g:airline#extensions#tabline#show_buffers = 1
  endif

  call s:F.check_tabs()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#update_obsession()
  let string = 'let g:xtabline.Tabs = '.string(s:X.Tabs).
        \' | let g:xtabline.Buffers = '.string(s:X.Buffers).
        \' | let g:xtabline.pinned_buffers = '.string(s:X.pinned_buffers).
        \' | call xtabline#filter_buffers(1)'
  if !exists('g:obsession_append')
    let g:obsession_append = [string]
  else
    for i in g:obsession_append
      if match(i, "^let g:xtabline") >= 0
        call remove(g:obsession_append, i)
        break
      endif
    endfor
    call add(g:obsession_append, string)
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Main functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#new_tab_dict(...)
  """Create an entry in the Tabs list.
  """tab_properties can be set by a command, before this function is called.

  let p = a:0? extend(a:1, s:v.tab_properties) : s:v.tab_properties

  "cwd:     (string)  working directory
  "name:    (string)  tab name
  "buffers: (dict)    with accepted and ordered buffer numbers lists
  "exclude: (list)    excluded buffer numbers
  "index:   (int)     tabpagenr() - 1, when tab is set
  "locked:  (bool)    when filtering is independent from cwd
  "rpaths:  (int)     whether the bufferline shows relative paths or filenames
  "depth:   (int)     filtering recursive depth (n. of directories below cwd)
  "                   -1 means full cwd, 0 means root dir only, >0 means up to n subdirs
  "vimrc:   (dict)    settings to be sourced when entering the tab
  "                   it can hold: {'file': string, 'commands': list} (one, both or empty)

  let cwd     = has_key(p, 'cwd')?     p.cwd     : getcwd()
  let name    = has_key(p, 'name')?    p.name    : ''
  let buffers = has_key(p, 'buffers')? p.buffers : {'valid': [], 'order': [], 'extra': []}
  let exclude = has_key(p, 'exclude')? p.exclude : []
  let locked  = has_key(p, 'locked')?  p.locked  : 0
  let depth   = has_key(p, 'depth')?   p.depth   : -1
  let vimrc   = has_key(p, 'vimrc')?   p.vimrc   : {}
  let rpaths  = has_key(p, 'rpaths')?  p.rpaths  : 0

  let s:v.tab_properties = {}

  return extend(s:F.tab_template(), {
        \'name':    name,       'cwd':     cwd,
        \ 'buffers': buffers,    'exclude': exclude,
        \ 'locked':  locked,     'depth':   depth,
        \ 'vimrc':   vimrc,      'rpaths':  rpaths})
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#filter_buffers(...)
  """Filter buffers so that only the ones within the tab's cwd will show up.
  let T = s:T() | let can_show_tabs = s:v.showing_tabs && has_key(T, 'init')

  " 'accepted' is a list of buffer numbers, for quick access.
  " 'excluded' is a list of paths, it will be used by Airline to hide buffers.

  if !s:ready() && !a:0 | call s:F.check_tabs() | return
  elseif can_show_tabs  | set tabline=%!xtabline#render#tabs()
    return
  endif

  let locked          = T.locked
  let accepted        = locked? T.buffers.valid   : []
  let excluded        = locked? T.exclude : []
  let depth           = T.depth
  let cwd             = getcwd()
  let _pre            = '^'
  let post_           = s:F.sep()

  for buf in range(1, bufnr("$"))

    if s:is_special(buf)        | call add(accepted, buf)
    elseif s:invalid(buf)       | continue
    elseif !s:v.filtering       | call add(accepted, buf)
    elseif s:is_ma(buf)         | call add(accepted, buf)
    else
      " get the path
      let path = expand("#".buf.":p")

      " accept or exclude buffer
      if locked && index(accepted, buf) < 0
        call add(excluded, buf)

      elseif s:F.within_depth(path, depth) && path =~ _pre.cwd.post_
        call add(accepted, buf)

      else
        call add(excluded, buf)
      endif
    endif
  endfor

  let T.buffers.valid = accepted
  let T.exclude       = excluded
  let T.init          = 1
  call s:F.update_buffers()
  call s:F.refresh_tabline()
  call xtabline#update_obsession()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#next_buffer(nr, pinned)
  """Switch to next visible/pinned buffer."""

  if s:F.not_enough_buffers(a:pinned) | return | endif
  let accepted = a:pinned? s:pB() : s:oB()

  let ix = index(accepted, bufnr("%"))
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

fun! xtabline#prev_buffer(nr, pinned)
  """Switch to previous visible/pinned buffer."""

  if s:F.not_enough_buffers(a:pinned) | return | endif
  let accepted = a:pinned? s:pB() : s:oB()

  let ix = index(accepted, bufnr("%"))
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


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommand Functions
" Inspired by TabPageCd
" Copyright (C) 2012-2013 Kana Natsuno <http://whileimautomaton.net/>
" License: MIT License
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Do(action, ...)
  if empty(g:xtabline.Tabs) | return | endif

  let X = g:xtabline | let F = X.Funcs | let V = X.Vars
  let N = tabpagenr() - 1

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  if a:action == 'new'

    call insert(X.Tabs, xtabline#new_tab_dict(), N)
    if V.auto_set_cwd && s:ready()
      let s:new_tab_created = 1
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'bufenter'
    if s:new_tab_created && V.auto_set_cwd && s:ready()
      call s:set_new_tab_cwd(N)
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'enter'

    call F.check_tabs()
    let T = X.Tabs[N]

    cd `=T.cwd`

    if !empty(T)
      if has_key(T.vimrc, 'commands')
        for c in commands | exe c | endfor
      endif
      if has_key(T.vimrc, 'file')
        exe "source ".T.vimrc.file
      endif
    endif

    if s:F.airline_enabled()
      call xtabline#filter_buffers()
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'leave'

    let V.last_tab = N
    let X.Tabs[N].cwd = getcwd()
    call F.clean_up_buffer_dict()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'close'

    if index(X.closed_cwds, X.Tabs[V.last_tab].cwd) < 0
      call add(X.closed_tabs, copy(X.Tabs[V.last_tab]))
      call add(X.closed_cwds, X.Tabs[V.last_tab].cwd)
    endif
    call remove(X.Tabs, V.last_tab)

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'session'

    for buf in s:X.pinned_buffers
      let i = index(s:X.pinned_buffers, buf)
      if s:invalid(buf)
        call remove(s:X.pinned_buffers, i)
      endif
    endfor
    let cwd = X.Tabs[N].cwd | cd `=cwd` | call xtabline#filter_buffers()
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:set_new_tab_cwd(N)
  """Find suitable cwd for the new tab. Only runs after XT commands."""
  let s:new_tab_created = 0 | let T = s:X.Tabs[a:N]

  " empty tab sets cwd to ~, non-empty tab looks for a .git dir
  if empty(bufname("%"))
    let T.cwd = s:F.fullpath('~')
  elseif T.cwd == '~' || s:F.fullpath("%") !~ s:F.fullpath(T.cwd)
    let T.cwd = s:F.find_suitable_cwd()
  endif
  cd `=T.cwd`
  call s:F.force_update()
  call s:F.delay(200, 'g:xtabline.Funcs.msg([[ "CWD set to ", "Label" ], [ "'.T.cwd.'", "Directory" ]])')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:is_special(nr)
  """Prefilter special/extra buffers."""
  let b = a:nr | let B = s:B()

  if s:is_extra(b)
    if !buflisted(b)    | call remove(s:T().buffers.extra, b)
    else                | return 1 | endif
  elseif !has_key(B, b) | return
  elseif !bufexists(b)  | unlet B[b]
  else                  | return index(s:F.wins(), b) >= 0 && has_key(s:B()[b], 'special')
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

augroup plugin-xtabline
  autocmd!

  autocmd TabNew        * call s:Do('new')
  autocmd TabEnter      * call s:Do('enter')
  autocmd TabLeave      * call s:Do('leave')
  autocmd TabClosed     * call s:Do('close')
  autocmd BufEnter      * call s:Do('bufenter')
  autocmd ColorScheme   * if s:ready() | call xtabline#hi#update_theme() | endif

  "NOTE: BufEnter needed. Timer improves reliability. Keep it like this.
  autocmd BufAdd,BufWrite,BufEnter  * call g:xtabline.Funcs.delay(100, 'xtabline#filter_buffers()')
  autocmd VimLeavePre               * call g:xtabline.Funcs.clean_up_buffer_dict()
  autocmd SessionLoadPost           * call s:Do('session')
augroup END

