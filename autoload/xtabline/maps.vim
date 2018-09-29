""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:do_map()

  let S = g:xtabline_settings
  let X = S.map_prefix
  let L = '<leader>'

  fun! s:mapkeys(keys, plug)
    let plug = '<Plug>(XT-'.a:plug.')'
    if maparg(a:keys, 'n') == '' && !hasmapto(plug)
      silent! execute 'nmap <unique>' a:keys plug
    endif
  endfun

  call s:mapkeys('<F5>',  'Toggle-Tabs')
  call s:mapkeys('<BS>',  'Select-Buffer')
  call s:mapkeys(']b',    'Next-Buffer')
  call s:mapkeys('[b',    'Prev-Buffer')
  call s:mapkeys('[B',    'Prev-Pinned')
  call s:mapkeys(']B',    'Next-Pinned')
  call s:mapkeys(X.'q',   'Close-Buffer')
  call s:mapkeys(X.'e',   'Edit')
  call s:mapkeys(X.'lb',  'List-Buffers')
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
  call s:mapkeys(X.'mb',  'Move-Buffer')
  call s:mapkeys(X.'hb',  'Hide-Buffer')
  call s:mapkeys(X.'tf',  'Toggle-Filtering')
  call s:mapkeys(X.'cdc', 'Cd-Current')
  call s:mapkeys(X.'cdd', 'Cd-Down')
  call s:mapkeys(X.'Rt',  'Reset-Tab')
  call s:mapkeys(X.'Rb',  'Reset-Buffer')

  call s:mapkeys('+t',    'Move-Tab+')
  call s:mapkeys('-t',    'Move-Tab-')
  call s:mapkeys('+T',    'Move-Tab0')
  call s:mapkeys('-T',    'Move-Tab$')

  if exists('g:loaded_leaderGuide_vim') && maparg(toupper(X)) == '' && !hasmapto('<Plug>(XT-Leader-Guide)')
    silent! execute 'nmap <unique>' X '<Plug>(XT-Leader-Guide)'
    silent! execute 'nmap <unique><nowait>' toupper(X) '<Plug>(XT-Leader-Guide)'
  endif
endfun

function! xtabline#maps#init()

  nnoremap <unique> <silent>        <Plug>(XT-Move-Tab+)             :XTabMove +<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Move-Tab-)             :XTabMove -<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Move-Tab0)             :<c-u>XTabMove 0<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Move-Tab$)             :<c-u>XTabMove $<cr>
  nnoremap <unique>                 <Plug>(XT-Tab-New)               :<c-u>XTabNew<space>
  nnoremap <unique>                 <Plug>(XT-Tab-Edit)              :<c-u>XTabEdit<space>
  nnoremap <unique>                 <Plug>(XT-Edit)                  :<c-u>XEdit<space>

  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Tabs)           :<c-u>call xtabline#cmds#run('toggle_tabs')<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Filtering)      :<c-u>call xtabline#cmds#run('toggle_buffers')<cr>
  nnoremap <unique> <silent> <expr> <Plug>(XT-Select-Buffer)         v:count? <sid>select_buffer(v:count-1) : ":\<C-U>".g:xtabline_settings.select_buffer_alt_action."\<cr>"
  nnoremap <unique> <silent> <expr> <Plug>(XT-Next-Buffer)           xtabline#next_buffer(v:count1, 0)
  nnoremap <unique> <silent> <expr> <Plug>(XT-Prev-Buffer)           xtabline#prev_buffer(v:count1, 0)
  nnoremap <unique> <silent> <expr> <Plug>(XT-Next-Pinned)           xtabline#next_buffer(v:count1, 1)
  nnoremap <unique> <silent> <expr> <Plug>(XT-Prev-Pinned)           xtabline#prev_buffer(v:count1, 1)
  nnoremap <unique> <silent>        <Plug>(XT-Close-Buffer)          :<c-u>XTabCloseBuffer<cr>
  nnoremap <unique> <silent>        <Plug>(XT-List-Buffers)          :<c-u>XTabListBuffers<cr>
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
  nnoremap <unique> <silent>        <Plug>(XT-Move-Buffer)           :<c-u>call xtabline#cmds#run('move_buffer', v:count)<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Hide-Buffer)           :<c-u>call xtabline#cmds#run('hide_buffer', v:count1)<cr>
  nnoremap <unique> <silent> <expr> <Plug>(XT-Hide-Buffer-n)         v:count? ":\<c-u>call xtabline#cmds#run('hide_buffer', v:count)\<cr>" : ":\<C-U>".g:xtabline_settings.hide_buffer_alt_action."\<cr>"
  nnoremap <unique> <silent>        <Plug>(XT-Tab-Todo)              :<c-u>XTabTodo<cr>
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
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide)          :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.x<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide-f)        :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.f<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide-t)        :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.t<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide-u)        :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.u<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide-b)        :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.b<cr>

  if !g:xtabline_settings.disable_keybindings | call s:do_map() | endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:select_buffer(cnt)
  let bufs = s:tab_buffers()
  let n = min([a:cnt, len(bufs)-1])
  let b = bufs[n]
  return ":\<C-U>silent! exe 'b'.".b."\<cr>"
