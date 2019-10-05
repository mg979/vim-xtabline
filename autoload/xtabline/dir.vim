"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands and functions that handle the working directory
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:X    = g:xtabline
let s:v    = s:X.Vars
let s:Sets = g:xtabline_settings
let s:T    =  { -> s:X.Tabs[tabpagenr()-1] }       "current tab

let s:Dir  = {}

fun! xtabline#dir#init(funcs)
  let s:F = a:funcs
  return extend(a:funcs, s:Dir)
endfun "}}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" When we change directory, we can use either `cd`, `tcd` or `lcd`.
" The user issues a command, this is confronted with the current type of
" working directory.
"
" Mappings are:
"
"   CDW: prompts for a global directory, confirm if a :tcd or :lcd is found
"   CDC: automatic (cd directory of current file), confirm as above
"   CDD: automatic (cd N directories below current file), confirm as above
"   CDT: prompts for a tab-local directory, no confirmation
"   CDL: prompts for a window-local directory, no confirmation
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#dir#cd(count) abort
  " Set cwd relatively to directory of current file.  {{{1

  let path = ':p:h'
  for c in range(max([a:count, 0]))
    let path .= ':h'
  endfor
  let dir = s:F.fullpath(expand("%"), path)
  if !empty(expand("%")) && empty(dir)
    let dir = '/'
  endif
  call s:F.manual_cwd(dir, 'working')
endfun "}}}

fun! xtabline#dir#set(...) abort
  " Set new working/local/tab directory. {{{1

  let [ type, bang, dir ] = [ a:1, a:2, a:3 ]

  if !bang && empty(dir)
    let base = s:F.fullpath(s:F.find_root_dir())
    let dir = s:F.input("Enter a new ".type." directory: ", base, "file")
  else
    let dir = s:F.fullpath(dir)
  endif

  if empty(dir)
    call s:F.msg ([[ "Canceled.", 'WarningMsg' ]])

  elseif s:F.manual_cwd(dir, type)
    " reset tab name if directory change was successful
    let s:X.Tabs[tabpagenr()-1].name = ''
  endif

  call xtabline#update()
endfun "}}}

fun! xtabline#dir#info() abort
  " Print current repo/cwd/tagfiles information. {{{1

  " show global/local cwd
  let cwd = haslocaldir(winnr(), tabpagenr())? 'local cwd:' : 'cwd:'
  echo printf("%-20s %s", 'Current '.cwd, getcwd())

  " show tab cwd, if present
  if exists(':tcd') == 2 && haslocaldir(-1, 0)
    echo printf("%-20s %s", 'Current tab cwd', getcwd(-1, 0))
  endif

  " show git dir
  try
    let d = exists('*FugitiveGitDir')
          \ ? substitute(FugitiveGitDir(), '/\.git$', '', '') : getcwd()
    let gitdir = systemlist('git -C '.d.' rev-parse --show-toplevel 2>/dev/null')[0]
    if gitdir != ''
      echo printf("%-20s %s", 'Current git dir:', gitdir)
    endif
  catch
  endtry

  " show current tagfiles
  if !empty(tagfiles())
    echo printf("%-20s %s", 'Tag files:', string(tagfiles()))
  endif
endfun "}}}





"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Main functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Dir.manual_cwd(dir, type) abort
  " Set the working directory through mappings or Ex commands. {{{1
  " Confirmation may be needed.
  let dir = match(a:dir, '\%(/\|\\\)$') > 0 ? a:dir[:-2] : a:dir

  if !isdirectory(dir)
    return self.msg("Invalid directory: ".dir, 1)
  endif
  call extend(s:T(), { 'cwd': dir })

  let [error, out] = self.change_wd(dir, a:type)

  if error
    return self.msg([[ "Directory not set: ", 'WarningMsg' ], [ out, 'None' ]])
  endif

  call xtabline#update()
  call self.msg ([[ out." directory: ", 'Label' ], [ dir, 'None' ]])
  return 1
endfun "}}}

"------------------------------------------------------------------------------

