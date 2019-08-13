" BufTabLine credits {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Description: Vim global plugin for rendering the buffer list in the tabline
" Mantainer:   Aristotle Pagaltzis <pagaltzis@gmx.de>
" Url:         https://github.com/ap/vim-buftabline
" Licence:     The MIT License (MIT)
" Copyright:   (c) 2015 Aristotle Pagaltzis <pagaltzis@gmx.de>
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Taboo credits {{{1
"" =============================================================================
" File: taboo.vim
" Description: A little plugin for managing the vim tabline
" Mantainer: Giacomo Comitti (https://github.com/gcmt)
" Url: https://github.com/gcmt/taboo.vim
" License: MIT
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables and lambdas {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X    = g:xtabline
let s:v    = g:xtabline.Vars
let s:F    = g:xtabline.Funcs
let s:Sets = g:xtabline_settings

let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:B =  { -> s:X.Buffers             }       "customized buffers
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:eB = { -> s:T().buffers.extra     }       "extra buffers for tab
let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab

let s:special = { nr -> s:B()[nr].special }
let s:refilter = 0
let s:mod_width = 0

let s:Hi        = { -> g:xtabline_highlight.themes[s:Sets.theme] }
let s:is_open   = { n -> s:F.has_win(n) && index(s:vB(), n) < 0 && getbufvar(n, "&ma") }
let s:is_extra  = { n -> index(s:eB(), n) >= 0 }

let s:dirsep            = fnamemodify(getcwd(),':p')[-1:]
let s:centerbuf         = winbufnr(0)
let s:is_current_buf    = { nr -> nr == winbufnr(0)                                           }
let s:scratch           = { nr -> index(['nofile','acwrite'], getbufvar(nr, '&buftype')) >= 0 }
let s:nowrite           = { nr -> !getbufvar(nr, '&modifiable')                               }
let s:pinned            = { -> s:X.pinned_buffers                                             }
let s:buffer_has_format = { buf -> has_key(s:B()[buf.nr], 'format')                           }
let s:has_buf_icon      = { nr -> !empty(get(s:B()[nr], 'icon', ''))                          }
let s:extraHi           = { b -> s:is_extra(b) || s:is_open(b) || index(s:pinned(), b) >= 0   }
let s:specialHi         = { b -> s:B()[b].special                                             }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Main functions {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:v.time_to_update = 1
let s:last_modified_state = { winbufnr(0): &modified }

" The tabline is refreshed rather often by vim (TextChanged, InsertEnter, etc)
" We want to update it less often, mostly on buffer enter/write and when
" a buffer has been modified. We store the last rendered tabline, and if
" there's no need to reprocess it, just return the old string

fun! xtabline#render#tabline() abort "{{{2
  if !s:ready() | return g:xtabline.last_tabline | endif
  call xtabline#tab#check_index()
  let currentbuf = winbufnr(0)

  " no room for a full tabline
  if &columns < 40 | return s:get_label_for_right_corner()[0] | endif

  let changed_modified_state =
        \ !has_key(s:last_modified_state, currentbuf) ||
        \ &modified != s:last_modified_state[currentbuf]

  if changed_modified_state || exists('s:v.time_to_update')
    let s:last_modified_state[currentbuf] = &modified
    silent! unlet s:v.time_to_update
  else
    return g:xtabline.last_tabline
  endif

  if s:v.tabline_mode == 'tabs'
    return s:render_tabs()
  else
    return s:render_buffers()
  endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:render_tabs() abort "{{{2
  let centerlabel = tabpagenr()
  let tabs = []
  let labels = range(1, tabpagenr('$'))

  let fmt_unnamed = s:fmt_chars(s:Sets.tab_format)
  let fmt_renamed = s:fmt_chars(s:Sets.named_tab_format)

  for tnr in labels
    if tnr == tabpagenr() | let centerlabel = tnr | endif
    let hi = tnr == tabpagenr() ? 'TabActive' : 'TabInactive'
    let label = printf('%%#XT%s#', hi) . '%' . tnr . 'T'
    if !s:Sets.use_tab_cwd || get(s:Sets, 'tabs_show_bufname', 0)
      let buflist = tabpagebuflist(tnr)
      let winnr = tabpagewinnr(tnr)
      let bname = bufname(buflist[winnr - 1])
      let label .= printf("%s %s ", s:tabnum(tnr, 1), s:F.short_cwd(tnr, 0, bname))
    else
      let fmt = empty(s:tabname(tnr)) ? fmt_unnamed : fmt_renamed
      let label .= s:format_tab(tnr, fmt)
    endif
    call add(tabs, {'label': label, 'nr': tnr, 'hilite': hi})
  endfor

  return s:fit_tabline(centerlabel, tabs)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:render_buffers() abort "{{{2
  call xtabline#filter_buffers() " filter buffers is called only from here
  let centerlabel = s:centerbuf " prevent tabline jumping around when non-user buffer current (e.g. help)
  let currentbuf = winbufnr(0)

  " pick up data on all the buffers
  let tabs = []
  let Tab  = s:T()

  if s:v.tabline_mode == 'buffers'
    let labels = s:oB()
    let max = get(s:Sets, 'recent_buffers', 10)
    call filter(labels, 'bufexists(v:val)')

    "limiting to x most recent buffers, if option is set; here we consider only
    "valid buffers, special/extra/etc will be added later
    if max > 0
      let recent = Tab.buffers.recent[:(max-1)]
      call filter(labels, 'index(recent, v:val) >= 0')
    endif

    "put current buffer first
    if s:Sets.last_open_first
      let i = index(labels, currentbuf)
      if i >= 0
        call remove(labels, i)
        call insert(labels, currentbuf, 0)
      endif
    endif

    "include special buffers (upfront)
    let front = [] | let specials = []
    for b in s:F.wins()
      if s:B()[b].special
        call add(specials, b)
      elseif s:is_open(b)
        call add(front, b)
      endif
    endfor

    "put upfront: special > pinned > open > extra buffers
    for b in ( s:eB() + front + s:pinned() + specials )
      call s:F.add_ordered(b, 1)
    endfor
  else
    let labels = s:F.uniq(map(argv(), 'bufnr(v:val)'))
    call filter(labels, 'bufexists(v:val)')
  endif

  "no need to render more than 20 buffers at a time, since they'll be offscreen
  let begin = 0
  if len(labels) > 20
    let curr = index(labels, currentbuf)
    let max  = len(labels) - 1
    if curr < 10
      let end   = 20
    elseif curr < ( max - 10 )
      let begin = curr - 10
      let end   = begin + 20
    else
      let begin = max - 20
      let end   = max
    endif
    let labels  = labels[begin:end]
  endif

  " get the default buffer format, and set its type
  let s:default_buffer_format = s:get_default_buffer_format()

  " make tabline string
  for bnr in labels
    let special = s:specialHi(bnr)
    let scratch = s:scratch(bnr)

    " exclude special buffers without window, or non-special scratch buffers
    if special && !s:F.has_win(bnr) | continue
    elseif scratch && !special      | continue | endif

    let n = index(labels, bnr) + 1 + begin       "tab buffer index
    let is_currentbuf = currentbuf == bnr

    let tab = { 'nr': bnr,
          \ 'n': n,
          \ 'tried_devicon': 0,
          \ 'tried_icon': 0,
          \ 'has_icon': 0,
          \ 'path': &columns < 150 || !Tab.rpaths ? fnamemodify(bufname(bnr), ':t')
          \                                       : s:F.short_path(bnr, Tab.rpaths),
          \ 'hilite':   is_currentbuf && special  ? 'Special' :
          \             is_currentbuf             ? 'Select' :
          \             special || s:extraHi(bnr) ? 'Extra' :
          \             s:F.has_win(bnr)          ? 'Visible' : 'Hidden'
          \}

    let tab.label = s:format_buffer(tab)

    if type(s:Sets.bufline_format) == v:t_number
      let tab.path = s:get_buf_name(tab)
    else
      let tab.path = fnamemodify(bufname(bnr), (Tab.rpaths ? ':p:~:.' : ':t'))
      let tab.separators = s:buf_separators(bnr)
      let tab.indicator = s:buf_indicator(bnr)
    endif

    if is_currentbuf | let [centerlabel, s:centerbuf] = [bnr, bnr] | endif

    let tabs += [tab]
  endfor

  return s:fit_tabline(centerlabel, tabs)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:fit_tabline(centerlabel, tabs) abort "{{{2
  " toss away tabs and pieces until all fits
  let [active_tab, tab_width] = s:get_label_for_right_corner()
  let Tabs = a:tabs

  " limit is the max bufline length
  let limit = &columns - tab_width - 1

  " now keep the current buffer center-screen as much as possible
  let L = { 'lasttab':  0, 'cut':  '.', 'indicator': '<', 'width': 0, 'half': limit / 2 }
  let R = { 'lasttab': -1, 'cut': '.$', 'indicator': '>', 'width': 0, 'half': limit - L.half }

  " sum the string lengths for the left and right halves
  let currentside = L
  for tab in Tabs
    let tab.width = strwidth(substitute(tab.label, '%#\w*#', '', 'g'))
    if a:centerlabel == tab.nr
      let halfwidth = tab.width / 2
      let L.width += halfwidth
      let R.width += tab.width - halfwidth
      let currentside = R
      continue
    endif
    let currentside.width += tab.width
  endfor

  if currentside is L " centered buffer not seen?
    let [L.width, R.width] = [0, L.width]
  endif

  let left_has_been_cut = 0
  let right_has_been_cut = 0

  if ( L.width + R.width ) > limit
    while limit - ( L.width + R.width ) < 0
      " remove a tab from the biggest side
      if L.width <= R.width
        let right_has_been_cut = 1
        let R.width -= remove(Tabs, -1).width
      else
        let left_has_been_cut = 1
        let L.width -= remove(Tabs, 0).width
      endif
    endwhile
    if left_has_been_cut
      let lab = substitute(Tabs[0].label, '%#X\w*#', '', 'g')
      let Tabs[0].label = printf('%%#DiffDelete# < %%#XT%s#%s', Tabs[0].hilite, strcharpart(lab, 3))
    endif
    if right_has_been_cut
      let Tabs[-1].label = printf('%s%%#DiffDelete# > ', Tabs[-1].label[:-4])
    endif
  endif

  let buffers = join(map(Tabs,'v:val.label'),'')
  let padding = s:extra_padding(L.width + R.width, limit)
  let g:xtabline.last_tabline = buffers . padding . active_tab . '%999X'
  return g:xtabline.last_tabline
endfun "}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer label formatting {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:format_buffer(buf) abort "{{{2
  let [ B, fmt ] = [ a:buf, s:default_buffer_format ]
  if s:buffer_has_format(B)
    let chars = s:fmt_chars(s:B()[B.nr].format)
  elseif fmt.simple
    let mod = index(s:pinned(), B.nr) >= 0 ? ' '.s:Sets.bufline_indicators.pinned : ''
    let mod .= (getbufvar(B.nr, "&modified") ? " [+] " : " ")
    let hi = printf(" %%#XT%s# ", B.hilite)
    let ic = s:get_buf_icon(B)
    let bn = fmt.simple == 2 ? B.n : B.nr
    let nu = winbufnr(0) == B.nr ? ("%#XTNumSel# " . bn) : ("%#XTNum# " . bn)
    let st = nu . hi . ic . B.path . mod
    return st
  elseif fmt.is_func
    return fmt.content(B.nr)
  else
    let chars = fmt.content
  endif

  let out = []
  for c in chars
    let C = nr2char(c)
    "custom tab icon, if tab has a name and/or icon has been defined
    if     C ==# 'l' | let C = s:get_buf_name(B)
    elseif C ==# 'n' | let C = s:unicode_nrs(B.n)
    elseif C ==# 'N' | let C = B.n
    elseif C ==# '+' | let C = B.indicator
    elseif C ==# 'f' | let C = B.path
    elseif C ==# 'i' | let C = s:get_dev_icon(B)
    elseif C ==# 'I' | let C = s:get_buf_icon(B)
    elseif C ==# '<' | let C = s:needs_separator(B)? B.separators[0] : ''
    elseif C ==# '>' | let C = B.separators[1]
    endif
    call add(out, C)
  endfor
  let st = join(out, '')
  let hi = '%#XT' . B.hilite . '#'
  return hi.st
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:buf_indicator(bnr) abort "{{{2
  let mods = s:Sets.bufline_indicators | let nr = a:bnr
  let mod = index(s:pinned(), nr) >= 0 ? mods.pinned : ''
  let modHi = s:is_current_buf(nr) ? "%#XTSelectMod#" :
        \     s:extraHi(nr)        ? "%#XTExtraMod#" :
        \     bufwinnr(nr) > 0     ? "%#XTVisibleMod#" : "%#XTHiddenMod#"
  if getbufvar(nr, '&mod')
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

fun! s:buf_separators(nr) abort "{{{2
  """Use custom separators if defined in buffer entry."""
  let B = s:B()[a:nr]
  return has_key(B, 'separators') ? B.separators : s:Sets.bufline_separators
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_buf_name(buf) abort "{{{2
  """Return custom buffer name, if it has been set, otherwise the filename."""
  let B = s:B()[a:buf.nr]
  return !empty(B.name)       ? B.name :
        \ empty( a:buf.path ) ? s:Sets.bufline_unnamed : a:buf.path
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_dev_icon(buf) abort "{{{2
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

fun! s:get_buf_icon(buf) abort "{{{2
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

fun! s:needs_separator(buf) abort "{{{2
  """Verify if a separator must be inserted."""
  let either_or = s:Sets.bufline_sep_or_icon
  return (either_or && !a:buf.has_icon) || !either_or
endfun "}}}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tab label formatting {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:fmt_chars(fmt) abort "{{{2
  """Return a split string with the formatting option in use.
  let chars = []
  for i in range(strchars(a:fmt))
    call add(chars, strgetchar(a:fmt, i))
  endfor
  return chars
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:format_tab(tabnr, fmt) abort "{{{2
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
    elseif C =~ '\d' | let C = s:F.short_cwd(a:tabnr, C)
    endif
    call add(out, C)
  endfor
  return join(out, '')
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tabnum(tabnr, all) abort "{{{2
  if a:all && s:v.tabline_mode != 'tabs'
    let hi = has_key(s:T(), 'dir') ? " %#XTNumSel#" : " %#XTTabInactive#"
    return "%#XTNumSel# " . a:tabnr .'/' . tabpagenr('$') . hi
  else
    return a:tabnr == tabpagenr() ?
          \   "%#XTNumSel# " . a:tabnr . " %#XTTabActive#"
          \ : "%#XTNum# "    . a:tabnr . " %#XTTabInactive#"
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:wincount(tabnr, all) abort "{{{2
  return a:all || a:tabnr == tabpagenr() ?
        \tabpagewinnr(a:tabnr, '$') : ''
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:wincountUnicode(tabnr, all) abort "{{{2
  let buffers_number = s:unicode_nrs(tabpagewinnr(a:tabnr, '$'))
  return a:all || a:tabnr == tabpagenr() ? buffers_number : ''
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:modflag(tabnr) abort "{{{2
  let flag = s:Sets.modified_tab_flag
  for buf in tabpagebuflist(a:tabnr)
    if getbufvar(buf, "&mod")
      return a:tabnr == tabpagenr() ?
              \ "%#XTHiddenMod#"  . flag . "%#XTHidden#" :
              \ "%#XTVisibleMod#" . flag . "%#XTVisible#"
    endif
  endfor
  return ""
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bufname(tabnr) abort "{{{2
  let buffers = tabpagebuflist(a:tabnr)
  let buf = s:first_normal_buffer(buffers)
  let bname = bufname(buf > -1 ? buf : buffers[0])
  if !empty(bname)
    return s:basename(bname)
  endif
  return s:Sets.unnamed_tab_label
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bufpath(tabnr) abort "{{{2
  let buffers = tabpagebuflist(a:tabnr)
  let buf = s:first_normal_buffer(buffers)
  let bname = bufname(buf > -1 ? buf : buffers[0])
  if !empty(bname)
    return fnamemodify(bname, ':~')
  endif
  return s:Sets.unnamed_tab_label
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_tab_icon(tabnr) abort "{{{2
  if !s:v.custom_tabs | return s:Sets.tab_icon | endif

  let T = s:X.Tabs[a:tabnr-1]
  let icon = s:has_tab_icon(T)

  return !empty(icon) ? icon :
       \ !empty(T.name) ? s:Sets.named_tab_icon : s:Sets.tab_icon
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:has_tab_icon(T) abort "{{{2
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
endfun "}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:tabcwd = { n -> s:X.Tabs[n-1].cwd }
let s:windows = { n -> range(1, tabpagewinnr(n, '$')) }
let s:basename = { f -> fnamemodify(f, ':p:t') }

"------------------------------------------------------------------------------

fun! s:tabname(tabnr) abort "{{{2
  if s:v.custom_tabs
    return s:X.Tabs[a:tabnr-1].name
  else
    return s:short_cwd(a:tabnr, 2)
  endif
endfun

"------------------------------------------------------------------------------

fun! s:first_normal_buffer(buffers) abort "{{{2
  for buf in a:buffers
    if buflisted(buf) && getbufvar(buf, "&bt") != 'nofile'
      return buf
    end
  endfor
  return -1
endfun

"------------------------------------------------------------------------------

fun! s:get_default_buffer_format() abort "{{{2
  " get the default buffer format, and set its type, either:
  " - funcref
  " - format string
  " - number (1 to show bufnr, 2 to show buffer order)
  let fmt = { 'is_func': 0, 'simple': 0 }
  if type(s:Sets.bufline_format) == v:t_func
    let fmt.is_func = 1
    let fmt.content = s:Sets.bufline_format
  elseif type(s:Sets.bufline_format) == v:t_string
    let fmt.content = s:fmt_chars(s:Sets.bufline_format)
  elseif type(s:Sets.bufline_format) == v:t_number
    let fmt.simple = s:Sets.bufline_format
  endif
  return fmt
endfun

"------------------------------------------------------------------------------

let s:unr1 = [ '₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉', '₁₀',
      \'₁₁', '₁₂', '₁₃', '₁₄', '₁₅', '₁₆', '₁₇', '₁₈', '₁₉', '₂₀',
      \'₂₁', '₂₂', '₂₃', '₂₄', '₂₅', '₂₆', '₂₇', '₂₈', '₂₉', '₃₀' ]

let s:unr2 = [ '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹', '¹⁰',
      \'¹¹', '¹²', '¹³', '¹⁴', '¹⁵', '¹⁶', '¹⁷', '¹⁸', '¹⁹', '²⁰',
      \'²¹', '²²', '²³', '²⁴', '²⁵', '²⁶', '²⁷', '²⁸', '²⁹', '³⁰' ]

fun! s:unicode_nrs(nr) abort "{{{2
  """Adapted from Vim-CtrlSpace (https://github.com/szw/vim-ctrlspace)
  let u_nr = ""

  if !s:Sets.superscript_unicode_nrs && a:nr < 31
    return s:unr1[a:nr-1]
  elseif a:nr < 31
    return s:unr2[a:nr-1]
  elseif !s:Sets.superscript_unicode_nrs
    let small_numbers = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
  else
    let small_numbers = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
  endif
  let number_str = string(a:nr)

  for i in range(0, len(number_str) - 1)
    let u_nr .= small_numbers[str2nr(number_str[i])]
  endfor

  return u_nr
endfun

"------------------------------------------------------------------------------

fun! s:get_label_for_right_corner() abort "{{{2
  """Build string with tab label and icon for the bufline."""
  let N = tabpagenr()

  "TODO: a right side corner for the tabs mode
  if s:v.tabline_mode == 'tabs'
    return ['', 0]
  elseif s:v.tabline_mode == 'arglist'
    let [ n, N ] = [ index(argv(), bufname(bufnr('%'))) + 1, len(argv()) ]
    let num = "%#XTNumSel# " . n .'/' . N . " "
    let fmt_tab = num . "%#XTSelect# arglist" . " %#XTTabInactive#"
  elseif ! s:Sets.show_current_tab
    let fmt_tab = s:tabnum(N, 1)
  elseif s:Sets.use_tab_cwd == 0
    let buflist = tabpagebuflist(N)
    let winnr = tabpagewinnr(N)
    let bname = bufname(buflist[winnr - 1])
    let fmt_tab = printf("%s %s ", s:tabnum(N, 1), s:F.short_cwd(N, 0, bname))
  else
    let fmt = empty(s:tabname(N)) ? s:Sets.bufline_tab_format : s:Sets.bufline_named_tab_format
    let fmt_chars = s:fmt_chars(fmt)                         "formatting options
    let fmt_tab = s:format_tab(N, fmt_chars)                 "formatted string
  endif
  let label = substitute(fmt_tab, '%#\w*#', '', 'g')         "text only, to find width
  return [fmt_tab, strwidth(label)]
endfun

"------------------------------------------------------------------------------

fun! s:extra_padding(l_r, limit) abort "{{{2
  return a:l_r < a:limit ? '%#XTFill#'.repeat(' ', a:limit - a:l_r) : ''
endfun

"------------------------------------------------------------------------------

fun! s:ready() abort "{{{2
   return !exists('g:SessionLoad')
endfun "}}}

