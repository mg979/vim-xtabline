fun! xtabline#funcs#init() abort "{{{1
  let s:X = g:xtabline
  let s:v = s:X.Vars
  let s:Sets = g:xtabline_settings

  let s:T =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab
  let s:vB = { -> s:T().buffers.valid     }       "valid buffers for tab
  let s:oB = { -> s:T().buffers.order     }       "ordered buffers for tab
  return xtabline#dir#init(s:Funcs)
endfun

let s:Funcs = {}

let s:Funcs.wins    = {   -> tabpagebuflist(tabpagenr()) }
let s:Funcs.has_win = { b -> index(s:Funcs.wins(), b) >= 0 }
"}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Misc functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.input(prompt, ...) abort
  " Input with colored prompt. {{{1
  echohl Label
  let [ text, complete ] = a:0 ? [ a:1, a:2 ] : [ '', '' ]
  let i = input(a:prompt, text, complete)
  echohl None
  return i
endfun "}}}


fun! s:Funcs.msg(txt, ...) abort
  " Print a message with highlighting. {{{1
  redraw
  if type(a:txt) == v:t_string
    exe "echohl" a:0 && a:1? "WarningMsg" : "Label"
    echon a:txt | echohl None
    return
  endif

  for txt in a:txt
    exe "echohl ".txt[1]
    echon txt[0]
    echohl None
  endfor
endfun "}}}


fun! s:Funcs.confirm(txt) abort
  " Ask for confirmation (y/n). {{{1
  return confirm(a:txt, "&Yes\n&No") == 1
endfun "}}}


fun! s:Funcs.set_buffer_var(buf, var, val) abort
  " Set variable in Buffers dict to given value. Return buffer dict. {{{1
  let [B, bufs] = [a:buf, s:X.Buffers]

  " create key in custom buffers dict if buffer wasn't customized yet
  if !has_key(bufs, B)
    let bufs[B] = copy(s:X._buffers[B])
  endif

  let bufs[B][a:var] = a:val
  return bufs[B]
endfun "}}}


fun! s:Funcs.fullpath(path) abort
  " Return full path. {{{1
  let path = expand(a:path)
  let path = empty(path) ? a:path : path "expand can fail
  return fnamemodify(path, ':p')
endfun

if has('win32')
  fun! s:Funcs.fullpath(path) abort
    let path = expand(a:path)
    let path = empty(path) ? a:path : path "expand can fail
    let path = fnamemodify(path, ':p')
    return substitute(path, '\\\ze[^ ]', '/', 'g')
  endfun
endif " }}}


fun! s:Funcs.fulldir(path)
  " Return full directory with trailing slash. {{{1
  let path = self.fullpath(a:path)
  return path[-1:] != '/' ? path.'/' : path
endfun

if has('win32')
  fun! s:Funcs.fulldir(path)
    let path = expand(a:path)
    let path = empty(path) ? a:path : path "expand can fail
    let path = fnamemodify(path, ':p')
    let path = substitute(path, '\\\ze\%([^ ]\|$\)', '/', 'g')
    return path[-1:] != '/' ? path.'/' : path
  endfun
endif "}}}


fun! s:Funcs.tab_buffers() abort
  " Return a list of buffers names for this tab. {{{1
  return map(copy(s:vB()), 'bufname(v:val)')
endfun "}}}


fun! s:Funcs.add_ordered(buf, put_first) abort
  " Add a buffer to the Tab.buffers.order list. {{{1

  let b    = a:buf          " the buffer number that must be added
  let bufs = s:oB()         " the list of ordered buffers
  let i    = index(bufs, b) " the index of the buffer in the list

  " if the buffer goes first, remove it from the list if present
  if i >= 0 && a:put_first | call remove(bufs, i) | endif

  " if the buffer doesn't go first, only add it if not present
  if a:put_first | call insert(bufs, b, 0)
  elseif i < 0   | call add(bufs, b)
  endif
endfun "}}}


