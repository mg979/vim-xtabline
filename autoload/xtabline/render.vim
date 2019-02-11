let s:X    = g:xtabline
let s:v    = g:xtabline.Vars
let s:F    = g:xtabline.Funcs
let s:Sets = g:xtabline_settings

let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:B =  { -> s:X.Buffers             }       "customized buffers
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:eB = { -> s:T().buffers.extra     }       "extra buffers for tab
let s:oB = { -> s:F.buffers_order()     }       "ordered buffers for tab

let s:special = { nr -> has_key(s:B(), nr) && s:B()[nr].special }
let s:refilter = 0
let s:mod_width = 0

let s:Hi        = { -> g:xtabline_highlight.themes[s:Sets.theme] }
let s:is_open   = { n -> s:F.has_win(n) && index(s:vB(), n) < 0 && getbufvar(n, "&ma") }
let s:is_extra  = { n -> index(s:eB(), n) >= 0 }


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" BufTabLine {{{1
" =============================================================================
" Description: Vim global plugin for rendering the buffer list in the tabline
" Mantainer:   Aristotle Pagaltzis <pagaltzis@gmx.de>
" Url:         https://github.com/ap/vim-buftabline
" Licence:     The MIT License (MIT)
" Copyright:   (c) 2015 Aristotle Pagaltzis <pagaltzis@gmx.de>
" =============================================================================

" Variables
" =============================================================================

let s:dirsep            = fnamemodify(getcwd(),':p')[-1:]
let s:centerbuf         = winbufnr(0)
let s:is_current_buf    = { nr -> nr == winbufnr(0)                                                }
let s:scratch           = { nr -> index(['nofile','acwrite'], getbufvar(nr, '&buftype')) >= 0      }
let s:nowrite           = { nr -> !getbufvar(nr, '&modifiable')                                    }
let s:pinned            = { -> s:X.pinned_buffers                                                  }
let s:buffer_has_format = { buf -> has_key(s:B(), buf.nr) && has_key(s:B()[buf.nr], 'format')      }
let s:has_buf_icon      = { nr -> has_key(s:B(), string(nr)) && !empty(get(s:B()[nr], 'icon', '')) }
let s:extraHi           = { b -> s:is_extra(b) || s:is_open(b) || index(s:pinned(), b) >= 0        }
let s:specialHi         = { b -> s:B()[b].special                                                  }

" BufTabLine main function {{{1
" =============================================================================

