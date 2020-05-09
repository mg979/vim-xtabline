"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize buffer object
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Script variables and lambdas
let s:X = g:xtabline
let s:F = s:X.Funcs
let s:v = s:X.Vars
let s:Sets = g:xtabline_settings

let s:T       = { -> s:X.Tabs[tabpagenr()-1] }
let s:bufpath = { f -> filereadable(f) ? s:F.fullpath(f) : '' }

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


fun! xtabline#buffer#set(nr, opts) abort
  " Customize a buffer, assigning name, icons, special status.
  try
    let s:X.Buffers[a:nr] = extend(copy(s:X._buffers[a:nr]), a:opts)
  catch
    echoerr '[xtabline] error while trying to apply custom properties to'
          \ 'buffer n.'.a:nr
  endtry
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Special buffers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! xtabline#buffer#terminal(nr) abort
  " Set special label for terminal buffers.
  call xtabline#buffer#add(a:nr) " ensure buffer is indexed

  let bufdict = has_key(s:X.Buffers, a:nr) ? s:X.Buffers : s:X._buffers

  " buffer has already been labeled
  if bufdict[a:nr].special | return | endif

  if bufname(a:nr) =~ ';#FZF$'
    let name = 'FZF'

  elseif has('nvim')
    let pid = matchstr(bufname(a:nr), '\d\+\ze:')
    let name = printf('[PID %d]', pid)

  else
    let name = 'TERMINAL'
  endif

  call extend(bufdict[a:nr], {'name': name, 'special': 1})
endfun


fun! s:is_special(nr, ...) abort
  " Customize special buffers, if visible in a window.
  if !s:F.has_win(a:nr) | return { 'special': 0 } | endif

  let [ n, ft, ret ] = [ a:nr, getbufvar(a:nr, "&ft"), {} ]

  let git = index(['gitcommit', 'magit', 'git', 'fugitive'], ft)

  if ft == "GV"

    call xtabline#tab#lock(tabpagenr(), [n], {'icon': s:Sets.icons.git})
    let ret = {'name': 'GV', 'icon': s:Sets.icons.git, 'refilter': 1 }

  elseif git >= 0
    let nam = ['Commit', 'Magit', 'Git', 'Status']
    let ret = {'name': nam[git], 'icon': s:Sets.icons.git}

  elseif bufname(n) =~ '^\Cfugitive'
    let ret = {'name': 'fugitive', 'icon': s:Sets.icons.git}

  elseif ft == "help" && getbufvar(n, '&modifiable') == 0
    let ret = {'name': 'HELP', 'icon': s:Sets.icons.book}

  elseif ft == "netrw"
    let ico = ' '.s:Sets.icons.netrw.' '
    let ret = {'name': ico.'Netrw'.ico}

  elseif ft == "dirvish"
    let ico = ' '.s:Sets.icons.netrw.' '
    let ret = {'name': ico.'Dirvish'.ico}

  elseif ft == "startify"
    let ico = ' '.s:Sets.icons.flag2.' '
    let ret = {'name': ico.'Startify'.ico}

  elseif ft == "ctrlsf"
    let ico = ' '.s:Sets.icons.lens.' '
    let ret = {'name': ico.'CtrlSF'.ico}
  endif

  return empty(ret) ? {'special': 0} : extend(ret, {'special': 1})
endfun



" vim: et sw=2 ts=2 sts=2 fdm=indent fdn=1
