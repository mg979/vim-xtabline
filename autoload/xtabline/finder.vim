" http://vim.wikia.com/wiki/Implement_your_own_interactive_finder_without_plugins
" main functions by Lifepillar
" extended options, fuzzy matching and multiple picks by mg979

"------------------------------------------------------------------------------
" INPUT can be:
"
"   1. a list:        processed as-is, chosen line is returned
"   2. a string:      split by newlines, chosen line is returned
"   3. a dictionary:  Finder shows keys(input), but input[key] is returned
"------------------------------------------------------------------------------
" ARGS (...) can be:
"
"   1. a string       statusline will be set to this string
"   2. a dictionary   with keys:
"
"        'prompt'     (on the command line)
"        'statusline' (statusline will be set to this string)
"        'syntax'     (to colorize buffer, if desired)
"        'position'   (command to create the buffer, defining its position)
"        'multi'      (allow multiple picks with TAB)
"        'on_change'  (function to be called on line change)
"        'on_cancel'  (function to be called on ESC)
"        'on_keys'    (a dict {[key]: function to be called on [key]})
"
"   3. both           the string will be the statusline, the dict as above
"------------------------------------------------------------------------------
" RETURN value:     a STRING by default (the chosen line), but a LIST if the
"                   'multi' switch is used.
"------------------------------------------------------------------------------
" MULTI selections: when Finder is called with the 'multi' switch, it's
"                   possible to select multiple items with TAB.
"                   If no items are selected with TAB, and ENTER is pressed,
"                   the chosen item is returned; on the other hand, if some
"                   item has been chosen with TAB, the ENTER key will return
"                   the current item only if it has been selected. The most
"                   important thing is: when the 'multi' switch is used, the
"                   return value is a LIST, not a STRING, even in the case
"                   that a single item is returned. So, commands that use the
"                   'multi' switch, must handle LISTS as return values.
"------------------------------------------------------------------------------

fun! xtabline#finder#open(input, ...) abort "{{{1
  let finder       = s:init(a:input, a:000)
  let extra_keys = !empty(finder.on_keys)
  let filter     = []
  let undoseq    = []

  while 1
    let error = 0 " Set to 1 when pattern is invalid
    try
      let ch = getchar()
    catch /^Vim:Interrupt$/                               " CTRL-C
      return finder.cancel()
    endtry

    if ch ==# "\<bs>"                                     " Backspace
      let filter = filter[:-2]
      call finder.match(
            \ len(filter) ? s:fuzzy(filter) : '^$')
      let undo = empty(undoseq) ? 0 : remove(undoseq, -1)
      if undo
        silent norm! u
      endif

    elseif ch ==# 0x1B                                    " Escape
      return finder.cancel()

    elseif ch ==# 0x0D                                    " Enter
      return finder.select()

    elseif ch ==# 0x15                                    " CTRL-U (clear)
      " use finder.input, a:input could be a dictionary
      call setline(1, finder.input)
      call finder.match('^$')
      let undoseq = []
      let filter = []

    elseif ch ==# 0x0B || ch == 0x10 || ch == "\<Up>"     " CTRL-K, CTRL-P, UP
      norm! k
      call finder.on_move()

    elseif ch ==# 0x0A || ch == 0x0E || ch == "\<Down>"   " CTRL-J, CTRL-N, DOWN
      norm! j
      call finder.on_move()

    elseif ch ==# 0x02                                    " CTRL-B
      norm! 10k

    elseif ch ==# 0x06                                    " CTRL-F
      norm! 10j

    elseif extra_keys && has_key(finder.on_keys, ch)      " EXTRA KEYS
      call finder.on_keys[ch](finder)

    elseif finder.multi && ch ==# 0x09                    " TAB
      call finder.pick()
      norm! j

    elseif ch >=# 0x20                                    " Printable character
      let char = nr2char(ch)
      if char == '\'
        let char .= nr2char(getchar())
      endif
      let filter += [char]
      let seq_old = get(undotree(), 'seq_cur', 0)
      try " Ignore invalid regexps
        let pattern = s:fuzzy(filter)
        call finder.match(pattern)
        let wl = winline()
        execute 'silent keepp v/\V' . pattern . '/d _'
        exe wl
      catch /^Vim\%((\a\+)\)\=:E/
        let error = 1
      endtry
      let seq_new = get(undotree(), 'seq_cur', 0)
      " seq_new != seq_old if the buffer has changed
      call add(undoseq, seq_new != seq_old)
    endif
    normal! 0
    redraw
    echo (error ? "[Invalid pattern] " : "").finder.prompt join(filter, '')
    let &l:statusline = &l:statusline
  endwhile
endfun "}}}


"------------------------------------------------------------------------------

" This function parses all arguments and creates the Finder instance
" it also calls s:buffer() that creates the Finder buffer

fun! s:init(input, args) abort "{{{1
  sign define Finder text=>> texthl=WarningMsg
  let s:placed = 1
  let nargs = len(a:args)

  let finder         = deepcopy(s:Finder)
  let finder.input   = a:input
  let finder.is_dict = type(a:input) == v:t_dict
  let finder.lines   = type(a:input) == v:t_dict    ? keys(a:input)
        \            : type(a:input) ==# v:t_string ? split(a:input, '\n') : a:input

  if nargs > 1
    let finder.statusline = a:args[0]
    call extend(finder, a:args[1])
  elseif nargs && type(a:args[0]) == v:t_dict
    let finder = extend(finder, a:args[0])
  elseif nargs
    let finder.statusline = a:args[0]
  endif

  let finder.bufnr = s:buffer(finder)
  return finder
