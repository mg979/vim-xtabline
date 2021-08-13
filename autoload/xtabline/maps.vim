""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:base_mappings() abort
  if !hasmapto('<Plug>(XT-Select-Buffer)')
    silent! nmap <BS> <Plug>(XT-Select-Buffer)
  endif

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

  call s:mapkey_('<F5>', 'Mode')
  call s:mapkeyc(']b',   'NextBuffer')
  call s:mapkeyc('[b',   'PrevBuffer')
  call s:mapkey0('cdc',  'CD')
  call s:mapkey_('cdw',  'WD')
  call s:mapkey_('cd?',  'Info')
  call s:mapkey_('cdl',  'LD')

  if exists(':tcd') == 2
    call s:mapkey_('cdt',  'TD')
  endif
endfun


fun! s:prefix_mappings() abort
  let S = g:xtabline_settings
  let X = substitute(S.map_prefix, '<leader>', get(g:, 'mapleader', '\'), 'g')

  call s:mapkey_(X.'q',  'CloseBuffer')
  call s:mapkey_(X.'a',  'ListTabs')
  call s:mapkey_(X.'z',  'ListBuffers')
  call s:mapkey_(X.'x',  'Purge')
  call s:mapkey_(X.'\',  'Last')
  call s:mapkey_(X.'u',  'Reopen')
  call s:mapkey_(X.'U',  'ReopenList')
  call s:mapkey_(X.'p',  'PinBuffer')
  call s:mapkeyc(X.'m',  'MoveBuffer')
  call s:mapkeyc(X.']',  'MoveBufferNext')
  call s:mapkeyc(X.'[',  'MoveBufferPrev')
  call s:mapkey_(X.'h',  'HideBuffer')
  call s:mapkey_(X.'k',  'CleanUp')
  call s:mapkey_(X.'K',  'CleanUp!')
  call s:mapkey_(X.'d',  'Todo')
  call s:mapkey_(X.'.',  'ToggleLabels')
  call s:mapkey_(X.'/',  'Filtering')
  call s:mapkey0(X.'+',  'Paths')
  call s:mapkey0(X.'-',  'Paths!')
  call s:mapkey_(X.'?',  'Menu')
  call s:mapkey_(X.'R',  'ResetAll')
  call s:mapkeys(X.'T',  'Theme')
  call s:mapkey_(X.'tr', 'ResetTab')
  call s:mapkeys(X.'ti', 'IconTab')
  call s:mapkeys(X.'tn', 'NameTab')
  call s:mapkeys(X.'bi', 'IconBuffer')
  call s:mapkeys(X.'bn', 'NameBuffer')
  call s:mapkey_(X.'br', 'ResetBuffer')
  call s:mapkey_(X.'bd', 'DeleteBuffers')
  call s:mapkey_(X.'tl', 'LoadTab')
  call s:mapkey_(X.'ts', 'SaveTab')
  call s:mapkey_(X.'td', 'DeleteTab')
  call s:mapkey_(X.'sl', 'LoadSession')
  call s:mapkey_(X.'ss', 'SaveSession')
  call s:mapkey_(X.'sd', 'DeleteSession')
  call s:mapkey_(X.'sn', 'NewSession')

  exe 'nnoremap' X '<Nop>'
endfun


function! xtabline#maps#init()
  nnoremap <unique> <silent> <expr> <Plug>(XT-Select-Buffer) v:count
        \ ? xtabline#cmds#select_buffer(v:count-1)
        \ : ":\<C-U>buffer #\r"
  let S = g:xtabline_settings
  if S.enable_mappings
    call s:base_mappings()
    if get(g:, 'mapleader', '\') =~ ' \+'
      let S.map_prefix = substitute(S.map_prefix, '<leader>', '<space>', 'g')
    endif
    call s:prefix_mappings()
  endif
endfunction


fun! xtabline#maps#menu() abort
  let basic = [
        \['<F5>', 'Cycle mode'],
        \[']b',   'Next Buffer'],
        \['[b',   'Prev Buffer'],
        \]

  let cd = [
        \['cdw',  'Working directory'],
        \['cd?',  'Directory info'],
        \['cdl',  'Window-local directory'],
        \['cdc',  'Cd to current directory'],
        \]

  let leader = [
        \['\',    'Go to last tab'],
        \['+',    'Paths format (+)'],
        \['/',    'Toggle filtering'],
        \['-',    'Paths format (-)'],
        \['.',    'Toggle user labels'],
        \['', ''],
        \['', ''],
        \['', ''],
        \['a',    'List tabs'],
        \[']',    'Move buffer forwards'],
        \['z',    'List buffers'],
        \['[',    'Move buffer backwards'],
        \['', ''],
        \['', ''],
        \['m',    'Move buffer to...'],
        \['h',    'Hide buffer'],
        \['q',    'Close buffer'],
        \['u',    'Reopen last tab'],
        \['U',    'Reopen tab from list'],
        \['p',    'Pin buffer'],
        \['d',    'Tab todo'],
        \['', ''],
        \['', ''],
        \['k',    'Clean up tabs'],
        \['x',    'Purge tab'],
        \['K',    'Clean up! tabs'],
        \['R',    'Reset all'],
        \['T',    'Select theme'],
        \]

  let manage = [
        \['bd',   'Delete tab buffers'],
        \['bi',   'Change buffer icon'],
        \['bn',   'Name buffer'],
        \['br',   'Reset buffer'],
        \['', ''],
        \['', ''],
        \['sd',   'Delete session'],
        \['sl',   'Load session'],
        \['sn',   'New session'],
        \['ss',   'Save session'],
        \['', ''],
        \['', ''],
        \['td',   'Delete tab'],
        \['ti',   'Change tab icon'],
        \['tl',   'Load tab'],
        \['tn',   'Name tab'],
        \['tr',   'Reset tab'],
        \['ts',   'Save tab'],
        \]

  if exists(':tcd') == 2
    call insert(cd, ['cdt', 'Tab-local directory'], 1)
  endif

  let X = substitute(g:xtabline_settings.map_prefix, '<leader>', get(g:, 'mapleader', '\'), 'g')
  vnew +setlocal\ bt=nofile\ bh=wipe\ noswf\ nobl xtabline mappings
  80wincmd |
  let text = []
  for group in [[basic, 'basic'], [cd, 'cd'], [leader, X], [manage, X.' tabs/buffer/session']]
    let i = 1
    call add(text, "\n" . group[1] . " mappings:\n")
    for m in group[0]
      if i % 2
        call add(text, printf("%-25s%-10s", m[1], m[0]))
      else
        let text[-1] .= printf("%-25s%-10s", m[1], m[0])
      endif
      let i += 1
    endfor
  endfor
  silent put =text
  silent normal! gg2"_dd
  syntax match XtablineMappings '^.*:$'
  hi default link XtablineMappings Title
endfun


" vim: et sw=2 ts=2 sts=2 fdm=indent fdn=1
