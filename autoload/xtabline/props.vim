" Script for templates and functions that set/update tabs/buffers properties

fun! xtabline#props#init()
  let s:X = g:xtabline
  let s:F = s:X.Funcs
  let s:v = s:X.Vars
  let s:Sets = g:xtabline_settings
  let s:v.reset_dir = 0

  let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
  let s:B =  { -> s:X.Buffers             }       "customized buffers
  let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
  let s:fB = { -> s:T().buffers.front     }       "temp buffers for tab
  return s:Props
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:is_valid = { n -> index(s:vB(), n) >= 0 }
let s:is_extra = { n -> index(s:T().buffers.extra, n) >= 0 }
let s:is_pinned = { n -> index(s:X.pinned_buffers, n) >= 0 }
let s:is_open = { n -> s:F.has_win(n) && index(s:vB(), n) < 0 && getbufvar(n, "&ma") }

let s:Props = {}
let s:Props.bufpath = { n -> filereadable(bufname(n)) ? s:F.fullpath(bufname(n)) : '' }

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Templates {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.tab_template(...) dict
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

  let mod = a:0? a:1 : {}
  return extend({'name':    '',
        \ 'cwd':     s:F.fullpath(getcwd()),
        \ 'vimrc':   {},
        \ 'locked':  0,
        \ 'depth':   -1,
        \ 'rpaths':  0,
        \ 'icon':    '',
        \ 'buffers': {'valid': [], 'order': [], 'extra': [], 'front': []},
        \ 'exclude': [],
        \}, mod)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.buf_template(nr, ...) dict
  let bv = getbufvar(a:nr, 'XTbuf')
  if !empty(bv)
    let buf = extend(bv, {
          \ 'extra':   s:is_extra(a:nr),
          \ 'path':    self.bufpath(a:nr),
          \ 'front':   s:is_open(a:nr),
          \ 'special': get(bv, 'special', 1),
          \ 'icon':    get(bv, 'icon', ''),
          \ 'name':    get(bv, 'name', ''),
          \})
  else
    let buf = {
          \ 'name':    '',
          \ 'extra':   s:is_extra(a:nr),
          \ 'path':    self.bufpath(a:nr),
          \ 'front':   s:is_open(a:nr),
          \ 'icon':    '',
          \}

    if !a:0 || !has_key(a:1, 'special')
      call extend(buf, self.is_special(a:nr))
    endif
  endif
  return extend(buf, a:0? a:1 : {})
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions {{{1
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
  let T = s:T()
  call extend(T, self.tab_template(), 'keep')
  call extend(T.buffers,
        \{'valid': [], 'order': [], 'extra': [], 'front': []},
        \'keep')
  if !has_key(T, 'use_dir') || s:v.reset_dir
    let T.use_dir = s:F.fullpath(T.cwd)
    let s:v.reset_dir = 0
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.set_buffer(nr, ...) dict
  """Set and return the buffer dict.
  let B = s:B() | let n = a:nr
  let B[n] = self.buf_template(n)
  return B[n]
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Props.new_tab(...) dict
  """Create an entry in the Tabs list.
  """tab_properties can be set by a command, before this function is called.

  let p = a:0? extend(a:1, s:v.tab_properties) : s:v.tab_properties
  let s:v.tab_properties = {}
  return extend(self.tab_template(), p)
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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Special buffers {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:set_special = { name, dict -> extend({ 'name': name, 'special': 1 }, dict) }
let s:Is          = { n,s -> match(bufname(n), '\C'.s) == 0 }
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

  elseif s:Is(n, "fugitive")
    return s:set_special('fugitive', { 'icon': s:Sets.custom_icons.git })

  elseif s:Is(n, "Kronos")
    let i = s:Sets.extra_icons ? ' ➤ ' : ' ⚑ '
    if exists('t:original_tab')
      call self.lock_tab([n], {'name': 'Kronos', 'icon': i})
    endif
    return s:set_special(bufname(n), { 'icon': i })

  elseif s:Ft(n, "netrw")
    let i = s:Sets.extra_icons ? ' '.s:Sets.custom_icons.netrw.' ' : ' '
    return s:set_special(i.'Netrw'.i, { 'format': 'l' })

  elseif s:Ft(n, "startify")
    let i = s:Sets.extra_icons ? ' 🏁 ' : ' ⚑ '
    return s:set_special(i.'Startify'.i, { 'format': 'l' })

  elseif s:Ft(n, "ctrlsf")
    let i = s:Sets.extra_icons ? ' 🔍 ' : ' ⚑ '
    return s:set_special(i.'CtrlSF'.i, { 'format': 'l' })

  elseif s:Ft(n, "colortemplate-info")
    let i = s:Sets.extra_icons ? ' 🎨 ' : ' '
    return s:set_special(i.'Colortemplate'.i, { 'format': 'l' })

  else
    return { 'special': 0 }
  endif
endfun

