"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize buffer object
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Script variables and lambdas
let s:X = g:xtabline
let s:F = s:X.Funcs
let s:v = s:X.Vars
let s:Sets = g:xtabline_settings

let s:T           = { -> s:X.Tabs[tabpagenr()-1] }
let s:bufpath     = { f -> filereadable(f) ? s:F.fullpath(f) : '' }
let s:set_special = { name, dict -> extend({ 'name': name, 'special': 1 }, dict) }
let s:Is          = { n,s -> match(bufname(n), '\C'.s) == 0 }
let s:Ft          = { n,s -> getbufvar(n, "&ft")       == s }

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Template
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:template(nr) abort
  " Template for buffer entry.
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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! xtabline#buffer#add(nr) abort
  " Index buffer in xtabline dictionary.
  if !has_key(s:X._buffers, a:nr)
    " clean up any lingering customization, if present
    if has_key(s:X.Buffers, a:nr) | unlet s:X.Buffers[a:nr] | endif
    let s:X._buffers[a:nr] = s:template(a:nr)
  endif
endfun


fun! xtabline#buffer#get(nr) abort
  " Get buffer properties while filtering.
  call xtabline#buffer#add(a:nr) " ensure buffer is indexed
  let bufdict = has_key(s:X.Buffers, a:nr) ? s:X.Buffers : s:X._buffers
  return bufdict[a:nr]
endfun


fun! xtabline#buffer#update(nr) abort
  " Refresh buffer informations.
  call xtabline#buffer#add(a:nr) " ensure buffer is indexed

  " if a buffer variable for customization has been set, pick it up
  call s:xbuf_var(a:nr)

  let bufdict = has_key(s:X.Buffers, a:nr) ? s:X.Buffers : s:X._buffers
  let bufdict[a:nr].path = s:bufpath(bufname(a:nr))
endfun


fun! xtabline#buffer#is_special(nr) abort
  " Check if a buffer is special.
  call xtabline#buffer#add(a:nr) " ensure buffer is indexed

  let bufdict = has_key(s:X.Buffers, a:nr) ? s:X.Buffers : s:X._buffers
  if !bufdict[a:nr].special
    call extend(bufdict[a:nr], s:is_special(a:nr))
  endif
  return bufdict[a:nr].special
endfun


fun! xtabline#buffer#reset(nr) abort
  " Reset buffer entry. Called on BufFilePost.
  silent! unlet s:X.Buffers[a:n]
  silent! unlet s:X._buffers[a:n]
  call xtabline#buffer#add(a:nr)
endfun



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:xbuf_var(nr) abort
  " If b:XTbuf has been set, it will extend the custom buffers dict.
  if !empty(getbufvar(a:nr, 'XTbuf'))
    let bv = extend(getbufvar(a:nr, 'XTbuf'), { 'special': 1 }, 'keep')
    call setbufvar(a:nr, "XTbuf", {})
    let s:X.Buffers[a:nr] = extend(copy(s:X._buffers[a:nr]), bv)
  endif
endfun


fun! s:is_special(nr, ...) abort
  " Customize special buffers, if visible in a window.
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

  else
    return { 'special': 0 }
  endif
endfun



" vim: et sw=2 ts=2 sts=2 fdm=indent fdn=1
