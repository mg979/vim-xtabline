"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:X = g:xtabline
let s:T = { -> s:X.Tabs[tabpagenr()-1] } "current tab

fun! xtabline#vimrc#open()
  """Open buffer with tab vimrc."""
  let lead = get(g:, 'mapleader', '\')

  let s:v.buffer_properties = {'name': 'TabVimrc', 'special': 1}
  silent! botright sp TabVimrc
  setlocal bt=nofile bh=wipe nobl noswf
  setfiletype vim
  call append(0, '"This Tab vimrc will be temporary, unless you save the tab.')
  call append(1, '"Save this vimrc with'.lead.'w, quit with '.lead.'q')
  let rc = get(s:T().vimrc, 'commands', [])
  if !empty(rc)
    for line in rc
      call append("$", line)
    endfor
  endif
  normal! gg}j
  nnoremap <silent><buffer> <esc><esc> <esc>
  nnoremap <silent><buffer><nowait> <leader>w :call xtabline#vimrc#update()<cr>
  nnoremap <silent><buffer><nowait> <leader>q :q<cr>
  nnoremap <silent><buffer><nowait> : :echoerr 'Leave this buffer first'<cr>
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#vimrc#exe(T) abort
  """Try to execute the tab vimrc."""
  let T = a:T
  if empty(T.vimrc) | return | endif
  if !has_key(t:, 'XTvimrc')
    " echom "[XTabline] Tab nr.".tabpagenr() "has a vimrc, but it waits to be activated"
    return
  endif
  if has_key(T.vimrc, 'commands')
    for c in T.vimrc.commands | exe c | endfor
  elseif has_key(T.vimrc, 'file')
    exe "source ".T.vimrc.file
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#vimrc#update()
  """Update the tab vimrc."""
  let T = s:T()
  let T.vimrc.commands = filter(getline(3, "$"), "match(v:val, '\\w') >= 0")
  if !has_key(t:, 'XTvimrc') && !empty(T.vimrc.commands) &&
        \ confirm("Activate this tab's vimrc?", "&Yes\n&No", 2) == 1
    let t:XTvimrc = 1
    call xtabline#vimrc#exe(T)
    echom "[XTabline] Tab nr.".tabpagenr() "has been activated"
  elseif has_key(t:, 'XTvimrc') && empty(T.vimrc.commands)
    unlet t:XTvimrc
  endif
  quit
endfun

