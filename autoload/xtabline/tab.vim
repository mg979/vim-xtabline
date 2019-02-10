" Initialize tab object

let s:F = g:xtabline.Funcs
let s:v = g:xtabline.Vars
let s:Sets = g:xtabline_settings

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#tab#new(...)
  """Create an entry in the Tabs list.
  """tab_properties can be set by a command, before this function is called.

  let tab = deepcopy(s:Tab)
  call extend(tab, s:v.tab_properties)
  call extend(tab, a:0 ? a:1 : {})
  let s:v.tab_properties = {} "reset tab_properties
  return tab
endfun

"name:    (string)  tab name
"cwd:     (string)  working directory
"dirs:    (list)    list of accepted directories (for buffer filtering purposes)
"buffers: (dict)    with accepted and ordered buffer numbers lists
"index:   (int)     tabpagenr() - 1, when tab is set
"locked:  (bool)    when filtering is independent from cwd
"rpaths:  (int)     whether the bufferline shows relative paths or filenames
"depth:   (int)     filtering recursive depth (n. of directories below cwd)
"                   -1 means full cwd, 0 means root dir only, >0 means up to n subdirs
"vimrc:   (dict)    settings to be sourced when entering/leaving the tab

let s:Tab = {
      \ 'name':    '',
      \ 'cwd':     s:F.fullpath(getcwd()),
      \ 'dirs':    [s:F.fullpath(getcwd())],
      \ 'locked':  0,
      \ 'depth':   -1,
      \ 'vimrc':   get(s:Sets, 'use_tab_vimrc', 0) ? xtabline#vimrc#init() : {},
      \ 'rpaths':  0,
      \ 'icon':    '',
      \ 'index':   tabpagenr()-1,
      \ 'buffers': {'valid': [], 'order': [], 'extra': [], 'front': []},
      \}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#tab#lock(bufs, ...)
  """Lock tab with predefined buffers and properties.
  let T = g:xtabline.Tabs[tabpagenr()-1]
  let T.locked = 1
  let T.buffers.valid = a:bufs
  call extend(T, a:0 ? a:1 : {})
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
