""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:do_map() abort

  let S = g:xtabline_settings
  let X = S.map_prefix

  fun! s:mapkey_(keys, cmd) abort
    let cmd = ':<c-u>XTab'.a:cmd.'<CR>'
    if !hasmapto(cmd)
      silent! execute 'nnoremap <silent><unique>' a:keys cmd
    endif
  endfun

  fun! s:mapkeyc(keys, cmd) abort
    let cmd = ':<c-u>XTab'.a:cmd.' <C-r>=v:count1<CR><CR>'
    if !hasmapto(cmd)
      silent! execute 'nnoremap <silent><unique>' a:keys cmd
    endif
  endfun

  fun! s:mapkey0(keys, cmd) abort
    let cmd = ':<c-u>XTab'.a:cmd.' <C-r>=v:count<CR><CR>'
    if !hasmapto(cmd)
      silent! execute 'nnoremap <silent><unique>' a:keys cmd
    endif
  endfun

  fun! s:mapkeys(keys, cmd) abort
    let cmd = ':<c-u>XTab'.a:cmd.'<Space>'
    if !hasmapto(cmd)
      silent! execute 'nnoremap <unique>' a:keys cmd
    endif
  endfun

  if !hasmapto('<Plug>(XT-Select-Buffer)')
    silent! nmap <BS> <Plug>(XT-Select-Buffer)
  endif

  call s:mapkey_('<F5>',  'CycleMode')
  call s:mapkeyc(']b',    'NextBuffer')
  call s:mapkeyc('[b',    'PrevBuffer')
  call s:mapkey_('[B',    'FirstBuffer')
  call s:mapkey_(']B',    'LastBuffer')
  call s:mapkey_('cdc',   'CdCurrent')
  call s:mapkeyc('cdd',   'CdDown')
  call s:mapkey_('cdw',   'WD!')
  call s:mapkey_('cdb',   'BD')
  call s:mapkey_(X.'q',   'CloseBuffer')
  call s:mapkey_(X.'x',   'Purge')
  call s:mapkey_(X.'z',   'Last')
  call s:mapkey_(X.'u',   'Reopen')
  call s:mapkey_(X.'b',   'PinBuffer')
  call s:mapkeyc(X.'m',   'MoveBufferTo')
  call s:mapkey_(X.'h',   'HideBuffer')
  call s:mapkey_(X.'f',   'ToggleFiltering')
  call s:mapkey_(X.'c',   'CleanUp')
  call s:mapkey_(X.'k',   'CleanUp!')
  call s:mapkey_(X.'d',   'Todo')
  call s:mapkey0(X.'p',   'RelativePaths')
  call s:mapkey_(X.'tc',  'CustomTabs')
  call s:mapkey_(X.'tr',  'ResetTab')
  call s:mapkeys(X.'te',  'Edit')
  call s:mapkeys(X.'ti',  'TabIcon')
  call s:mapkeys(X.'tn',  'RenameTab')
  call s:mapkeys(X.'bi',  'BufferIcon')
  call s:mapkeys(X.'bn',  'RenameBuffer')
  call s:mapkey_(X.'br',  'ResetBuffer')
  call s:mapkey_(X.'bf',  'FormatBuffer')
  call s:mapkey_(X.'C',   'Config')
  call s:mapkeys(X.'T',   'Theme')

  if exists('g:loaded_fzf')
    call s:mapkey_(X.'<space>', 'ListBuffers')
    call s:mapkey_(X.'a',       'ListTabs')
    call s:mapkey_(X.'bd',      'DeleteBuffers')
    call s:mapkey_(X.'tl',      'LoadTab')
    call s:mapkey_(X.'ts',      'SaveTab')
    call s:mapkey_(X.'td',      'DeleteTab')
    call s:mapkey_(X.'ls',      'LoadSession')
    call s:mapkey_(X.'ss',      'SaveSession')
    call s:mapkey_(X.'sd',      'DeleteSession')
    call s:mapkey_(X.'sn',      'NewSession')
  endif

  if maparg(toupper(X)) == '' && !hasmapto('<Plug>(XT-Menu)')
    silent! execute 'nmap <unique><nowait>' toupper(X) '<Plug>(XT-Menu)'
  endif
endfun

function! xtabline#maps#init()

  nnoremap <unique> <silent> <expr> <Plug>(XT-Select-Buffer)         v:count? <sid>select_buffer(v:count-1) : ":\<C-U>".g:xtabline_settings.select_buffer_alt_action."\<cr>"

  if g:xtabline_settings.enable_mappings | call s:do_map() | endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:select_buffer(cnt) abort
  let Fmt = g:xtabline_settings.buffer_format
  if type(Fmt) == v:t_number && Fmt == 1
    let cn = a:cnt + 1
    return ":\<C-U>silent! exe 'b'.".cn."\<cr>"
  endif
  let bufs = g:xtabline.Tabs[tabpagenr()-1].buffers.order
  let n = min([a:cnt, len(bufs)-1])
  let b = bufs[n]
  return ":\<C-U>silent! exe 'b'.".b."\<cr>"
endfun

