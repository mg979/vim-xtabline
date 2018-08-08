let s:yelw1 = '#DADA93' | let s:yelw2 = '#F2C38F' | let s:lblu1 = '#97BEEF' | let s:lblu2 = '#83AFE5'
let s:blue1 = '#569cd6' | let s:blue2 = '#3A7CB2' | let s:blue3 = '#264F78' | let s:blue4 = '#244756'
let s:dblu1 = '#073655' | let s:dblu2 = '#212733' | let s:gren1 = '#A8CE93' | let s:gren2 = '#608b4e'
let s:cyan1 = '#7FC1CA' | let s:cyan2 = '#42DCD7' | let s:purpl = '#9A93E1' | let s:pink1 = '#dfafdf'
let s:pink2 = '#D18EC2' | let s:pink3 = '#C586C0' | let s:grey1 = '#556873' | let s:grey2 = '#4C4E50'
let s:grey3 = '#3C4C55' | let s:dgrey = '#3D3D40' | let s:lgry1 = '#C5D4DD' | let s:lgry2 = '#c9c6c9'
let s:lgry3 = '#a9a9a9' | let s:lgry4 = '#9a9a9a' | let s:blugr = '#6A7D89' | let s:clay1 = '#ce9178'
let s:redli = '#DF8C8C' | let s:redbr = '#ff0000' | let s:reddk = '#bf3434' | let s:whit1 = '#F9F9FF'
let s:whit2 = '#E6EEF3' | let s:blak1 = '#333233' | let s:blak2 = '#262626' | let s:blak3 = '#1e1e1e'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:black    = '#282a36' "235
let s:gray     = '#44475a' "236
let s:white    = '#f8f8f2' "231
let s:darkblue = '#6272a4' "61
let s:cyan     = '#8be9fd' "117
let s:green    = '#50fa7b' "84
let s:orange   = '#ffb86c' "215
let s:purple   = '#bd93f9' "141
let s:red      = '#ff79c6' "212
let s:yellow   = '#f1fa8c' "228

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 'highlight_group': [ ctermfg, ctermbg, guifg, guibg ]
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Themes = {}

let s:Themes.dracula = {
      \'name': 'dracula',
      \'enable_extra_highlight': 1,
      \'basic': {
          \"XBufLineCurrent" : [ 231,  61, s:white, s:darkblue ],
          \"XBufLineActive"  : [ 117,  235, s:cyan, s:black ],
          \"XBufLineHidden"  : [ 248, 236, s:lgry3, s:gray ],
          \"XBufLineFill"    : [ 248, 235, s:lgry3, s:black ],
          \"XTabLineSelMod"  : [ 231,  61, s:white, s:darkblue ],
          \"XTabLineSel"     : [ 231,  61, s:white, s:darkblue ],
          \"XTabLineMod"     : [ 248, 236, s:lgry3, s:gray ],
          \"XTabLine"        : [ 248, 236, s:lgry3, s:gray ],
          \"XTabLineFill"    : [ 248, 235, s:lgry3, s:black ],
          \"XTabLineNumSel"  : [ 236, 84, s:gray, s:green ],
          \"XTabLineNum"     : [ 228, 235, s:yellow, s:black ]},
      \'extra': {
          \"XBufLineSpecial" : [ 236, 84, s:gray, s:green ],
          \"XBufLineMod"     : [ 212, 61, s:red, s:darkblue ],
          \"XBufLinePinned"  : [ 141, 17,  s:purple, s:dblu1 ]}
      \}


let s:Themes.codedark = {
      \'name': 'codedark',
      \'enable_extra_highlight': 1,
      \'basic': {
          \"XBufLineCurrent" : [ 74,  237, s:lblu2, s:grey3 ],
          \"XBufLineActive"  : [ 68,  234, s:blue1, s:blak3 ],
          \"XBufLineHidden"  : [ 248, 234, s:lgry3, s:blak3 ],
          \"XBufLineFill"    : [ 248, 234, s:lgry3, s:blak3 ],
          \"XTabLineSelMod"  : [ 74,  237, s:lblu2, s:grey3 ],
          \"XTabLineSel"     : [ 74,  237, s:lblu2, s:grey3 ],
          \"XTabLineMod"     : [ 248, 234, s:lgry3, s:blak3 ],
          \"XTabLine"        : [ 248, 234, s:lgry3, s:blak3 ],
          \"XTabLineFill"    : [ 248, 234, s:lgry3, s:blak3 ],
          \"XTabLineNumSel"  : [ 237, 150, s:grey3, s:gren1 ],
          \"XTabLineNum"     : [ 180, 234, s:yelw2, s:blak3 ]},
      \'extra': {
          \"XBufLineSpecial" : [ 237, 150, s:grey3, s:gren1 ],
          \"XBufLineMod"     : [ 203, 237, s:redli, s:grey3 ],
          \"XBufLinePinned"  : [ 251, 17,  s:lgry1, s:dblu1 ]}
      \}


fun! xtabline#themes#init()
  for theme in keys(s:Themes)
    call xtabline#hi#generate(s:Themes[theme])
  endfor
endfun