endfun

fun! s:tab_buffers()
  return g:xtabline.Funcs.buffers_order()
endfun

fun! s:cd(count)
  let path = ':p:h'
  for c in range(a:count)
    let path .= ':h'
  endfor
  let cwd = g:xtabline.Funcs.fullpath(expand("%"), path).'/'
  cd `=cwd`
  let g:xtabline.Tabs[tabpagenr()-1].cwd = cwd
  let g:xtabline.Tabs[tabpagenr()-1].use_dir = cwd
  call g:xtabline.Funcs.force_update()
  pwd
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Leader guides
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:fk = { p -> 'call feedkeys("\<Plug>(XT-'.p.')")"' }
let s:_ = '                               '
let g:xtabline.leader_guide   = {}
let g:xtabline.leader_guide.x = {
      \'f':   [s:fk('Leader-Guide-f'), "Files/Sessions".s:_.s:_.s:_  ],
      \'t':   [s:fk('Leader-Guide-t'), "Tabs".s:_.s:_.s:_  ],
      \'b':   [s:fk('Leader-Guide-b'), "Buffers".s:_.s:_.s:_  ],
      \'u':   [s:fk('Leader-Guide-u'), "Utilities".s:_.s:_.s:_      ],
      \}

let g:xtabline.leader_guide.f = {
      \'lt': ["XTabLoadTab",            "Load Tab Bookmark(s)".s:_      ],
      \'st': ["XTabSaveTab",            "Save Tab Bookmark(s)".s:_      ],
      \'dt': ["XTabDeleteTab",          "Delete Tab Bookmark(s)".s:_    ],
      \'ls': ["XTabLoadSession",        "Load Session".s:_              ],
      \'ss': ["XTabSaveSession",        "Save Session".s:_              ],
      \'ds': ["XTabDeleteSession",      "Delete Session".s:_            ],
      \'ns': ["XTabNewSession",         "New Session".s:_               ],
      \}

let g:xtabline.leader_guide.t = {
      \'te': [s:fk('Tab-Edit'),         "Tab Edit".s:_                  ],
      \'tn': [s:fk('Tab-New'),          "Tab New".s:_                   ],
      \'R':  ["XTabResetTab",           "Reset Tab".s:_                 ],
      \'wd': ["XTabWD!",                "Change Working Directory".s:_  ],
      \'it': [s:fk("Tab-Icon"),         "Change Tab Icon".s:_           ],
      \'nt': [s:fk("Rename-Tab"),       "Rename Tab".s:_                ],
      \'ct': ["XTabCustomTabs",         "Toggle Custom Tabs".s:_        ],
      \'r':  ["XTabReopen",             "Reopen Tab".s:_                ],
      \}

let g:xtabline.leader_guide.u = {
      \'o':  ["XTabTodo",               "Open Todo".s:_                 ],
      \'c':  ["XTabCleanUp",            "Clean Up".s:_                  ],
      \'w':  ["XTabCleanUp!",           "Wipe All".s:_                  ],
      \'p':  ["XTabPurge",              "Purge".s:_                     ],
      \'t':  [s:fk("Apply-Theme"),      "Change Theme".s:_              ],
      \}

let g:xtabline.leader_guide.b = {
      \'pb': ["XTabPinBuffer",          "Toggle Pin Buffer".s:_         ],
      \'rp': ["XTabRelativePaths",      "Toggle Relative Paths".s:_     ],
      \'fb': ["XTabFormatBuffer",       "Change Buffer Format".s:_      ],
      \'ib': [s:fk("Buffer-Icon"),      "Change Buffer Icon".s:_        ],
      \'nb': [s:fk("Rename-Buffer"),    "Rename Buffer".s:_             ],
      \'R':  ["XTabResetBuffer",        "Reset Buffer".s:_              ],
      \'h':  [s:fk("Hide-Buffer"),      "Hide Buffer".s:_               ],
      \'0':  [s:fk("Move-Buffer"),      "Make First Buffer".s:_         ],
      \}

let g:xtabline.leader_guide.b.f = ["call xtabline#cmds#run('depth', [0, v:count])", "Toggle Filtering".s:_]

