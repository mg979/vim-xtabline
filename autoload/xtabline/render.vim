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

let s:buf        = function('xtabline#buffer#get')
let s:is_special = { nr -> s:buf(nr).special }
let s:is_open    = { n -> s:F.has_win(n) && index(s:vB(), n) < 0 && getbufvar(n, "&ma") }
let s:is_extra   = { n -> index(s:eB(), n) >= 0 }

let s:scratch           = { nr -> index(['nofile','acwrite'], getbufvar(nr, '&buftype')) >= 0 }
let s:pinned            = { -> s:X.pinned_buffers                                             }
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
  let center = tabpagenr()
  let tabs = []

  for tnr in range(1, tabpagenr('$'))
    call add(tabs, s:format_tab_label(tnr))
  endfor

  return s:fit_tabline(center, tabs)
endfun "}}}

fun! s:render_buffers() abort
  " Tabline rendering in 'buffers' or 'arglist' mode {{{1
  let [currentbuf, center] = [winbufnr(0), winbufnr(0)]

  " pick up data on all the buffers
  let tabs = []

  if s:v.tabline_mode == 'buffers'
    let labels = filter(s:oB(), 'bufexists(v:val)')
    let max = get(s:Sets, 'recent_buffers', 10)

    "limiting to x most recent buffers, if option is set; here we consider only
    "valid buffers, special/extra/etc will be added later
    if max > 0
      let recent = s:T().buffers.recent[:(max-1)]
      call filter(labels, 'index(recent, v:val) >= 0')
    endif

    "put current buffer first?
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
      elseif s:is_open(b) && getbufvar(b, '&buftype') == ''
        call add(front, b)
      endif
    endfor

    "put upfront: special > pinned > open > extra buffers
    for b in ( s:eB() + front + s:pinned() + specials )
      call s:F.add_ordered(b, 1)
    endfor
  elseif !empty(argv())
    let labels = filter(map(argv(), 'bufnr(v:val)'), 'v:val > 0')
    if empty(labels) | return s:no_arglist() | endif
  else
    return s:no_arglist()
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
    let B       = s:buf(bnr)        " a buffer object in the xtabline dicts

    " exclude special buffers without window, or non-special scratch buffers
    if special && !s:F.has_win(bnr) | continue
    elseif scratch && !special      | continue | endif

    let n = index(labels, bnr) + 1 + begin       "tab buffer index
    let is_currentbuf = currentbuf == bnr

    " create a buffer object that inherits attributes (name and icon) from the
    " global xtabline buffers dictionary, the most important here is 'name',
    " that is either a custom name, or the displayed shortened path

    let buf = {
          \ 'nr':     bnr,
          \ 'n':      n,
          \ 'name':   empty(B.name) ? s:bufpath(bnr) : B.name,
          \ 'icon':   B.icon,
          \ 'hilite': is_currentbuf && special  ? 'Special' :
          \           is_currentbuf             ? 'Select' :
          \           special || extra          ? 'Extra' :
          \           s:F.has_win(bnr)          ? 'Visible' : 'Hidden'
          \}

    let buf.himod = special ? buf.hilite : buf.hilite . 'Mod'

    if is_currentbuf | let center = bnr | endif

    let buf.label = s:format_buffer(buf)
    let tabs += [buf]
  endfor

  return s:fit_tabline(center, tabs)
endfun "}}}

fun! s:no_arglist() abort
  " Switch off arglist mode and restart tabline rendering {{{1
  let s:v.time_to_update = 1
  let s:v.tabline_mode = get(filter(copy(s:Sets.tabline_modes),
        \                    'v:val != "arglist"'), 0, 'tabs')
  return xtabline#render#tabline()
endfun "}}}

