" let s:yelw1 = '#DADA93' | let s:yelw2 = '#F2C38F' | let s:lblu1 = '#97BEEF' | let s:lblu2 = '#83AFE5'
" let s:blue1 = '#569cd6' | let s:blue2 = '#3A7CB2' | let s:blue3 = '#264F78' | let s:blue4 = '#244756'
" let s:dblu1 = '#073655' | let s:dblu2 = '#212733' | let s:gren1 = '#A8CE93' | let s:gren2 = '#608b4e'
" let s:cyan1 = '#7FC1CA' | let s:cyan2 = '#42DCD7' | let s:purpl = '#9A93E1' | let s:pink1 = '#dfafdf'
" let s:pink2 = '#D18EC2' | let s:pink3 = '#C586C0' | let s:grey1 = '#556873' | let s:grey2 = '#4C4E50'
" let s:grey3 = '#3C4C55' | let s:dgrey = '#3D3D40' | let s:lgry1 = '#C5D4DD' | let s:lgry2 = '#c9c6c9'
" let s:lgry3 = '#a9a9a9' | let s:lgry4 = '#9a9a9a' | let s:blugr = '#6A7D89' | let s:clay1 = '#ce9178'
" let s:redli = '#DF8C8C' | let s:redbr = '#ff0000' | let s:reddk = '#bf3434' | let s:whit1 = '#F9F9FF'
" let s:whit2 = '#E6EEF3' | let s:blak1 = '#333233' | let s:blak2 = '#262626' | let s:blak3 = '#1e1e1e'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" let s:black    = '#282a36' "235
" let s:gray     = '#44475a' "236
" let s:white    = '#f8f8f2' "231
" let s:darkblue = '#6272a4' "61
" let s:cyan     = '#8be9fd' "117
" let s:green    = '#50fa7b' "84
" let s:orange   = '#ffb86c' "215
" let s:purple   = '#bd93f9' "141
" let s:red      = '#ff79c6' "212
" let s:yellow   = '#f1fa8c' "228

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 'highlight_group': [ ctermfg, ctermbg, guifg, guibg, style ]
" style: 0=NONE, 1=bold, 2=italic, 3=underline
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Groups:
" 1. selected (w/red)   XTSelect XTSelectMod
" 2. inactive (w/red)   XTVisible XTVisibleMod
" 3. hidden (w/red)     XTHidden XTHiddenMod
" 4. extra (w/red)      XTExtra  XTExtraMod
" 5. special            XTSpecial
" 6. number (selected)  XTNum XTNumSel
" TODO: 7. warning            XTWarning
" 8. fill               XTFill

let s:Themes = {}

let s:fill_dark = [ 248, 233, '#a9a9a9',   '#171717', 0 ]
let s:fill_lite = [ 231, 241, '#f8f8f2',   '#616161', 0 ]
let s:tm_dark   = [ 241, 236, '#666666',   '#2d2d2d', 0 ]
let s:tm_lite   = [ 252, 242, '#cccccc',   '#666666', 0 ]
let s:bg        = { c1, c2 -> &background=='light' ? c1 : c2 }

fun! s:Themes.seoul()
  return {
      \"XTSelect":      [ 187, 23,  '#DFDEBD',   '#007173',   1 ],
      \"XTSelectMod":   [ 174, 23,  '#DF8C8C',   '#007173',   1 ],
      \"XTVisible":     [ 223, 233, '#F2C38F',   '#171717',   0 ],
      \"XTVisibleMod":  [ 174, 233, '#DF8C8C',   '#171717',   1 ],
      \"XTHidden":      s:fill_lite,
      \"XTHiddenMod":   [ 174, 241, '#DF8C8C',   '#616161',   0 ],
      \"XTExtra":       [ 253, 126, '#D9D9D9',   '#9B1D72',   1 ],
      \"XTExtraMod":    [ 174, 126, '#DF8C8C',   '#9B1D72',   1 ],
      \"XTSpecial":     [ 239, 223, '#3C4C55',   '#F2C38F',   1 ],
      \"XTNumSel":      [ 239, 150, '#3C4C55',   '#A8CE93',   0 ],
      \"XTNum":         [ 223, 233, '#F2C38F',   '#171717',   0 ],
      \"XTCorner":      [ 223, 233, '#F2C38F',   '#171717',   0 ],
      \"XTFill":        s:bg(s:fill_lite, s:fill_dark),
      \}
