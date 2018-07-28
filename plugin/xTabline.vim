"""""""""""""""""""""""""""" =============================================================================
" File: xtabline.vim
" Mantainer: Gianmaria Bajo <mg1979.git@gmail.com>
" Url: https://github.com/mg979/vim-xtabline
" License: MIT
" """""""""""""""""""""""""""""""""""""""""""""""""""""

if exists("g:loaded_xtabline")
  finish
endif

let g:loaded_xtabline = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

autocmd VimEnter  * call xtabline#init()

com! -nargs=? -complete=buffer XTabOpenBuffers call fzf#vim#buffers(<q-args>, {
      \ 'source': xtabline#fzf#tab_buffers(),
      \ 'options': '--multi --prompt "Open Tab Buffer >>>  "'})

com! -nargs=? -complete=buffer XTabDeleteBuffers call fzf#vim#files(<q-args>, {
      \ 'source': xtabline#fzf#tab_buffers(),
      \ 'sink': function('xtabline#fzf#bufdelete'), 'down': '30%',
      \ 'options': '--multi --no-preview --ansi --prompt "Delete Tab Buffer >>>  "'})

com! -nargs=? -complete=buffer XTabDeleteGlobalBuffers call fzf#vim#buffers(<q-args>, {
      \ 'sink': function('xtabline#fzf#bufdelete'), 'down': '30%',
      \ 'options': '--multi --no-preview --ansi --prompt "Delete Any Buffer >>>  "'})

com! -nargs=? XTabLoadSession call fzf#vim#files(<q-args>, {
      \ 'source': xtabline#fzf#sessions_list(),
      \ 'sink': function('xtabline#fzf#session_load'), 'down': '30%',
      \ 'options': '--header-lines=1 --no-preview --ansi --prompt "Load Session >>>  "'})

com! -nargs=? XTabDeleteSession call fzf#vim#files(<q-args>, {
      \ 'source': xtabline#fzf#sessions_list(),
      \ 'sink': function('xtabline#fzf#session_delete'), 'down': '30%',
      \ 'options': '--header-lines=1 --no-multi --no-preview --ansi --prompt "Delete Session >>>  "'})

com! -nargs=? XTabLoadTab call fzf#vim#files(<q-args>, {
      \ 'source': xtabline#fzf#tabs(),
      \ 'sink': function('xtabline#fzf#tab_load'), 'down': '30%',
      \ 'options': '--header-lines=1 --multi --no-preview --ansi --prompt "Load Tab Bookmark >>>  "'})

com! -nargs=? XTabDeleteTab call fzf#vim#files(<q-args>, {
      \ 'source': xtabline#fzf#tabs(),
      \ 'sink': function('xtabline#fzf#tab_delete'), 'down': '30%',
      \ 'options': '--header-lines=1 --multi --no-preview --ansi --prompt "Delete Tab Bookmark >>>  "'})

com! -nargs=? XTabNERDBookmarks call fzf#vim#files(<q-args>, {
      \ 'source': xtabline#fzf#tab_nerd_bookmarks(),
      \ 'sink': function('xtabline#fzf#tab_nerd_bookmarks_load'), 'down': '30%',
      \ 'options': '--multi --no-preview --ansi --prompt "Load NERD Bookmark >>>  "'})

com!                XTabSaveTab         call xtabline#fzf#tab_save()
com!                XTabSaveSession     call xtabline#fzf#session_save(0)
com!                XTabCreateSession   call xtabline#fzf#session_save(1)
com!                XTabTodo            call xtabline#cmds#run('tab_todo')
com!                XTabPurge           call xtabline#cmds#run('purge_buffers')
com!                XTabReopen          call xtabline#cmds#run('reopen_last_tab')
com!                XTabCloseBuffer     call xtabline#cmds#run('close_buffer')
com! -bang -count   XTabDepth           call xtabline#cmds#run('depth', [<bang>0, <count>])
com! -bang          XTabCleanUp         call xtabline#cmds#run('clean_up', <bang>0)
com! -nargs=1       XTabRenameTab       call xtabline#cmds#run("rename_tab", <q-args>)
com! -nargs=1       XTabRenameBuffer    call xtabline#cmds#run("rename_buffer", <q-args>)
com! -nargs=1       XTabOpen            call xtabline#cmds#run("new_tab", <q-args>)
com!                XTabReset           call xtabline#cmds#run("reset_tab")
com!                XTabRelativePaths   call xtabline#cmds#run("relative_paths")
com!                XTabPinBuffer       call xtabline#cmds#run("pin_buffer")

com! -nargs=1 -complete=customlist,<sid>icons      XTabIcon            call xtabline#cmds#run("tab_icon", <q-args>)
com! -nargs=1 -complete=customlist,<sid>icons      XTabBufferIcon      call xtabline#cmds#run("buffer_icon", <q-args>)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:xtabline = {'Tabs': [], 'Vars': {}}
let s:S = get(g:, 'xtabline_settings', {})

let s:S.sessions_path              = get(s:S, 'sessions_path', '$HOME/.vim/session')
let s:S.map_prefix                 = get(s:S, 'map_prefix', '<leader>x')
let s:S.include_previews           = get(s:S, 'include_previews', 1)
let s:S.close_buffer_can_close_tab = get(s:S, 'close_buffer_can_close_tab', 0)
let s:S.unload_session_ask_confirm = get(s:S, 'unload_session_ask_confirm', 1)

let s:S.alt_action                 = get(s:S, 'alt_action', "buffer #")
let s:S.bookmaks_file              = get(s:S, 'bookmaks_file ', expand('$HOME/.vim/.XTablineBookmarks'))
let s:S.sessions_data              = get(s:S, 'sessions_data', expand('$HOME/.vim/.XTablineSessions'))
let s:S.default_named_tab_icon     = get(s:S, 'default_named_tab_icon', ['📌','📌'])

let s:S.todo                       = get(s:S, 'todo', {})
let s:S.todo.command               = get(s:S.todo, 'command', 'sp')
let s:S.todo.prefix                = get(s:S.todo, 'prefix',  'below')
let s:S.todo.file                  = get(s:S.todo, 'file',    ".TODO")
let s:S.todo.size                  = get(s:S.todo, 'size',    20)
let s:S.todo.syntax                = get(s:S.todo, 'syntax',  'markdown')

let s:S.custom_icons               = extend({
                                    \'folder_open': '📂',
                                    \'folder_closed': '📁',
                                    \'pin': '📌',
                                    \'star': '★',
                                    \'book': '📖',
                                    \'lock': '🔒',
                                    \'hammer': '🔨',
                                    \}, get(s:S, 'custom_icons', {}))

if !filereadable(s:S.bookmaks_file) | call writefile(['{}'], S.bookmaks_file) | endif
if !filereadable(s:S.sessions_data) | call writefile(['{}'], S.sessions_data) | endif

fun! s:icons(A,L,P)
  return keys(s:S.custom_icons)
endfun

