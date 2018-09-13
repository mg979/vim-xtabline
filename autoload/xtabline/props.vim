" Script for templates and functions that set/update tabs/buffers properties

fun! xtabline#props#init()
  let s:X = g:xtabline
  let s:F = s:X.Funcs
  let s:v = s:X.Vars
  let s:Sets = g:xtabline_settings

  let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
  let s:B =  { -> s:X.Buffers             }       "customized buffers
  let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
  return s:Props
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Props = {}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.tab_template(...) dict
  let mod = a:0? a:1 : {}
  return extend({'name':    '',
        \ 'cwd':     s:F.fullpath(getcwd()),
        \ 'vimrc':   {},
        \ 'locked':  0,
        \ 'depth':   -1,
        \ 'rpaths':  0,
        \ 'icon':    '',
        \ 'use_dir': s:F.fullpath(getcwd()),
        \}, mod)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.buf_template(nr, ...) dict
  let buf = {
        \ 'name':    '',
        \ 'icon':    ''}

  let buf.path = filereadable(bufname(a:nr)) ? s:F.fullpath(bufname(a:nr)) : ''
  call extend(buf, self.is_special(a:nr))
  return extend(buf, a:0? a:1 : {})
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.check_tabs() dict
  """Create or remove tab dicts if necessary. Rearrange tabs list if order is wrong.
  let Tabs = s:X.Tabs
  while len(Tabs) < tabpagenr("$") | call add(Tabs, self.new_tab()) | endwhile
  while len(Tabs) > tabpagenr('$') | call remove(Tabs, -1)          | endwhile
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.check_this_tab() dict
  """Ensure all tab dict keys are present.
  call extend(s:T(), self.tab_template(), 'keep')
  call extend(s:T().buffers, {'valid': [], 'order': [], 'extra': []}, 'keep')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.check_buffer(nr, ...) dict
  """Ensure buffer dict is initialized, return the buffer dict.
  let B = s:B() | let n = a:nr

  if has_key(B, n) && s:F.fullpath(bufname(a:nr)) == B[n].path
    return B[n]
  else
    let B[n] = self.buf_template(n)
    return B[n]
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.new_tab(...) dict
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

  let cwd     = has_key(p, 'cwd')?     p.cwd     : s:F.fullpath(getcwd())
  let name    = has_key(p, 'name')?    p.name    : ''
  let buffers = has_key(p, 'buffers')? p.buffers : {'valid': [], 'order': [], 'extra': []}
  let exclude = has_key(p, 'exclude')? p.exclude : []
  let locked  = has_key(p, 'locked')?  p.locked  : 0
  let depth   = has_key(p, 'depth')?   p.depth   : -1
  let vimrc   = has_key(p, 'vimrc')?   p.vimrc   : {}
  let rpaths  = has_key(p, 'rpaths')?  p.rpaths  : 0

  let s:v.tab_properties = {}

  return extend(self.tab_template(), {
        \'name':    name,       'cwd':     cwd,
        \ 'buffers': buffers,    'exclude': exclude,
        \ 'locked':  locked,     'depth':   depth,
        \ 'vimrc':   vimrc,      'rpaths':  rpaths})
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:set_special = { name, dict -> extend({ 'name': name, 'special': 1 }, dict) }
let s:Is          = { n,s -> match(bufname(n), s) == 0 }
let s:Ft          = { n,s -> getbufvar(n, "&ft")  == s }

fun! s:Props.is_special(nr, ...) dict
  """Customize special buffers, if visible in a window.
  let n = a:nr | if !s:F.has_win(n) | return { 'special': 0 } | endif

  let git = index(['gitcommit', 'magit', 'git'], getbufvar(n, "&ft"))

  if s:Ft(n, "GV")
    call self.lock_tab([n], {'icon': s:Sets.custom_icons.git})
    return s:set_special('GV', { 'icon': s:Sets.custom_icons.git, 'refilter': 1 })

  elseif git >= 0
    let gitn   = ['Commit', 'Magit', 'Git']
    return s:set_special(gitn[git], { 'icon': s:Sets.custom_icons.git })

  elseif s:Is(n, "fugitive")      "fugitive buffer, set name and icon
    return s:set_special('fugitive', { 'icon': s:Sets.custom_icons.git })

  elseif s:Ft(n, "startify")
    let i = s:Sets.extra_icons ? ' 🏁 ' : ' ⚑ '
    return s:set_special(i.'Startify'.i, { 'format': 'l' })

  elseif s:Ft(n, "ctrlsf")
    let i = s:Sets.extra_icons ? ' 🔍 ' : ' ⚑ '
    return s:set_special(i.'CtrlSF'.i, { 'format': 'l' })

  else
    return { 'special': 0 }
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.lock_tab(bufs, props) dict
  """Lock tab with predefined buffers and properties.
  let T = tabpagenr() - 1
  let s:X.Tabs[T].locked = 1
  let s:X.Tabs[T].buffers.valid = a:bufs
  for prop in keys(a:props)
    let s:X.Tabs[T][prop] = a:props[prop]
  endfor
endfun

