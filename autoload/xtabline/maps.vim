""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#maps#init()

  let S = g:xtabline_settings
  let X = S.map_prefix

  fun! s:mapkeys(keys, plug)
    if maparg(a:keys) == '' && !hasmapto(a:plug)
      silent! execute 'nmap <unique> '.a:keys.' <Plug>(XT-'.a:plug.')'
    endif
  endfun

  call s:mapkeys('<F5>',  'Toggle-Tabs')
  call s:mapkeys('<BS>',  'Select-Buffer')
  call s:mapkeys(']b',    'Next-Buffer')
  call s:mapkeys('[b',    'Prev-Buffer')
  call s:mapkeys(X.'q',   'Close-Buffer')
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
  call s:mapkeys(X.'tr',  'Reopen')
  call s:mapkeys(X.'sd',  'Set-Depth')
  call s:mapkeys(X.'cti', 'Tab-Icon')
  call s:mapkeys(X.'cbi', 'Buffer-Icon')
  call s:mapkeys(X.'nt',  'Name-Tab')
  call s:mapkeys(X.'nb',  'Name-Buffer')
  call s:mapkeys(X.'bf',  'Buffer-Format')
  call s:mapkeys(X.'tt',  'Tab-Todo')
  call s:mapkeys(X.'rp',  'Relative-Paths')
  call s:mapkeys(X.'ct',  'Toggle-Custom-Tabs')
  call s:mapkeys(X.'pb',  'Pin-Buffer')
  call s:mapkeys(X.'tf',  'Toggle-Filtering')
  call s:mapkeys(X.'cdc', 'Cd-Current')
  call s:mapkeys(X.'cdd', 'Cd-Down')
  call s:mapkeys(X.'rt',  'Reset-Tab')
  call s:mapkeys(X.'rb',  'Reset-Buffer')

  call s:mapkeys('+t',    'Move-Tab+')
  call s:mapkeys('-t',    'Move-Tab-')
  call s:mapkeys('+T',    'Move-Tab0')
  call s:mapkeys('-T',    'Move-Tab$')

  if exists('g:loaded_leaderGuide_vim') && maparg(toupper(X)) == '' && !hasmapto('<Plug>(XT-Leader-Guide)')
      silent! execute 'nmap <unique>' X '<Plug>(XT-Leader-Guide)'
      silent! execute 'nmap <unique><nowait>' toupper(X) '<Plug>(XT-Leader-Guide)'
  endif


  nnoremap <unique> <silent>        <Plug>(XT-Move-Tab+)             :XTabMove +<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Move-Tab-)             :XTabMove -<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Move-Tab0)             :<c-u>XTabMove 0<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Move-Tab$)             :<c-u>XTabMove $<cr>
  nnoremap <unique>                 <Plug>(XT-Tab-New)               :<c-u>XTabNew<space>
  nnoremap <unique>                 <Plug>(XT-Tab-Edit)              :<c-u>XTabEdit<space>

  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Tabs)           :<c-u>call xtabline#cmds#run('toggle_tabs')<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Filtering)      :<c-u>call xtabline#cmds#run('toggle_buffers')<cr>
  nnoremap <unique> <silent> <expr> <Plug>(XT-Select-Buffer)         v:count? ":\<C-U>silent! exe 'b'.\<sid>tab_buffers()[v:count-1]\<cr>" : ":\<C-U>".g:xtabline_settings.alt_action."\<cr>"
  nnoremap <unique> <silent> <expr> <Plug>(XT-Next-Buffer)           xtabline#next_buffer(v:count1)
  nnoremap <unique> <silent> <expr> <Plug>(XT-Prev-Buffer)           xtabline#prev_buffer(v:count1)
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
  nnoremap <unique> <silent>        <Plug>(XT-Set-Depth)             :<c-u>call xtabline#cmds#run('depth', [0, v:count])<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Tab-Todo)              :<c-u>XTabTodo<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Custom-Tabs)    :<c-u>XTabCustomTabs<cr>
  nnoremap <unique>                 <Plug>(XT-Tab-Icon)              :<c-u>XTabIcon<Space>
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
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide-f)          :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.f<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide-o)          :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.o<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide-u)          :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.u<cr>
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:tab_buffers()
  return g:xtabline.Tabs[tabpagenr()-1].buffers.order
