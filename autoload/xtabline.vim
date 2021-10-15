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
let s:v.user_labels    = 1                      "tabline shows custom names/icons
let s:v.queued_update = 0

let s:T  = { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:eB = { -> s:T().buffers.extra     }       "extra buffers for tab
let s:pB = { -> s:X.pinned_buffers      }       "pinned buffers list
let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab

let s:invalid    = { b -> !buflisted(b) || getbufvar(b, "&buftype") != '' }
let s:is_open    = { b -> s:F.has_win(b) && getbufvar(b, "&ma") }
let s:ready      = { -> !exists('g:SessionLoad') }
let s:v.slash    = exists('+shellslash') && !&shellslash ? '\' : '/'
"}}}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Init functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#init() abort
  " Initialize the plugin. {{{1
  let s:X.Funcs = xtabline#funcs#init()
  let s:F = s:X.Funcs
  call xtabline#hi#init()
  call xtabline#maps#init()
  call xtabline#tab#check_all()
  call xtabline#filter_buffers()
  call xtabline#update()
endfun "}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Persistance
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" NOTE: if vim-obsession is installed, it is expected to be used for sessions.
" xtabline will never touch session files if obsession is present, not even in
" the case that obsession isn't handling the current session.

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" this function creates a string with the informations needed for persistance
" a custom method is implemented if vim-obsession is not detected

fun! xtabline#persistance() abort
  " {{{1
  if !get(s:Sets, 'persistance', 0) | return | endif
  let session = 'let g:xtabline = get(g:, "xtabline", {})'.
        \' | if exists("*xtabline#session_loaded")'.
        \' | let g:xtabline.Tabs = '.string(s:X.Tabs).
        \' | let g:xtabline.Buffers = '.string(s:X.Buffers).
        \' | let g:xtabline.pinned_buffers = '.string(s:X.pinned_buffers).
        \' | call xtabline#session_loaded()'.
        \' | endif'
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
  call timer_start(50, { t -> xtabline#update(1) })
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

  call xtabline#tab#check()
  call xtabline#update()
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Update tabline
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#update(...) abort
  " Set the variable that triggers tabline update. {{{1
  if !s:Sets.enabled
    return
  elseif empty(s:Sets.tabline_modes)
    set tabline=
  elseif exists('b:xtabline_override')
    let &tabline = b:xtabline_override
  else
    if a:0
      call xtabline#filter_buffers()
    endif
    let s:v.time_to_update = 1
    set tabline=%!xtabline#render#tabline()
  endif
endfun "}}}

fun! xtabline#queue_update()
  " Queue buffers refiltering, but only if not queued already. {{{1
  " A timer is used to prevent that buffers deletion in batch retriggers buffer
  " filtering every time. s:v.queued_update is set to 1 in the render script.
  if !s:v.queued_update
    let s:v.queued_update = 2
    let s:v.time_to_update = 1
    call timer_start(100, { -> execute('let s:v.queued_update = 0') })
  endif
endfun "}}}



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Filter buffers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" This function is called by (auto)commands to update the list of valid
" buffers.

fun! xtabline#filter_buffers() abort
  " Filter buffers so that only valid buffers for this tab will be shown. {{{1
  if !s:ready() | return | endif

  " Types of tab buffers:
  "
  " 'valid' is a list of buffer numbers that belong to the tab, either because:
  "     - their path is valid for this tab
  "     - tab is locked and buffers are included
  "
  " 'extra' are buffers that have been purposefully added by other means to the tab
  "     - not a dynamic list, elements are manually added or removed
  "     - they aren't handled here, they are handled at render time

  try
    let T = xtabline#tab#check()
  catch /.*/
    return
  endtry

  let T.buffers.valid = T.locked? T.buffers.valid : []
  let use_files = !empty(get(T, 'files', []))

  let tabPat = '^\V' . escape(getcwd(), '\')

  " /////////////////// ITERATE BUFFERS //////////////////////

  for buf in range(1, bufnr("$"))
    if !bufexists(buf) | continue | endif
    let B = xtabline#buffer#get(buf)

    " if special, buffer will be handled by the render script
    let is_special = s:F.has_win(buf) && s:X._buffers[buf].special

    if is_special
      continue

    elseif !buflisted(buf) || getbufvar(buf, "&buftype") != ''
      " unlisted or otherwise invalid buffer, skip it
      continue

    elseif !T.locked
      " if tab is locked, there's no filtering to do

      if !s:Sets.buffer_filtering
        " buffer filtering is disabled, accept all buffers
        let valid = v:true

      elseif use_files
        " to be accepted, buffer's path must be among valid files
        let valid = index(T.files, B.path) >= 0

      else
        " to be accepted, buffer's path must be valid for this tab
        let valid = fnamemodify(bufname(buf), ':p') =~ tabPat
      endif

      if valid
        call add(T.buffers.valid, buf)
      endif
    endif
  endfor

  " //////////////////////////////////////////////////////////

  let T.buffers.order  = s:ordered_buffers(T)
  let T.buffers.recent = s:recent_buffers(T)
  call xtabline#persistance()
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ordered and recent buffers lists
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:ordered_buffers(tab) abort
  " Ensure the tab's ordered buffers are valid. {{{1
  let B = a:tab.buffers

  "clean up ordered/recent buffers list
  call filter(B.order, 'index(B.valid, v:val) >= 0 || index(B.extra, v:val) >= 0')
  call s:F.uniq(B.extra)

  " add missing entries in ordered list
  for buf in B.valid
    call s:F.add_ordered(buf, 0)
  endfor
  return B.order
endfun "}}}

fun! s:recent_buffers(tab)
  " Update list of recent buffers for the current tab. {{{1
  let B = a:tab.buffers

  if get(s:Sets, 'recent_buffers', 10) <= 0
    return copy(B.valid)
  endif

  " if list of recent buffers is still empty, set it to current valid buffers
  if empty(B.recent)
    return copy(B.valid)
  endif
  " ensure recent buffers are valid, and all valid buffers are present
  call filter(B.recent, 'index(B.valid, v:val) >= 0')
  return extend(B.recent, filter(copy(B.valid), 'index(B.recent, v:val) < 0'))
endfun "}}}

fun! s:reorder_recent_buffers(buf)
  " Move the current buffer at the top of the recent buffers list. {{{1
  let bufs      = s:T().buffers
  let rix       = index(bufs.recent, a:buf)
  let is_recent = rix >= 0
  let is_valid  = index(bufs.valid, a:buf) >= 0

  " remove the current buffer if present, it will be inserted if valid
  if is_recent
    call remove(bufs.recent, rix)
  endif

  if is_valid
    call insert(bufs.recent, a:buf)
  endif
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

  let X = g:xtabline
  let F = X.Funcs
  let V = X.Vars
  let N = tabpagenr() - 1
  let B = bufnr(str2nr(expand('<abuf>')))

  " """""""""""""""""""""""""""""""""""""""""""""""""""""""""

  if a:action == 'new'

    call insert(X.Tabs, xtabline#tab#new(), N)

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'bufenter'

    call xtabline#buffer#update(B)

    if get(s:, 'last_dir', '') != getcwd()
      call xtabline#filter_buffers()
    else
      let X.Tabs[N].buffers.recent = s:recent_buffers(X.Tabs[N])
    endif
    call s:reorder_recent_buffers(B)

    let s:last_dir = getcwd()

    " if variable for buffer customization has been set, pick it up
    if !empty(s:v.buffer_properties)
      let s:X.Buffers[B] = extend(copy(s:X._buffers[B]), s:v.buffer_properties)
      let s:v.buffer_properties = {}
    endif

    call xtabline#update()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'bufwrite'

    call xtabline#buffer#update(B)
    call xtabline#update()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'buffilepost'

    call xtabline#buffer#reset(B)
    call xtabline#update()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'filetype'

    if xtabline#buffer#is_special(B)
      call xtabline#update()
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'enter'

    call xtabline#tab#check_all()
    call xtabline#tab#check()
    call xtabline#update(1)

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'leave'

    if N < len(X.Tabs)
      let V.last_tabn = N + 1
      let V.last_tab = X.Tabs[N]
      let V.last_tab.active_buffer = B
      let V.last_tab.wd_cmd = F.is_local_dir() ? 2 : F.is_tab_dir() ? 1 : 0
      call F.set_tab_wd()
    else
      call xtabline#tab#check_all()
      call xtabline#tab#check()
      call xtabline#update(1)
    endif

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'close'

    " add this tab to the list of closed tabs, but first remove any tab with
    " the same cwd, because the tab that we're adding is more up-to-date
    for Tx in range(len(X.closed_tabs))
      if X.closed_tabs[Tx].cwd ==# V.last_tab.cwd
        call remove(X.closed_tabs, Tx)
        break
      endif
    endfor
    call add(X.closed_tabs, deepcopy(V.last_tab))
    call remove(X.Tabs, index(X.Tabs, V.last_tab))
    call xtabline#update()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  elseif a:action == 'terminal'

    call xtabline#buffer#terminal(B)
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
  autocmd FileType      * call s:Do('filetype')
  autocmd BufEnter      * call s:Do('bufenter')
  autocmd WinEnter      * call xtabline#update()
  autocmd BufFilePost   * call s:Do('buffilepost')
  autocmd BufWritePost  * call s:Do('bufwrite')
  autocmd OptionSet     * call xtabline#update()
  autocmd CursorHold    * call xtabline#update()
  autocmd VimResized    * call xtabline#update()
  autocmd VimLeavePre   * call xtabline#update_this_session()

  autocmd BufAdd,BufDelete,BufFilePost * call xtabline#queue_update()

  if has('nvim')
    autocmd TermOpen     * call s:Do('terminal')
  else
    autocmd TerminalOpen * call s:Do('terminal')
  endif

  if exists('##DirChanged')
    autocmd DirChanged  * call xtabline#filter_buffers()
  endif

  if exists('##CmdlineLeave')
    autocmd CmdlineLeave  * call xtabline#update()
  endif

  autocmd SessionLoadPost * call s:restore_session_info()
  autocmd ColorScheme     * call xtabline#hi#update_theme()
augroup END

" vim: et sw=2 ts=2 sts=2 fdm=marker