fun! s:fit_tabline(center, tabs) abort
  " Toss away tabs and pieces until all fits {{{1
  let corner_label = s:format_right_corner()
  let corner_width = s:strwidth(corner_label)
  let Tabs = a:tabs

  let modelabel = s:get_mode_label()
  if modelabel != ''
    let corner_width += s:strwidth(modelabel)
  endif

  if tabpagenr('$') > 1 && s:Sets.tab_number_in_left_corner
    let tabsnums = '%#ErrorMsg# ' . tabpagenr() . '/'. tabpagenr('$') . ' %#XTFill# '
    let corner_width += s:strwidth(tabsnums)
  else
    let tabsnums = ''
  endif

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
    if a:center == tab.nr
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
    try
      if left_has_been_cut
        let lab = substitute(Tabs[0].label, '%#X\w*#', '', 'g')
        let Tabs[0].label = printf('%%#DiffDelete# < %%#XT%s#%s', Tabs[0].hilite, strcharpart(lab, 3))
      endif
      if right_has_been_cut
        let Tabs[-1].label = printf('%s%%#DiffDelete# > ', Tabs[-1].label[:-4])
      endif
    catch
      return corner_label
    endtry
  endif

  let labels = map(Tabs,'v:val.label')
  if s:v.tabline_mode == 'tabs'
    "FIXME: it works like this, but it's adding the %nT part for the second
    "time, for some reason it doesn't work anymore if I only add it here
    for n in range(len(labels))
      let labels[n] = '%' . (n+1) . 'T' . labels[n]
    endfor
  endif
  let labels = tabsnums . modelabel . join(labels, '')
  let g:xtabline.last_tabline = labels . '%#XTFill#%=' . corner_label . '%999X'
  return g:xtabline.last_tabline
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Buffer label formatting
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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

  if fmt.flat                  " default format
    return s:flat_buffer(B)

  elseif fmt.func              " user-defined funcref
    return fmt.content(B.nr)
  endif
endfun "}}}

fun! s:flat_buffer(buf) abort
  " Buffer label, using the default flat formatter {{{1
  "
  " @param bufdict: a buffer object, as generated in s:render_buffers()
  " Returns: the buffer label, complete with highlight groups
  let B = a:buf
  let curbuf = winbufnr(0) == B.nr

  let mod = index(s:pinned(), B.nr) >= 0
        \ ? ' '.s:Sets.indicators.pinned.' ' : ' '

  if getbufvar(B.nr, "&modified")
    let mod .= printf("%%#XT%s#%s ", B.himod, s:Sets.indicators.modified)
  endif

  let hi     = printf(" %%#XT%s# ", B.hilite)
  let icon   = s:get_buf_icon(B)
  let bn     = s:Sets.buffer_format == 2 ? B.n : B.nr
  let number = curbuf ? ("%#XTNumSel# " . bn) : ("%#XTNum# " . bn)

  return number . hi . icon . B.name . mod
endfun "}}}

fun! s:bufpath(bnr) abort
  " Return the path for the label in buffers mode. {{{1
  let bname = bufname(a:bnr)
  let minimal = &columns < 100 " window is small

  if !filereadable(bname)                           " new files/scratch buffers
    return empty(bname)
          \ ? &buftype != '' ? s:Sets.scratch_label
          \                  : s:Sets.unnamed_label
          \ : &buftype != '' ? bufname('')
          \ : minimal ? fnamemodify(bname, ':t')
          \ : s:F.short_path(a:bnr, 1)              " shortened buffer path

  elseif minimal
    return fnamemodify(bname, ':t')

  else
    return s:F.short_path(a:bnr, s:Sets.buffers_paths)
  endif
endfun " }}}

