"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Main script: buffer filtering, persistance, autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Script variables and lambdas {{{1
let s:X    = g:xtabline
let s:v    = s:X.Vars
let s:F    = s:X.Funcs
let s:Sets = g:xtabline_settings

let s:v.tab_properties = {}                     "if not empty, newly created tab will inherit them
let s:v.buffer_properties = {}                  "if not empty, newly created tab will inherit them
let s:v.custom_tabs    = 1                      "tabline shows custom names/icons
let s:v.halt           = 0                      "used to temporarily halt some functions

let s:T  = { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:B  = { -> s:X.Buffers             }       "customized buffers
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:eB = { -> s:T().buffers.extra     }       "extra buffers for tab
let s:pB = { -> s:X.pinned_buffers      }       "pinned buffers list
let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab
let s:rB = { -> s:T().buffers.recent    }       "recent buffers for tab

let s:invalid    = { b -> !buflisted(b) || getbufvar(b, "&buftype") == 'quickfix' }
let s:is_special = { b -> s:F.has_win(b) && s:B()[b].special }
let s:is_open    = { b -> s:F.has_win(b) && getbufvar(b, "&ma") }
let s:ready      = { -> !(exists('g:SessionLoad') || s:v.halt) }
let s:v.slash    = exists('+shellslash') && !&shellslash ? '\' : '/'
"}}}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Init functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#init() abort
  " Initialize the plugin. {{{1
  set showtabline=2
  let s:X.Funcs = xtabline#funcs#init()
  let s:F = s:X.Funcs
  call xtabline#maps#init()
  call xtabline#tab#check_all()
  call xtabline#update()
endfun "}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Persistance
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" NOTE: if vim-obsession is installed, it is expected to be used for sessions.
" xtabline will never touch session files if obsession is present, not even in
" the case that obsession isn't handling the current session.
" This may change in the future but I couldn't get them to work well together.

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" this function creates a string with the informations needed for persistance
" a custom method is implemented if vim-obsession is not detected

fun! xtabline#persistance() abort
  " {{{1
  if !get(s:Sets, 'persistance', 1) | return | endif
  let session = 'let g:xtabline = get(g:, "xtabline", {})'.
        \' | try | let g:xtabline.Tabs = '.string(s:X.Tabs).
        \' | let g:xtabline.Buffers = '.string(s:X.Buffers).
        \' | let g:xtabline.pinned_buffers = '.string(s:X.pinned_buffers).
        \' | call xtabline#session_loaded()'.
        \' | catch | endtry'
  if exists('g:loaded_obsession')
    if !exists('g:obsession_append')
      let g:obsession_append = [session]
    else
      for i in g:obsession_append
        if match(i, "^let g:xtabline") >= 0
          call remove(g:obsession_append, i)
          break
        endif
      endfor
      call add(g:obsession_append, session)
    endif
  else
    let g:Xtsession = session
  endif
endfun "}}}

" update session file, if obsession isn't loaded
" add the g:Xtsession variable even if 'globals' not in &sessionoptions
" code derived from vim-obsession

fun! xtabline#update_this_session() abort
  " {{{1
  if v:this_session != "" && !exists('g:loaded_obsession') && exists('g:Xtsession')
    exe 'mksession!' v:this_session
    if &sessionoptions !~ 'globals'
      let body = readfile(v:this_session)
      for line in range(len(body))
        if match(body[line], '^let g:Xtsession') == 0
          let body[line] = 'let g:Xtsession = '.string(g:Xtsession)
          return writefile(body, v:this_session)
        endif
      endfor
      call insert(body, 'let g:Xtsession = '.string(g:Xtsession), 3)
      call writefile(body, v:this_session)
    endif
  endif
endfun "}}}

" called on SessionLoadPost, it will restore non-obsession data if it has been
" stored in the session file; the variable is cleared as soon as it's used, it
" will be regenerated if obsession isn't loaded
" if no data has been stored (pre-xtabline session), just run session_loaded()
" to ensure xtabline data is generated

fun! s:restore_session_info() abort
  " {{{1
  if exists('g:Xtsession')
    exe g:Xtsession
    unlet g:Xtsession
  elseif !exists('g:this_obsession')
    call xtabline#session_loaded()
  endif
endfun "}}}

" called directly from inside the session file (if using obsession), or when
" restoring session info in the function above; it ensures that data is
" consistent with the actual running session, cleaning up invalid data

fun! xtabline#session_loaded() abort
  " {{{1
  for i in range(len(s:X.Tabs))
    let s:X.Tabs[i] = extend(xtabline#tab#new(), s:X.Tabs[i])
  endfor
  call xtabline#tab#check_all()
  for buf in s:X.pinned_buffers
    let i = index(s:X.pinned_buffers, buf)
    if s:invalid(buf)
      call remove(s:X.pinned_buffers, i)
    endif
  endfor
  for buf in keys(s:X.Buffers) " restored buffers may be mismatched
    if s:invalid(buf) || s:X.Buffers[buf].path != s:F.fullpath(buf)
      unlet s:X.Buffers[buf]
    endif
  endfor

  let s:v.force_update = 1
  call xtabline#tab#check()
  call xtabline#update()
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Update tabline
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#refresh() abort
  " Perform a full tabline refresh. This should only be called manually. {{{1
  for buf in range(1, bufnr("$"))
    if s:existing(buf) | continue | endif
    call xtabline#buffer#update(buf)
  endfor
  call xtabline#update()
endfun "}}}

fun! xtabline#update(...) abort
  " Set the variable that triggers tabline update. {{{1
  if !s:Sets.enabled || ( exists('b:no_xtabline') && b:no_xtabline )
    return
  elseif empty(s:Sets.tabline_modes)
    set tabline=
  else
    let s:v.time_to_update = 1
    set tabline=%!xtabline#render#tabline()
  endif
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Filter buffers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" This function is called in the render script, every time the tabline is
" updated. It won't always run, though: xtabline#update() will set the flag

fun! xtabline#filter_buffers(...) abort
  " Filter buffers so that only valid buffers for this tab will be shown. {{{1

  if      exists('s:v.force_update')          | unlet s:v.force_update
  elseif  !s:ready()                          | return
  endif

  " Types of tab buffers:
  "
  " 'valid' is a list of buffer numbers that belong to the tab, either because:
  "     - their path is valid for this tab
  "     - tab is locked and buffers are included
  "
  " 'extra' are buffers that have been purposefully added by other means to the tab
  "     - not a dynamic list, elements are manually added or removed
  "     - they aren't handled here, they are handled at render time

  let T = xtabline#tab#check()

  let T.buffers.valid = T.locked? T.buffers.valid : []
  let use_files = !empty(get(T, 'files', []))

  " /////////////////// ITERATE BUFFERS //////////////////////

  for buf in range(1, bufnr("$"))
    if !bufexists(buf) | continue | endif
    let B = xtabline#buffer#get(buf)

    " if special, buffer will be handled by the render script
    " if tab is locked, there's no filtering to do

    if s:is_special(buf)   | continue
    elseif s:invalid(buf)  | continue
    elseif !T.locked

      if !s:Sets.buffer_filtering
        " buffer filtering is disabled, accept all buffers
        let valid = 1

      elseif use_files
        " to be accepted, buffer's path must be among valid files
        let valid = index(T.files, B.path) >= 0

      else
        " to be accepted, buffer's path must be valid for this tab
        let valid = B.path =~ '^' . ( has_key(T, 'dir') ? T.dir : T.cwd )
      endif

      if valid
        call add(T.buffers.valid, buf)
        if index(T.buffers.recent, buf) < 0
          call add(T.buffers.recent, buf)
        endif
      endif
    endif
  endfor

  " //////////////////////////////////////////////////////////

  call s:ordered_buffers()
  call xtabline#persistance()
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:ordered_buffers() abort
  " Ensure the tab's buffers lists are valid. {{{1
  let B = s:T().buffers

  " if list of recent buffers is still empty, set it to current valid buffers
  if empty(B.recent)
    let B.recent = copy(B.valid)
  endif

  "clean up ordered/recent buffers list
  call filter(B.order, 'index(B.valid, v:val) >= 0 || index(B.extra, v:val) >= 0')
  call filter(B.recent, 'index(B.valid, v:val) >= 0')
  " call s:F.uniq(B.order)
  call s:F.uniq(B.extra)

  " add missing entries in ordered list
  for buf in B.valid
    call s:F.add_ordered(buf)
  endfor
endfun "}}}

fun! s:existing(buf) abort
  " Check if buffer exists, clean up the buffers dict if not. {{{1
  if bufexists(a:buf)            | return 1                 | endif
  if has_key(s:X.Buffers, a:buf) | unlet s:X.Buffers[a:buf] | endif
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommand Functions
" Inspired by TabPageCd
" Copyright (C) 2012-2013 Kana Natsuno <http://whileimautomaton.net/>
" License: MIT License
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Do(action, ...)
  " Called by several autocommands. {{{1
  if exists('g:SessionLoad') || empty(g:xtabline.Tabs) | return | endif

  let X = g:xtabline | let F = X.Funcs | let V = X.Vars
  let N = tabpagenr() - 1
  let B = bufnr(str2nr(expand('<abuf>')))

  " """""""""""""""""""""""""""""""""""""""""""""""""""""""""

  if a:action == 'new'

    call insert(X.Tabs, xtabline#tab#new(), N)

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'bufenter'

    call xtabline#buffer#add(B)
    call xtabline#tab#recent_buffers(B)
    call xtabline#update()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'bufwrite'

    call xtabline#buffer#update(B)
    call xtabline#update()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'enter'

    call xtabline#tab#check_all()
    call xtabline#tab#check()
    call xtabline#update()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'leave'

    let V.last_tab = X.Tabs[N]
    let V.last_tab_buf = B
    call F.set_tab_wd()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'close'

    let closed_tab = copy(V.last_tab)
    let closed_tab.active_buffer = V.last_tab_buf
    call add(X.closed_tabs, closed_tab)
    call remove(X.Tabs, index(X.Tabs, V.last_tab))
    call xtabline#update()

  endif
endfunction "}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

augroup plugin-xtabline
  autocmd!

  autocmd TabNew        * call s:Do('new')
  autocmd TabEnter      * call s:Do('enter')
  autocmd TabLeave      * call s:Do('leave')
  autocmd TabClosed     * call s:Do('close')
  autocmd BufEnter      * call s:Do('bufenter')
  autocmd BufWritePost  * call s:Do('bufwrite')
  autocmd BufDelete     * call xtabline#update()
  autocmd VimLeavePre   * call xtabline#update_this_session()

  autocmd SessionLoadPost * call s:restore_session_info()
  autocmd ColorScheme   * if s:ready() | call xtabline#hi#update_theme() | endif
augroup END

" vim: et sw=2 ts=2 sts=2 fdm=marker
