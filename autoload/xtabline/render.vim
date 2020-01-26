""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables and lambdas {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:X    = g:xtabline
let s:v    = g:xtabline.Vars
let s:F    = g:xtabline.Funcs
let s:Sets = g:xtabline_settings

let s:T  = { -> s:X.Tabs[tabpagenr()-1] }       "current tab
let s:Tn = { n -> s:X.Tabs[n-1]         }       "tab n
let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
let s:eB = { -> s:T().buffers.extra     }       "extra buffers for tab
let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab

let s:buf        = { nr -> get(s:X.Buffers, nr, s:X._buffers[nr]) }
let s:is_special = { nr -> s:buf(nr).special }
let s:is_open    = { n -> s:F.has_win(n) && index(s:vB(), n) < 0 && getbufvar(n, "&ma") }
let s:is_extra   = { n -> index(s:eB(), n) >= 0 }

let s:scratch           = { nr -> index(['nofile','acwrite'], getbufvar(nr, '&buftype')) >= 0 }
let s:pinned            = { -> s:X.pinned_buffers                                             }
let s:buffer_has_format = { buf -> has_key(s:buf(buf.nr), 'format')                           }
let s:has_buf_icon      = { nr -> !empty(get(s:buf(nr), 'icon', ''))                          }
let s:extraHi           = { b -> s:is_extra(b) || s:is_open(b) || index(s:pinned(), b) >= 0   }
let s:strwidth          = { label -> strwidth(substitute(label, '%#\w*#\|%\d\+T', '', 'g'))   }
let s:tab_buffer        = { t -> tabpagebuflist(t)[tabpagewinnr(t)-1]                         }

let s:v.time_to_update = 1
let s:last_modified_state = { winbufnr(0): &modified }
"}}}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Main functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" The tabline is refreshed rather often by vim (TextChanged, InsertEnter, etc)
" We want to update it less often, mostly on buffer enter/write and when
" a buffer has been modified. We store the last rendered tabline, and if
" there's no need to reprocess it, just return the old string

fun! xtabline#render#tabline() abort
  " Entry point {{{1
  if !s:ready() | return g:xtabline.last_tabline | endif
  call xtabline#tab#check_all()
  call xtabline#tab#check_index()
  call xtabline#filter_buffers() " filter buffers is called only from here

  " no room for a full tabline
  if &columns < 40 | return s:format_right_corner() | endif

  " reuse last tabline because there's no need to update it
  if s:reuse_last_tabline()
    return g:xtabline.last_tabline
  endif

  if s:v.tabline_mode == 'tabs'
    return s:render_tabs()
  else
    return s:render_buffers()
  endif
endfun "}}}

fun! s:render_tabs() abort
  " Tabline rendering in 'tabs' mode {{{1
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
endfun "}}}

fun! s:render_buffers() abort
  " Tabline rendering in 'buffers' or 'arglist' mode {{{1
  let [currentbuf, centerlabel] = [winbufnr(0), winbufnr(0)]

  " pick up data on all the buffers
  let tabs = []
  let Tab  = s:T()

  if s:v.tabline_mode == 'buffers'
    let labels = filter(s:oB(), 'bufexists(v:val)')
    let max = get(s:Sets, 'recent_buffers', 10)

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
      if s:buf(b).special
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
    let labels = map(argv(), 'bufnr(v:val)')
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
    let special = s:is_special(bnr)
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
          \ 'path': s:bufpath(bnr, tabpagenr()),
          \ 'hilite':   is_currentbuf && special  ? 'Special' :
          \             is_currentbuf             ? 'Select' :
          \             special || extra          ? 'Extra' :
          \             s:F.has_win(bnr)          ? 'Visible' : 'Hidden'
          \}

    if !s:buffer_has_format(buf) && type(s:Sets.buffer_format) == v:t_number
      let buf.path = s:get_buf_name(buf)
    else
      let buf.path = fnamemodify(bufname(bnr), (s:Sets.buffers_paths ? ':p:~:.' : ':t'))
      let buf.separators = s:buf_separators(bnr)
      let buf.indicator = s:buf_indicator(bnr)
    endif

    if is_currentbuf | let centerlabel = bnr | endif

    let buf.label = s:format_buffer(buf)
    let tabs += [buf]
  endfor

  return s:fit_tabline(centerlabel, tabs)
endfun "}}}

