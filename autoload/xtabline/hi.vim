""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:Hi   = g:xtabline_highlight
let s:Sets = g:xtabline_settings

fun! xtabline#hi#init()
  let s:Sets.theme = get(s:Sets, 'theme', 'seoul')
  call xtabline#hi#apply_theme(s:Sets.theme, 1)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#hi#apply_theme(theme, ...)
  """Apply a theme."""

  call s:clear_groups()
  call xtabline#themes#init()

  if !empty(a:theme) && !has_key(s:Hi.themes, a:theme)
    echohl WarningMsg | echo "Wrong theme." | echohl None | return | endif

  let d = a:0? "default" : ""
  let theme = s:Hi.themes[a:theme]

  for group in keys(theme)
    if theme[group][1]
      exe "hi ".d." link ".group." ".theme[group][0]
    else
      exe "hi ".d." ".group." ".theme[group][0]
    endif
  endfor

  if !exists('s:last_theme') || s:Sets.theme != s:last_theme
    let s:last_theme = s:Sets.theme
  endif
  let s:Sets.theme = a:theme
  let g:xtabline.Vars.has_reloaded_scheme = 0
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
  let xbuf = ['Current', 'Visible', 'Hidden', 'Fill', 'Special', 'Mod', 'Pinned']
  let xtab = ['SelMod', 'Sel', 'Mod', 'Fill', 'NumSel', 'Num', '']

  for h in xbuf | exe "silent! hi clear XBufLine".h | endfor
  for h in xtab | exe "silent! hi clear XTabLine".h | endfor
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:style(k)
  let s = !a:k ? "NONE" : a:k==1 ? "BOLD" : a:k==2 ? "ITALIC" : "UNDERLINE"
  return ("term=".s." cterm=".s." gui=".s)
endfun

fun! xtabline#hi#generate(theme, name)
  """Create an entry in g:xtabline_highlight.themes for the give theme."""
  let t = a:theme | let T = {}

  for h in keys(t)
    let T[h] = [printf(
          \"ctermfg=%s ctermbg=%s guifg=%s guibg=%s ".s:style(t[h][4]),
          \t[h][0], t[h][1], t[h][2], t[h][3]), 0]
  endfor
  let s:Hi.themes[a:name] = T
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:xtabline.Vars.has_reloaded_scheme = 0

fun! xtabline#hi#update_theme()
  """Reload theme on colorscheme switch."""
  if g:xtabline.Vars.has_reloaded_scheme | return | endif
  call xtabline#hi#apply_theme(g:xtabline_settings.theme)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Default theme
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Hi.themes.default = {
      \"XTSelect":     ["TabLineSel",  1],
      \"XTVisible":    ["Special",     1],
      \"XTHidden":     ["TabLine",     1],
      \"XTSelectMod":  ["TabLineSel",  1],
      \"XTVisibleMod": ["Special",     1],
      \"XTHiddenMod":  ["WarningMsg",  1],
      \"XTExtra":      ["PmenuSel",    1],
      \"XTSpecial":    ["DiffAdd",     1],
      \"XTFill":       ["TabLineFill", 1],
      \"XTVisibleTab": ["TabLineSel",  1],
      \"XTNumSel":     ["DiffAdd",     1],
      \"XTNum":        ["Special",     1],
      \}

