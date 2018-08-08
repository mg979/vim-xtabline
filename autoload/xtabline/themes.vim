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

let s:Themes = {}

let s:Themes.codedark = {
      \'enable_extra_highlight': 1,
      \'basic': {
          \"XBufLineCurrent" : ["guifg=" . s:lblu2 . " guibg=" . s:grey3 . "", 0],
          \"XBufLineActive"  : ["guifg=" . s:blue1 . " guibg=" . s:blak3 . "", 0],
          \"XBufLineHidden"  : ["guifg=" . s:lgry3 . " guibg=" . s:blak3 . "", 0],
          \"XBufLineFill"    : ["guifg=" . s:lgry3 . " guibg=" . s:blak3 . "", 0],
          \"XTabLineSelMod"  : ["guifg=" . s:lblu2 . " guibg=" . s:grey3 . "", 0],
          \"XTabLineSel"     : ["guifg=" . s:lblu2 . " guibg=" . s:grey3 . "", 0],
          \"XTabLineMod"     : ["guifg=" . s:lgry3 . " guibg=" . s:blak3 . "", 0],
          \"XTabLine"        : ["guifg=" . s:lgry3 . " guibg=" . s:blak3 . "", 0],
          \"XTabLineFill"    : ["guifg=" . s:lgry3 . " guibg=" . s:blak3 . "", 0],
          \"XTabLineNumSel"  : ["guifg=" . s:grey3 . " guibg=" . s:gren1 . "", 0],
          \"XTabLineNum"     : ["guifg=" . s:yelw2,                            0]},
      \'extra': {
          \"XBufLineSpecial" : ["guifg=" . s:grey3 . " guibg=" . s:gren1 . "", 0],
          \"XBufLineMod"     : ["guifg=" . s:redli . " guibg=" . s:grey3 . "", 0],
          \"XBufLinePinned"  : ["guifg=" . s:lgry1 . " guibg=" . s:dblu1 . "", 0]}
      \}


fun! xtabline#themes#init()
  return s:Themes
endfun