fun! xtabline#render#buffers()
  let show_num = s:Sets.bufline_numbers

  let centerbuf = s:centerbuf " prevent tabline jumping around when non-user buffer current (e.g. help)

  " pick up data on all the buffers
  let tabs = []
  let path_tabs = []
  let tabs_per_tail = {}
  let currentbuf = winbufnr(0)
  let bufs = s:oB()
  let was_locked = s:T().locked

  "put current buffer first
  if s:Sets.sort_buffers_by_last_open
    let i = index(bufs, currentbuf)
    if i >= 0
      call remove(bufs, i)
      call insert(bufs, currentbuf, 0)
    endif
  endif

  "include special buffers (upfront)
  let front = [] | let specials = []
  for b in s:F.wins()
    let B = xtabline#buffer#get(b)
    if B.special
      call add(specials, b)
    elseif s:is_open(b)
      call add(front, b)
    endif
  endfor

  " if the tab has been locked by an open buffer, must refilter
  if !was_locked && s:T().locked
    call xtabline#filter_buffers()
    return xtabline#render#buffers()
  endif

  "put upfront: special > pinned > open > extra buffers
  for b in ( s:eB() + front + s:pinned() + specials )
    call s:put_first(b)
  endfor

  " make buftabline string
  for bnr in bufs
    if !s:clean_buf(bnr) | continue | endif

    let special = s:specialHi(bnr)
    let scratch = s:scratch(bnr)

    " exclude special buffers without window, or non-special scratch buffers
    if special && !s:F.has_win(bnr) | continue
    elseif !special && scratch      | continue | endif

    let n = index(bufs, bnr) + 1       "tab buffer index
    let is_currentbuf = currentbuf == bnr

    let tab = { 'nr': bnr,
              \ 'n': n,
              \ 'tried_devicon': 0,
              \ 'tried_icon': 0,
              \ 'has_icon': 0,
              \ 'separators': s:buf_separators(bnr),
              \ 'path': bufname(bnr),
              \ 'indicator': s:buf_indicator(bnr),
              \ 'hilite':   is_currentbuf && special  ? 'Special' :
                          \ is_currentbuf             ? 'Select' :
                          \ special || s:extraHi(bnr) ? 'Extra' :
                          \ s:F.has_win(bnr)          ? 'Active' : 'Hidden'
              \}

    if is_currentbuf | let [centerbuf, s:centerbuf] = [bnr, bnr] | endif

    if s:T().rpaths
      let tab.path  = fnamemodify(tab.path, ':p:~:.')
    else
      let tab.path  = fnamemodify(tab.path, ':t')
    endif
    let tabs += [tab]
  endfor

  " now keep the current buffer center-screen as much as possible:

  " 1. setup
  let lft = { 'lasttab':  0, 'cut':  '.', 'indicator': '<', 'width': 0, 'half': &columns / 2 }
  let rgt = { 'lasttab': -1, 'cut': '.$', 'indicator': '>', 'width': 0, 'half': &columns - lft.half }

  " 2. sum the string lengths for the left and right halves
  let s:default_buffer_format = s:fmt_chars(s:Sets.bufline_format)

  let currentside = lft
  for tab in tabs
    let tab.label = s:format_buffer(tab)
    let tab.width = strwidth(strtrans(tab.label))
    if centerbuf == tab.nr
      let halfwidth = tab.width / 2
      let lft.width += halfwidth
      let rgt.width += tab.width - halfwidth
      let currentside = rgt
      continue
    endif
    let currentside.width += tab.width
  endfor
  let lft.width -= s:mod_width
  let s:mod_width = 0
  if currentside is lft " centered buffer not seen?
    " then blame any overflow on the right side, to protect the left
    let [lft.width, rgt.width] = [0, lft.width]
  endif

  " 3. add the current tab name/cwd to the right side
  let [active_tab, active_tab_label] = s:get_tab_for_bufline()
  if !empty(active_tab_label)
    let rgt.width += strwidth(strtrans(active_tab_label)) + 3
  endif

  " 4. toss away tabs and pieces until all fits:

  if ( lft.width + rgt.width ) > &columns
    let oversized
          \ = lft.width < lft.half ? [ [ rgt, &columns - lft.width ] ]
          \ : rgt.width < rgt.half ? [ [ lft, &columns - rgt.width ] ]
          \ :                        [ [ lft, lft.half ], [ rgt, rgt.half ] ]
    for [side, budget] in oversized
      let delta = side.width - budget
      " toss entire tabs to close the distance
      while delta >= tabs[side.lasttab].width
        let delta -= remove(tabs, side.lasttab).width
      endwhile
      " then snip at the last one to make it fit
      let endtab = tabs[side.lasttab]
      while delta > ( endtab.width - strwidth(strtrans(endtab.label)) )
        let endtab.label = substitute(endtab.label, side.cut, '', '')
      endwhile
      let endtab.label = substitute(endtab.label, side.cut, side.indicator, '')
    endfor
  endif

  let swallowclicks = '%'.(1 + tabpagenr('$')).'X'
  let left = swallowclicks . join(map(tabs,'printf("%%#XT%s#%s",v:val.hilite,strtrans(v:val.label))'),'')
  let right = active_tab . '%#XTFill#'
  let l_r =  lft.width + rgt.width
  return left . s:extra_padding(l_r) . right
endfun

" Buffer label formatting {{{1
" =============================================================================

