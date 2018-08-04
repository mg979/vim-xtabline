let s:X    = g:xtabline
let s:V    = g:xtabline.Vars
let s:Sets = g:xtabline_settings

let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:B =  { -> s:X.Buffers             }       "customized buffers
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab

let s:Is = { n,s -> match(bufname(n), s) == 0 }
let s:Ft = { n,s -> getbufvar(n, "&ft")  == s }
let s:Bd = { n,i -> { 'name': n, 'icon': i, 'path': '', 'nomod': 1 } }

let s:nomod = { nr -> has_key(s:B(), nr) && has_key(s:B()[nr], 'nomod') }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Bufline/Tabline settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:indicators = {
      \ 'modified': '[+]',
      \ 'readonly': '[🔒]',
      \ 'scratch': '[!]',
      \ 'pinned': '[📌]',
      \}

let s:Sets.bufline_numbers           = get(s:Sets, 'bufline_numbers',    1)
let s:Sets.bufline_indicators        = extend(get(s:Sets, 'bufline_indicators', {}),  s:indicators)
let s:Sets.bufline_sep_or_icon       = get(s:Sets, 'bufline_sep_or_icon', 0)
let s:Sets.bufline_separators        = get(s:Sets, 'bufline_separators_cur', ['', '']) "old: nr2char(0x23B8)
let s:Sets.bufline_format            = get(s:Sets, 'bufline_format',  ' n I< l +')
let s:Sets.devicon_for_all_filetypes = get(s:Sets, 'devicon_for_all_filetypes', 0)
let s:Sets.devicon_for_extensions    = get(s:Sets, 'devicon_for_extensions', ['md', 'txt'])

let s:Sets.tab_format                = get(s:Sets, "tab_format", " U - 2+ ")
let s:Sets.renamed_tab_format        = get(s:Sets, "renamed_tab_format", " U - l+ ")
let s:Sets.modified_tab_flag         = get(s:Sets, "modified_tab_flag", "*")
let s:Sets.close_tabs_label          = get(s:Sets, "close_tabs_label", "")
let s:Sets.unnamed_tab_label         = get(s:Sets, "unnamed_tab_label", "[no name]")

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" BufTabLine {{{
" =============================================================================
" Description: Vim global plugin for rendering the buffer list in the tabline
" Mantainer:   Aristotle Pagaltzis <pagaltzis@gmx.de>
" Url:         https://github.com/ap/vim-buftabline
" Licence:     The MIT License (MIT)
" Copyright:   (c) 2015 Aristotle Pagaltzis <pagaltzis@gmx.de>
" =============================================================================

" Variables {{{
" =============================================================================

let s:dirsep            = fnamemodify(getcwd(),':p')[-1:]
let s:centerbuf         = winbufnr(0)
let s:scratch           = { nr -> index(['nofile','acwrite'], getbufvar(nr, '&buftype')) >= 0 }
let s:nowrite           = { nr -> !getbufvar(nr, '&modifiable') }
let s:pinned            = { -> s:X.pinned_buffers               }
let s:buffer_has_format = { buf -> has_key(s:B(), buf.nr) && has_key(s:B()[buf.nr], 'format') }
let s:has_buf_icon      = { nr -> has_key(s:B(), string(nr)) && !empty(get(s:B()[nr], 'icon', '')) }
"}}}

" Main function {{{
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

  "include pinned buffers and put them upfront
  for b in s:pinned()
    let i = index(bufs, b)
    if i >= 0 | call remove(bufs, i) | endif
    call insert(bufs, b, 0)
  endfor

  "include special buffers
  "Note: maybe not necessary to find index
  for b in tabpagebuflist(tabpagenr())
    if index(bufs, b) < 0 && s:is_special_buffer(b)
      let i = index(bufs, b)
      if i >= 0 | call remove(bufs, i) | endif
      call insert(bufs, b, 0)
      call add(s:V.special_buffers, b)
    endif
  endfor

  " make buftab string
  for bnr in bufs
    let n = index(bufs, bnr) + 1       "tab buffer index

    let tab = { 'nr': bnr,
              \ 'n': n,
              \ 'tried_devicon': 0,
              \ 'tried_icon': 0,
              \ 'has_icon': 0,
              \ 'separators': s:Sets.bufline_separators,
              \ 'path': bufname(bnr),
              \ 'indicator': s:buf_indicator(bnr),
              \ 'hilite' : currentbuf == bnr ? 'Current' : bufwinnr(bnr) > 0 ? 'Active' : 'Hidden'
              \}

    if currentbuf == bnr | let [centerbuf, s:centerbuf] = [bnr, bnr] | endif

    if strlen(tab.path) && !s:V.buftail
      let tab.path  = fnamemodify(tab.path, ':p:~:.')

    elseif strlen(tab.path)
      let tab.path  = fnamemodify(tab.path, ':t')

    elseif !s:scratch(bnr)       " unnamed file
      let tab.name = '[ Unnamed ]'
    endif
    let tabs += [tab]
  endfor

  " now keep the current buffer center-screen as much as possible:

  " 1. setup
  let lft = { 'lasttab':  0, 'cut':  '.', 'indicator': '<', 'width': 0, 'half': &columns / 2 }
  let rgt = { 'lasttab': -1, 'cut': '.$', 'indicator': '>', 'width': 0, 'half': &columns - lft.half }

  " 2. sum the string lengths for the left and right halves
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
  if currentside is lft " centered buffer not seen?
    " then blame any overflow on the right side, to protect the left
    let [lft.width, rgt.width] = [0, lft.width]
  endif

  " 3. toss away tabs and pieces until all fits:
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
  return swallowclicks . join(map(tabs,'printf("%%#XBufLine%s#%s",v:val.hilite,strtrans(v:val.label))'),'') . '%#XBufLineFill#'
