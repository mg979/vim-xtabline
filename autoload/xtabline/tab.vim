"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize tab object
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Script variables and lambdas {{{1
let s:F = g:xtabline.Funcs
let s:v = g:xtabline.Vars
let s:Sets = g:xtabline_settings
let s:T = { -> g:xtabline.Tabs[tabpagenr()-1] } "current tab

" }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Template
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"name:    (string)  tab name
"cwd:     (string)  working directory
"files:   (list)    restrict valid files to this list (for filtering, default [])
"buffers: (dict)    with accepted and ordered buffer numbers lists
"index:   (int)     tabpagenr() - 1, when tab is set
"locked:  (bool)    when filtering is independent from cwd
"rpaths:  (int)     whether the bufferline shows relative paths or filenames

fun! s:template() abort
  " {{{1
    return {
          \ 'name':    '',
          \ 'cwd':     s:F.fullpath(getcwd()),
          \ 'locked':  0,
          \ 'rpaths':  s:Sets.relative_paths,
          \ 'icon':    '',
          \ 'files':   [],
          \ 'buffers': {'valid': [], 'order': [], 'extra': [], 'recent': []},
          \}
  endfun " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#tab#new(...) abort
  " Create an entry in the Tabs list. {{{1
  " tab_properties can be set by a command, before this function is called.

  let tab = extend(s:template(), s:v.tab_properties)
  call extend(tab, a:0 ? a:1 : {})
  let s:v.tab_properties = {} "reset tab_properties
  return tab
endfun "}}}

fun! xtabline#tab#recent_buffers(buf) abort
  " Update the recent buffers list. {{{1
  let bufs = s:T().buffers
  let r = index(bufs.recent, a:buf)

  let [ is_recent, is_valid ] = [ r >= 0, index(bufs.valid, a:buf) >= 0 ]

  " remove the current buffer if present, it will be inserted if valid
  if is_recent
    call remove(bufs.recent, r)
  endif

  if is_valid
    call insert(bufs.recent, a:buf)
  endif
endfun "}}}

fun! xtabline#tab#lock(bufs, ...) abort
  " Lock tab with predefined buffers and properties. {{{1
  let T = g:xtabline.Tabs[tabpagenr()-1]
  let T.locked = 1
  let T.buffers.valid = a:bufs
  call extend(T, a:0 ? a:1 : {})
endfun "}}}

fun! xtabline#tab#check() abort
  " Ensure all tab dict keys are present. {{{1
  let Tab = s:T()
  call extend(Tab, s:template(), 'keep')
  if !has_key(t:, 'xtab')
    let t:xtab = Tab
  endif

  " ensure 'recent' key is present
  let bufs = extend(Tab.buffers, {'recent': []}, 'keep')
  return Tab
endfun "}}}

fun! xtabline#tab#check_index() abort
  " Ensure g:xtabline.Tabs[tabpagenr()-1] matches t:xtab. {{{1
  if !has_key(t:, 'xtab') | return | endif

  " t:xtab is generally the same dictionary as g:xtabline.Tabs[tabpagenr()-1]
  " but if a tab is moved with :tabmove, they will be mismatched
  " this is checked at every tabline refresh, to ensure the correct order

  let XT = g:xtabline.Tabs
  if t:xtab isnot s:T() && index(XT, t:xtab) >= 0
    let old_position = index(XT, t:xtab)
    let new_position = tabpagenr()-1
    call insert(XT, remove(XT, old_position), new_position)
    let s:v.time_to_update = 1
  endif
endfun "}}}

fun! xtabline#tab#check_all() abort
  " Create or remove tab dicts if necessary. {{{1
  let Tabs = g:xtabline.Tabs
  while len(Tabs) < tabpagenr("$") | call add(Tabs, xtabline#tab#new()) | endwhile
  while len(Tabs) > tabpagenr('$') | call remove(Tabs, -1)              | endwhile
  if !has_key(s:v, 'last_tab')
    let s:v.last_tab = s:T()
  endif
endfun "}}}

" vim: et sw=2 ts=2 sts=2 fdm=marker
