""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Script variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X    = g:xtabline
let s:V    = s:X.Vars
let s:F    = s:X.Funcs
let s:Sets = g:xtabline_settings

let s:V.tab_properties = {}                     "if not empty, newly created tab will inherit them
let s:V.filtering      = 1                      "whether bufline filtering is active
let s:V.show_tab_icons = 1                      "tabline shows custom names/icons
let s:V.showing_tabs   = 0                      "tabline or bufline?
let s:V.buftail        = s:Sets.relative_paths  "whether the bufline is showing basenames only
let s:V.halt           = 0                      "used to temporarily halt some functions
let s:V.auto_set_cwd   = 0                      "used to temporarily allow auto cwd detection
let s:V.special_buffers = []

let s:T  = { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:B  = { -> s:X.Buffers             }       "customized buffers
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab
let s:pB = { -> s:X.pinned_buffers      }       "pinned buffers list

let s:ready    = { -> !(exists('g:SessionLoad') || s:V.halt) }
let s:fullpath = { p -> fnamemodify(expand(p), ":p")         }
let s:is_ma    = { b -> index(tabpagebuflist(tabpagenr()), b) >= 0 && getbufvar(b, "&ma") }

let s:most_recent = -1
let s:new_tab_created = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Init functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#init()
  let s:X.Funcs = xtabline#funcs#init()
  let s:F = s:X.Funcs

  if !exists('g:xtabline_disable_keybindings')
    call xtabline#maps#init()
  endif

  if exists('g:loaded_webdevicons')
    let extensions = g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols
    let exact = g:WebDevIconsUnicodeDecorateFileNodesExactSymbols
    let patterns = g:WebDevIconsUnicodeDecorateFileNodesPatternSymbols
    let s:X.devicons = {'extensions': extensions, 'exact': exact, 'patterns': patterns}
  endif

  call s:F.check_tabs()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#update_obsession()
  let string = 'let g:xtabline.Tabs = '.string(s:X.Tabs).
        \' | let g:xtabline.Buffers = '.string(s:X.Buffers).
        \' | let g:xtabline.pinned_buffers = '.string(s:X.pinned_buffers).
        \' | call xtabline#filter_buffers()'
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

fun! xtabline#new_tab(...)
  """Create an entry in the Tabs list.
  """tab_properties can be set by a command, before this function is called.

  let p = a:0? a:1 : s:V.tab_properties

  "cwd:     (string)  working directory
  "name:    (string)  tab name
  "buffers: (dict)    with accepted and ordered buffer numbers lists
  "exclude: (list)    excluded buffer numbers
  "index:   (int)     tabpagenr() - 1, when tab is set
  "locked:  (bool)    when filtering is independent from cwd
  "depth:   (int)     filtering recursive depth (n. of directories below cwd)
  "                   0 means infinite, -1 means filtering disabled
  "vimrc:   (dict)    settings to be sourced when entering the tab
  "                   it can hold: {'file': string, 'commands': list} (one, both or empty)

  let cwd     = has_key(p, 'cwd')?     p.cwd     : getcwd()
  let name    = has_key(p, 'name')?    p.name    : ''
  let buffers = has_key(p, 'buffers')? p.buffers : {'valid': [], 'order': []}
  let exclude = has_key(p, 'exclude')? p.exclude : []
  let locked  = has_key(p, 'locked')?  p.locked  : 0
  let depth   = has_key(p, 'depth')?   p.depth   : 0
  let vimrc   = has_key(p, 'vimrc')?   p.vimrc   : {}

  let s:V.tab_properties = {}

  return {'name':    name,       'cwd':     cwd,
        \ 'buffers': buffers,    'exclude': exclude,
        \ 'locked':  locked,     'depth':   depth,
        \ 'vimrc':   vimrc}
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#filter_buffers(...)
  """Filter buffers so that only the ones within the tab's cwd will show up.
  let T = s:T() | let can_show_tabs = s:V.showing_tabs && has_key(T, 'init')

  " 'accepted' is a list of buffer numbers, for quick access.
  " 'excludes' is a list of paths, it will be used by Airline to hide buffers."""

  if !s:ready()        | return
  elseif can_show_tabs | set tabline=%!xtabline#render#tabs()
    return
  endif

  let locked          = T.locked
  let accepted        = locked? T.buffers.valid   : []
  let excluded        = locked? T.exclude : []
  let depth           = T.depth
  let cwd             = getcwd()
  let _pre            = s:Sets.exact_paths? '^' : ''
  let post_           = s:F.sep()
  let nofilter        = T.depth < 0 || !s:V.filtering

  for buf in range(1, bufnr("$"))

    if s:F.invalid_buffer(buf)  | continue
    elseif s:is_ma(buf)         | call add(accepted, buf) | continue
    elseif nofilter             | call add(accepted, buf) | continue | endif

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

    let tab = !empty(V.tab_properties)? V.tab_properties : {'cwd': '~'}
    call insert(X.Tabs, xtabline#new_tab(tab), N)
    if V.auto_set_cwd && s:ready()
      let s:new_tab_created = 1
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'bufenter'
    if s:new_tab_created && V.auto_set_cwd && s:ready()
      call s:set_new_tab_cwd(N)
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'bufdelete'
    " call F.delay(100, 'g:xtabline.Funcs.clean_up_buffer_dict('.a:1.')')

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

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'leave'

    call F.clean_up_buffer_dict()
    let V.last_tab = N
    let X.Tabs[N].cwd = getcwd()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'close'

    if index(X.closed_cwds, X.Tabs[V.last_tab].cwd) < 0
      call add(X.closed_tabs, copy(X.Tabs[V.last_tab]))
      call add(X.closed_cwds, X.Tabs[V.last_tab].cwd)
    endif
    call remove(X.Tabs, V.last_tab)
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:set_new_tab_cwd(N)
  """Find suitable cwd for the new tab."""
  let s:new_tab_created = 0 | let T = s:X.Tabs[a:N]

  " empty tab sets cwd to ~, non-empty tab looks for a .git dir
  if empty(bufname("%"))
    let T.cwd = s:fullpath('~')
  elseif T.cwd == '~' || s:fullpath("%") !~ s:fullpath(T.cwd)
    let T.cwd = s:F.find_suitable_cwd()
  endif
  cd `=T.cwd`
  call xtabline#filter_buffers()
  call s:F.delay(200, 'g:xtabline.Funcs.msg([[ "CWD set to ", "Label" ], [ "'.T.cwd.'", "Directory" ]])')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

augroup plugin-xtabline
  autocmd!

  autocmd TabNew    * call s:Do('new')
  autocmd TabEnter  * call s:Do('enter')
  autocmd TabLeave  * call s:Do('leave')
  autocmd TabClosed * call s:Do('close')
  autocmd BufEnter  * call s:Do('bufenter')
  autocmd BufDelete * call s:Do('bufdelete', expand("<abuf>"))

  "NOTE: BufEnter needed. Timer improves reliability. Keep it like this.
  autocmd BufAdd,BufWrite,BufEnter  * call g:xtabline.Funcs.delay(100, 'xtabline#filter_buffers()')
  autocmd QuitPre                   * call xtabline#update_obsession()
  autocmd SessionLoadPost           * let cwd = g:xtabline.Tabs[tabpagenr()-1].cwd | cd `=cwd` | doautocmd BufAdd
augroup END

