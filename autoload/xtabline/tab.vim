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

fun s:template()
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
        \ 'index':   tabpagenr()-1,
        \ 'buffers': {'valid': [], 'order': [], 'extra': []},
        \}
endfun

fun! xtabline#tab#new(...)
  """Create an entry in the Tabs list.
  "tab_properties can be set by a command, before this function is called.

  let tab = extend(s:template(), s:v.tab_properties)
  call extend(tab, a:0 ? a:1 : {})
  let s:v.tab_properties = {} "reset tab_properties
  call xtabline#tab#update_git_files(tab)
  return tab
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

fun! xtabline#tab#update_git_files(tab)
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

