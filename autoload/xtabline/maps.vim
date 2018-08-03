""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! xtabline#maps#init()

  let S = g:xtabline_settings
  let X = S.map_prefix

  fun! s:mapkeys(keys, plug)
    if maparg(a:keys) == '' && !hasmapto(a:plug)
      silent! execute 'nmap <unique> '.a:keys.' '.a:plug
    endif
  endfun

  call s:mapkeys('<F5>',  '<Plug>(XT-Toggle-Tabs)')
  call s:mapkeys('<BS>',  '<Plug>(XT-Select-Buffer)')
  call s:mapkeys(']b',    '<Plug>(XT-Next-Buffer)')
  call s:mapkeys('[b',    '<Plug>(XT-Prev-Buffer)')
  call s:mapkeys(X.'q',   '<Plug>(XT-Close-Buffer)')
  call s:mapkeys(X.'b',   '<Plug>(XT-Open-Buffers)')
  call s:mapkeys(X.'db',  '<Plug>(XT-Delete-Buffers)')
  call s:mapkeys(X.'dgb', '<Plug>(XT-Delete-Global-Buffers)')
  call s:mapkeys(X.'lt',  '<Plug>(XT-Load-Tab)')
  call s:mapkeys(X.'st',  '<Plug>(XT-Save-Tab)')
  call s:mapkeys(X.'dt',  '<Plug>(XT-Delete-Tab)')
  call s:mapkeys(X.'ls',  '<Plug>(XT-Load-Session)')
  call s:mapkeys(X.'ss',  '<Plug>(XT-Save-Session)')
  call s:mapkeys(X.'ds',  '<Plug>(XT-Delete-Session)')
  call s:mapkeys(X.'p',   '<Plug>(XT-Purge)')
  call s:mapkeys(X.'wa',  '<Plug>(XT-Wipe-All)')
  call s:mapkeys(X.'wd',  '<Plug>(XT-Working-Directory)')
  call s:mapkeys(X.'cu',  '<Plug>(XT-Clean-Up)')
  call s:mapkeys(X.'u',   '<Plug>(XT-Reopen)')
  call s:mapkeys(X.'sd',  '<Plug>(XT-Set-Depth)')
  call s:mapkeys(X.'cti', '<Plug>(XT-Change-Tab-Icon)')
  call s:mapkeys(X.'cbi', '<Plug>(XT-Change-Buffer-Icon)')
  call s:mapkeys(X.'ctn', '<Plug>(XT-Change-Tab-Name)')
  call s:mapkeys(X.'cbn', '<Plug>(XT-Change-Buffer-Name)')
  call s:mapkeys(X.'cbf', '<Plug>(XT-Change-Buffer-Format)')
  call s:mapkeys(X.'tt',  '<Plug>(XT-Tab-Todo)')
  call s:mapkeys(X.'trp', '<Plug>(XT-Relative-Paths)')
  call s:mapkeys(X.'tct', '<Plug>(XT-Toggle-Custom-Tabs)')
  call s:mapkeys(X.'tp',  '<Plug>(XT-Toggle-Pin)')
  call s:mapkeys(X.'tf',  '<Plug>(XT-Toggle-Filtering)')
  call s:mapkeys(X.'cdc', '<Plug>(XT-Cd-Current)')
  call s:mapkeys(X.'cdd', '<Plug>(XT-Cd-Down)')
  call s:mapkeys(X.'rt',  '<Plug>(XT-Reset-Tab)')
  call s:mapkeys(X.'rb',  '<Plug>(XT-Reset-Buffer)')

  if exists('g:loaded_leaderGuide_vim') && maparg(toupper(X)) == '' && !hasmapto('<Plug>(XT-Leader-Guide)')
      silent! execute 'nmap <unique>' X '<Plug>(XT-Leader-Guide)'
      silent! execute 'nmap <unique><nowait>' toupper(X) '<Plug>(XT-Leader-Guide)'
  endif

  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Tabs)           :<c-u>call xtabline#cmds#run('toggle_tabs')<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Filtering)      :<c-u>call xtabline#cmds#run('toggle_buffers')<cr>
  nnoremap <unique> <silent> <expr> <Plug>(XT-Select-Buffer)         v:count? ":\<C-U>silent! exe 'b'.\<sid>tab_buffers()[v:count-1]\<cr>" : ":\<C-U>".g:xtabline_settings.alt_action."\<cr>"
  nnoremap <unique> <silent> <expr> <Plug>(XT-Next-Buffer)           xtabline#next_buffer(v:count1)
  nnoremap <unique> <silent> <expr> <Plug>(XT-Prev-Buffer)           xtabline#prev_buffer(v:count1)
  nnoremap <unique> <silent>        <Plug>(XT-Close-Buffer)          :<c-u>XTabCloseBuffer<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Open-Buffers)          :<c-u>XTabOpenBuffers<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Delete-Buffers)        :<c-u>XTabDeleteBuffers<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Delete-Global-Buffers) :<c-u>XTabDeleteGlobalBuffers<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Load-Tab)              :<c-u>XTabLoadTab<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Save-Tab)              :<c-u>XTabSaveTab<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Delete-Tab)            :<c-u>XTabDeleteTab<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Load-Session)          :<c-u>XTabLoadSession<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Save-Session)          :<c-u>XTabSaveSession<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Delete-Session)        :<c-u>XTabDeleteSession<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Purge)                 :<c-u>XTabPurge<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Pin)            :<c-u>XTabTogglePin<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Clean-Up)              :<c-u>XTabCleanUp<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Wipe-All)              :<c-u>XTabCleanUp!<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Reopen)                :<c-u>XTabReopen<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Working-Directory)     :<c-u>XTabWD!<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Set-Depth)             :<c-u>call xtabline#cmds#run('depth', [0, v:count])<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Tab-Todo)              :<c-u>XTabTodo<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Toggle-Custom-Tabs)    :<c-u>XTabToggleTabNames<cr>
  nnoremap <unique>                 <Plug>(XT-Change-Tab-Icon)       :<c-u>XTabIcon<Space>
  nnoremap <unique>                 <Plug>(XT-Change-Buffer-Icon)    :<c-u>XTabBufferIcon<Space>
  nnoremap <unique>                 <Plug>(XT-Change-Tab-Name)       :<c-u>XTabRenameTab<Space>
  nnoremap <unique>                 <Plug>(XT-Change-Buffer-Name)    :<c-u>XTabRenameBuffer<Space>
  nnoremap <unique>                 <Plug>(XT-Change-Buffer-Format)  :<c-u>XTabFormatBuffer<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Cd-Current)            :<c-u>call <sid>cd(0)<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Cd-Down)               :<c-u>call <sid>cd(v:count1)<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Reset-Tab)             :<c-u>XTabResetTab<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Reset-Buffer)          :<c-u>XTabResetBuffer<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Relative-Paths)        :<c-u>XTabRelativePaths<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide)          :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.x<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide-f)          :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.f<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide-t)          :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.t<cr>
  nnoremap <unique> <silent>        <Plug>(XT-Leader-Guide-c)          :<c-u>silent! LeaderGuideD g:xtabline.leader_guide.c<cr>
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
      \'f':   [s:fk('Leader-Guide-f'), "Tabs/Sessions".s:_  ],
      \'t':   [s:fk('Leader-Guide-t'), "Toggle Options".s:_ ],
      \'c':   [s:fk('Leader-Guide-c'), "Change Options".s:_ ],
      \'u':   [s:fk('Leader-Guide-u'), "Utilities".s:_ ],
      \}

