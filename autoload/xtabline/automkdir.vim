" Vim global plugin for autocreating missing directories
" Last change:  Sat May 20 10:21:31 BST 2017

" Author:       Damian Conway
" Adaptation:   mg979 <mg1979.git@gmail.com>
" License:      This file is placed in the public domain.

"======[ Magically build interim directories if necessary ]===================

function! s:quit (msg, options, quit_option)
  if confirm(a:msg, a:options) == a:quit_option
    XTabCloseBuffer
    return 1
  endif
endfunction

function! xtabline#automkdir#ensure_dir_exists ()
  if exists('g:SessionLoad') || exists("loaded_AutoMkdir") || !get(g:xtabline_settings, 'automkdir', 0)
    return
  endif
  let required_dir = resolve(expand("%:p:h"))
  if !isdirectory(required_dir)
    if !s:quit("Parent directory '" . required_dir . "' doesn't exist.",
          \       "&Create it\nor &Abort?", 2)

      try
        call mkdir( required_dir, 'p' )
      catch
        call s:quit("Can't create '" . required_dir . "'",
              \            "&Abort\nor &Continue anyway?", 1)
      endtry
    endif
  endif
endfunction