fun! s:get_buf_icon(buf) abort
  " Return custom icon for buffer, or devicon if installed. {{{1
  let nr = a:buf.nr
  if !empty(a:buf.icon)
    return a:buf.icon.' '
  elseif get(s:Sets, 'use_devicons', 1)
    try
      let icon = WebDevIconsGetFileTypeSymbol(bufname(a:buf.nr)).' '
      return icon
    catch
    endtry
  endif
  return ''
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tab label formatting
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:format_tab_label(tnr) abort
  " Format the tab label in 'tabs' mode {{{1
  "
  " @param tnr: the tab's number
  " Returns: a tab 'object' with label and highlight groups

  let nr    = '%' . a:tnr . 'T' . s:tab_num(a:tnr)
  let hi    = s:tab_hi(a:tnr)
  let icon  = s:get_tab_icon(a:tnr, 0)
  let label = s:tab_label(a:tnr)
  let mod   = s:tab_mod_flag(a:tnr, 0)

  let label = printf("%s%%#XT%s# %s%s %s", nr, hi, icon, label, mod)

  return {'label': label, 'nr': a:tnr, 'hilite': hi}
endfun "}}}

fun! s:tab_num(tabnr) abort
  " Format the tab number, for either the tab label or the right corner. {{{1
  "
  " @param tabnr: tab number
  " Returns: the formatted tab number

  if s:v.tabline_mode != 'tabs'
    return printf("%s %d/%d ", "%#XTNumSel#", a:tabnr, tabpagenr('$'))
  else
    return a:tabnr == tabpagenr() ?
          \   printf("%s %d ", "%#XTNumSel#", a:tabnr)
          \ : printf("%s %d ", "%#XTNum#", a:tabnr)
  endif
endfun "}}}

fun! s:tab_hi(tnr) abort
  " The highlight group for the tab label {{{1
  let special = s:Sets.special_tabs && s:is_special(s:tab_buffer(a:tnr))
  return a:tnr == tabpagenr() ? special ? 'Special' : 'Select' : 'Hidden'
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
    let B    = s:buf(bnr)
    let buf  = {'nr': bnr, 'icon': B.icon, 'name': B.name}
    let icon = s:get_buf_icon(buf)
  endif

  return type(icon) == v:t_string ? icon : icon[a:tabnr != tabpagenr()] . ' '
endfun "}}}

fun! s:tab_label(tnr) abort
  " Build the tab label in tabs mode. {{{1
  "
  " The label can be either:
  " 1. the shortened cwd
  " 2. the name of the active special buffer for this tab
  " 3. custom tab or active buffer label (option: user_labels)
  " 4. the name of the active buffer for this tab (option-controlled)
  "
  " @param tnr: the tab number
  " Returns: the formatted tab label

  let bnr = s:tab_buffer(a:tnr)
  let buf = s:buf(bnr)            " a buffer object in the xtabline dicts
  let tab = s:X.Tabs[a:tnr-1]     " the tab object in the xtabline dicts

  " custom label
  if s:is_special(bnr)
    return buf.name

  elseif s:v.user_labels
    if !empty(tab.name)
      return tab.name
    elseif !empty(buf.name)
      return buf.name
    endif
  endif

  let fname = bufname(bnr)
  let minimal = &columns < 100         " window is small
  let current = a:tnr == tabpagenr()

  if !filereadable(fname)              " new files/scratch buffers
    " 1. unnamed scratch buffer
    " 2. unnamed regular buffer
    " 3. named scratch buffer
    " 4. window is too small
    " 5. shortened file path
    return empty(fname)
          \ ? &buftype != '' ? s:Sets.scratch_label
          \                  : s:Sets.unnamed_label
          \ : &buftype != '' ? bufname('')
          \ : minimal ? fnamemodify(fname, ':t')
          \ : s:F.short_path(bnr, 1)

  elseif minimal
    return fnamemodify(fname, ':t')

  else
    return s:F.short_path(bnr, current ? s:Sets.current_tab_paths
          \                              : s:Sets.other_tabs_paths)
  endif
endfun " }}}

fun! s:tab_mod_flag(tabnr, corner) abort
  " Flag for the 'modified' state for a tab label. {{{1
  "
  " @param tabnr:  the tab number
  " @param corner: if the flag is for the right corner
  " Returns: the formatted flag

  let flag = s:Sets.indicators.modified
  for buf in tabpagebuflist(a:tabnr)
    if getbufvar(buf, "&mod")
      return a:corner
            \ ? "%#XTVisibleMod#" . flag
            \ : a:tabnr == tabpagenr()
            \   ? "%#XTSelectMod#" . flag . ' '
            \   : "%#XTHiddenMod#" . flag . ' '
    endif
  endfor
  return ""