endfun
"}}}

" Formatting function{{{
" =============================================================================

fun! s:format_buffer(buf)
  let fmt = s:buffer_has_format(a:buf)? s:B()[a:buf.nr].format : s:Sets.bufline_format
  let chars = s:fmt_chars(fmt)

  let out = []
  for c in chars
    let C = nr2char(c)
    "custom tab icon, if tab has a name and/or icon has been defined
    if     C ==# 'l' | let C = s:get_buf_name(a:buf)
    elseif C ==# 'n' | let C = s:unicode_nrs(a:buf.n)
    elseif C ==# 'N' | let C = a:buf.n
    elseif C ==# '+' | let C = a:buf.indicator
    elseif C ==# 'f' | let C = a:buf.path
    elseif C ==# 'i' | let C = s:get_dev_icon(a:buf)
    elseif C ==# 'I' | let C = s:get_buf_icon(a:buf)
    elseif C ==# '<' | let C = s:needs_separator(a:buf)? a:buf.separators[0] : ''
    elseif C ==# '>' | let C = a:buf.separators[1]
    endif
    call add(out, C)
  endfor
  return join(out, '')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:buf_indicator(bnr)
  let mods = s:Sets.bufline_indicators | let nr = a:bnr
  let mod = index(s:pinned(), nr) >= 0 ? mods.pinned : ''
  if getbufvar(nr, '&mod')
    return (mod . mods.modified)
  elseif s:nomod(nr)
    return ''
  elseif s:scratch(nr)
    return (mod . mods.scratch)
  elseif !getbufvar(nr, '&ma')
    return (mod . mods.readonly)
  else
    return mod
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_buf_name(buf)
  """Return custom buffer name, if it has been set, otherwise the filename."""
  let bufs = s:B()
  let nr = a:buf.nr
  if !has_key(bufs, nr)         | return a:buf.path | endif
  if !has_key(bufs[nr], 'name') | return a:buf.path | endif
  return bufs[nr].name
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_dev_icon(buf)
  """Return preferably devicon for buffer, or custom icon if present."""
  let a:buf.tried_devicon = 1
  if g:loaded_webdevicons &&
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

"}}}}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""



"Taboo {{{
"" =============================================================================
" File: taboo.vim
" Description: A little plugin for managing the vim tabline
" Mantainer: Giacomo Comitti (https://github.com/gcmt)
" Url: https://github.com/gcmt/taboo.vim
" License: MIT
" =============================================================================

" Init{{{
" =============================================================================
if v:version < 702
  finish
endif
let g:loaded_taboo = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

" Main command{{{
" =============================================================================

" To construct the tabline string for terminal vim.
fun! xtabline#render#tabs()
  let tabline = ''
  let fmt_unnamed = s:fmt_chars(s:Sets.tab_format)
  let fmt_renamed = s:fmt_chars(s:Sets.renamed_tab_format)

  for i in s:tabs()
    let tabline .= i == tabpagenr() ? '%#XTabLineSel#' : '%#XTabLine#'
    let tabline .= '%' . i . 'T'
    let fmt = empty(s:tabname(i)) ? fmt_unnamed : fmt_renamed
    let tabline .= s:format_tab(i, fmt)
  endfor

  let tabline .= '%#XTabLineFill#%T'
  let tabline .= '%=%#XTabLine#%999X' . s:Sets.close_tabs_label
  return tabline
endfun
"}}}

" Functions for formatting the tab title{{{
" =============================================================================

fun! s:fmt_chars(fmt)
  let chars = []
  for i in range(strchars(a:fmt))
    call add(chars, strgetchar(a:fmt, i))
  endfor
  return chars
endfun

