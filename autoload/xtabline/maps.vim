""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:do_map()

  let S = g:xtabline_settings
  let X = S.map_prefix

  fun! s:mapkeys(keys, plug)
    let plug = '<Plug>(XT-'.a:plug.')'
    if !hasmapto(plug)
      silent! execute 'nmap <unique>' a:keys plug
    endif
  endfun

  call s:mapkeys('<F5>',  'Toggle-Tabs')
  call s:mapkeys('<BS>',  'Select-Buffer')
  call s:mapkeys(']b',    'Next-Buffer')
  call s:mapkeys('[b',    'Prev-Buffer')
  call s:mapkeys('[B',    'First-Buffer')
  call s:mapkeys(']B',    'Last-Buffer')
  call s:mapkeys(X.'q',   'Close-Buffer')
  call s:mapkeys(X.'e',   'Edit')
  call s:mapkeys(X.'bl',  'List-Buffers')
  call s:mapkeys(X.'tl',  'List-Tabs')
  call s:mapkeys(X.'db',  'Delete-Buffers')
  call s:mapkeys(X.'dgb', 'Delete-Global-Buffers')
  call s:mapkeys(X.'lt',  'Load-Tab')
  call s:mapkeys(X.'st',  'Save-Tab')
  call s:mapkeys(X.'dt',  'Delete-Tab')
  call s:mapkeys(X.'ls',  'Load-Session')
  call s:mapkeys(X.'ss',  'Save-Session')
  call s:mapkeys(X.'ds',  'Delete-Session')
  call s:mapkeys(X.'ns',  'New-Session')
  call s:mapkeys(X.'te',  'Tab-Edit')
  call s:mapkeys(X.'tn',  'Tab-New')
  call s:mapkeys(X.'pt',  'Purge')
  call s:mapkeys(X.'wa',  'Wipe-All')
  call s:mapkeys(X.'wd',  'Working-Directory')
  call s:mapkeys(X.'cu',  'Clean-Up')
  call s:mapkeys(X.'rt',  'Reopen')
  call s:mapkeys(X.'sd',  'Set-Depth')
  call s:mapkeys(X.'it',  'Tab-Icon')
  call s:mapkeys(X.'ib',  'Buffer-Icon')
  call s:mapkeys(X.'nt',  'Rename-Tab')
  call s:mapkeys(X.'nb',  'Rename-Buffer')
  call s:mapkeys(X.'fb',  'Buffer-Format')
  call s:mapkeys(X.'tt',  'Tab-Todo')
  call s:mapkeys(X.'rp',  'Relative-Paths')
  call s:mapkeys(X.'ct',  'Toggle-Custom-Tabs')
  call s:mapkeys(X.'pb',  'Pin-Buffer')
  call s:mapkeys(X.'C',   'Config')
  call s:mapkeys(X.'T',   'Theme')
  call s:mapkeys(X.'mb',  'Move-Buffer-To')
  call s:mapkeys(X.'hb',  'Hide-Buffer')
  call s:mapkeys(X.'tf',  'Toggle-Filtering')
  call s:mapkeys(X.'cdc', 'Cd-Current')
  call s:mapkeys(X.'cdd', 'Cd-Down')
  call s:mapkeys(X.'tr',  'Reset-Tab')
  call s:mapkeys(X.'br',  'Reset-Buffer')
  call s:mapkeys(X.'tv',  'Tab-Vimrc')

  if maparg(toupper(X)) == '' && !hasmapto('<Plug>(XT-Menu)')
    silent! execute 'nmap <unique><nowait>' toupper(X) '<Plug>(XT-Menu)'
  endif
endfun

