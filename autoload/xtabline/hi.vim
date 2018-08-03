" Highlight
" =============================================================================

fun! xtabline#hi#init()
  let g:xtabline_highlight = get(g:, 'xtabline_highlight', {})
  let s:Hi = g:xtabline_highlight

  let s:Hi.XBufLineCurrent = get(s:Hi, "XBufLineCurrent", ["TabLineSel",  1])
  let s:Hi.XBufLineActive  = get(s:Hi, "XBufLineActive",  ["StatusLine",  1])
  let s:Hi.XBufLineHidden  = get(s:Hi, "XBufLineHidden",  ["TabLine",     1])
  let s:Hi.XBufLineFill    = get(s:Hi, "XBufLineFill",    ["TabLineFill", 1])
  let s:Hi.XTabLineSelMod  = get(s:Hi, "XTabLineSelMod",  ["TabLineSel",  1])
  let s:Hi.XTabLineSel     = get(s:Hi, "XTabLineSel",     ["TabLineSel",  1])
  let s:Hi.XTabLineMod     = get(s:Hi, "XTabLineMod",     ["TabLine",     1])
  let s:Hi.XTabLine        = get(s:Hi, "XTabLine",        ["TabLine",     1])
  let s:Hi.XTabLineFill    = get(s:Hi, "XTabLineFill",    ["TabLineFill", 1])

  call xtabline#hi#refresh(1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#hi#refresh(...)
  """Refresh highlight.

  let d = a:0? "default" : ""

  for group in keys(s:Hi)
    if s:Hi[group][1]
      exe "silent! hi clear".group
      exe "hi ".d." link ".group." ".s:Hi[group][0]
    else
      exe "hi ".d." ".group." ".s:Hi[group][0]
    endif
  endfor
endfun

