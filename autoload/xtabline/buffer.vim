" Initialize buffer object

let s:X = g:xtabline
let s:F = s:X.Funcs
let s:v = s:X.Vars
let s:Sets = g:xtabline_settings

let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:bufpath = { f -> filereadable(f) ? s:F.fullpath(f) : '' }

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Template
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:template(nr)
  let buf = {
        \ 'name':    '',
        \ 'path':    s:bufpath(bufname(a:nr)),
        \ 'icon':    '',
        \}

  if !has_key(buf, 'special')
    call extend(buf, s:is_special(a:nr))
  endif
  return buf
endfun

"------------------------------------------------------------------------------

fun! s:update(nr)
  let B = s:X.Buffers[a:nr]
  if !B.special
    call extend(B, s:is_special(a:nr))
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#buffer#get(nr)
  """Generate/update buffer properties while filtering.
  if !has_key(s:X.Buffers, a:nr)
    call xtabline#buffer#add(a:nr)
    call extend(s:X.Buffers[a:nr], s:buf_var(a:nr))
  else
    call s:update(a:nr)
    call extend(s:X.Buffers[a:nr], s:buf_var(a:nr))
  endif
  return s:X.Buffers[a:nr]
endfun

fun! xtabline#buffer#add(nr)
  """For new buffers, apply s:v.buffer_properties and update tabline.
  if !has_key(s:X.Buffers, a:nr)
    let s:X.Buffers[a:nr] = s:template(a:nr)
    if !empty(s:v.buffer_properties)
      call extend(s:X.Buffers[a:nr], s:v.buffer_properties)
      let s:v.buffer_properties = {}
    endif
  endif
endfun

fun! xtabline#buffer#update(nr)
  if has_key(s:X.Buffers, a:nr) && !s:X.Buffers[a:nr].special
    let s:X.Buffers[a:nr].path = s:bufpath(bufname(a:nr))
  endif
endfun

"------------------------------------------------------------------------------

fun! s:buf_var(nr)
  """If b:XTbuf has been set, it will extend the buffer dict.
  if empty(getbufvar(a:nr, 'XTbuf'))
    return {}
  else
    let bv = getbufvar(a:nr, 'XTbuf')
    call setbufvar(a:nr, "XTbuf", {})
    return extend(bv, { 'special': get(bv, 'special', 1) })
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Special buffers {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:set_special = { name, dict -> extend({ 'name': name, 'special': 1 }, dict) }
let s:Is          = { n,s -> match(bufname(n), '\C'.s) == 0 }
let s:Ft          = { n,s -> getbufvar(n, "&ft")  == s }

fun! s:is_special(nr, ...)
  """Customize special buffers, if visible in a window.
  let n = a:nr | if !s:F.has_win(n) | return { 'special': 0 } | endif

  let git = index(['gitcommit', 'magit', 'git', 'fugitive'], getbufvar(n, "&ft"))

  if s:Ft(n, "GV")
    call xtabline#tab#lock([n], {'icon': s:Sets.icons.git})
    return s:set_special('GV', { 'icon': s:Sets.icons.git, 'refilter': 1 })

  elseif git >= 0
    let gitn   = ['Commit', 'Magit', 'Git', 'Status']
    return s:set_special(gitn[git], { 'icon': s:Sets.icons.git })

  elseif s:Is(n, "fugitive")
    return s:set_special('fugitive', { 'icon': s:Sets.icons.git })

  elseif s:Is(n, "Kronos")
    let i = ' '.s:Sets.icons.arrow.' '
    if exists('t:original_tab')
      call xtabline#tab#lock([n], {'name': 'Kronos', 'icon': i})
    endif
    return s:set_special(bufname(n), { 'icon': i })

  elseif s:Ft(n, "netrw")
    let i = ' '.s:Sets.icons.netrw.' '
    return s:set_special(i.'Netrw'.i, { 'format': 'l' })

  elseif s:Ft(n, "dirvish")
    let i = ' '.s:Sets.icons.netrw.' '
    return s:set_special(i.'Dirvish'.i, { 'format': 'l' })

  elseif s:Ft(n, "startify")
    let i = ' '.s:Sets.icons.flag2.' '
    return s:set_special(i.'Startify'.i, { 'format': 'l' })

  elseif s:Ft(n, "ctrlsf")
    let i = ' '.s:Sets.icons.lens.' '
    return s:set_special(i.'CtrlSF'.i, { 'format': 'l' })

  elseif s:Ft(n, "colortemplate-info")
    let i = ' '.s:Sets.icons.palette.' '
    return s:set_special(i.'Colortemplate'.i, { 'format': 'l' })

  else
    return { 'special': 0 }
  endif
endfun