fun! s:fit_tabline(centerlabel, tabs) abort
  " Toss away tabs and pieces until all fits {{{1
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
    if tab.width >= limit
      let tab.label = tab.label[:limit-1] . '…'
      let tab.width = s:strwidth(tab.label)
    endif
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
  let g:xtabline.last_tabline = labels . '%#XTFill#%=' . corner_label . '%999X'
  return g:xtabline.last_tabline
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer label formatting
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:flat_buffer(buf) abort
  " Buffer label, using the default flat formatter {{{1
  "
  " @param bufdict: a buffer object, as generated in s:render_buffers()
  " Returns: the buffer label, complete with highlight groups
  let B = a:buf
  let curbuf = winbufnr(0) == B.nr

  let mod = index(s:pinned(), B.nr) >= 0
        \ ? ' '.s:Sets.bufline_indicators.pinned.' ' : ' '

  if getbufvar(B.nr, "&modified")
    let mod .= printf("%%#XT%sMod#%s",
          \    (curbuf ? "Select" : "Hidden"), s:Sets.modified_flag)
  endif

  let hi     = printf(" %%#XT%s# ", B.hilite)
  let icon   = s:get_buf_icon(B)
  let bn     = s:Sets.buffer_format == 2 ? B.n : B.nr
  let number = curbuf ? ("%#XTNumSel# " . bn) : ("%#XTNum# " . bn)

  return number . hi . icon . B.path . mod
endfun "}}}

fun! s:custom_buffer_label(bufdict, chars) abort
  " Buffer label, using a custom formatter {{{1
  "
  " @param bufdict: a buffer object, as generated in s:render_buffers()
  " @param chars: the formatter, as a list of characters
  " Returns: the formatted label
  let out = []
  let B = a:bufdict
  for c in a:chars
    let C = c
    "custom tab icon, if tab has a name and/or icon has been defined
    if     C == 32  | let C = ' '
    elseif C == 108 | let C = s:get_buf_name(B)                             "l
    elseif C == 117 | let C = s:unicode_nrs(B.n)                            "u
    elseif C == 78  | let C = B.n                                           "N
    elseif C == 110 | let C = B.nr                                          "n
    elseif C == 43  | let C = B.indicator                                   "+
    elseif C == 102 | let C = B.path                                        "f
    elseif C == 73  | let C = s:get_buf_icon(B)                             "i
    elseif C == 60  | let C = !B.has_icon ? B.separators[0] : ''            "<
    elseif C == 62  | let C = B.separators[1]                               ">
    endif
    call add(out, C)
  endfor
  let st = join(out, '')
  let hi = '%#XT' . B.hilite . '#'
  return hi.st
endfun "}}}

fun! s:format_buffer(bufdict) abort
  " Generate label in 'buffers' mode {{{1
  "
  " In buffer mode, the buffer formatting can be specified in different ways:
  " - specific buffer's format
  " - flat (default)
  " - funcref (user defined)

  " @param bufdict: a buffer object, as generated in s:render_buffers()
  " Returns: the buffer label, complete with highlight groups
  ""
  let [ B, fmt ] = [ a:bufdict, s:default_buffer_format ]

  if s:buffer_has_format(B)
    let chars = s:fmt_chars(s:buf(B.nr).format)

  elseif fmt.flat
    return s:flat_buffer(B)

  elseif fmt.func
    return fmt.content(B.nr)

  else
    let chars = fmt.content
  endif
  return s:custom_buffer_label(B, chars)
endfun "}}}

fun! s:buf_indicator(bnr) abort
  " Different kinds of indicators: modified, pinned {{{1
  let [ nr, mods ] = [ a:bnr, s:Sets.bufline_indicators ]
  let current_buf  = nr == winbufnr(0)
  let has_window   = bufwinnr(nr) > 0

  let mod = index(s:pinned(), nr) >= 0 ? mods.pinned : ''
  let modHi = current_buf      ? "%#XTSelectMod#" :
        \     s:extraHi(nr)    ? "%#XTExtraMod#" :
        \     has_window       ? "%#XTVisibleMod#" : "%#XTHiddenMod#"
  if s:is_special(nr)
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
endfun "}}}

fun! s:buf_separators(nr) abort
  " Use custom separators if defined in buffer entry. {{{1
  let B = s:buf(a:nr)
  return has_key(B, 'separators') ? B.separators : s:Sets.bufline_separators
endfun "}}}

fun! s:get_buf_name(buf) abort
  " Return custom buffer name, if it has been set, otherwise the filename. {{{1
  let B = s:buf(a:buf.nr)
  return !empty(B.name)       ? B.name :
        \ empty( a:buf.path ) ? s:Sets.unnamed_buffer : a:buf.path
endfun "}}}