fun! s:format_tab(tabnr, fmt)
  let out = []
  for c in a:fmt
    let C = nr2char(c)
    "custom tab icon, if tab has a name and/or icon has been defined
    if C == '-'
      let icon = s:get_tab_icon(a:tabnr)
      let C = a:tabnr == tabpagenr()? icon[0] : icon[1]
    elseif C ==# 'n' | let C = s:tabnum(a:tabnr, 0)
    elseif C ==# 'N' | let C = s:tabnum(a:tabnr, 1)
    elseif C ==# 'w' | let C = s:wincount(a:tabnr, 0)
    elseif C ==# 'W' | let C = s:wincount(a:tabnr, 1)
    elseif C ==# 'u' | let C = s:wincountUnicode(a:tabnr, 0)
    elseif C ==# 'U' | let C = s:wincountUnicode(a:tabnr, 1)
    elseif C ==# '+' | let C = s:modflag(a:tabnr)
    elseif C ==# 'l' | let C = s:tabname(a:tabnr)
    elseif C ==# 'f' | let C = s:bufname(a:tabnr)
    elseif C ==# 'a' | let C = s:bufpath(a:tabnr)
    elseif C ==# 'P' | let C = s:tabcwd(a:tabnr)
    elseif C ==# '0' | let C = s:short_cwd(a:tabnr, 0)
    elseif C ==# '1' | let C = s:short_cwd(a:tabnr, 1)
    elseif C ==# '2' | let C = s:short_cwd(a:tabnr, 2)
    endif
    call add(out, C)
  endfor
  return join(out, '')
endfun

fun! s:short_cwd(tabnr, h)
  if !a:h
    return fnamemodify(expand(s:X.Tabs[a:tabnr-1].cwd), ":t")
  else
    let H = fnamemodify(expand(s:X.Tabs[a:tabnr-1].cwd), ":~")
    while count(H, "/") > a:h
      let H = substitute(H, "/[^/]*", "\.", "")
    endwhile
    return H
endfun

fun! s:tabnum(tabnr, ubiquitous)
  if a:ubiquitous
    return a:tabnr
  endif
  return a:tabnr == tabpagenr() ? a:tabnr : ''
endfun

fun! s:wincount(tabnr, ubiquitous)
  let windows = tabpagewinnr(a:tabnr, '$')
  if a:ubiquitous
    return windows
  endif
  return a:tabnr == tabpagenr() ? windows : ''
endfun

fun! s:wincountUnicode(tabnr, ubiquitous)
  let buffers_number = tabpagewinnr(a:tabnr, '$')
  if a:ubiquitous
    return s:unicode_nrs(buffers_number)
  else
    return a:tabnr == tabpagenr() ? s:unicode_nrs(buffers_number) : ''
  endif
endfun

fun! s:modflag(tabnr)
  for buf in tabpagebuflist(a:tabnr)
    if getbufvar(buf, "&mod")
      if a:tabnr == tabpagenr()
        return "%#XTabLineSelMod#"
              \. s:Sets.modified_tab_flag
              \. "%#XTabLineSel#"
      else
        return "%#XTabLineMod#"
              \. s:Sets.modified_tab_flag
              \. "%#XTabLine#"
      endif
    endif
  endfor
  return ""
endfun

fun! s:bufname(tabnr)
  let buffers = tabpagebuflist(a:tabnr)
  let buf = s:first_normal_buffer(buffers)
  let bname = bufname(buf > -1 ? buf : buffers[0])
  if !empty(bname)
    return s:basename(bname)
  endif
  return s:Sets.unnamed_tab_label
endfun

fun! s:bufpath(tabnr)
  let buffers = tabpagebuflist(a:tabnr)
  let buf = s:first_normal_buffer(buffers)
  let bname = bufname(buf > -1 ? buf : buffers[0])
  if !empty(bname)
    return fnamemodify(bname, ':~')
  endif
  return s:Sets.unnamed_tab_label
endfun

fun! s:get_tab_icon(tabnr)
  if !s:V.show_tab_icons
    return get(s:Sets, 'tab_icon', ["📂", "📁"]) | endif

  let T = s:X.Tabs[a:tabnr-1]
  let icon = s:has_tab_icon(T)

  return !empty(icon) ? icon :
       \ !empty(T.name) && !empty(s:Sets.default_named_tab_icon) ?
       \   s:Sets.default_named_tab_icon :
       \   get(s:Sets, 'tab_icon', ["📂", "📁"])
endfun

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
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""






" Helpers{{{
" =============================================================================

fun! s:tabs()
  return range(1, tabpagenr('$'))
endfun

fun! s:tabcwd(tabnr)
  return s:X.Tabs[a:tabnr-1].cwd
endfun

fun! s:tabname(tabnr)
  if s:V.show_tab_icons
    return s:X.Tabs[a:tabnr-1].name
  else
    return s:short_cwd(a:tabnr, 2)
  endif
endfun

fun! s:windows(tabnr)
  return range(1, tabpagewinnr(a:tabnr, '$'))
endfun

fun! s:basename(name)
  return fnamemodify(a:name, ':p:t')
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

fun! s:is_special_buffer(nr)
  """Customize special buffers.
  let bufs = s:B()

  if s:Is(a:nr, "fugitive")      "fugitive buffer, set name and icon
    let bufs[a:nr] = s:Bd('fugitive', s:Sets.custom_icons.git)
    return 1

  elseif s:Ft(a:nr, "GV")
    let bufs[a:nr] = s:Bd('GV', s:Sets.custom_icons.git)
    return 1

  elseif s:Ft(a:nr, "magit")
    let bufs[a:nr] = s:Bd('Magit', s:Sets.custom_icons.git)
    return 1
  endif
endfun

"}}}