function! xtabline#maps#init()

  nnoremap <unique>                 <Plug>(XT-Tab-New)               :<c-u>XTabNew<space>
  nnoremap <unique>                 <Plug>(XT-Tab-Edit)              :<c-u>XTabEdit<space>
  nnoremap <unique>                 <Plug>(XT-Edit)                  :<c-u>XEdit<space>

  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Tabs)           :<c-u>call xtabline#cmds#run('toggle_tabs')<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Filtering)      :<c-u>call xtabline#cmds#run('toggle_buffers')<cr>
  nnoremap <unique> <silent> <expr> <Plug>(XT-Select-Buffer)         v:count? <sid>select_buffer(v:count-1) : ":\<C-U>".g:xtabline_settings.select_buffer_alt_action."\<cr>"
  nnoremap <unique> <silent> <expr> <Plug>(XT-Next-Buffer)           xtabline#cmds#next_buffer(v:count1, 0)
  nnoremap <unique> <silent> <expr> <Plug>(XT-Prev-Buffer)           xtabline#cmds#prev_buffer(v:count1, 0)
  nnoremap <unique> <silent> <expr> <Plug>(XT-Last-Buffer)           xtabline#cmds#next_buffer(v:count1, 1)
  nnoremap <unique> <silent> <expr> <Plug>(XT-First-Buffer)          xtabline#cmds#prev_buffer(v:count1, 1)
  nnoremap <unique> <silent>        <Plug>(XT-Close-Buffer)          :<c-u>XTabCloseBuffer<cr>
  nnoremap <unique> <silent>        <Plug>(XT-List-Buffers)          :<c-u>XTabListBuffers<cr>
  nnoremap <unique> <silent>        <Plug>(XT-List-Tabs)             :<c-u>XTabListTabs<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Delete-Buffers)        :<c-u>XTabDeleteBuffers<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Delete-Global-Buffers) :<c-u>XTabDeleteGlobalBuffers<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Load-Tab)              :<c-u>XTabLoadTab<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Save-Tab)              :<c-u>XTabSaveTab<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Delete-Tab)            :<c-u>XTabDeleteTab<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Load-Session)          :<c-u>XTabLoadSession<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Save-Session)          :<c-u>XTabSaveSession<cr>
  nnoremap <unique> <silent>        <Plug>(XT-New-Session)           :<c-u>XTabNewSession<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Delete-Session)        :<c-u>XTabDeleteSession<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Purge)                 :<c-u>XTabPurge<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Pin-Buffer)            :<c-u>XTabPinBuffer<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Clean-Up)              :<c-u>XTabCleanUp<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Wipe-All)              :<c-u>XTabCleanUp!<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Reopen)                :<c-u>XTabReopen<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Working-Directory)     :<c-u>XTabWD!<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Set-Depth)             :<c-u>call xtabline#cmds#run('depth', v:count)<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Move-Buffer-Next)      :<c-u>call xtabline#cmds#run('move_buffer', 1, v:count1)<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Move-Buffer-Prev)      :<c-u>call xtabline#cmds#run('move_buffer', 0, v:count1)<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Move-Buffer-To)        :<c-u>call xtabline#cmds#run('move_buffer_to', v:count)<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Hide-Buffer)           :<c-u>call xtabline#cmds#run('hide_buffer', v:count1)<cr>
  nnoremap <unique> <silent> <expr> <Plug>(XT-Hide-Buffer-n)         v:count? ":\<c-u>call xtabline#cmds#run('hide_buffer', v:count)\<cr>" : ":\<C-U>".g:xtabline_settings.hide_buffer_alt_action."\<cr>"
  nnoremap <unique> <silent>        <Plug>(XT-Tab-Todo)              :<c-u>XTabTodo<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Tab-Vimrc)             :<c-u>call xtabline#vimrc#open()<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Custom-Tabs)    :<c-u>XTabCustomTabs<cr>
  nnoremap <unique>                 <Plug>(XT-Theme)                 :<c-u>XTabTheme<Space>
  nnoremap <unique>                 <Plug>(XT-Tab-Icon)              :<c-u>XTabIcon<Space>
  nnoremap <unique>                 <Plug>(XT-Config)                :<c-u>XTabConfig<cr>
  nnoremap <unique>                 <Plug>(XT-Buffer-Icon)           :<c-u>XTabBufferIcon<Space>
  nnoremap <unique>                 <Plug>(XT-Rename-Tab)            :<c-u>XTabRenameTab<Space>
  nnoremap <unique>                 <Plug>(XT-Rename-Buffer)         :<c-u>XTabRenameBuffer<Space>
  nnoremap <unique>                 <Plug>(XT-Buffer-Format)         :<c-u>XTabFormatBuffer<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Cd-Current)            :<c-u>call <sid>cd(0)<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Cd-Down)               :<c-u>call <sid>cd(v:count1)<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Reset-Tab)             :<c-u>XTabResetTab<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Reset-Buffer)          :<c-u>XTabResetBuffer<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Relative-Paths)        :<c-u>XTabRelativePaths<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Menu)                  :<c-u>XTabMenu<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Update)                :<c-u>call xtabline#update()<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Refresh)               :<c-u>call xtabline#refresh()<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Last-Tab)              :<c-u>call xtabline#cmds#run('goto_last_tab')<cr>


  if g:xtabline_settings.enable_mappings | call s:do_map() | endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:select_buffer(cnt)
  let Fmt = g:xtabline_settings.bufline_format
  if type(Fmt) == v:t_number && Fmt == 1
    let cn = a:cnt + 1
    return ":\<C-U>silent! exe 'b'.".cn."\<cr>"
  endif
  let bufs = g:xtabline.Tabs[tabpagenr()-1].buffers.order
  let n = min([a:cnt, len(bufs)-1])
  let b = bufs[n]
  return ":\<C-U>silent! exe 'b'.".b."\<cr>"
endfun

fun! s:cd(count)
  let path = ':p:h'
  for c in range(a:count)
    let path .= ':h'
  endfor
  let cwd = g:xtabline.Funcs.fullpath(expand("%"), path)
  call g:xtabline.Funcs.change_wd(cwd)
endfun

