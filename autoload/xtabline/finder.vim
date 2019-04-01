" http://vim.wikia.com/wiki/Implement_your_own_interactive_finder_without_plugins
" functions by Lifepillar

fun! s:close(bufnr)
  wincmd p
  execute "bwipe" a:bufnr
  redraw
  echo "\r"
  return []
endf

"------------------------------------------------------------------------------

fun! s:buffer(input, cline)
  """.
  botright 10new +setlocal\ buftype=nofile\ bufhidden=wipe\
        \ nobuflisted\ nonumber\ norelativenumber\ noswapfile\ nowrap\
        \ foldmethod=manual\ nofoldenable\ modifiable\ noreadonly
  call setline(1, a:input)
  if !a:cline
    setlocal cursorline
  endif
  redraw
  return bufnr('%')
endfun

fun! xtabline#finder#open(input, prompt, exe_cmdline) abort
  let prompt = a:exe_cmdline ? a:prompt : a:prompt . '>'
  let filter = ""
  let undoseq = []
  let input = a:exe_cmdline ? split(execute(a:input), '\n')
        \ : type(a:input) ==# v:t_string ? systemlist(a:input)
        \ : a:input " Assume List
  let cur_buf = s:buffer(input, a:exe_cmdline)
  echo prompt . " "
  while 1
    let error = 0 " Set to 1 when pattern is invalid
    try
      let ch = getchar()
    catch /^Vim:Interrupt$/  " CTRL-C
      return s:close(cur_buf)
    endtry
    if ch ==# "\<bs>" " Backspace
      let filter = filter[:-2]
      let undo = empty(undoseq) ? 0 : remove(undoseq, -1)
      if undo
        silent norm u
      endif
    elseif ch >=# 0x20 " Printable character
      let filter .= nr2char(ch)
      let seq_old = get(undotree(), 'seq_cur', 0)
      try " Ignore invalid regexps
        execute 'silent keepp g!:\m' . escape(filter, '~\[:') . ':norm "_dd'
      catch /^Vim\%((\a\+)\)\=:E/
        let error = 1
      endtry
      let seq_new = get(undotree(), 'seq_cur', 0)
      " seq_new != seq_old iff the buffer has changed
      call add(undoseq, seq_new != seq_old)
    elseif ch ==# 0x1B " Escape
      return s:close(cur_buf)
    elseif ch ==# 0x0D " Enter
      if a:exe_cmdline
        call s:close(cur_buf)
        exe prompt filter
        return [prompt . ' ' . filter]
      else
        let result = empty(getline('.')) ? [] : [getline('.')]
        call s:close(cur_buf)
        return result
      endif
    elseif ch ==# 0x0C " CTRL-L (clear)
      call setline(1, type(a:input) ==# v:t_string ? input : a:input)
      let undoseq = []
      let filter = ""
      redraw
    elseif ch ==# 0x0B || ch ==# "\<Up>"   " CTRL-K
      norm k
    elseif ch ==# 0x0A || ch ==# "\<Down>" " CTRL-J
      norm j
    endif
    redraw
    echo (error ? "[Invalid pattern] " : "").prompt filter
  endwhile
endf

fun! xtabline#finder#sessions() abort
  let sessions = xtabline#fzf#sessions_list(1)
  let file = xtabline#finder#open(sessions, 'Load session ', 0)
  if !empty(file)
    call xtabline#fzf#session_load(file[0])
  endif
endfun