endfun


fun! s:Themes.tomorrow()
  return {
      \"XTSelect":      [ 235, 151, '#262626',   '#99cc99',   1 ],
      \"XTSelectMod":   [ 210, 151, '#f2777a',   '#99cc99',   1 ],
      \"XTVisible":     [ 222, 238, '#ffcc66',   '#444444',   0 ],
      \"XTVisibleMod":  [ 210, 238, '#f2777a',   '#444444',   1 ],
      \"XTHidden":      s:tm_lite,
      \"XTHiddenMod":   [ 210, 241, '#f2777a',   '#616161',   0 ],
      \"XTExtra":       [ 235, 182, '#262626',   '#cc99cc',   1 ],
      \"XTExtraMod":    [ 210, 182, '#f2777a',   '#cc99cc',   1 ],
      \"XTSpecial":     [ 239, 222, '#3C4C55',   '#ffcc66',   1 ],
      \"XTNumSel":      [ 150, 239, '#A8CE93',   '#3C4C55',   0 ],
      \"XTNum":         [ 222, 238, '#ffcc66',   '#444444',   0 ],
      \"XTCorner":      [ 222, 238, '#ffcc66',   '#444444',   0 ],
      \"XTFill":        s:bg(s:tm_lite, s:tm_dark),
      \}
endfun


fun! s:Themes.dracula()
  return {
      \"XTSelect":      [ 231, 60,  '#f8f8f2',   '#6272a4', 0 ],
      \"XTSelectMod":   [ 212, 60,  '#ff79c6',   '#6272a4', 1 ],
      \"XTVisible":     [ 81,  235, '#8be9fd',   '#282a36', 0 ],
      \"XTVisibleMod":  [ 212, 235, '#ff79c6',   '#282a36', 1 ],
      \"XTHidden":      [ 248, 238, '#a9a9a9',   '#44475a', 0 ],
      \"XTHiddenMod":   [ 212, 238, '#ff79c6',   '#44475a', 0 ],
      \"XTExtra":       [ 141, 24,  '#bd93f9',   '#073655', 1 ],
      \"XTExtraMod":    [ 212, 24,  '#ff79c6',   '#073655', 1 ],
      \"XTSpecial":     [ 238, 84,  '#44475a',   '#50fa7b', 0 ],
      \"XTNumSel":      [ 238, 84,  '#44475a',   '#50fa7b', 0 ],
      \"XTNum":         [ 228, 235, '#f1fa8c',   '#282a36', 0 ],
      \"XTCorner":      [ 231, 60,  '#f8f8f2',   '#6272a4', 0 ],
      \"XTFill":        s:bg(s:fill_lite, [ 248, 235, '#a9a9a9', '#282a36', 0 ]),
      \}
endfun


fun! s:Themes.wwdc16()
  return {
      \"XTSelect":      [ 231, 26,  '#f8f8f2',   '#4670d8', 0 ],
      \"XTSelectMod":   [ 167, 26,  '#e64547',   '#4670d8', 1 ],
      \"XTVisible":     [ 81,  238, '#8be9fd',   '#44475a', 0 ],
      \"XTVisibleMod":  [ 167, 238, '#e64547',   '#44475a', 1 ],
      \"XTHidden":      [ 248, 238, '#a9a9a9',   '#44475a', 0 ],
      \"XTHiddenMod":   [ 167, 238, '#e64547',   '#44475a', 0 ],
      \"XTExtra":       [ 231, 66,  '#f8f8f2',   '#64878f', 1 ],
      \"XTExtraMod":    [ 167, 24,  '#e64547',   '#073655', 1 ],
      \"XTSpecial":     [ 238, 150, '#44475a',   '#95c76f', 0 ],
      \"XTNumSel":      [ 238, 150, '#44475a',   '#95c76f', 0 ],
      \"XTNum":         [ 173, 235, '#c98351',   '#282a36', 0 ],
      \"XTCorner":      [ 231, 26,  '#f8f8f2',   '#4670d8', 0 ],
      \"XTFill":        s:bg(s:fill_lite, [ 248, 237, '#a9a9a9', '#353547', 0 ]),
      \}