endfun

"--------------------------------------------------------------------------}}}

" This function creates the Finder buffer

fun! s:buffer(finder) "{{{1
  exe a:finder.position
  setlocal bt=nofile bh=wipe nobl nonu nornu noswapfile nowrap
  setlocal fdm=manual nofoldenable ma noro
  call setline(1, a:finder.lines)
  setlocal cursorline
  exe 'silent! setfiletype' a:finder.syntax
  if has('patch-8.1.1391')
    set wincolor=Pmenu
  elseif has('nvim')
    exe 'set winhighlight=Normal:Pmenu'
  endif
  normal! gg
  let a:finder.current_line = 1
  call a:finder.on_move()
  redraw
  echo a:finder.prompt . " "
  return bufnr('%')
endfun

"--------------------------------------------------------------------------}}}

" This function returns the pattern on the base of which the Finder buffer
" will be filtered:
"
"  1. an exact match is searched and returned if found
"  2. if not found, the query is split by character, all characters are added
"     one by one, and an exact match is searched each time a character is added
"  3. when an exact match cannot be found anymore, the pattern becomes fuzzy
"     from that point forwards, but the part of the pattern for which an exact
"     match was found is retained as it was, so that precision is greater

fun! s:fuzzy(filter) abort "{{{1
  " no matches
  let partial_exact = escape(a:filter[0], '/')
  if !search('\V' . partial_exact, 'nc') | return '\^\$' | endif

  " prefer exact matches
  let exact = escape(join(a:filter, ''), '/')
  if search('\V' . exact, 'nc') | return exact | endif

  " if an exact submatch can be found, keep it
  let i = 1
  let N = len(a:filter)
  while i <= N
    let addchar = escape(join(a:filter[:i], ''), '/')
    if search('\V' . addchar, 'nc')
      let partial_exact = addchar
      let i += 1
    else
      break
    endif
  endwhile

  " the part after the exact submatch is made fuzzy
  return partial_exact . '\.\{\-\}' . escape(join(a:filter[i:], '\.\{\-\}'), '/')
endfun "}}}



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Finder instance
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Finder = {
      \ 'position': 'botright 10new',
      \ 'prompt':    '> ',    'statusline': '',   'syntax':  '',    'cwd': '',
      \ 'on_change': '',      'on_cancel':  '',   'on_preview': '',
      \ 'multi':     0,       'chosen':     {},   'on_keys': {},
      \}

" This function returns the item in the current line

fun! s:Finder.current() abort "{{{1
    return getline('.') == '' ? ''
          \     : self.is_dict ? self.input[getline('.')] : getline('.')
endfun

"--------------------------------------------------------------------------}}}

" This function updates the highlighted pattern

fun! s:Finder.match(pattern) abort "{{{1
  if exists('self.pattern')
    call matchdelete(self.pattern)
  endif
  let case = a:pattern =~ '\u' ? '\C' : '\c'
  let self.pattern = matchadd('SpellLocal', '\V' . case . a:pattern)
endfun

"--------------------------------------------------------------------------}}}

" This function sets the return value, because an item has been selected
" If 'multi' is on, the return value must be a LIST, otherwise a STRING

fun! s:Finder.select(...) abort "{{{1
  if !self.multi || empty(self.chosen)
    let res = self.multi ? [self.current()] : self.current()
  elseif self.multi
    let res = map(keys(self.chosen), 'self.chosen[v:val][1]')
  endif
  if !a:0 | call self.close() | endif
  return res
endfun

"--------------------------------------------------------------------------}}}

" This function is called if the operation is canceled with ESC or CTRL-C

fun! s:Finder.cancel() abort "{{{1
  call self.close()
  return type(self.on_cancel) == v:t_func ? self.on_cancel() : self.multi ? [] : ''
endfun

"--------------------------------------------------------------------------}}}

" If TAB is pressed, pick an item and add it to the list of chosen items
" If the item has been added already, remove it.

fun! s:Finder.pick() "{{{1
  if has_key(self.chosen, line('.'))
    let placed = self.chosen[line('.')][0]
    unlet self.chosen[line('.')]
    exe 'sign unplace' placed
  else
    exe 'sign place' s:placed 'line='.line('.') 'name=Finder buffer='.bufnr('%')
    let self.chosen[line('.')] = [ s:placed, self.current() ]
    let s:placed += 1
  endif
endfun

"--------------------------------------------------------------------------}}}

" This function is called when the line changes

fun! s:Finder.on_move() "{{{1
  let self.current_line = line('.')
  if type(self.on_change) == v:t_func
    call self.on_change(self)
  endif
  if type(self.on_preview) == v:t_func
    call self.on_preview(self)
  endif
  let &l:statusline = self.statusline . '%=%#IncSearch# %l/%L '
endfun

"--------------------------------------------------------------------------}}}

" This function closes the Finder buffer.

fun! s:Finder.close() "{{{1
  wincmd p
  exe "sign unplace * buffer=" . self.bufnr
  sign undefine Finder
  execute "bwipe" self.bufnr
  redraw
  echo "\r"
  silent! pclose
endfun "}}}