fun! s:format_buffer(buf)
  let fmt = s:buffer_has_format(a:buf)?
        \ s:fmt_chars(s:B()[a:buf.nr].format) : s:default_buffer_format

  let out = []
  for c in fmt
    "custom tab icon, if tab has a name and/or icon has been defined
    call add(out, s:fmt_buf(c, a:buf))
  endfor
  return join(out, '')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:buf_indicator(bnr)
  let mods = s:Sets.bufline_indicators | let nr = a:bnr
  let mod = index(s:pinned(), nr) >= 0 ? mods.pinned : ''
  let modHi = s:is_current_buf(nr) ? "%#XTSelectMod#" :
        \     s:extraHi(nr)        ? "%#XTExtraMod#" :
        \     bufwinnr(nr) > 0     ? "%#XTActiveMod#" : "%#XTHiddenMod#"
  if getbufvar(nr, '&mod')
    let s:mod_width += len (modHi)
    return (mod . modHi . mods.modified)
  elseif s:special(nr)
    return ''
  elseif s:scratch(nr)
    return (mod . modHi . mods.scratch)
  elseif !getbufvar(nr, '&ma')
    return (mod . modHi . mods.readonly)
  else
    return mod
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:buf_separators(nr)
  """Use custom separators if defined in buffer entry."""
  let bufs = s:B()
  return has_key(bufs, a:nr) && has_key(bufs[a:nr], 'separators') ?
        \       bufs[a:nr].separators : s:Sets.bufline_separators
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_buf_name(buf)
  """Return custom buffer name, if it has been set, otherwise the filename."""
  let bufs = s:B() | let nr = a:buf.nr
  let has_name = has_key(bufs, nr) && has_key(bufs[nr], 'name') && !empty(bufs[nr].name)

  return has_name ? bufs[nr].name : empty( a:buf.path ) ? s:Sets.bufline_unnamed : a:buf.path
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_dev_icon(buf)
  """Return preferably devicon for buffer, or custom icon if present."""
  let a:buf.tried_devicon = 1
  if exists('g:loaded_webdevicons') &&
        \ (s:Sets.devicon_for_all_filetypes ||
        \ index(s:Sets.devicon_for_extensions, expand("#".a:buf.nr.":e")) >= 0)
    let a:buf.has_icon = 1
    return WebDevIconsGetFileTypeSymbol(bufname(a:buf.path)).' '
  else
    return a:buf.tried_icon? '' : s:get_buf_icon(a:buf)
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_buf_icon(buf)
  """Return preferably custom icon for buffer, or devicon if present."""
  let a:buf.tried_icon = 1
  let nr = a:buf.nr
  if s:has_buf_icon(nr)
    let a:buf.has_icon = 1
    return s:B()[nr].icon.' '
  else
    return a:buf.tried_devicon? '' : s:get_dev_icon(a:buf)
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:needs_separator(buf)
  """Verify if a separator must be inserted."""
  let either_or = s:Sets.bufline_sep_or_icon
  return (either_or && !a:buf.has_icon) || !either_or
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""



"Taboo  {{{1
"" =============================================================================
" File: taboo.vim
" Description: A little plugin for managing the vim tabline
" Mantainer: Giacomo Comitti (https://github.com/gcmt)
" Url: https://github.com/gcmt/taboo.vim
" License: MIT
" =============================================================================

" Main command
" =============================================================================

" To construct the tabline string for terminal vim.
fun! xtabline#render#tabs()
  let tabline = ''
  let fmt_unnamed = s:fmt_chars(s:Sets.tab_format)
  let fmt_renamed = s:fmt_chars(s:Sets.named_tab_format)

  for i in s:tabs()
    let tabline .= i == tabpagenr() ? '%#XTTabActive#' : '%#XTTabInactive#'
    let tabline .= '%' . i . 'T'
    let fmt = empty(s:tabname(i)) ? fmt_unnamed : fmt_renamed
    let tabline .= s:format_tab(i, fmt)
  endfor

  let tabline .= '%#XTFill#%T'
  let tabline .= '%=%#XTHidden#%999X' . s:Sets.close_tabs_label
  return tabline