endfun


fun! s:Themes.molokai()
  return {
      \"XTSelect":      [ 185, 241, '#e6db74',   '#616161', 0 ],
      \"XTSelectMod":   [ 9,   241, '#ff0000',   '#616161', 0 ],
      \"XTVisible":     [ 185, 238, '#e6db74',   '#444444', 1 ],
      \"XTVisibleMod":  [ 9,   238, '#ff0000',   '#444444', 1 ],
      \"XTHidden":      [ 248, 236, '#a9a9a9',   '#333333', 0 ],
      \"XTHiddenMod":   [ 9,   236, '#ff0000',   '#333333', 0 ],
      \"XTExtra":       [ 197, 235, '#f92672',   '#232526', 1 ],
      \"XTExtraMod":    [ 185, 235, '#e6db74',   '#232526', 1 ],
      \"XTSpecial":     [ 8,   84,  '#808080',   '#50fa7b', 0 ],
      \"XTNumSel":      [ 235, 185, '#232526',   '#e6db74', 1 ],
      \"XTNum":         [ 185, 235, '#e6db74',   '#232526', 0 ],
      \"XTCorner":      [ 185, 238, '#e6db74',   '#444444', 1 ],
      \"XTFill":        s:bg(s:fill_lite, [ 248, 235, '#a9a9a9', '#232526', 0 ]),
      \}
endfun


fun! s:Themes.codedark()
  return {
      \"XTSelect":      [ 239, 110, '#3C4C55',   '#83AFE5', 1 ],
      \"XTSelectMod":   [ 160, 110, '#cf0000',   '#83AFE5', 1 ],
      \"XTVisible":     [ 39,  234, '#569cd6',   '#1e1e1e', 1 ],
      \"XTVisibleMod":  [ 160, 234, '#cf0000',   '#1e1e1e', 1 ],
      \"XTHidden":      s:bg(s:fill_lite, [ 110, 239, '#83AFE5', '#3C4C55', 0 ]),
      \"XTHiddenMod":   s:bg(s:fill_lite, [ 174, 239, '#DF8C8C', '#3C4C55', 0 ]),
      \"XTExtra":       [ 252, 24,  '#C5D4DD',   '#073655', 0 ],
      \"XTExtraMod":    [ 174, 24,  '#DF8C8C',   '#073655', 0 ],
      \"XTSpecial":     [ 239, 150, '#3C4C55',   '#A8CE93', 0 ],
      \"XTNumSel":      [ 234, 39,  '#1e1e1e',   '#569cd6', 1 ],
      \"XTNum":         [ 39,  236, '#569cd6',   '#333333', 1 ],
      \"XTCorner":      [ 39,  234, '#569cd6',   '#1e1e1e', 1 ],
      \"XTFill":        s:bg(s:fill_lite, [ 248, 236, '#a9a9a9', '#333333', 0 ]),
      \}
endfun


fun! s:Themes.slate()
  return {
      \"XTSelect":      [ 223, 234, '#f2c38f',   '#1e1e1e', 1 ],
      \"XTSelectMod":   [ 160, 234, '#cf0000',   '#1e1e1e', 1 ],
      \"XTVisible":     [ 39,  234, '#569cd6',   '#1e1e1e', 1 ],
      \"XTVisibleMod":  [ 160, 234, '#cf0000',   '#1e1e1e', 1 ],
      \"XTHidden":      s:bg(s:fill_lite, [ 110, 236, '#83AFE5', '#333233', 0 ]),
      \"XTHiddenMod":   s:bg(s:fill_lite, [ 174, 236, '#DF8C8C', '#333233', 0 ]),
      \"XTExtra":       [ 252, 24,  '#C5D4DD',   '#073655', 0 ],
      \"XTExtraMod":    [ 174, 24,  '#DF8C8C',   '#073655', 0 ],
      \"XTSpecial":     [ 239, 150, '#3C4C55',   '#A8CE93', 0 ],
      \"XTNumSel":      [ 24,  174, '#073655',   '#DF8C8C', 1 ],
      \"XTNum":         [ 39,  239, '#569cd6',   '#4c4e50', 1 ],
      \"XTCorner":      [ 39,  234, '#569cd6',   '#1e1e1e', 1 ],
      \"XTFill":        s:bg(s:fill_lite, [ 248, 236, '#a9a9a9', '#333333', 0 ]),
      \}