fun! s:Dir.change_wd(dir, ...) abort
  " Change working directory, update tab cwd and session data. {{{1

  if !a:0   " automatic attempt to change working directory
    return self.try_auto_change(a:dir)
  else
    let type = a:1
    let [error, out] = [0, type]
  endif

  if s:Dir.no_difference(type, a:dir)
      let [error, out] = [1, 'no difference']

  elseif type == 'window-local'
    " explicitly asking to set a window-local working directory
      exe 'lcd' a:dir

  elseif type == 'tab-local'
    " explicitly asking to set a tab-local working directory
      exe 'tcd' a:dir

  elseif self.is_local_dir() && getcwd() ==# a:dir
    " same directory as current window-local directory, either keep or clear {{{2
    let action = confirm('Same as current window-local directory, keep it or clear it?',
          \"&Keep\n&Clear")

    if action < 2
      let [error, out] = [1, 'window-local directory unchanged']
    else
      exe 'cd' a:dir
      let [error, out] = [0, 'working']
    endif "}}}

  elseif self.is_local_dir()
    " there is a window-local directory that would be overwritten, ask {{{2
    let action = confirm('Overwrite window-local directory ' .getcwd(). '?', "&Yes\n&No\n&Clear")

    if action == 1
      exe 'lcd' a:dir
      let [error, out] = [0, 'window-local']
    elseif action == 3
      exe 'cd' a:dir
    else
      let [error, out] = [1, 'window-local directory unchanged']
    endif "}}}

  elseif self.is_tab_dir() && getcwd(-1, 0) ==# a:dir
    " same directory as current tab-local directory, either keep or clear {{{2
    let action = confirm('Same as current tab-local directory, keep it or clear it?',
          \"&Keep\n&Clear")

    if action < 2
      let [error, out] = [1, 'tab-local directory unchanged']
    else
      exe 'cd' a:dir
      let [error, out] = [0, 'working']
    endif "}}}

  elseif self.is_tab_dir()
    " there is a tab-local directory that would be overwritten, ask {{{2
    let action = confirm('Overwrite tab-local directory ' .getcwd(-1, 0). '?', "&Yes\n&No\n&Clear")

    if action == 1
      exe 'tcd' a:dir
      let [error, out] = [0, 'tab-local']
    elseif action == 3
      exe 'cd' a:dir
    else
      let [error, out] = [1, 'tab-local directory unchanged']
    endif "}}}

  else
    " no tab cwd, no local cwd: just cd
    exe 'cd' a:dir
  endif

  if !self.is_local_dir()
    call self.set_tab_wd()
  endif

  call xtabline#update_this_session()
  return [error, out]
endfun "}}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! s:Dir.set_tab_wd() abort
  " Update the tab object's working directory. {{{1

  let T = s:T()
  if self.has_tcd()
    let T.cwd = self.fullpath(getcwd(-1, tabpagenr()))
  elseif !haslocaldir()
    let T.cwd = self.fullpath(getcwd())
  endif
endfun "}}}


fun! s:Dir.try_auto_change(dir) abort
  " Not a manual cwd change, check if it must be applied. "{{{1

  if getcwd() ==# a:dir
    return
  endif

  if self.is_local_dir()
    exe 'lcd' a:dir
  " elseif self.is_tab_dir() && getcwd(-1, 0) !=# a:dir
  "   exe 'tcd' a:dir
  endif
  call self.set_tab_wd()
  call xtabline#update_this_session()
endfun "}}}

"------------------------------------------------------------------------------

fun! s:Dir.find_root_dir(...) abort
  " Look for a VCS dir below current directory {{{1

  let current = a:0 ? a:1 : expand("%:h")
  let dir = system('git -C '.current.' rev-parse --show-toplevel 2>/dev/null')[:-2]
  return !empty(dir) ? dir : a:0 ? a:1 : current
endfun "}}}


fun! s:Dir.has_tcd() abort
  " Check if :tcd can be used. {{{1
  return exists(':tcd') == 2
endfun "}}}


fun! s:Dir.is_local_dir() abort
  "Check if there is a window-local directory. {{{1
  return haslocaldir(winnr(), tabpagenr())
endfun "}}}


fun! s:Dir.is_tab_dir() abort
  "Check if there is a tab-local directory. {{{1
  return exists(':tcd') == 2 && haslocaldir(-1, 0)
endfun "}}}


fun s:Dir.no_difference(type, dir)
  " Check if the the requested directory and type match the current ones. {{{1
  let [window, tab] = [self.is_local_dir(), self.is_tab_dir()]

  return     (a:type == 'window-local' && window && getcwd(0, 0) ==# a:dir)
        \ || (a:type == 'tab-local'    && tab    && getcwd(-1, 0) ==# a:dir)
        \ || (a:type == 'working' && !window && !tab && getcwd() ==# a:dir)
endfun "}}}

fun! s:Dir.get_cd_cmd() abort
  " Return the most appropriate command for automatic mode. {{{1
  return self.is_local_dir() ? 'lcd' : self.is_tab_dir() ? 'tcd' : 'cd'
endfun "}}}

