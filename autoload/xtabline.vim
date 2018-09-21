""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Script variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X    = g:xtabline
let s:v    = s:X.Vars
let s:F    = s:X.Funcs
let s:Sets = g:xtabline_settings

let s:v.tab_properties = {}                     "if not empty, newly created tab will inherit them
let s:v.buffer_properties = {}                  "if not empty, newly created tab will inherit them
let s:v.filtering      = 1                      "whether bufline filtering is active
let s:v.custom_tabs    = 1                      "tabline shows custom names/icons
let s:v.showing_tabs   = 0                      "tabline or bufline?
let s:v.halt           = 0                      "used to temporarily halt some functions
let s:v.auto_set_cwd   = 0                      "used to temporarily allow auto cwd detection

let s:T  = { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:B  = { -> s:X.Buffers             }       "customized buffers
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:eB = { -> s:T().buffers.extra     }       "extra buffers for tab
let s:fB = { -> s:T().buffers.front     }       "front buffers for tab
let s:pB = { -> s:X.pinned_buffers      }       "pinned buffers list
let s:oB = { -> s:F.buffers_order()     }       "ordered buffers for tab

let s:invalid    = { b -> !buflisted(b) || getbufvar(b, "&buftype") == 'quickfix' }
let s:is_extra   = { b -> s:B()[b].extra }
let s:is_front   = { b -> s:B()[b].front && index(s:fB(), b) < 0}
let s:is_special = { b -> s:F.has_win(b) && s:B()[b].special }
let s:is_open    = { b -> s:F.has_win(b) && getbufvar(b, "&ma") }
let s:ready      = { -> !(exists('g:SessionLoad') || s:v.halt) }

let s:most_recent = -1
let s:new_tab_created = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Init functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#init()
  set showtabline=2
  let s:X.Funcs = xtabline#funcs#init()
  let s:X.Props = xtabline#props#init()
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

  call s:X.Props.check_tabs()
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
" Filter buffers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#filter_buffers(...)
  """Filter buffers so that only the ones within the tab's cwd will show up.
  if !s:ready() && !(a:0 && a:1 == 1) | return | endif

  " 'accepted' is a list of buffer numbers that belong to the tab, either because:
  "     - within filtering working directory
  "     - tab is locked and buffers are included
  " 'excluded' is a list of buffer numbers, it will be used by Airline to hide buffers.
  " 'extra' are buffers that have been purposefully added by other means to the tab
  "     - not a dynamic list, elements are manually added or removed
  " 'front' are either:
  "     - pinned buffers
  "     - modfiable buffers in a tab window, even if they don't belong to the tab

  call s:X.Props.check_tabs()
  call s:X.Props.check_this_tab()
  let T = s:T()

  if s:v.showing_tabs && has_key(T, 'init')
    set tabline=%!xtabline#render#tabs()
    return
  endif

  let locked          = T.locked
  let accepted        = locked? T.buffers.valid   : []
  let excluded        = locked? T.exclude : []
  let depth           = T.depth
  let extra           = T.buffers.extra
  let front           = T.buffers.front

  " /////////////////// ITERATE BUFFERS //////////////////////

  for buf in range(1, bufnr("$"))
    let B = s:X.Props.update_buffer(buf)

    if s:is_special(buf)        | call add(accepted, buf)
    elseif s:invalid(buf)
      if index(excluded, buf) < 0
        call add(excluded, buf)
      endif
    elseif !s:v.filtering       | call add(accepted, buf)
    elseif s:is_extra(buf)      | continue
    else
      " accept or exclude buffer
      if locked
        if index(accepted, buf) < 0 && index(excluded, buf) < 0
          call add(excluded, buf)
        endif

      elseif s:F.within_depth(B.path, depth) && B.path =~ '^'.T['use_dir']
        call add(accepted, buf)

      elseif s:is_front(buf)
        call add(front, buf)

      elseif index(excluded, buf) < 0
        call add(excluded, buf)
      endif
    endif
  endfor

  " //////////////////////////////////////////////////////////

  let T.buffers.valid = accepted
  let T.exclude       = excluded
  call s:update_buffers()
  call s:F.refresh_tabline()
  call xtabline#update_obsession()
  if a:0 && a:1 == 2
    return xtabline#render#buffers()
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:update_buffers()
  let B = s:B()
  let valid = s:vB()
  let order = s:F.buffers_order()

  "clean up ordered/front buffers list
  call filter(order, 'index(valid, v:val) >= 0 || s:is_extra(v:val)')
  call filter(s:fB(), 's:B()[v:val].front')

  " add missing entries in ordered list
  for buf in valid
    if index(order, buf) < 0
      call add(order, buf)
    endif
  endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Select buffers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:set_new_tab_cwd(N)
  """Find suitable cwd for the new tab. Only runs after XT commands."""
  let s:new_tab_created = 0 | let T = s:X.Tabs[a:N]

  " empty tab sets cwd to ~, non-empty tab looks for a .git dir
  if empty(bufname("%"))
    let T.cwd = s:F.fullpath(getcwd())
  elseif T.cwd == '~' || s:F.fullpath("%") !~ s:F.fullpath(T.cwd)
    let T.cwd = s:F.find_suitable_cwd()
  endif
  cd `=T.cwd`
  call s:F.force_update()
  call s:F.delay(200, 'g:xtabline.Funcs.msg([[ "CWD set to ", "Label" ], [ "'.T.cwd.'", "Directory" ]])')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:set_buf_props()
  if !empty(s:v.buffer_properties)
    call extend(s:X.Buffers[expand('<abuf>')], s:v.buffer_properties)
    let s:v.buffer_properties = {}
  endif
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

    call insert(X.Tabs, s:X.Props.new_tab(), N)
    if V.auto_set_cwd && s:ready()
      let s:new_tab_created = 1
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'bufenter'
    if s:new_tab_created
      call s:set_new_tab_cwd(N)
    endif
    call s:X.Props.update_buffer(bufnr("%"))

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'enter'

    call s:X.Props.check_tabs()
    call s:X.Props.check_this_tab()
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

    if s:F.airline_enabled() || get(s:Sets, 'refresh_on_tabenter', 0)
      call xtabline#filter_buffers()
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'leave'

    let V.last_tab = N
    let X.Tabs[N].cwd = F.fullpath(getcwd())

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
    let cwd = X.Tabs[N].cwd | cd `=cwd`
    call xtabline#filter_buffers()
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

augroup plugin-xtabline
  autocmd!

  autocmd TabNew        * call s:Do('new')
  autocmd TabEnter      * call s:Do('enter')
  autocmd TabLeave      * call s:Do('leave')
  autocmd TabClosed     * call s:Do('close')
  autocmd BufEnter      * call s:Do('bufenter')
  autocmd ColorScheme   * if s:ready() | call xtabline#hi#update_theme() | endif
  autocmd BufWinEnter   * call s:set_buf_props()
  autocmd BufAdd        * call s:set_buf_props()

  "NOTE: BufEnter needed. Timer improves reliability. Keep it like this.
  autocmd BufAdd,BufWrite,BufEnter,BufDelete    * call g:xtabline.Funcs.delay(50, 'xtabline#filter_buffers()')
  autocmd VimLeavePre                 * call g:xtabline.Funcs.clean_up_buffer_dict()
  autocmd SessionLoadPost             * call s:Do('session')
  autocmd BufNewFile                  * call xtabline#automkdir#ensure_dir_exists()
augroup END