fun! s:get_buf_icon(buf) abort
  " Return custom icon for buffer, or devicon if present. {{{1
  let nr = a:buf.nr
  if s:has_buf_icon(nr)
    let a:buf.has_icon = 1
    let icon = s:buf(nr).icon.' '
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
" Tab label formatting
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:format_tab_label(tabnr) abort
  " Format the tab label in 'tabs' mode {{{1
  "
  " @param tabnr: the tab's number
  " Returns: the formatted tab label

  let nr    = s:tab_num(a:tabnr)
  let icon  = s:get_tab_icon(a:tabnr, 0)
  let mod   = s:tab_mod_flag(a:tabnr, 0)
  let label = s:tab_label(a:tabnr)

  return printf("%s %s%s %s", nr, icon, label, mod)
endfun "}}}

fun! s:tab_num(tabnr) abort
  " Format the tab number, for either the tab label or the right corner. {{{1
  "
  " @param tabnr: tab number
  " Returns: the formatted tab number

  if s:v.tabline_mode != 'tabs'
    let hi = has_key(s:T(), 'dir') ? " %#XTNumSel#" : " %#XTVisible#"
    return "%#XTNumSel# " . a:tabnr .'/' . tabpagenr('$') . hi
  else
    return a:tabnr == tabpagenr() ?
          \   "%#XTNumSel# " . a:tabnr . " %#XTSelect#"
          \ : "%#XTNum# "    . a:tabnr . " %#XTHidden#"
  endif
endfun "}}}

fun! s:tab_mod_flag(tabnr, corner) abort
  " Flag for the 'modified' state for a tab label. {{{1
  "
  " @param tabnr:  the tab number
  " @param corner: if the flag is for the right corner
  " Returns: the formatted flag

  let flag = s:Sets.modified_flag
  for buf in tabpagebuflist(a:tabnr)
    if getbufvar(buf, "&mod")
      return a:corner
            \ ? "%#XTVisibleMod#" . flag
            \ : a:tabnr == tabpagenr()
            \   ? "%#XTSelectMod#" . flag
            \   : "%#XTHiddenMod#" . flag
    endif
  endfor
  return ""
endfun "}}}

fun! s:tab_label(tabnr) abort
  " Build the tab label. {{{1
  "
  " The label can be either:
  " 1. the shortened cwd
  " 2. the name of the active special buffer for this tab
  " 3. the name of the active buffer for this tab (option-controlled)
  "
  " @param tabnr: the tab number
  " Returns: the formatted tab label

  let bnr = s:tab_buffer(a:tabnr)

  if s:is_special(bnr)
    return s:buf(bnr).name
  endif

  return s:bufpath(bnr, a:tabnr)
endfun "}}}

fun! s:get_tab_icon(tabnr, right_corner) abort
  " The icon for the tab label. {{{1
  "
  " @param tabnr: the tab number
  " @param right_corner: if it's for the right corner
  " Returns: the icon

  if !empty(get(s:Tn(a:tabnr), 'icon', ''))
    return s:Tn(a:tabnr).icon . ' '
  endif

  if a:right_corner
    let icon = s:Sets.tab_icon

  else
    let bnr  = s:tab_buffer(a:tabnr)
    let buf  = {'nr': bnr, 'has_icon': 0}
    let icon = s:get_buf_icon(buf)
  endif

  return type(icon) == v:t_string ? icon : icon[a:tabnr != tabpagenr()] . ' '
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Right corner label
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:format_right_corner() abort
  " Label for the upper right corner. {{{1
  let N = tabpagenr()

  " tab-local/window-local working directory indicator
  if s:Sets.wd_type_indicator
    let lcd   = haslocaldir(winnr(), tabpagenr()) == 1    ? '%#XTSpecial# W '
          \   : exists(':tcd') == 2 && haslocaldir(-1, 0) ? '%#XTSpecial# T ' : ''
  else
    let lcd = ''
  endif

  if has_key(s:T(), 'corner')
    " special right corner with its own label
    return s:T().corner

  elseif s:v.tabline_mode == 'arglist'
    " the number of the files in the arglist, in form n/N
    return s:right_corner_label() . "%#XTSelect# arglist " . lcd

  elseif !s:Sets.show_right_corner
    " no label, just the tab number in form n/N
    return s:tab_num(N) . lcd

  elseif s:v.tabline_mode == 'tabs'
    " no number, just the name or the cwd
    let icon  = "%#XTNumSel# " . s:get_tab_icon(N, 1)
    let label = "%#XTVisible# " . s:right_corner_label() . ' '
    let mod   = s:tab_mod_flag(N, 1)
    return icon . label . mod . lcd

  elseif s:v.tabline_mode == 'buffers'
    " tab number in form n/N, plus tab name or cwd
    let nr        = s:tab_num(N)
    let icon      = s:get_tab_icon(N, 1)
    let mod       = s:tab_mod_flag(N, 1)
    let label     = s:right_corner_label()
    return printf("%s %s%s %s", nr, icon, label, mod) . lcd
  endif
