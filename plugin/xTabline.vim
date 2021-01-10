""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" File:         xtabline.vim
" Description:  Vim plugin for the customization of the tabline
" Mantainer:    Gianmaria Bajo <mg1979.git@gmail.com>
" Url:          https://github.com/mg979/vim-xtabline
" Copyright:    (c) 2018 Gianmaria Bajo <mg1979.git@gmail.com>
" Licence:      The MIT License
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Credits {{{1
" Pieces of code have been taken from:
"
" BufTabLine {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Description: Vim global plugin for rendering the buffer list in the tabline
" Mantainer:   Aristotle Pagaltzis <pagaltzis@gmx.de>
" Url:         https://github.com/ap/vim-buftabline
" Licence:     The MIT License (MIT)
" Copyright:   (c) 2015 Aristotle Pagaltzis <pagaltzis@gmx.de>
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" Taboo {{{2
"" =============================================================================
" File: taboo.vim
" Description: A little plugin for managing the vim tabline
" Mantainer: Giacomo Comitti (https://github.com/gcmt)
" Url: https://github.com/gcmt/taboo.vim
" License: MIT
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"}}}

let s:save_cpo = &cpo
set cpo&vim

"------------------------------------------------------------------------------

if exists("g:loaded_xtabline")
  finish
endif

if get(g:, 'xtabline_lazy', 0)
  command! -bar XTablineInit call xtabline#init#start()

  " load on TabNew, BufAdd or SessionLoadPost
  augroup xtabline_lazy
    au!
    au TabNew,SessionLoadPost,BufAdd * call xtabline#init#start()
  augroup END

  let maps = !empty(get(g:, 'xtabline_settings', {})) &&
        \    get(g:xtabline_settings, 'enable_mappings', 1)
  if maps
    if empty(mapcheck('<bs>', 'n'))
      nnoremap <expr> <BS> v:count ? ":\<C-u>b ".v:count . "\e" : ":ls\<cr>:b\<space>"
    endif
  endif

  " setup a temporary tabline
  if empty(&tabline)
    fun! Bufline()
      let bufs    = filter(range(1, bufnr('$')), 'buflisted(v:val) && !empty(bufname(v:val))')
      let num     = '"%#TabLineSel# " . v:val . '
      let hi      = '(v:val           == bufnr("%") ? " %#Special# " : " %#TabLine# ") . '
      let bufname = 'fnamemodify(bufname(v:val), ":t") . '
      let mod     = '(getbufvar(v:val, "&modified") ? " [+] " : " ")'
      let cwd     = "%#TabLineFill#%T%=%#TabLineSel# 📂 %#TabLine# %<% " . fnamemodify(getcwd(), ':~')
      let bufline = join(map(bufs, num . hi . bufname . mod))
      return bufline . cwd . " %999X"
    endfun
    set tabline=%!Bufline()
  endif

else
  call xtabline#init#start()
endif

"------------------------------------------------------------------------------

let &cpo = s:save_cpo
unlet s:save_cpo