endfun

fun! s:cd(count)
  let path = ':p:h'
  for c in range(a:count)
    let path .= ':h'
  endfor
  let cwd = fnamemodify(expand("%", ":p"), path)
  cd `=cwd`
  let g:xtabline.Tabs[tabpagenr()-1].cwd = cwd
  doautocmd BufAdd
  call xtabline#update_obsession()
  pwd
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Leader guides
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:fk = { p -> 'call feedkeys("\<Plug>(XT-'.p.')")"' }
let s:_ = '                               '
let g:xtabline.leader_guide   = {}
let g:xtabline.leader_guide.x = {
      \'f':   [s:fk('Leader-Guide-f'), "Tabs/Sessions".s:_.s:_.s:_  ],
      \'o':   [s:fk('Leader-Guide-o'), "Options".s:_.s:_.s:_        ],
      \'u':   [s:fk('Leader-Guide-u'), "Utilities".s:_.s:_.s:_      ],
      \}

let g:xtabline.leader_guide.f = {
      \'lt': ["XTabLoadTab",            "Load Tab Bookmark(s)".s:_     ],
      \'st': ["XTabSaveTab",            "Save Tab Bookmark(s)".s:_     ],
      \'dt': ["XTabDeleteTab",          "Delete Tab Bookmark(s)".s:_   ],
      \'ls': ["XTabLoadSession",        "Load Session".s:_             ],
      \'ss': ["XTabSaveSession",        "Save Session".s:_             ],
      \'ds': ["XTabDeleteSession",      "Delete Session".s:_           ],
      \'ns': ["XTabNewSession",         "New Session".s:_              ],
      \'te': [s:fk('Tab-Edit'),         "Tab Edit".s:_                 ],
      \'tn': [s:fk('Tab-New'),          "Tab New".s:_                  ],
      \}

let g:xtabline.leader_guide.u = {
      \'o':  ["XTabTodo",               "Open Todo".s:_                ],
      \'c':  ["XTabCleanUp",            "Clean Up".s:_                 ],
      \'w':  ["XTabCleanUp!",           "Wipe All".s:_                 ],
      \'r':  ["XTabReopen",             "Undo Close Tab".s:_           ],
      \'p':  ["XTabPurge",              "Purge".s:_                    ],
      \'t':  ["XTabResetTab",           "Reset Tab".s:_                ],
      \'b':  ["XTabResetBuffer",        "Reset Buffer".s:_             ],
      \}

let g:xtabline.leader_guide.o = {
      \'pb': ["XTabPinBuffer",          "Toggle Pin Buffer".s:_        ],
      \'rp': ["XTabRelativePaths",      "Toggle Relative Paths".s:_    ],
      \'ct': ["XTabCustomTabs",         "Toggle Custom Tabs".s:_       ],
      \'bf': ["XTabFormatBuffer",       "Change Buffer Format".s:_     ],
      \'wd': ["XTabWD!",                "Change Working Directory".s:_ ],
      \'ti': [s:fk("Tab-Icon"),         "Change Tab Icon".s:_          ],
      \'bi': [s:fk("Buffer-Icon"),      "Change Buffer Icon".s:_       ],
      \'nt': [s:fk("Name-Tab"),         "Name Tab".s:_                 ],
      \'nb': [s:fk("Name-Buffer"),      "Name Buffer".s:_              ],
      \}
let g:xtabline.leader_guide.o.f = ["call xtabline#cmds#run('depth', [0, v:count])", "Toggle Filtering".s:_]

