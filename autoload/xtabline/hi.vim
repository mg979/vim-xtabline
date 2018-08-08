""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:Hi   = g:xtabline_highlight
let s:Sets = g:xtabline_settings

fun! xtabline#hi#init()
  call xtabline#themes#init()
  let s:Hi.active_theme = get(s:Hi, 'active_theme', 'default')
  call xtabline#hi#apply_theme(s:Hi.active_theme, 1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#hi#apply_theme(theme, ...)
  """Apply a theme."""

  if !empty(a:theme) && !has_key(s:Hi.themes, a:theme)
    echohl WarningMsg | echo "Wrong theme." | echohl None | return | endif

  call s:clear_groups()
  let d = a:0? "default" : ""
  let theme = s:Hi.themes[a:theme]

  for group in keys(theme.basic)
    if theme.basic[group][1]
      exe "hi ".d." link ".group." ".theme.basic[group][0]
    else
      exe "hi ".d." ".group." ".theme.basic[group][0]
    endif
  endfor

  if s:Sets.enable_extra_highlight &&
        \get(theme, 'enable_extra_highlight', 0) && has_key(theme, 'extra')
    for group in keys(theme.extra)
      if theme.extra[group][1]
        exe "hi ".d." link ".group." ".theme.extra[group][0]
      else
        exe "hi ".d." ".group." ".theme.extra[group][0]
      endif
    endfor
  endif

  if !exists('s:last_theme') || s:Hi.active_theme != s:last_theme
    let s:last_theme = s:Hi.active_theme
  endif
  let s:Hi.active_theme = a:theme
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#hi#load_theme(bang, theme)
  """Load a theme."""
  if a:bang
    call xtabline#hi#apply_theme(s:last_theme)
    echohl Special | echo "Theme switched to" s:last_theme | echohl None
  elseif !empty(a:theme)
    call xtabline#hi#apply_theme(a:theme)
    echohl Special | echo "Theme switched to" a:theme | echohl None
  else
    echohl WarningMsg | echo "No theme specified." | echohl None
  endif
endfun

fun! s:clear_groups()
  """Clear highlight before applying a theme."""
  let xbuf = ['Current', 'Active', 'Hidden', 'Fill', 'Special', 'Mod', 'Pinned']
  let xtab = ['SelMod', 'Sel', 'Mod', 'Fill', 'NumSel', 'Num', '']

  for h in xbuf | exe "silent! hi clear XBufLine".h | endfor
  for h in xtab | exe "silent! hi clear XTabLine".h | endfor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#hi#generate(theme)
  """Create an entry in g:xtabline_highlight.themes for the give theme."""
  let t = a:theme | let T = {'basic': {}, 'extra':{}}
  if !has_key(t, 'name') | return | endif

  for h in keys(t.basic)
    let T.basic[h] = [printf(
                      \"ctermfg=%s ctermbg=%s guifg=%s guibg=%s",
                      \t.basic[h][0], t.basic[h][1], t.basic[h][2], t.basic[h][3]), 0]
  endfor
  for h in keys(t.extra)
    let T.extra[h] = [printf(
                      \"ctermfg=%s ctermbg=%s guifg=%s guibg=%s",
                      \t.extra[h][0], t.extra[h][1], t.extra[h][2], t.extra[h][3]), 0]
  endfor
  let T.enable_extra_highlight = get(t, 'enable_extra_highlight', 0)
  let s:Hi.themes[t.name] = T
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Default theme
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Hi.themes.default = {
      \'enable_extra_highlight': 0,
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