endfun "}}}

fun! s:right_corner_label() abort
  " Build the label for the right corner. {{{1
  "
  " The label can be either:
  " 1. the shortened cwd ('tabs' and 'buffers' mode)
  " 2. a custom tab name ('buffers' mode)
  " 3. the name of the active buffer for this tab ('buffers' mode)
  " 4. the number/total files in the arglist ('arglist' mode)
  "
  " Returns: the formatted label
  let N = tabpagenr()

  if s:v.tabline_mode == 'tabs'
    return s:v.custom_tabs && !empty(s:T().name)
          \   ? s:T().name : s:F.short_cwd(N, 1)

  elseif s:v.tabline_mode == 'arglist'
    let [ n, N ]  = [ index(argv(), bufname(bufnr('%'))) + 1, len(argv()) ]
    return "%#XTNumSel# " . n .'/' . N . " "

  elseif s:v.tabline_mode == 'buffers'
    return s:v.custom_tabs && !empty(s:T().name)
          \ ? s:T().name : s:F.short_cwd(N, 1)
  endif
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:bufpath(bnr, tnr) abort
  " Return the buffer path as it is to be shown in the tabline. {{{1
  let bname = bufname(a:bnr)
  let minimal = &columns < 150 " window is small

  if !filereadable(bname)                           " new files/scratch buffers
    return empty(bname)
          \ ? &buftype != '' ? '[Volatile]'
          \                  : '...'
          \ : minimal ? fnamemodify(bname, ':t')
          \ : s:F.short_path(a:bnr, 1)              " shortened buffer path

  elseif minimal
    return fnamemodify(bname, ':t')

  else
    let format = s:v.tabline_mode == 'tabs'
          \    ? s:Sets.tabs_paths : s:Sets.buffers_paths
    return s:F.short_path(a:bnr, format)
  endif
endfun " }}}

fun! s:fmt_chars(fmt) abort
  " Return a split string with the formatting option in use. {{{1
  let chars = []
  for i in range(strchars(a:fmt))
    call add(chars, strgetchar(a:fmt, i))
  endfor
  return chars
endfun "}}}

fun! s:get_default_buffer_format() abort
  " Get the default buffer format, and set its type {{{1
  " It can be either:
  " - funcref
  " - format string
  " - number (1 to show bufnr, 2 to show buffer order)
  let fmt = { 'func': 0, 'flat': 0 }
  if type(s:Sets.buffer_format) == v:t_func
    let fmt.func = 1
    let fmt.content = s:Sets.buffer_format
  elseif type(s:Sets.buffer_format) == v:t_string
    let fmt.content = s:fmt_chars(s:Sets.buffer_format)
  elseif type(s:Sets.buffer_format) == v:t_number
    let fmt.flat = s:Sets.buffer_format
  endif
  return fmt
endfun "}}}

let s:unr1 = [ '₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉', '₁₀',
      \'₁₁', '₁₂', '₁₃', '₁₄', '₁₅', '₁₆', '₁₇', '₁₈', '₁₉', '₂₀',
      \'₂₁', '₂₂', '₂₃', '₂₄', '₂₅', '₂₆', '₂₇', '₂₈', '₂₉', '₃₀' ]

let s:unr2 = [ '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹', '¹⁰',
      \'¹¹', '¹²', '¹³', '¹⁴', '¹⁵', '¹⁶', '¹⁷', '¹⁸', '¹⁹', '²⁰',
      \'²¹', '²²', '²³', '²⁴', '²⁵', '²⁶', '²⁷', '²⁸', '²⁹', '³⁰' ]

fun! s:unicode_nrs(nr) abort
  " Adapted from Vim-CtrlSpace (https://github.com/szw/vim-ctrlspace) {{{1
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
endfun "}}}

fun! s:extra_padding(l_r, limit) abort
  " Padding before the right corner {{{1
  return a:l_r < a:limit ? '%#XTFill#'.repeat(' ', a:limit - a:l_r) : ''
endfun "}}}

fun! s:ready() abort
  " Do not update when a session is still loading. {{{1
   return !exists('g:SessionLoad')
 endfun "}}}

fun! s:reuse_last_tabline() abort
  " Check if it's time to update the tabline or not. {{{1
  " Returns: bool
  let currentbuf = winbufnr(0)

  " Update if flag is set, or buffer has been modified
  if exists('s:v.time_to_update')
        \|| !has_key(s:last_modified_state, currentbuf)
        \|| &modified != s:last_modified_state[currentbuf]

    let s:last_modified_state[currentbuf] = &modified
    silent! unlet s:v.time_to_update
  else
    return 1
  endif
endfun "}}}




"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim: et sw=2 ts=2 sts=2 fdm=marker