endfun

" Tab label formatting {{{1
" =============================================================================

fun! s:format_tab(tabnr, fmt)
  let out = []
  for c in a:fmt
    "custom tab icon, if tab has a name and/or icon has been defined
    if c == '-'
      let icon = s:get_tab_icon(a:tabnr)
      let c = a:tabnr == tabpagenr()? icon[0] : icon[1]
    else
      let c = s:fmt_tab(c, a:tabnr)
    endif
    call add(out, c)
  endfor
  return join(out, '')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:short_cwd(tabnr, h)
  if !a:h
    return fnamemodify(expand(s:X.Tabs[a:tabnr-1].cwd), ":t")
  else
    let H = fnamemodify(s:X.Tabs[a:tabnr-1].cwd, ":~")
    if s:v.winOS
      let H = tr(H, '\', '/')
    endif
    while len(split(H, '/')) > a:h+1
      let H = substitute(H, '/\([^/]\)[^/]*', '°\1', "")
    endwhile
    return tr(H, '°', '/')
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tabnum(tabnr, all)
  return a:tabnr == tabpagenr() ?
        \        "%#XTNumSel# " . a:tabnr . " %#XTTabActive#" :
        \a:all ? "%#XTNum# "    . a:tabnr . " %#XTTabInactive#" : ''
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:wincount(tabnr, all)
  return a:all || a:tabnr == tabpagenr() ?
        \tabpagewinnr(a:tabnr, '$') : ''
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:wincountUnicode(tabnr, all)
  let buffers_number = s:unicode_nrs(tabpagewinnr(a:tabnr, '$'))
  return a:all || a:tabnr == tabpagenr() ? buffers_number : ''
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:modflag(tabnr)
  let flag = s:Sets.modified_tab_flag
  for buf in tabpagebuflist(a:tabnr)
    if getbufvar(buf, "&mod")
      return a:tabnr == tabpagenr() ?
              \ "%#XTHiddenMod#" . flag . "%#XTHidden#" :
              \ "%#XTActiveMod#"    . flag . "%#XTActive#"
    endif
  endfor
  return ""
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bufname(tabnr)
  let buffers = tabpagebuflist(a:tabnr)
  let buf = s:first_normal_buffer(buffers)
  let bname = bufname(buf > -1 ? buf : buffers[0])
  if !empty(bname)
    return s:basename(bname)
  endif
  return s:Sets.unnamed_tab_label
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bufpath(tabnr)
  let buffers = tabpagebuflist(a:tabnr)
  let buf = s:first_normal_buffer(buffers)
  let bname = bufname(buf > -1 ? buf : buffers[0])
  if !empty(bname)
    return fnamemodify(bname, ':~')
  endif
  return s:Sets.unnamed_tab_label
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_tab_icon(tabnr)
  if !s:v.custom_tabs | return s:Sets.tab_icon | endif

  let T = s:X.Tabs[a:tabnr-1]
  let icon = s:has_tab_icon(T)

  return !empty(icon) ? icon :
       \ !empty(T.name) ? s:Sets.named_tab_icon : s:Sets.tab_icon
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:has_tab_icon(T)
  if !has_key(a:T, 'icon') | return | endif
  let I = a:T.icon

  if empty(I)
    return
  elseif type(I) == v:t_string
    return [I, I]
  elseif type(I) == v:t_list && len(I) == 2
    return I
  elseif type(I) == v:t_list && len(I) == 1
    return [I[0], I[0]]
  endif
endfun




" Helpers {{{1
" =============================================================================

let s:tabs = { -> range(1, tabpagenr('$')) }
let s:tabcwd = { n -> s:X.Tabs[n-1].cwd }
let s:windows = { n -> range(1, tabpagewinnr(n, '$')) }
let s:basename = { f -> fnamemodify(f, ':p:t') }

let s:fmt_chars = { s -> split(s, '\zs') }
let s:fmt_buf = { c, buf -> {
      \' ': ' ',
      \'l': s:get_buf_name(buf),
      \'n': s:unicode_nrs(buf.n),
      \'N': buf.n,
      \'+': buf.indicator,
      \'f': buf.path,
      \'i': s:get_dev_icon(buf),
      \'I': s:get_buf_icon(buf),
      \'<': s:needs_separator(buf)? buf.separators[0] : '',
      \'>': buf.separators[1],
      \}[c]
      \}
let s:fmt_tab = { c, tab -> {
      \' ': ' ',
      \'n': s:tabnum(tab, 0),
      \'N': s:tabnum(tab, 1),
      \'w': s:wincount(tab, 0),
      \'W': s:wincount(tab, 1),
      \'u': s:wincountUnicode(tab, 0),
      \'U': s:wincountUnicode(tab, 1),
      \'+': s:modflag(tab),
      \'l': s:tabname(tab),
      \'f': s:bufname(tab),
      \'a': s:bufpath(tab),
      \'P': s:tabcwd(tab),
      \'0': s:short_cwd(tab, 0),
      \'1': s:short_cwd(tab, 1),
      \'2': s:short_cwd(tab, 2),
      \}[c]
      \}

fun! s:put_first(b)
  """Ensure a buffer goes first in the bufline.
  let bufs = s:oB()
  let i = index(bufs, a:b)
  if i >= 0 | call remove(bufs, i) | endif
  call insert(bufs, a:b, 0)
endfun

fun! s:tabname(tabnr)
  if s:v.custom_tabs
    return s:X.Tabs[a:tabnr-1].name
  else
    return s:short_cwd(a:tabnr, 2)
  endif
endfun

fun! s:first_normal_buffer(buffers)
  for buf in a:buffers
    if buflisted(buf) && getbufvar(buf, "&bt") != 'nofile'
      return buf
    end
  endfor
  return -1
endfun

fun! s:unicode_nrs(nr)
  """Adapted from Vim-CtrlSpace (https://github.com/szw/vim-ctrlspace)
  let u_nr = ""

  if s:Sets.superscript_unicode_nrs
    let small_numbers = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
  else
    let small_numbers = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
  endif
  let number_str    = string(a:nr)

  for i in range(0, len(number_str) - 1)
    let u_nr .= small_numbers[str2nr(number_str[i])]
  endfor

  return u_nr
endfun

fun! s:get_tab_for_bufline()
  """Build string with tab label and icon for the bufline."""
  if ! s:Sets.show_current_tab | return ['', ''] | endif
  let N = tabpagenr()
  let fmt = empty(s:tabname(N)) ? s:Sets.bufline_tab_format : s:Sets.bufline_named_tab_format

  let fmt_tab = s:format_tab(N, s:fmt_chars(fmt))                 "formatted string
  let active_tab_label = substitute(fmt_tab, '%#X\w*#', '', 'g')  "text only, to find width
  let active_tab = '%#XTSelect#'.fmt_tab                          "use LineFill until label
  return [active_tab, active_tab_label]
endfun

fun! s:extra_padding(l_r)
  if !s:Sets.show_current_tab | return '' | endif
  let spaces = a:l_r > &columns ? 0 : &columns - a:l_r
  let s = '   '
  for i in range(spaces)
    let s .= ' '
  endfor
  return '%#XTFill#'.s
endfun

fun! s:clean_buf(b)
  if bufexists(a:b) && has_key(s:B(), a:b)
    return 1
  endif
  let iv = index(s:vB(), a:b)
  let io = index(s:oB(), a:b)
  if iv >= 0
    call remove(s:vB(), iv)
  endif
  if io >= 0
    call remove(s:oB(), io)
  endif
  silent! unlet! s:X.Buffers[a:b]
endfun
