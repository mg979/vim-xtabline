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
" 6. tab (selected)     XTTabInactive XTTabActive
" 7. number (selected)  XTNum XTNumSel
" TODO: 8. warning            XTWarning
" 9. fill               XTFill

let s:Themes = {}

let s:fill_dark = [ 248, 233, '#a9a9a9',   "#171717", 0 ]
let s:fill_lite = [ 231, 239, '#f8f8f2',   "#616161", 0 ]
let s:bg        = { c1, c2 -> &background=='light' ? c1 : c2 }

let s:Themes.seoul = { -> {
      \"XTSelect":      [ 187, 23,  "#DFDEBD",   "#007173",   1 ],
      \"XTSelectMod":   [ 203, 23,  '#DF8C8C',   "#007173",   1 ],
      \"XTVisible":     [ 68,  233, '#F2C38F',   "#171717",   0 ],
      \"XTVisibleMod":  [ 203, 23,  '#DF8C8C',   "#171717",   1 ],
      \"XTHidden":      s:fill_lite,
      \"XTHiddenMod":   [ 203, 239, '#DF8C8C',   "#616161",   0 ],
      \"XTExtra":       [ 252, 89,  "#D9D9D9",   "#9B1D72",   1 ],
      \"XTExtraMod":    [ 203, 89,  '#DF8C8C',   "#9B1D72",   1 ],
      \"XTSpecial":     [ 237, 150, '#3C4C55',   '#F2C38F',   1 ],
      \"XTTabActive":   [ 187, 237, "#DFDEBD",   '#3C4C55',   1 ],
      \"XTTabInactive": s:fill_lite,
      \"XTNumSel":      [ 237, 150, '#3C4C55',   '#A8CE93',   0 ],
      \"XTNum":         [ 180, 233, '#F2C38F',   "#171717",   0 ],
      \"XTFill":        s:bg(s:fill_lite, s:fill_dark),
      \}}


let s:tm_dark = [ 248, 233, "#666666",   "#2d2d2d", 0 ]
let s:tm_lite = [ 231, 239, "#cccccc",   "#666666", 0 ]

let s:Themes.tomorrow = { -> {
      \"XTSelect":      [ 187, 23,  '#262626',    "#99cc99",   1 ],
      \"XTSelectMod":   [ 203, 23,  '#f2777a',    "#99cc99",   1 ],
      \"XTVisible":     [ 68,  233, '#ffcc66',    "#444444",   0 ],
      \"XTVisibleMod":  [ 203, 23,  '#f2777a',    "#444444",   1 ],
      \"XTHidden":      s:tm_lite,
      \"XTHiddenMod":   [ 203, 239, '#f2777a',    "#616161",   0 ],
      \"XTExtra":       [ 252, 89,  '#262626',    "#cc99cc",   1 ],
      \"XTExtramod":    [ 203, 89,  '#f2777a',    "#cc99cc",   1 ],
      \"XTSpecial":     [ 237, 150, '#3C4C55',    '#ffcc66',   1 ],
      \"XTTabActive":   s:tm_lite,
      \"XTTabInactive": [ 231, 239, "#cccccc",    "#444444",   0 ],
      \"XTNumSel":      [ 237, 150, '#3C4C55',    '#A8CE93',   0 ],
      \"XTNum":         [ 180, 233, '#ffcc66',    "#444444",   0 ],
      \"XTFill":        s:bg(s:tm_lite, s:tm_dark),
      \}}