endfun "}}}




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Corner labels
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
    return s:T()['corner']

  elseif !s:Sets.show_right_corner
    " no label, just the tab number in form n/N
    return s:v.tabline_mode == 'tabs' || s:hide_tab_number()
          \ ? lcd : s:tab_num(N) . lcd

  elseif s:v.tabline_mode == 'tabs' || s:hide_tab_number()
    " no number, just the name or the cwd
    let hi    = "%#XTCorner#"
    let icon  = "%#XTNumSel# " . s:get_tab_icon(N, 1)
    let mod   = s:tab_mod_flag(N, 1)
    let label = s:right_corner_label()
    return printf("%s%s %s %s", icon, hi, label, mod) . lcd

  else
    " tab number in form n/N, plus tab name or cwd
    let hi    = "%#XTCorner#"
    let nr    = s:tab_num(N)
    let icon  = s:get_tab_icon(N, 1)
    let mod   = s:tab_mod_flag(N, 1)
    let label = s:right_corner_label()
    return printf("%s%s %s%s %s", nr, hi, icon, label, mod) . lcd
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
    return s:F.short_cwd(N, 1)

  elseif s:v.tabline_mode == 'buffers' || s:v.tabline_mode == 'arglist'
    return s:v.user_labels && !empty(s:T().name)
          \ ? s:T().name : s:F.short_cwd(N, 1)
  endif
endfun "}}}

fun! s:get_mode_label() abort
  let [labels, mode] = [s:Sets.mode_labels, s:v.tabline_mode]
  if labels == 'none' ||
        \ labels == 'secondary' && index(s:Sets.tabline_modes, mode) == 0 ||
        \ labels != 'all' && labels != 'secondary' && labels !~ mode
    return ''
  else
    return printf("%%#XTExtra# %s %%#XTFill# ", mode)
  endif
endfun




""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_default_buffer_format() abort
  " Get the default buffer format, and set its type {{{1
  " It can be either:
  " - 1 bufnr
  " - 2 buffer order
  " - funcref
  let fmt = { 'func': 0, 'flat': 0 }

  if type(s:Sets.buffer_format) == v:t_func
    let fmt.func = 1
    let fmt.content = s:Sets.buffer_format

  elseif type(s:Sets.buffer_format) == v:t_number
    let fmt.flat = s:Sets.buffer_format

  else
    let fmt.flat = 1
  endif
  return fmt
endfun "}}}

fun! s:ready() abort
  " Do not update during completion or when a session is still loading. {{{1
  return mode(1) !~ '.c' && !exists('g:SessionLoad')
endfun "}}}

fun! s:reuse_last_tabline() abort
  " Check if it's time to update the tabline or not. {{{1
  " Returns: bool
  let currentbuf = winbufnr(0)

  " Update if flag is set, or buffer has been modified
  if exists('s:v.time_to_update')
        \|| !has_key(s:last_modified_state, currentbuf)
        \|| &modified != s:last_modified_state[currentbuf]

    if s:v.queued_update == 2
      let s:v.queued_update = 1
      call xtabline#filter_buffers()
    else
      let T = s:T()
      if exists('T.refilter')
        unlet T.refilter
        call xtabline#filter_buffers()
      endif
    endif
    let s:last_modified_state[currentbuf] = &modified
    silent! unlet s:v.time_to_update
    return v:false
  endif
  return v:true
endfun "}}}

fun! s:hide_tab_number() abort
  " If tab number should be hidden from the top right corner. {{{1
  return tabpagenr('$') == 1 || s:Sets.tab_number_in_left_corner
endfun "}}}



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim: et sw=2 ts=2 sts=2 fdm=marker