endfun


fun! s:Themes.paper()
  return {
      \"XTSelect":      [ 16,    255,   '#000000', '#F0ECDD', 1 ],
      \"XTSelectMod":   [ 160,   255,   '#cf0000', '#F0ECDD', 1 ],
      \"XTVisible":     [ 16,    252,   '#555555', '#F0ECDD', 2 ],
      \"XTVisibleMod":  [ 160,   252,   '#cf0000', '#F0ECDD', 1 ],
      \"XTHidden":      [ 240,   252,   '#555555', '#D4D2C9', 2 ],
      \"XTHiddenMod":   [ 174,   252,   '#DF8C8C', '#D4D2C9', 1 ],
      \"XTExtra":       [ 16,    249,   '#000000', '#B3B2AE', 0 ],
      \"XTExtraMod":    [ 174,   249,   '#DF8C8C', '#B3B2AE', 0 ],
      \"XTSpecial":     [ 252,   245,   '#D4D2C9', '#8D8C86', 0 ],
      \"XTNumSel":      [ 252,   245,   '#F0ECDD', '#8D8C86', 1 ],
      \"XTNum":         [ 252,   245,   '#D4D2C9', '#B3B2AE', 0 ],
      \"XTCorner":      [ 16,    252,   '#000000', '#D4D2C9', 1 ],
      \"XTFill":        [ 16,    252,   '#000000', '#D4D2C9', 1 ],
      \}
endfun


fun! s:Themes.paramount()
  return {
      \"XTSelect":      [ 251, 140, '#000000', '#a790d5', 0 ],
      \"XTSelectMod":   [ 251, 140, '#cf0000', '#a790d5', 0 ],
      \"XTVisible":     [ 243, 0,   '#767676', '#000000', 2 ],
      \"XTVisibleMod":  [ 160, 234, '#cf0000', '#000000', 2 ],
      \"XTHidden":      [ 251, 236, '#C6C6C6', '#303030', 0 ],
      \"XTHiddenMod":   [ 251, 236, '#cf0000', '#303030', 0 ],
      \"XTExtra":       [ 251, 140, '#C6C6C6', '#a790d5', 0 ],
      \"XTExtraMod":    [ 174, 24,  '#cf0000', '#a790d5', 0 ],
      \"XTSpecial":     [ 235, 228, '#262626', '#ffff87', 0 ],
      \"XTNumSel":      [ 140, 239, '#a790d5', '#4E4E4E', 1 ],
      \"XTNum":         [ 140, 239, '#a790d5', '#4E4E4E', 1 ],
      \"XTCorner":      [ 243, 0,   '#767676', '#000000', 2 ],
      \"XTFill":        [ 243, 0,   '#767676', '#000000', 0 ],
      \}
endfun


fun! xtabline#themes#init(theme) abort
  if has_key(g:xtabline_highlight.themes, a:theme)
    return 1
  elseif has_key(s:Themes, a:theme)
    call xtabline#hi#generate(a:theme, s:Themes[a:theme]())
    return 1
  endif
endfun


fun! xtabline#themes#list() abort
  let themes = keys(g:xtabline_highlight.themes)
  for t in keys(s:Themes)
    if index(themes, t) < 0
      call add(themes, t)
    endif
  endfor
  return themes
endfun


" vim: et sw=2 ts=2 sts=2 fdm=indent fdn=1
