""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" File:         xtabline.vim
" Description:  Vim plugin for the customization of the tabline
" Mantainer:    Gianmaria Bajo <mg1979.git@gmail.com>
" Url:          https://github.com/mg979/vim-xtabline
" Copyright:    (c) 2018 Gianmaria Bajo <mg1979.git@gmail.com>
" Licence:      The MIT License
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if exists("g:loaded_xtabline")
  finish
endif

let g:loaded_xtabline = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

autocmd VimEnter  * call xtabline#init() | doautocmd BufEnter

com! -nargs=? -complete=buffer XTabListBuffers call fzf#vim#buffers(<q-args>, {
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

com!                    XTabSaveTab         call xtabline#fzf#tab_save()
com!                    XTabSaveSession     call xtabline#fzf#session_save()
com! -nargs=?           XTabNewSession      call xtabline#fzf#session_save(<q-args>)
com!                    XTabTodo            call xtabline#cmds#run('tab_todo')
com!                    XTabPurge           call xtabline#cmds#run('purge_buffers')
com!                    XTabReopen          call xtabline#cmds#run('reopen_last_tab')
com!                    XTabCloseBuffer     call xtabline#cmds#run('close_buffer')
com!       -count       XTabDepth           call xtabline#cmds#run('depth', <count>)
com! -bang              XTabCleanUp         call xtabline#cmds#run('clean_up', <bang>0)
com! -nargs=1           XTabRenameTab       call xtabline#cmds#run("rename_tab", <q-args>)
com! -nargs=1           XTabRenameBuffer    call xtabline#cmds#run("rename_buffer", <q-args>)
com!                    XTabResetTab        call xtabline#cmds#run("reset_tab")
com!                    XTabResetBuffer     call xtabline#cmds#run("reset_buffer")
com!                    XTabRelativePaths   call xtabline#cmds#run("relative_paths")
com!                    XTabFormatBuffer    call xtabline#cmds#run("format_buffer")
com!                    XTabCustomTabs      call xtabline#cmds#run("toggle_tab_names")
com!                    XTabLock            call xtabline#cmds#run("lock_tab")
com! -nargs=?           XTabPinBuffer       call xtabline#cmds#run("toggle_pin_buffer", <q-args>)
com!                    XTabConfig          call xtabline#config#start()

com! -nargs=? -count    XTabNew             call xtabline#cmds#run("new_tab", <count>, <q-args>)
com! -nargs=?           XTabMove            call xtabline#cmds#run("move_tab", <q-args>)
com!                    XTabFzf             call xtabline#fzf#cmds()
com!                    XTabVimrc           call xtabline#vimrc#open()

com! -nargs=? -count -complete=file -bang            XTabEdit            call xtabline#cmds#run("edit_tab", <count>, <bang>0, <q-args>)
com! -nargs=? -bang  -complete=file                  XTabWD              call xtabline#cmds#run("set_cwd", [<bang>0, <q-args>])
com! -nargs=? -bang  -complete=customlist,<sid>icons XTabIcon            call xtabline#cmds#run("tab_icon", [<bang>0, <q-args>])
com! -nargs=? -bang  -complete=customlist,<sid>icons XTabBufferIcon      call xtabline#cmds#run("buffer_icon", [<bang>0, <q-args>])
com! -nargs=? -bang  -complete=customlist,<sid>theme XTabTheme           call xtabline#hi#load_theme(<bang>0, <q-args>)

fun! s:icons(A,L,P)
  """Icons completions for commands.
  return keys(g:xtabline_settings.icons)
endfun

fun! s:theme(A,L,P)
  """Theme names completion.
  return keys(g:xtabline_highlight.themes)
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Variables
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:xtabline = {'Tabs': [], 'Vars': {}, 'Buffers': {}, 'Funcs': {},
                 \'pinned_buffers': [], 'closed_tabs': [], 'closed_cwds': []}

