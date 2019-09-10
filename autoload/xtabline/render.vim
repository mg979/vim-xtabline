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

let s:T  = { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:Tn = { n -> s:X.Tabs[n-1]         }       "tab n
let s:B  = { -> s:X.Buffers             }       "customized buffers
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
let s:show_bufname      = { -> !s:Sets.use_tab_cwd || get(s:Sets, 'tabs_show_bufname', 1)     }
let s:strwidth          = { label -> strwidth(substitute(label, '%#\w*#\|%\d\+T', '', 'g'))   }

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
  call xtabline#tab#check_all()
  call xtabline#tab#check_index()
  call xtabline#filter_buffers() " filter buffers is called only from here
  let currentbuf = winbufnr(0)

  " no room for a full tabline
  if &columns < 40 | return s:format_right_corner() | endif

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

  for tnr in labels
    if tnr == tabpagenr() | let centerlabel = tnr | endif

    let hi     = tnr == tabpagenr() ? 'TabActive' : 'TabInactive'
    let label  = printf('%%#XT%s#', hi) . '%' . tnr . 'T'
    let label .= s:format_tab_label(tnr)

    call add(tabs, {'label': label, 'nr': tnr, 'hilite': hi})
  endfor

  return s:fit_tabline(centerlabel, tabs)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:render_buffers() abort "{{{2
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
    let special = s:special(bnr)
    let scratch = s:scratch(bnr)
    let extra   = s:extraHi(bnr)

    " exclude special buffers without window, or non-special scratch buffers
    if special && !s:F.has_win(bnr) | continue
    elseif scratch && !special      | continue | endif

    let n = index(labels, bnr) + 1 + begin       "tab buffer index
    let is_currentbuf = currentbuf == bnr

    let buf = { 'nr': bnr,
          \ 'n': n,
          \ 'has_icon': 0,
          \ 'path': &columns < 150 || !Tab.rpaths ? fnamemodify(bufname(bnr), ':t')
          \                                       : s:F.short_path(bnr, Tab.rpaths),
          \ 'hilite':   is_currentbuf && special  ? 'Special' :
          \             is_currentbuf             ? 'Select' :
          \             special || extra          ? 'Extra' :
          \             s:F.has_win(bnr)          ? 'Visible' : 'Hidden'
          \}

    if !s:buffer_has_format(buf) && type(s:Sets.buffer_format) == v:t_number
      let buf.path = s:get_buf_name(buf)
    else
      let buf.path = fnamemodify(bufname(bnr), (Tab.rpaths ? ':p:~:.' : ':t'))
      let buf.separators = s:buf_separators(bnr)
      let buf.indicator = s:buf_indicator(bnr)
    endif

    if is_currentbuf | let [centerlabel, s:centerbuf] = [bnr, bnr] | endif

    let buf.label = s:format_buffer(buf)
    let tabs += [buf]
  endfor

  return s:fit_tabline(centerlabel, tabs)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:fit_tabline(centerlabel, tabs) abort "{{{2
  " toss away tabs and pieces until all fits
  let corner_label = s:format_right_corner()
  let corner_width = s:strwidth(corner_label)
  let Tabs = a:tabs

  " limit is the max bufline length
  let limit = &columns - corner_width - 1

  " now keep the current buffer center-screen as much as possible
  let L = { 'lasttab':  0, 'cut':  '.', 'indicator': '<', 'width': 0, 'half': limit / 2 }
  let R = { 'lasttab': -1, 'cut': '.$', 'indicator': '>', 'width': 0, 'half': limit - L.half }

  " sum the string lengths for the left and right halves
  let currentside = L
  for tab in Tabs
    let tab.width = s:strwidth(tab.label)
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

  let labels = map(Tabs,'v:val.label')
  if s:v.tabline_mode == 'tabs'
    "FIXME: it works like this, but it's adding the %nT part for the second
    "time, for some reason it doesn't work anymore if I only add it here
    for n in range(len(labels))
      let labels[n] = '%' . (n+1) . 'T' . labels[n]
    endfor
  endif
  let labels = join(labels, '')
  let padding = s:extra_padding(L.width + R.width, limit)
  let g:xtabline.last_tabline = labels . padding . corner_label . '%999X'
  return g:xtabline.last_tabline
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Label formatting {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:flat_buffer(buf) abort "{{{2
  let B = a:buf

  let mod    = index(s:pinned(), B.nr) >= 0 ? ' '.s:Sets.bufline_indicators.pinned : ''
  let mod   .= (getbufvar(B.nr, "&modified") ? " [+] " : " ")

  let hi     = printf(" %%#XT%s# ", B.hilite)
  let icon   = s:get_buf_icon(B)
  let bn     = s:Sets.buffer_format == 2 ? B.n : B.nr
  let number = winbufnr(0) == B.nr ? ("%#XTNumSel# " . bn) : ("%#XTNum# " . bn)

  return number . hi . icon . B.path . mod
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:format_buffer_label(item, chars) abort "{{{2
  let out = []
  let I = a:item
  for c in a:chars
    let C = c
    "custom tab icon, if tab has a name and/or icon has been defined
    if     C == 32  | let C = ' '
    elseif C == 108 | let C = s:get_buf_name(I)                             "l
    elseif C == 117 | let C = s:unicode_nrs(I.n)                            "u
    elseif C == 78  | let C = I.n                                           "N
    elseif C == 110 | let C = I.nr                                          "n
    elseif C == 43  | let C = I.indicator                                   "+
    elseif C == 102 | let C = I.path                                        "f
    elseif C == 73  | let C = s:get_buf_icon(I)                             "i
    elseif C == 60  | let C = !I.has_icon ? I.separators[0] : ''            "<
    elseif C == 62  | let C = I.separators[1]                               ">
    endif
    call add(out, C)
  endfor
  let st = join(out, '')
  let hi = '%#XT' . I.hilite . '#'
  return hi.st
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:format_tab_label(tabnr) abort "{{{2
  let nr    = s:tabnum(a:tabnr, 1)
  let icon  = s:get_tab_icon(a:tabnr, 0)
  let mod   = s:modflag(a:tabnr)
  let label = s:tab_label(a:tabnr, 0)

  return printf("%s %s%s%s ", nr, icon, label, mod)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:format_right_corner() abort "{{{2
  """Build string with tab label and icon for the bufline.
  let N = tabpagenr()

  if s:v.tabline_mode == 'arglist'
    let [ n, N ]  = [ index(argv(), bufname(bufnr('%'))) + 1, len(argv()) ]
    let num       = "%#XTNumSel# " . n .'/' . N . " "
    return num . "%#XTSelect# arglist" . " %#XTTabInactive#"

  elseif !s:Sets.show_right_corner
    return s:tabnum(N, 1)

  elseif s:v.tabline_mode == 'tabs'
    let icon      = "%#XTNumSel# " . s:get_tab_icon(N, 1)
    let name      = "%#XTTabActive# " . s:F.short_cwd(N, 1)
    return icon . name

  elseif !s:Sets.use_tab_cwd && !haslocaldir(-1, tabpagenr())
    " not using per-tab cwd, show the buffer name, unless there is a local cwd
    let buflist   = tabpagebuflist(N)
    let winnr     = tabpagewinnr(N)
    let bname     = bufname(buflist[winnr - 1])
    return printf("%s %s ", s:tabnum(N, 1), s:F.short_cwd(N, 0, bname))

  else
    let nr        = s:tabnum(N, 1)
    let icon      = s:get_tab_icon(N, 1)
    let mod       = s:modflag(N)
    let label     = s:tab_label(N, 1)
    return printf("%s %s%s%s ", nr, icon, label, mod)
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:format_buffer(buf) abort "{{{2
  let [ B, fmt ] = [ a:buf, s:default_buffer_format ]
  if s:buffer_has_format(B)
    let chars = s:fmt_chars(s:B()[B.nr].format)
  elseif fmt.flat
    return s:flat_buffer(B)
  elseif fmt.is_func
    return fmt.content(B.nr)
  else
    let chars = fmt.content
  endif
  return s:format_buffer_label(B, chars)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:buf_indicator(bnr) abort "{{{2
  let mods = s:Sets.bufline_indicators | let nr = a:bnr
  let mod = index(s:pinned(), nr) >= 0 ? mods.pinned : ''
  let modHi = s:is_current_buf(nr) ? "%#XTSelectMod#" :
        \     s:extraHi(nr)        ? "%#XTExtraMod#" :
        \     bufwinnr(nr) > 0     ? "%#XTVisibleMod#" : "%#XTHiddenMod#"
  if s:special(nr)
    return ''
  elseif getbufvar(nr, '&mod')
    return (mod . modHi . mods.modified)
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
  """Use custom separators if defined in buffer entry.
  let B = s:B()[a:nr]
  return has_key(B, 'separators') ? B.separators : s:Sets.bufline_separators
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_buf_name(buf) abort "{{{2
  """Return custom buffer name, if it has been set, otherwise the filename.
  let B = s:B()[a:buf.nr]
  return !empty(B.name)       ? B.name :
        \ empty( a:buf.path ) ? s:Sets.unnamed_buffer : a:buf.path
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_buf_icon(buf) abort "{{{2
  """Return custom icon for buffer, or devicon if present.
  let nr = a:buf.nr
  if s:has_buf_icon(nr)
    let a:buf.has_icon = 1
    let icon = s:B()[nr].icon.' '
  else
    try
      let icon = WebDevIconsGetFileTypeSymbol(bufname(a:buf.nr)).' '
      let a:buf.has_icon = 1
    catch
      return ''
    endtry
  endif
  return icon
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tab label formatting {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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

fun! s:tab_label(tabnr, right_corner) abort "{{{2
  return !empty(s:Tn(a:tabnr).name) ? s:Tn(a:tabnr).name :
        \     !a:right_corner && s:show_bufname() ? s:tabbufname(a:tabnr)
        \     : s:F.short_cwd(a:tabnr, s:Sets.tab_format)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tabbufname(tabnr) abort "{{{2
  let bnr = s:first_normal_buffer(a:tabnr)
  return empty(bufname(bnr)) ? s:Sets.unnamed_tab
        \ : &columns < 150 || !s:Tn(a:tabnr).rpaths ? fnamemodify(bufname(bnr), ':t')
        \ : s:F.short_path(bnr, s:Tn(a:tabnr).rpaths)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_tab_icon(tabnr, right_corner) abort "{{{2
  let icon = s:tab_icon(s:Tn(a:tabnr))
  if !empty(icon) | return icon | endif

  if a:right_corner
    let icon = s:Sets.tab_icon
  elseif s:show_bufname()
    let bnr  = s:first_normal_buffer(a:tabnr)
    let buf  = {'nr': bnr, 'has_icon': 0}
    let icon = s:get_buf_icon(buf)
  else
    return ''
  endif

  return type(icon) == v:t_string ? icon : icon[a:tabnr != tabpagenr()] . ' '
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tab_icon(T) abort "{{{2
  if !has_key(a:T, 'icon') | return | endif
  let I = a:T.icon

  if empty(I)
    return ''
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

fun! s:fmt_chars(fmt) abort "{{{2
  """Return a split string with the formatting option in use.
  let chars = []
  for i in range(strchars(a:fmt))
    call add(chars, strgetchar(a:fmt, i))
  endfor
  return chars
endfun

"------------------------------------------------------------------------------

fun! s:first_normal_buffer(tabnr) abort "{{{2
  let bufs = tabpagebuflist(a:tabnr)
  for buf in bufs
    if buflisted(buf) && getbufvar(buf, "&bt") != 'nofile'
      return bufnr(buf)
    end
  endfor
  return bufnr(bufs[0])
endfun

"------------------------------------------------------------------------------

fun! s:get_default_buffer_format() abort "{{{2
  " get the default buffer format, and set its type, either:
  " - funcref
  " - format string
  " - number (1 to show bufnr, 2 to show buffer order)
  let fmt = { 'is_func': 0, 'flat': 0 }
  if type(s:Sets.buffer_format) == v:t_func
    let fmt.is_func = 1
    let fmt.content = s:Sets.buffer_format
  elseif type(s:Sets.buffer_format) == v:t_string
    let fmt.content = s:fmt_chars(s:Sets.buffer_format)
  elseif type(s:Sets.buffer_format) == v:t_number
    let fmt.flat = s:Sets.buffer_format
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

fun! s:extra_padding(l_r, limit) abort "{{{2
  return a:l_r < a:limit ? '%#XTFill#'.repeat(' ', a:limit - a:l_r) : ''
endfun

"------------------------------------------------------------------------------

fun! s:ready() abort "{{{2
   return !exists('g:SessionLoad')
endfun "}}}