let g:xtabline.leader_guide.f = {
      \'lt':  ["XTabLoadTab",                        "Load Tab Bookmark(s)".s:_    ],
      \'st':  ["XTabSaveTab",                        "Save Tab Bookmark(s)".s:_    ],
      \'dt':  ["XTabDeleteTab",                      "Delete Tab Bookmark(s)".s:_  ],
      \'ls':  ["XTabLoadSession",                    "Load Session".s:_            ],
      \'ss':  ["XTabSaveSession",                    "Save Session".s:_            ],
      \'ds':  ["XTabDeleteSession",                  "Delete Session".s:_          ],
      \}

let g:xtabline.leader_guide.u = {
      \'t':   ["XTabTodo",                           "Open Todo".s:_               ],
      \'cu':  ["XTabCleanUp",                        "Clean Up".s:_                ],
      \'wa':  ["XTabCleanUp!",                       "Wipe All".s:_                ],
      \'u':   ["XTabReopen",                         "Undo Close Tab".s:_          ],
      \'p':   ["XTabPurge",                          "Purge".s:_                   ],
      \'rt':  ["XTabResetTab",                       "Reset Tab".s:_               ],
      \'rb':  ["XTabResetBuffer",                    "Reset Buffer".s:_            ],
      \}

let g:xtabline.leader_guide.t = {
      \'p':  ["XTabTogglePin",                      "Toggle Pin".s:_              ],
      \'rp': ["XTabRelativePaths",                  "Toggle Relative Paths".s:_   ],
      \'tn': ["XTabToggleTabNames",                 "Toggle Tab Names".s:_        ],
      \}
let g:xtabline.leader_guide.t.f = ["call xtabline#cmds#run('depth', [0, v:count])", "Toggle Filtering".s:_]

let g:xtabline.leader_guide.c = {
      \'bf': ["XTabFormatBuffer",                   "Change Buffer Format".s:_           ],
      \'wd':  ["XTabWD!",                           "Change Working Directory".s:_       ],
      \'ti':  [s:fk("Change-Tab-Icon"),             "Change Tab Icon".s:_       ],
      \'bi':  [s:fk("Change-Buffer-Icon"),          "Change Buffer Icon".s:_       ],
      \'tn':  [s:fk("Change-Tab-Name"),             "Change Tab Name".s:_       ],
      \'bn':  [s:fk("Change-Buffer-Name"),          "Change Buffer Name".s:_       ],
      \}