let g:xtabline.Vars.winOS = has("win16") || has("win32") || has("win64")
let s:vimdir = ( has('win32unix') || g:xtabline.Vars.winOS ) &&
      \        isdirectory(expand('$HOME/vimfiles')) ? '$HOME/vimfiles' : '$HOME/.vim'

let g:xtabline_highlight = get(g:, 'xtabline_highlight', {'themes': {}})

let s:S = {}

let s:S.sessions_path              = expand(s:vimdir . '/session')
let s:S.map_prefix                 = '<leader>x'
let s:S.close_buffer_can_close_tab = 0
let s:S.close_buffer_can_quit_vim  = 0
let s:S.depth_tree_size            = 20

let s:S.select_buffer_alt_action   = "buffer #"
let s:S.hide_buffer_alt_action     = "buffer #"
let s:S.bookmarks_file             = expand(s:vimdir . '/.XTablineBookmarks')
let s:S.sessions_data              = expand(s:vimdir . '/.XTablineSessions')
let s:S.superscript_unicode_nrs    = 0
let s:S.show_current_tab           = 1
let s:S.enable_extra_highlight     = 1
let s:S.sort_buffers_by_last_open  = 0
let s:S.override_airline           = 1
let s:S.disable_keybindings        = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Bufline/Tabline settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:S.no_icons = 0

let s:S.bufline_indicators = {
      \ 'modified': s:S.no_icons ? '[+]'  : '✛ ',
      \ 'readonly': s:S.no_icons ? '[RO]' : '🔒',
      \ 'scratch': s:S.no_icons ?  '[!]'  : '💣',
      \ 'pinned': s:S.no_icons ?   '[^]'  : '[📌]',
      \}

let s:S.bufline_numbers           = 1
let s:S.bufline_sep_or_icon       = 0
let s:S.bufline_separators        = ['|', '|']
let s:S.bufline_format            =  ' n I< l +'
let s:S.bufline_unnamed           =  '...'

let s:S.tab_format                = "N - 2+ "
let s:S.named_tab_format          = "N - l+ "
let s:S.bufline_named_tab_format  = s:S.named_tab_format
let s:S.bufline_tab_format        = s:S.tab_format
let s:S.modified_tab_flag         = "*"
let s:S.close_tabs_label          = ""
let s:S.unnamed_tab_label         = "[no name]"
let s:S.tab_icon                  = ["📂", "📁"]
let s:S.named_tab_icon            = ["📂", "📁"]

let s:S.devicon_for_all_filetypes = 0
let s:S.devicon_for_extensions    = ['md', 'txt']

let g:xtabline_settings  = extend(s:S, get(g:, 'xtabline_settings', {}))

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Icons
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:xtabline_settings.icons = extend({
      \'pin':     '📌',     'star':    '★',     'book':    '📖',     'lock':    '🔒',
      \'hammer':  '🔨',     'tick':    '✔',     'cross':   '✖',      'warning': '⚠',
      \'menu':    '☰',      'apple':   '🍎',    'linux':   '🐧',     'windows': '❖',
      \'git':     '',      'git2':    '⎇ ',    'palette': '🎨',     'lens':    '🔍',
      \'flag':    '⚑',      'flag2':   '🏁',    'fire':    '🔥',     'bomb':    '💣',
      \'home':    '🏠',     'mail':    '✉ ',    'netrw':   '🖪 ',     'arrow':   '➤',
      \}, get(g:xtabline_settings, 'icons', {}))

" \'folder_open': '📂',
" \'folder_closed': '📁',

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" TabTodo settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:xtabline_settings.todo = extend({
      \"command": 'sp',
      \"prefix":  'below',
      \"file":    ".TODO",
      \"size":    20,
      \"syntax":  'markdown',
      \}, get(g:xtabline_settings, 'todo', {}))

if !filereadable(g:xtabline_settings.bookmarks_file) | call writefile(['{}'], g:xtabline_settings.bookmarks_file) | endif
if !filereadable(g:xtabline_settings.sessions_data) | call writefile(['{}'], g:xtabline_settings.sessions_data) | endif

call xtabline#hi#init()
