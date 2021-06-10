"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:Hi   = g:xtabline_highlight
let s:Sets = g:xtabline_settings


fun! xtabline#hi#init() abort
  call xtabline#hi#apply_theme(s:Sets.theme)
endfun


fun! xtabline#hi#apply_theme(theme) abort
  " Apply a theme.

  call s:clear_groups()

  if a:theme == 'default'
    let s:Sets.theme = a:theme
    return s:Hi.themes.default()
  endif

  if !xtabline#themes#init(a:theme)
    echohl WarningMsg | echo "Wrong theme." | echohl None | return
  endif

  let theme = s:Hi.themes[a:theme]

  for group in keys(theme)
    if theme[group][1]
      exe "hi link ".group." ".theme[group][0]
    else
      exe "hi ".group." ".theme[group][0]
    endif
  endfor

  let s:Sets.theme = a:theme
endfun


fun! xtabline#hi#load_theme(bang, theme) abort
  " Load a theme.
  if !empty(a:theme)
    call timer_start(50, { t -> xtabline#hi#apply_theme(a:theme) })
  elseif a:bang
    call timer_start(50, { t -> xtabline#hi#apply_theme(s:Sets.theme) })
  else
    echo "[xtabline] current theme is" s:Sets.theme
  endif
endfun

fun! s:clear_groups() abort
  " Clear highlight before applying a theme.
  silent! hi clear XTSelect
  silent! hi clear XTSelectMod
  silent! hi clear XTVisible
  silent! hi clear XTVisibleMod
  silent! hi clear XTHidden
  silent! hi clear XTHiddenMod
  silent! hi clear XTExtra
  silent! hi clear XTExtramod
  silent! hi clear XTSpecial
  silent! hi clear XTNumSel
  silent! hi clear XTNum
  silent! hi clear XTFill
  silent! hi clear XTCorner
endfun


fun! xtabline#hi#generate(name, theme) abort
  " Create an entry in g:xtabline_highlight.themes for the given theme.
  let t = a:theme | let T = {}

  fun! s:style(k) abort
    let s =   a:k == 0 ? "NONE"
          \ : a:k == 1 ? "BOLD"
          \ : a:k == 2 ? "ITALIC"
          \ : a:k == 3 ? "ITALIC,BOLD" : "UNDERLINE"
    return ("term=".s." cterm=".s." gui=".s)
  endfun

  for h in keys(t)
    let T[h] = [printf(
          \"ctermfg=%s ctermbg=%s guifg=%s guibg=%s ".s:style(t[h][4]),
          \t[h][0], t[h][1], t[h][2], t[h][3]), 0]
  endfor
  let s:Hi.themes[a:name] = T
endfun


fun! xtabline#hi#update_theme() abort
  " Reload theme on colorscheme switch.
  try
    call xtabline#hi#apply_theme(g:xtabline_settings.theme)
  catch
    call xtabline#hi#apply_theme('default')
  endtry
endfun



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Default theme
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Hi.themes.default() abort
  " Apply default theme, based on highlight linking.

  hi! link XTSelect         PmenuSel
  hi! link XTVisible        Special
  hi! link XTHidden         TabLine
  hi! link XTExtra          Visual
  hi! link XTSpecial        IncSearch
  hi! link XTFill           Folded
  hi! link XTNumSel         TabLineSel
  hi! link XTNum            TabLineSel
  hi! link XTCorner         Special

  let pat = has('gui_running') || &termguicolors ? 'guibg=\S\+' : 'ctermbg=\S\+'
  try
    exe 'hi XTSelectMod'  matchstr(execute('hi PmenuSel'), pat) 'guifg=#af0000 gui=bold cterm=bold'
  catch
    hi! link XTSelectMod PmenuSel
  endtry
  try
    exe 'hi XTVisibleMod' matchstr(execute('hi Special'), pat) 'guifg=#af0000 gui=bold cterm=bold'
  catch
    hi! link XTVisibleMod Special
  endtry
  try
    exe 'hi XTHiddenMod'  matchstr(execute('hi TabLine'), pat) 'guifg=#af0000 gui=bold cterm=bold'
  catch
    hi! link XTHiddenMod TabLine
  endtry
  try
    exe 'hi XTExtraMod'   matchstr(execute('hi Visual'), pat) 'guifg=#af0000 gui=bold cterm=bold'
  catch
    hi! link XTExtraMod Visual
  endtry
endfun


" vim: et sw=2 ts=2 sts=2 fdm=indent
