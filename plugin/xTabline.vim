""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" File:         xtabline.vim
" Description:  Vim plugin for the customization of the tabline
" Mantainer:    Gianmaria Bajo <mg1979.git@gmail.com>
" Url:          https://github.com/mg979/vim-xtabline
" Copyright:    (c) 2018 Gianmaria Bajo <mg1979.git@gmail.com>
" Licence:      The MIT License
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:save_cpo = &cpo
set cpo&vim

"------------------------------------------------------------------------------

if exists("g:loaded_xtabline")
  finish
endif

if get(g:, 'xtabline_lazy', 0)

  if g:xtabline_lazy == 1
    " load on TabNew or SessionLoadPost
    augroup xtabline_lazy
      au!
      au TabNew,SessionLoadPost * call xtabline#init#start()
    augroup END

    " setup a temporary tabline
    if empty(&tabline)
      fun! Xtabline()
        let bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && !empty(bufname(v:val))')
        let bufline = join(map(bufs, '"%#TabLineSel# " . v:val . '.
              \'(v:val == bufnr("%") ? " %#Special# " : " %#TabLine# ") . fnamemodify(bufname(v:val), ":t") . '.
              \'(getbufvar(v:val, "&modified") ? " [+] " : " ")'))
        return bufline."%#TabLineFill#%T%=%#TabLineSel# 📂 %#TabLine# %<% ".
              \fnamemodify(getcwd(), ':~')."%999X"
      endfun
      set tabline=%!Xtabline()
    endif
  endif

  " init command also if g:xtabline_lazy > 1
  command! XTablineInit call xtabline#init#start()

else
  call xtabline#init#start()
  autocmd VimEnter  * call xtabline#init() | doautocmd BufEnter
endif

"------------------------------------------------------------------------------

let &cpo = s:save_cpo
unlet s:save_cpo
