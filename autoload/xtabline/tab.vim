" Initialize tab object

let s:F = g:xtabline.Funcs
let s:v = g:xtabline.Vars
let s:Sets = g:xtabline_settings
let s:T = { -> g:xtabline.Tabs[tabpagenr()-1] } "current tab

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"name:    (string)  tab name
"cwd:     (string)  working directory
"dirs:    (list)    list of accepted directories (for filtering, default [cwd])
"files:   (list)    restrict valid files to this list (for filtering, default [])
"buffers: (dict)    with accepted and ordered buffer numbers lists
"index:   (int)     tabpagenr() - 1, when tab is set
"locked:  (bool)    when filtering is independent from cwd
"rpaths:  (int)     whether the bufferline shows relative paths or filenames
"depth:   (int)     filtering recursive depth (n. of directories below cwd)
"                   -1 means full cwd, 0 means root dir only, >0 means up to n subdirs
"vimrc:   (dict)    settings to be sourced when entering/leaving the tab
"is_git:  (bool)    if the tab must respect git tracked files when filtering

fun! s:template()
  return {
        \ 'name':    '',
        \ 'cwd':     s:F.fullpath(getcwd()),
        \ 'dirs':    [s:F.fullpath(getcwd())],
        \ 'locked':  0,
        \ 'depth':   -1,
        \ 'vimrc':   get(s:Sets, 'use_tab_vimrc', 0) ? xtabline#vimrc#init() : {},
        \ 'rpaths':  0,
        \ 'icon':    '',
        \ 'files':   [],
        \ 'buffers': {'valid': [], 'order': [], 'extra': [], 'recent': []},
        \}
endfun

fun! xtabline#tab#new(...)
  """Create an entry in the Tabs list.
  " tab_properties can be set by a command, before this function is called.

  let tab = extend(s:template(), s:v.tab_properties)
  call extend(tab, a:0 ? a:1 : {})
  let s:v.tab_properties = {} "reset tab_properties
  call xtabline#tab#git_files(tab)
  return tab
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#tab#recent_buffers(buf)
  """Keep the valid buffers ordered by recency of access.
  let bufs = s:T().buffers
  let r = index(bufs.recent, a:buf)

  " update recent list
  if len(bufs.recent) != len(bufs.valid)
    for b in bufs.valid
      if index(bufs.recent, b) < 0
        call add(bufs.recent, b)
      endif
    endfor
  endif

  if index(bufs.valid, a:buf) >= 0
    call insert(bufs.recent, r >= 0 ? remove(bufs.recent, r) : a:buf)
  elseif r >= 0
    call remove(bufs.recent, r)
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#tab#lock(bufs, ...)
  """Lock tab with predefined buffers and properties.
  let T = g:xtabline.Tabs[tabpagenr()-1]
  let T.locked = 1
  let T.buffers.valid = a:bufs
  call extend(T, a:0 ? a:1 : {})
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#tab#check() abort
  """Ensure all tab dict keys are present.
  call extend(s:T(), s:template(), 'keep')
  if !has_key(t:, 'xtab')
    let t:xtab = s:T()
  endif

  " ensure 'recent' key is present
  let bufs = extend(s:T().buffers, {'recent': []}, 'keep')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#tab#check_index() abort
  """Ensure g:xtabline.Tabs[tabpagenr()-1] matches t:xtab.
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
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#tab#check_all()
  """Create or remove tab dicts if necessary.
  let Tabs = g:xtabline.Tabs
  while len(Tabs) < tabpagenr("$") | call add(Tabs, xtabline#tab#new()) | endwhile
  while len(Tabs) > tabpagenr('$') | call remove(Tabs, -1)              | endwhile
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#tab#git_files(tab)
  """Update tracked files if tab cwd is a repo, or disable tracking.
  let T = a:tab
  if T.locked | return | endif

  " initialize T.is_git if not present, based on use_git setting
  let T.is_git = get(T, 'is_git', s:Sets.use_git && s:F.is_repo(T))

  " reset git files, if cwd is a repo, the list will be fetched again
  let T.git_files = []

  if T.is_git && s:F.is_repo(T)
    " it's a repo, so fetch the tracked files list
    let T.git_files = systemlist('git --git-dir='. T.cwd . s:v.slash .'/.git ls-files')

  elseif T.is_git
    " not a repo and is_git is set, reset it
    let T.is_git = 0
  endif
endfun