let s:Themes.dracula = { -> {
      \"XTSelect":      [ 231, 61,  '#f8f8f2',    '#6272a4',   0 ],
      \"XTSelectMod":   [ 212, 61,  '#ff79c6',    '#6272a4',   1 ],
      \"XTVisible":     [ 117, 235, '#8be9fd',    '#282a36',   0 ],
      \"XTVisibleMod":  [ 212, 61,  '#ff79c6',    '#282a36',   1 ],
      \"XTHidden":      [ 248, 236, '#a9a9a9',    '#44475a',   0 ],
      \"XTHiddenMod":   [ 212, 236, '#ff79c6',    '#44475a',   0 ],
      \"XTExtra":       [ 141, 17,  '#bd93f9',    '#073655',   1 ],
      \"XTExtraMod":    [ 212, 17,  '#ff79c6',    '#073655',   1 ],
      \"XTSpecial":     [ 236, 84,  '#44475a',    '#50fa7b',   0 ],
      \"XTTabActive":   [ 231, 61,  '#f8f8f2',    '#6272a4',   0 ],
      \"XTTabInactive": [ 248, 236, '#a9a9a9',    '#44475a',   0 ],
      \"XTNumSel":      [ 236, 84,  '#44475a',    '#50fa7b',   0 ],
      \"XTNum":         [ 228, 235, '#f1fa8c',    '#282a36',   0 ],
      \"XTFill":        s:bg(s:fill_lite, [ 248, 235, '#a9a9a9', '#282a36', 0 ]),
      \}}


let s:Themes.molokai = { -> {
      \"XTSelect":      [ 234, 61,  '#232526',   '#e6db74', 1 ],
      \"XTSelectMod":   [ 160, 61,  '#ff0000',   '#e6db74', 1 ],
      \"XTVisible":     [ 81,  233, '#e6db74',   '#232526', 1 ],
      \"XTVisibleMod":  [ 160, 61,  '#ff0000',   '#232526', 1 ],
      \"XTHidden":      [ 248, 17,  '#a9a9a9',   '#333333', 0 ],
      \"XTHiddenMod":   [ 160, 244, '#ff0000',   '#333333', 0 ],
      \"XTExtra":       [ 161, 17,  '#f92672',   '#232526', 1 ],
      \"XTExtraMod":    [ 160, 17,  '#ff0000',   '#232526', 1 ],
      \"XTSpecial":     [ 244, 84,  '#808080',   '#50fa7b', 0 ],
      \"XTTabActive":   [ 234, 61,  '#f8f8f2',   '#232526', 1 ],
      \"XTTabInactive": [ 248, 17,  '#a9a9a9',   '#333333', 0 ],
      \"XTNumSel":      [ 244, 84,  '#232526',   '#e6db74', 0 ],
      \"XTNum":         [ 229, 233, '#e6db74',   '#232526', 0 ],
      \"XTFill":        s:bg(s:fill_lite, [ 248, 233, '#a9a9a9', '#232526', 0 ]),
      \}}


let s:Themes.codedark = { -> {
      \"XTSelect":      [ 237, 74,  '#3C4C55',   '#83AFE5', 1 ],
      \"XTSelectMod":   [ 160, 74,  '#cf0000',   '#83AFE5', 1 ],
      \"XTVisible":     [ 68,  234, '#569cd6',   '#1e1e1e', 1 ],
      \"XTVisibleMod":  [ 160, 237, '#cf0000',   '#1e1e1e', 1 ],
      \"XTHidden":      s:bg(s:fill_lite, [ 74,  237, '#83AFE5', '#3C4C55', 0 ]),
      \"XTHiddenMod":   s:bg(s:fill_lite, [ 203, 237, '#DF8C8C', '#3C4C55', 0 ]),
      \"XTExtra":       [ 251, 17,  '#C5D4DD',   '#073655', 0 ],
      \"XTExtraMod":    [ 203, 17,  '#DF8C8C',   '#073655', 0 ],
      \"XTSpecial":     [ 237, 150, '#3C4C55',   '#A8CE93', 0 ],
      \"XTTabActive":   [ 74,  237, '#83AFE5',   '#3C4C55', 1 ],
      \"XTTabInactive": [ 248, 234, '#a9a9a9',   '#1e1e1e', 0 ],
      \"XTNumSel":      [ 237, 150, '#3C4C55',   '#A8CE93', 0 ],
      \"XTNum":         [ 180, 234, '#F2C38F',   '#1e1e1e', 0 ],
      \"XTFill":        s:bg(s:fill_lite, [ 248, 234, '#a9a9a9', '#1e1e1e', 0 ]),
      \}}


fun! xtabline#themes#init()
  for theme in keys(s:Themes)
    call xtabline#hi#generate(s:Themes[theme](), theme)
  endfor
endfun
