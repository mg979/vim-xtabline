function! xtabline#maps#init()

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Mappings
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    let X = g:xtabline_map_prefix

    fun! s:mapkeys(keys, plug)
        if !hasmapto(a:plug)
            execute 'map <unique> '.a:keys.' '.a:plug
        endif
    endfun

    call s:mapkeys('<F5>','<Plug>XTablineToggleTabs')
    call s:mapkeys('<leader><F5>','<Plug>XTablineToggleBuffers')
    call s:mapkeys('<leader>l','<Plug>XTablineSelectBuffer')
    call s:mapkeys(']l','<Plug>XTablineNextBuffer')
    call s:mapkeys('[l','<Plug>XTablinePrevBuffer')
    call s:mapkeys(X.'q','<Plug>XTablineCloseBuffer')
    call s:mapkeys(X.'x','<Plug>XTablineBuffersOpen')
    call s:mapkeys(X.'d','<Plug>XTablineBuffersDelete')
    call s:mapkeys(X.'D','<Plug>XTablineAllBuffersDelete')
    call s:mapkeys(X.'l','<Plug>XTablineBookmarksLoad')
    call s:mapkeys(X.'s','<Plug>XTablineBookmarksSave')
    call s:mapkeys(X.'L','<Plug>XTablineSessionLoad')
    call s:mapkeys(X.'S','<Plug>XTablineSessionSave')
    call s:mapkeys(X.'p','<Plug>XTablinePurge')
    call s:mapkeys(X.'r','<Plug>XTablineReopen')
    call s:mapkeys(X.'tt','<Plug>XTablineTabTodo')

    nnoremap <unique> <script> <Plug>XTablineToggleTabs <SID>ToggleTabs
    nnoremap <silent> <SID>ToggleTabs :call xtabline#toggle_tabs()<cr>

    nnoremap <unique> <script> <Plug>XTablineToggleBuffers <SID>ToggleBuffers
    nnoremap <silent> <SID>ToggleBuffers :call xtabline#toggle_buffers()<cr>

    nnoremap <unique> <script> <Plug>XTablineSelectBuffer <SID>SelectBuffer
    nnoremap <silent> <expr> <SID>SelectBuffer g:xtabline_changing_buffer ? "\<C-c>" : ":<C-u>call xtabline#select_buffer(v:count)\<cr>"

    nnoremap <unique> <script> <Plug>XTablineNextBuffer <SID>NextBuffer
    nnoremap <silent> <expr> <SID>NextBuffer xtabline#next_buffer(v:count1)

    nnoremap <unique> <script> <Plug>XTablinePrevBuffer <SID>PrevBuffer
    nnoremap <silent> <expr> <SID>PrevBuffer xtabline#prev_buffer(v:count1)

    nnoremap <unique> <script> <Plug>XTablineCloseBuffer <SID>CloseBuffer
    nnoremap <silent> <SID>CloseBuffer :call xtabline#close_buffer()<cr>

    nnoremap <unique> <script> <Plug>XTablineBuffersOpen <SID>TabBuffersOpen
    nnoremap <silent> <SID>TabBuffersOpen :XTabBuffersOpen<cr>

    nnoremap <unique> <script> <Plug>XTablineBuffersDelete <SID>TabBuffersDelete
    nnoremap <silent> <SID>TabBuffersDelete :XTabBuffersDelete<cr>

    nnoremap <unique> <script> <Plug>XTablineAllBuffersDelete <SID>TabAllBuffersDelete
    nnoremap <silent> <SID>TabAllBuffersDelete :XTabAllBuffersDelete<cr>

    nnoremap <unique> <script> <Plug>XTablineBookmarksLoad <SID>TabBookmarksLoad
    nnoremap <silent> <SID>TabBookmarksLoad :XTabBookmarksLoad<cr>

    nnoremap <unique> <script> <Plug>XTablineBookmarksSave <SID>TabBookmarksSave
    nnoremap <silent> <SID>TabBookmarksSave :XTabBookmarksSave<cr>

    nnoremap <unique> <script> <Plug>XTablineSessionLoad <SID>SessionLoad
    nnoremap <silent> <SID>SessionLoad :XTabSessionLoad<cr>

    nnoremap <unique> <script> <Plug>XTablineSessionSave <SID>SessionSave
    nnoremap <silent> <SID>SessionSave :XTabSessionSave<cr>

    nnoremap <unique> <script> <Plug>XTablinePurge <SID>PurgeBuffers
    nnoremap <silent> <SID>PurgeBuffers :XTabPurge<cr>

    nnoremap <unique> <script> <Plug>XTablineReopen <SID>ReopenLastTab
    nnoremap <silent> <SID>ReopenLastTab :XTabReopen<cr>

    nnoremap <unique> <script> <Plug>XTablineTabTodo <SID>TabTodo
    nnoremap <silent> <SID>TabTodo :XTabTodo<cr>

    if get(g:, 'xtabline_cd_commands', 0)
        map <unique> <leader>cdc <Plug>XTablineCdCurrent
        map <unique> <leader>cdd <Plug>XTablineCdDown1
        map <unique> <leader>cd2 <Plug>XTablineCdDown2
        map <unique> <leader>cd3 <Plug>XTablineCdDown3
        map <unique> <leader>cdh <Plug>XTablineCdHome
        nnoremap <unique> <script> <Plug>XTablineCdCurrent :cd %:p:h<cr>:doautocmd BufAdd<cr>:pwd<cr>
        nnoremap <unique> <script> <Plug>XTablineCdDown1   :cd %:p:h:h<cr>:doautocmd BufAdd<cr>:pwd<cr>
        nnoremap <unique> <script> <Plug>XTablineCdDown2   :cd %:p:h:h:h<cr>:doautocmd BufAdd<cr>:pwd<cr>
        nnoremap <unique> <script> <Plug>XTablineCdDown3   :cd %:p:h:h:h:h<cr>:doautocmd BufAdd<cr>:pwd<cr>
        nnoremap <unique> <script> <Plug>XTablineCdHome    :cd ~<cr>:doautocmd BufAdd<cr>:pwd<cr>
    endif

endfunction

