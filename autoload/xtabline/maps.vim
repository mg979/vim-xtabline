""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:do_map() abort

  let S = g:xtabline_settings
  let X = S.map_prefix

  fun! s:mapkey_(keys, cmd) abort
    let cmd = ':<c-u>XTab'.a:cmd.'<CR>'
    if maparg(a:keys, 'n') == ''
      silent! execute 'nnoremap <silent><unique>' a:keys cmd
    endif
  endfun

  fun! s:mapkeyc(keys, cmd) abort
    let cmd = ':<c-u>XTab'.a:cmd.' <C-r>=v:count1<CR><CR>'
    if maparg(a:keys, 'n') == ''
      silent! execute 'nnoremap <silent><unique>' a:keys cmd
    endif
  endfun

  fun! s:mapkey0(keys, cmd) abort
    let cmd = ':<c-u>XTab'.a:cmd.' <C-r>=v:count<CR><CR>'
    if maparg(a:keys, 'n') == ''
      silent! execute 'nnoremap <silent><unique>' a:keys cmd
    endif
  endfun

  fun! s:mapkeys(keys, cmd) abort
    let cmd = ':<c-u>XTab'.a:cmd.'<Space>'
    if maparg(a:keys, 'n') == ''
      silent! execute 'nnoremap <unique>' a:keys cmd
    endif
  endfun

  if !hasmapto('<Plug>(XT-Select-Buffer)')
    silent! nmap <BS> <Plug>(XT-Select-Buffer)
  endif

  if maparg(X, 'n') == ''
    exe 'nnoremap' X '<Nop>'
  endif

  call s:mapkey_('<F5>', 'CycleMode')
  call s:mapkeyc(']b',   'NextBuffer')
  call s:mapkeyc('[b',   'PrevBuffer')
  call s:mapkey_('cdc',  'CdCurrent')
  call s:mapkeyc('cdd',  'CdDown')
  call s:mapkey_('cdw',  'WD')
  call s:mapkey_('cd?',  'Info')
  call s:mapkey_('cdl',  'LD')
  call s:mapkey_(X.'q',  'CloseBuffer')
  call s:mapkey_(X.'a',  'ListTabs')
  call s:mapkey_(X.'z',  'ListBuffers')
  call s:mapkey_(X.'x',  'Purge')
  call s:mapkey_(X.'\',  'Last')
  call s:mapkey_(X.'u',  'Reopen')
  call s:mapkey_(X.'p',  'PinBuffer')
  call s:mapkeyc(X.'m',  'MoveBuffer')
  call s:mapkeyc(X.']',  'MoveBufferNext')
  call s:mapkeyc(X.'[',  'MoveBufferPrev')
  call s:mapkey_(X.'h',  'HideBuffer')
  call s:mapkey_(X.'k',  'CleanUp')
  call s:mapkey_(X.'K',  'CleanUp!')
  call s:mapkey_(X.'d',  'Todo')
  call s:mapkey_(X.'.',  'CustomLabels')
  call s:mapkey_(X.'/',  'Filtering')
  call s:mapkey0(X.'+',  'RelativePaths')
  call s:mapkey0(X.'-',  'RelativePaths!')
  call s:mapkey_(X.'?',  'Menu')
  call s:mapkey_(X.'C',  'Config')
  call s:mapkeys(X.'T',  'Theme')
  call s:mapkey_(X.'tr', 'ResetTab')
  call s:mapkeys(X.'ti', 'Icon')
  call s:mapkeys(X.'tn', 'RenameTab')
  call s:mapkeys(X.'bi', 'BufferIcon')
  call s:mapkeys(X.'bn', 'RenameBuffer')
  call s:mapkey_(X.'br', 'ResetBuffer')
  call s:mapkey_(X.'bd', 'DeleteBuffers')
  call s:mapkey_(X.'tl', 'LoadTab')
  call s:mapkey_(X.'ts', 'SaveTab')
  call s:mapkey_(X.'td', 'DeleteTab')
  call s:mapkey_(X.'sl', 'LoadSession')
  call s:mapkey_(X.'ss', 'SaveSession')
  call s:mapkey_(X.'sd', 'DeleteSession')
  call s:mapkey_(X.'sn', 'NewSession')

  if exists(':tcd') == 2
    call s:mapkey_('cdt',  'TD')
  endif
endfun

function! xtabline#maps#init()
  nnoremap <unique> <silent> <expr> <Plug>(XT-Select-Buffer) v:count
        \ ? xtabline#cmds#select_buffer(v:count-1)
        \ : ":\<C-U>".g:xtabline_settings.select_buffer_alt_action."\<cr>"
  if g:xtabline_settings.enable_mappings | call s:do_map() | endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:basic = [
      \['<F5>', 'Cycle mode',                   "XTabCycleMode"],
      \[']b',   'Next Buffer',                  "XTabNextBuffer"],
      \['[b',   'Prev Buffer',                  "XTabPrevBuffer"],
      \]

let s:cd = [
      \['cdw',  'Working directory',            "XTabWD"],
      \['cd?',  'Directory info',               "XTabInfo"],
      \['cdl',  'Window-local directory',       "XTabLD"],
      \['cdc',  'Cd to current directory',      "XTabCdCurrent"],
      \['cdd',  'Cd to parent directory',       "XTabCdDown"],
      \]

let s:leader = [
      \['\',    'Go to last tab',               "XTabLastTab"],
      \['+',    'Relative paths (+)',           "XTabRelativePaths"],
      \['/',    'Toggle filtering',             "XTabFiltering"],
      \['-',    'Relative paths (-)',           "XTabRelativePaths!"],
      \['.',    'Toggle custom tabs',           "XTabCustomLabels"],
      \['', '', ''],
      \['', '', ''],
      \['', '', ''],
      \['a',    'List tabs',                    "XTabListTabs"],
      \[']',    'Move buffer forwards',         "XTabMoveBufferNext"],
      \['z',    'List buffers',                 "XTabListBuffers"],
      \['[',    'Move buffer backwards',        "XTabMoveBufferPrev"],
      \['', '', ''],
      \['', '', ''],
      \['m',    'Move buffer to...',            "XTabMoveBuffer"],
      \['h',    'Hide buffer',                  "XTabHideBuffer"],
      \['q',    'Close buffer',                 "XTabCloseBuffer"],
      \['u',    'Reopen last tab',              "XTabReopen"],
      \['p',    'Pin buffer',                   "XTabPinBuffer"],
      \['d',    'Tab todo',                     "XTabTodo"],
      \['', '', ''],
      \['', '', ''],
      \['k',    'Clean up tabs',                "XTabCleanUp"],
      \['x',    'Purge tab',                    "XTabPurge"],
      \['K',    'Clean up! tabs',               "XTabCleanUp!"],
      \['', '', ''],
      \['', '', ''],
      \['', '', ''],
      \['C',    'Configure',                    "XTabConfig"],
      \['T',    'Select theme',                 "XTabTheme  "],
      \]

let s:manage = [
      \['bd',   'Delete tab buffers',           "XTabDeleteBuffers"],
      \['bi',   'Change buffer icon',           "XTabBufferIcon "],
      \['bn',   'Rename buffer',                "XTabRenameBuffer "],
      \['br',   'Reset buffer',                 "XTabResetBuffer"],
      \['', '', ''],
      \['', '', ''],
      \['sd',   'Delete session',               "XTabDeleteSession"],
      \['sl',   'Load session',                 "XTabLoadSession"],
      \['sn',   'New session',                  "XTabNewSession"],
      \['ss',   'Save session',                 "XTabSaveSession"],
      \['', '', ''],
      \['', '', ''],
      \['td',   'Delete tab',                   "XTabDeleteTab"],
      \['ti',   'Change tab icon',              "XTabIcon  "],
      \['tl',   'Load tab',                     "XTabLoadTab"],
      \['tn',   'Rename tab',                   "XTabRenameTab "],
      \['tr',   'Reset tab',                    "XTabResetTab"],
      \['ts',   'Save tab',                     "XTabSaveTab"],
      \]

if exists(':tcd') == 2
  call insert(s:cd, ['cdt', 'Tab-local directory', "XTabTD"], 1)
endif

fun! xtabline#maps#menu() abort
  let X = substitute(g:xtabline_settings.map_prefix, '<leader>', get(g:, 'mapleader', '\'), 'g')
  for group in [[s:basic, 'basic'], [s:cd, 'cd'], [s:leader, X], [s:manage, X.' tabs/buffer/session']]
    let i = 1
    echohl Title
    echo "\n" . group[1] "mappings:\n\n"
    echohl None
    for m in group[0]
      if i % 2
        echo printf("%-25s%-10s", m[1], m[0])
      else
        echon printf("%-25s%s", m[1], m[0])
      endif
      let i += 1
    endfor
  endfor
  echo "\n\\x... "
  let [ch, cmd] = [nr2char(getchar()), '']
  let i = index(map(copy(s:leader), 'v:val[0]'), ch)
  if i >= 0
    let cmd = s:leader[i][2]
  elseif index(['b', 't', 's'], ch) >= 0
    echon ch
    let ch .= nr2char(getchar())
    let i = index(map(copy(s:manage), 'v:val[0]'), ch)
    if i >= 0
      let cmd = s:manage[i][2]
    endif
  endif
  let tab = "\<c-r>=feedkeys(\"\<Tab>\", 't')\<cr>"
  if !empty(cmd)
    call feedkeys("\<cr>:".cmd.(cmd[-2:-1]=='  '?tab:cmd[-1:-1]==' '?'':"\<cr>"), 'n')
  else
    call feedkeys("\<cr>", 'n')
  endif
endfun

