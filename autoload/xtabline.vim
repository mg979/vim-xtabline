""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Script variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X = g:xtabline
let s:V = s:X.Vars
let s:V.tab_properties = {}
let s:V.filtering = 1
let s:V.showing_tabs = 0
let s:V.buftail = 0
let s:Sets = g:xtabline_settings

let s:T =  { -> s:X.Tabs[tabpagenr()-1]               }
let s:B =  { -> s:X.Tabs[tabpagenr()-1].buffers       }
let s:vB = { -> s:X.Tabs[tabpagenr()-1].buffers.valid }
let s:oB = { -> s:X.Tabs[tabpagenr()-1].buffers.order }

let s:most_recent = -1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Main functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#new_tab(...)
  """Create an entry in the Tabs list.
  """tab_properties can be set by a command, before this function is called.

  let p = a:0? a:1 : s:V.tab_properties

  "cwd:     (string)  working directory
  "name:    (string)  tab name
  "buffers: (list)    accepted buffer numbers
  "exclude: (list)    excluded buffer numbers
  "index:   (int)     tabpagenr() - 1, when tab is set
  "locked:  (bool)    when filtering is independent from cwd
  "depth:   (int)     filtering recursive depth (n. of directories below cwd)
  "                   0 means infinite
  "vimrc:   (dict)    settings to be sourced when entering the tab
  "                   it can hold: {'file': string, 'commands': list} (one, both or empty)

  let cwd     = has_key(p, 'cwd')?     p.cwd     : getcwd()
  " let name    = has_key(p, 'name')?    p.name    : fnamemodify(expand(cwd), ':t:r')
  let name    = has_key(p, 'name')?    p.name    : ''
  let buffers = has_key(p, 'buffers')? p.buffers : {'valid': [], 'order': []}
  let exclude = has_key(p, 'exclude')? p.exclude : []
  let locked  = has_key(p, 'locked')?  p.locked  : 0
  let depth   = has_key(p, 'depth')?   p.depth   : 0
  let vimrc   = has_key(p, 'vimrc')?   p.vimrc   : {}

  let s:V.tab_properties = {}

  return {'name':    name,       'cwd':     cwd,
        \ 'buffers': buffers,    'exclude': exclude,
        \ 'vimrc':   vimrc,      'index':   tabpagenr()-1,
        \ 'locked':  locked,     'depth':   depth}
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#filter_buffers(...)
  """Filter buffers so that only the ones within the tab's cwd will show up.

  " 'accepted' is a list of buffer numbers, for quick access.
  " 'excludes' is a list of paths, it will be used by Airline to hide buffers."""

  if empty(g:xtabline) || exists('g:SessionLoad') | return
  elseif s:V.showing_tabs | set tabline=%!xtabline#render#tabs()
    return
  endif

  let T = s:T()

  let locked          = T.locked
  let accepted        = locked? T.buffers.valid   : []
  let excluded        = locked? T.exclude : []
  let depth           = T.depth
  let cwd             = getcwd()
  let exact           = s:Sets.include_previews? '' : '^'

  for buf in range(1, bufnr("$"))

    if s:F.invalid_buffer(buf)             | continue
    elseif T.depth < 0 || !s:V.filtering   | call add(accepted, buf) | continue | endif

    " get the path
    let path = expand("#".buf.":p")

    " accept or exclude buffer
    if locked && index(accepted, buf) < 0
      call add(excluded, buf)

    elseif path =~ exact.cwd && s:F.within_depth(path, depth)
      call add(accepted, buf)

    else
      call add(excluded, buf)
    endif
  endfor

  let T.buffers.valid = accepted
  let T.exclude  = excluded
  call s:F.update_buffers()
  call s:F.refresh_tabline()
  call xtabline#update_obsession()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#next_buffer(nr)
  """Switch to next visible buffer."""

  if ( s:F.not_enough_buffers() || !s:V.filtering ) | return | endif
  let accepted = s:vB()

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

fun! xtabline#prev_buffer(nr)
  """Switch to previous visible buffer."""

  if ( s:F.not_enough_buffers() || !s:V.filtering ) | return | endif
  let accepted = s:vB()

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

fun! xtabline#select_buffer(nr)
  """Switch to visible buffer in the tabline with [count]."""

  if ( a:nr == 0 || !s:V.filtering ) | execute s:Sets.alt_action | return | endif
  let accepted = s:vB()

  if (a:nr > len(accepted)) || s:F.not_enough_buffers() || accepted[a:nr - 1] == bufnr("%")
    return
  else
    let g:xtabline.Vars.changing_buffer = 1
    execute "buffer ".accepted[a:nr - 1]
  endif
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Init functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#init()
  let s:X.Funcs = xtabline#funcs#init()
  let s:F = s:X.Funcs

  if !exists('g:xtabline_disable_keybindings')
    call xtabline#maps#init()
  endif

  call s:F.check_tabs()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#update_obsession()
  let string = 'let g:xtabline.Tabs = '.string(s:X.Tabs).' | call xtabline#update_obsession()'
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
" Autocommand Functions
" Inspired by TabPageCd
" Copyright (C) 2012-2013 Kana Natsuno <http://whileimautomaton.net/>
" License: MIT License
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Do(action)
  if empty(g:xtabline.Tabs) | return | endif

  let X = g:xtabline | let F = X.Funcs | let V = X.Vars
  let N = tabpagenr() - 1

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  if a:action == 'new'

    call insert(X.Tabs, xtabline#new_tab({'cwd': '~'}), N)
    call F.check_tabs()
    call xtabline#filter_buffers()

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
    call xtabline#filter_buffers()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'leave'

    let V.last_tab = N
    let X.Tabs[N].cwd = getcwd()
    call xtabline#update_obsession()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'close'

    let V.most_recently_closed_tab = copy(X.Tabs[V.last_tab])
    call remove(X.Tabs, V.last_tab)
    call xtabline#update_obsession()
  endif
endfunction

augroup plugin-xtabline
  autocmd!

  autocmd TabNew    * call s:Do('new')
  autocmd TabEnter  * call s:Do('enter')
  autocmd TabLeave  * call s:Do('leave')
  autocmd TabClosed * call s:Do('close')
  autocmd BufEnter  * let g:xtabline.Vars.changing_buffer = 0

  autocmd BufAdd,BufDelete,BufWrite,BufEnter  * call timer_start(200, 'xtabline#filter_buffers')
  autocmd QuitPre  * call xtabline#update_obsession()
  autocmd SessionLoadPost  * let cwd = g:xtabline.Tabs[tabpagenr()-1].cwd | cd `=cwd` | doautocmd BufAdd
augroup END