fun! s:Funcs.uniq(list) abort
  " Make sure an element appears only once in the list. {{{1
  let [ i, max ] = [ 0, len(a:list)-2 ]
  while i <= max
    let extra = index(a:list, a:list[i], i+1)
    if extra > 0
      call remove(a:list, extra)
      let max -= 1
    else
      let i += 1
    endif
  endwhile
  return a:list
endfun "}}}


fun! s:Funcs.is_tab_buffer(...) abort
  " Verify that the buffer belongs to the tab {{{1
  return (index(s:vB(), a:1) != -1)
endfun "}}}


fun! s:Funcs.all_valid_buffers(...) abort
  " Return all valid buffers for all tabs. {{{1

  let valid = []
  for i in range(tabpagenr('$'))
    if a:0
      call extend(valid, s:X.Tabs[i].buffers.order)
    else
      call extend(valid, s:X.Tabs[i].buffers.valid)
    endif
  endfor
  return valid
endfun "}}}


fun! s:Funcs.all_open_buffers() abort
  " Return all open buffers for all tabs. {{{1

  let open = []
  for i in range(tabpagenr('$')) | call extend(open, tabpagebuflist(i + 1)) | endfor
  return open
endfun "}}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Shortened paths
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Funcs.short_cwd(tabnr, h, ...) abort
  " A shortened CWD, 'h' is the number of non-collapsed directory names. {{{1
  let path = a:0 ? a:1 : getcwd()

  if !a:h
    return fnamemodify(path, ":t")
  else
    let H = fnamemodify(path, ":~")
    if s:v.winOS | let H = tr(H, '\', '/')
  endif

  let splits = split(H, '/')
  if len(splits) > a:h
    let [ head, tail ] = [splits[:-(a:h+1)], splits[-(a:h):]]
    call map(head, "substitute(v:val, '\\(.\\).*', '\\1', '')")
    let H = join(head + tail, '/')
  endif
  if s:v.winOS
    let H = tr(H, '/', '\')
  endif
  return H
endfun "}}}


fun! s:Funcs.short_path(bnr, h) abort
  " A shortened file path, see :h xtabline-paths {{{1
  if !a:h
    return fnamemodify(bufname(a:bnr), ":t")
  elseif empty(bufname(a:bnr))
    return ''
  endif

  let H = fnamemodify(bufname(a:bnr), ":~:.")

  if s:v.winOS
    let H = tr(H, '\', '/')
  else
    let is_root = H[:0] == '/'
  endif

  if H !~ '/' | return H | endif

  let splits  = split(H, '/')

  if a:h < 0
    let h = min([len(splits) - 1, abs(a:h)])
    let head = splits[:-2]
    let tail = splits[-1:]
    return join(head[-h:] + tail, s:v.winOS ? '\' : '/')
  else
    let h = min([len(splits), abs(a:h)])
    let head = splits[:-(h+1)]
    let tail = splits[-h:]
  endif
  call map(head, "substitute(v:val, '\\(.\\).*', '\\1', '')")
  let H = join(head + tail, '/')
  if s:v.winOS
    let H = tr(H, '/', '\')
  elseif is_root
    let H = '/' . H
  endif
  return H
endfun "}}}


fun! s:Funcs.bdelete(buf) abort
  " Delete buffer if unmodified and not pinned. {{{1

  if index(s:X.pinned_buffers, a:buf) >= 0
    call self.msg("Pinned buffer has not been deleted.", 1)

  elseif s:T().locked && index(s:T().buffers.valid, a:buf) >= 0
    call remove(s:T().buffers.valid, index(s:T().buffers.valid, a:buf))

  elseif getbufvar(a:buf, '&ft') == 'nofile'
    exe "silent! bwipe ".a:buf

  elseif !getbufvar(a:buf, '&modified')
    exe "silent! bdelete ".a:buf
  endif
endfun "}}}


" vim: et sw=2 ts=2 sts=2 fdm=marker

