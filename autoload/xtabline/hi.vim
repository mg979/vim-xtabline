" Highlight
" =============================================================================
let s:Th = g:xtabline_themes

fun! xtabline#hi#init()
  let theme = get(s:Th, 'active_theme', 'default')
  call xtabline#hi#load_theme(theme, 1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#hi#load_theme(theme, ...)
  """Apply a theme."""

  call s:clear_groups()
  let d = a:0? "default" : ""
  let theme = s:Th.themes[a:theme]

  for group in keys(theme.basic)
    if theme.basic[group][1]
      exe "hi ".d." link ".group." ".theme.basic[group][0]
    else
      exe "hi ".d." ".group." ".theme.basic[group][0]
    endif
  endfor

  if get(theme, 'enable_extra_highlight', 0)
    for group in keys(theme.extra)
      if theme.extra[group][1]
        exe "hi ".d." link ".group." ".theme.extra[group][0]
      else
        exe "hi ".d." ".group." ".theme.extra[group][0]
      endif
    endfor
  endif

  let s:Th.active_theme = a:theme
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Th.themes.default = {
      \'enable_extra_highlight': 1,
      \'basic': {
          \"XBufLineCurrent" : ["TabLineSel",  1],
          \"XBufLineActive"  : ["StatusLine",  1],
          \"XBufLineHidden"  : ["TabLine",     1],
          \"XBufLineFill"    : ["TabLineFill", 1],
          \"XTabLineSelMod"  : ["TabLineSel",  1],
          \"XTabLineSel"     : ["TabLineSel",  1],
          \"XTabLineMod"     : ["TabLine",     1],
          \"XTabLine"        : ["TabLine",     1],
          \"XTabLineFill"    : ["TabLineFill", 1],
          \"XTabLineNumSel"  : ["DiffAdd",     1],
          \"XTabLineNum"     : ["Special",     1]},
      \'extra': {
          \"XBufLineSpecial" : ["DiffAdd",     1],
          \"XBufLineMod"     : ["WarningMsg",  1],
          \"XBufLinePinned"  : ["PmenuSel",    1]}
      \}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:clear_groups()
  """Clear highlight before applying a theme."""
  silent! hi clear XBufLineCurrent
  silent! hi clear XBufLineActive
  silent! hi clear XBufLineHidden
  silent! hi clear XBufLineFill
  silent! hi clear XTabLineSelMod
  silent! hi clear XTabLineSel
  silent! hi clear XTabLineMod
  silent! hi clear XTabLine
  silent! hi clear XTabLineFill
  silent! hi clear XTabLineNumSel
  silent! hi clear XTabLineNum
  silent! hi clear XBufLineSpecial
  silent! hi clear XBufLineMod
  silent! hi clear XBufLinePinned
endfun
