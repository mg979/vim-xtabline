## xtabline

![pic](https://i.imgur.com/SN6FNnA.gif)

<!-- vim-markdown-toc GFM -->

* [Features list](#features-list)
* [Requirements](#requirements)
* [Installation](#installation)
* [Settings and mappings](#settings-and-mappings)
* [Tab buffers navigation](#tab-buffers-navigation)
* [Closing buffers](#closing-buffers)
* [Tabs, buffers and sessions](#tabs-buffers-and-sessions)
    * [Opening tabs](#opening-tabs)
    * [Rearranging tabs](#rearranging-tabs)
    * [Saving and loading tabs](#saving-and-loading-tabs)
    * [Managing buffers](#managing-buffers)
    * [Tuning buffer filtering](#tuning-buffer-filtering)
    * [Customizing tabs and buffers](#customizing-tabs-and-buffers)
    * [Sessions management](#sessions-management)
* [Other commands, plugs and mappings](#other-commands-plugs-and-mappings)
* [Buffers clean-up](#buffers-clean-up)
* [Tab-Todo](#tab-todo)
* [Cwd selection](#cwd-selection)
* [Restrict Cwd](#restrict-cwd)
* [Customization](#customization)
* [Interaction With Airline](#interaction-with-airline)
* [Credits](#credits)
* [License](#license)

<!-- vim-markdown-toc -->

----------------------------------------------------------------------------
 
### Features list

This plugin tries to give you full control on the tabline. I wanted ways to:

* switch between tabs and buffer mode
* have buffers filtered on te base of the current CWD, or other criterias
* rename tabs/buffers, and give them icons/separators
* load/save customized tabs from/to disk
* reopen closed tabs
* have any customization persist across sessions
* have it look good, with easy formatting options

Additionally, it provides:

* buffers quick navigation (next, previous, with *[count]*)
* session management: load/save/delete sessions, with timestamping and descriptions
* commands to clean up buffers across all tabs
* Tab-todo: customizable command to open a todo file for that tab

Integrated with:

* *fzf-vim* (load saved tabs, sessio management)
* *vim-obsession* for automatic CWDs persistance across sessions
* additional support for *vim-airine* and *vim-devicons*

----------------------------------------------------------------------------
 
### Requirements

[vim-obsession](https://github.com/tpope/vim-obsession) is required for persistance.  
[fzf-vim](https://github.com/junegunn/fzf.vim) is required for lots of commands.  

----------------------------------------------------------------------------
 
### Installation

Use [vim-plug](https://github.com/junegunn/vim-plug) or any other Vim plugin manager.

With vim-plug:

    Plug 'mg979/vim-xtabline'

----------------------------------------------------------------------------
 
### Settings and mappings

To change any setting, you have to initialize the settings dictionary:

    let g:xtabline_settings = {}

Most of xtabline mappings can be associated to a prefix. Default is:

    let g:xtabline_settings.map_prefix = '<leader>x'

This means that most commands will be mapped to `<leader>x` + a modifier. You can change the prefix and all mappings will be changed accordingly.  
Most mappings presented are meant prefixed by `prefix`, unless <kbd>enclosed<\kbd>. Other settings will be described later.

----------------------------------------------------------------------------
 
### Tab buffers navigation

By default, in the bufferline will be shown buffers that belong to the tab's CWD, or any open buffer inside the window.
Using xtabline buffer navigation commands you can switch among them, while using the normal *:bnext* command, you still cycle among the default (global) buffer list.

|Mapping               | Plug                                |
|----------------------|-------------------------------------|
|[count]<kbd>BS</kbd>  | `<Plug>(XT-Select-Buffer)`          |
|<kbd>]b</kbd>         | `<Plug>(XT-Next-Buffer)`            |
|<kbd>[b</kbd>         | `<Plug>(XT-Prev-Buffer)`            |
|q                     | `<Plug>(XT-Close-Buffer)`           |

*Next-Buffer* and *Prev-Buffer* accept a [count], to move to ±[N] buffer, as they are shown in the tabline. If moving beyond the limit, it will start from the start (or the end).

*Select-Buffer* works this way:

* it needs a *[count]* to work, eg. 2\<BS> would bring you to buffer #2
* when not using a *[count]*, it will execute a command of your choice

Define this command by setting the *g:xtabline_settings.alt_action* variable.
Default is `buffer #`

Examples:

    let g:xtabline_settings.alt_action = "buffer #"    (switch to alternative buffer)
    let g:xtabline_settings.alt_action = "Buffers"     (call fzf-vim :Buffers command)

----------------------------------------------------------------------------
 
### Closing buffers

*XTabCloseBuffer* will close and delete the current buffer, while keeping the window open, and loading either:

* the alternate buffer
* a valid buffer for the tab

It will not try to close the tab page/quit vim, unless:

    let g:xtabline_settings.close_buffer_can_close_tab = 1
    let g:xtabline_settings.close_buffer_can_quit_vim  = 1

----------------------------------------------------------------------------
 
### Tabs, buffers and sessions

You can toggle between buffers and tabs with <kbd>F5<\kbd>.

#### Opening tabs

|Command      | Mapping | Plug                         | Description                                       |
|-------------|---------|------------------------------|---------------------------------------------------|
|XTabNew      | tn      | `<Plug>(XT-Tab-New)`         | accepts a parameter, that is the name of the new tab|
|XTabEdit     | te      | `<Plug>(XT-Tab-Edit)`        | accepts a path, and if called with bang, you'll be able to rename the tab soon after|
|XTabReopen   | tr      | `<Plug>(XT-Reopen)`          | lets you reopen a previosly closed tab, and is repeatable  |

#### Rearranging tabs

`XTabMove` should be used to rearrange tabs, and not the regular `tabmove` command. It can be called with arguments:

|Command       | Mapping | Plug                              | Description           |
|--------------|---------|-----------------------------------|-----------------------|
|`XTabMove +`  | <kbd>+t</kbd>      | `<Plug>(XT-Move-Tab+)` | move forward by 1     | 
|`XTabMove -`  | <kbd>-t</kbd>      | `<Plug>(XT-Move-Tab-)` | move backwards by 1   | 
|`XTabMove 0`  | <kbd>+T</kbd>      | `<Plug>(XT-Move-Tab0)` | make it the first tab | 
|`XTabMove $`  | <kbd>-T</kbd>      | `<Plug>(XT-Move-Tab$)` | move at end           | 

#### Saving and loading tabs

_fzf-vim_ is required. With most of the *fzf-vim* commands you can select multiple items by pressing `<Tab>`.

|Command               | Mapping | Plug                   |
|----------------------|---------|------------------------|
|XTabLoadTab           | lt      |`<Plug>(XT-Load-Tab)`   |
|XTabSaveTab           | st      |`<Plug>(XT-Save-Tab)`   |
|XTabDeleteTab         | dt      |`<Plug>(XT-Delete-Tab)` |

Saved tabs are stored in `$HOME/.vim/.XTablineTabs`.

#### Managing buffers

_fzf-vim_ is required.

|Command                 | Mapping | Plug                                | Description                                       |
|------------------------|---------|-------------------------------------|---------------------------------------------------|
|XTabListBuffers         | b       | `<Plug>(XT-List-Buffers)`           | list a list of `Tab Buffers` to choose from       |
|XTabDeleteBuffers       | db      | `<Plug>(XT-Delete-Buffers)`         | same list, but use `bdelete` command on them      |
|XTabDeleteGlobalBuffers | dgb     | `<Plug>(XT-Delete-Global-Buffers)`  | `bdelete`, but choose from the global buffers list|

#### Tuning buffer filtering

|Command         | Mapping | Plug                             | Description                                       |
|----------------|---------|----------------------------------|---------------------------------------------------|
|XTabWD!         |  wd     | `<Plug>(XT-Working-Directory)`   | will let you set the `cwd` and updates the tabline. With a bang, you'll be prompted for a cwd. |
|XTabPinBuffer   |  pb     | `<Plug>(XT-Pin-Buffer)`          | a pinned buffer will be visible in all tabs       |
|XTabDepth       |  sd     | `<Plug>(XT-Set-Depth)`           | will let you set the filtering depth (number of directories below current one, for which buffers are shown) |

By default, in the bufferline will be shown buffers that belong to the tab's CWD, or any open buffer inside the window.

With `XTabDepth` you can define how many directories below the current one will be valid for buffer filtering. If a [count] is given, filtering depth will be set to that number.
#### Customizing tabs and buffers

|Command                | Mapping     | Plug                             | Notes                                             |
|-----------------------|-------------|----------------------------------|---------------------------------------------------|
|XTabRenameTab          |  nt         |`<Plug>(XT-Rename-Tab)`           |                                                   |
|XTabRenameBuffer       |  nb         |`<Plug>(XT-Rename-Buffer)`        |                                                   |
|XTabIcon               |  ti         |`<Plug>(XT-Tab-Icon)`      |                                                   |
|XTabBufferIcon         |  bi         |`<Plug>(XT-Buffer-Icon)`   |                                                   |
|XTabFormatBuffer       |  bf         |`<Plug>(XT-Buffer-Format)` |                                                   |
|XTabRelativePaths      |  rp         |`<Plug>(XT-Relative-Paths)`       | Toggles between basename and relative path in the bufferline |
|XTabResetTab           |  rt         |`<Plug>(XT-Reset-Tab)`            | Reset tab customizations, also try to find a suitable cwd for that tab |
|XTabResetBuffer        |  rb         |`<Plug>(XT-Reset-Buffer)`         | Reset buffer customization |

When assigning an icon, you can autocomplete the icon name, or insert a single character. To expand the list of available icons for autocompletion, see [Customization](#customization).

`XTabResetTab` will also try to find a suitable cwd for that tab.

#### Sessions management

Both _vim-obsession_ and _fzf-vim_ are required for session management.

|Command               | Mapping | Plug                            |
|----------------------|---------|---------------------------------|
|XTabLoadSession       | ls      |`<Plug>(XT-Load-Session)`        |
|XTabSaveSession       | ss      |`<Plug>(XT-Save-Session)`        |
|XTabDeleteSession     | ds      |`<Plug>(XT-Delete-Session)`      |
|XTabNewSession        | ns      |`<Plug>(XT-New-Session)`         |

Descriptions are saved in `$HOME/.vim/.XTablineSessions`.

Session commands operate on sessions found in the specified directory. Default:

    let g:xtabline_settings.sessions_path = '$HOME/.vim/session'

----------------------------------------------------------------------------
 
### Other commands, plugs and mappings

|Command                | Mapping     | Plug                          | Description                                             |
|-----------------------|-------------|-------------------------------|---------------------------------------------------------|
|                       |<kbd>F5<\kbd>|`<Plug>(XT-Toggle-Tabs)`          | toggle between tabs and buffers                      |
|XTabPurge              |  pt         |`<Plug>(XT-Purge)`                | purge orphaned buffers/previews                      |
|XTabCleanUp!           |  wa         |`<Plug>(XT-Wipe-All)`             | only leaves buffers with open windows in each tab    |
|XTabCleanUp            |  cu         |`<Plug>(XT-Clean-Up)`             | clean up the global buffers list                     |
|XTabTodo               |  tt         |`<Plug>(XT-Tab-Todo)`             | open tab todo file                                   |
|XTabCustomTabs         |  ct         |`<Plug>(XT-Custom-Tabs)`          | Toggle visibility of tab customizations (name, icon) |
|                       |  tf         |`<Plug>(XT-Toggle-Filtering)`     | toggle buffer filtering                              |
|                       |  cdc        |`<Plug>(XT-Cd-Current)`           |                                                      |
|                       |  cdd        |`<Plug>(XT-Cd-Down)`              | accepts [count]                                      |
|XTabNERDBookmarks      |             |                                  | open the list of `NERDTreeBookmarks`                 |

### Buffers clean-up

`XTabPurge`

This command is handy to close all buffers that aren't bound to a physical file (such `vim-fugitive` logs, `vim-gitgutter` previews, quickfix windows etc).
If the only window in the tab is going to be closed, the buffer switches to the first tab buffer, so that you won't lose the tab.

Default mapping: `<prefix>p`

----------------------------------------------------------------------------

`XTabCleanUp`

This command deletes all buffers from the global buffers list, that are not valid for any of the current tabs. Useful to get rid of terminal buffers in
neovim, for example, or to keep slim your buffer list.

Default mapping: `<prefix>c`

----------------------------------------------------------------------------

`XTabWipe`

This command is similar to the previous one, except that it also deletes tab buffers, leaving only the currently open windows/buffers for each tab.


Default mapping: `<prefix>C`

----------------------------------------------------------------------------
 
### Tab-Todo

This command opens a todo file at the tab's CWD. Default mapping is `prefix`t

If you change the following options, make sure that both of them appear in
your *.vimrc* file.

You can define the filename (include the directory separator):

    let g:xtabline_settings.todo_file = "/.TODO"

And you can define other options:
```vim
    let g:xtabline_settings.todo = {'path': getcwd().g:xtabline_todo_file,
                         \ 'command': 'sp', 'prefix': 'below',
                         \ 'size': 20, 'syntax': 'markdown'}
```
__*path*__    : you shouldn't change this, only change *g:xtabline_todo_file*
__*command*__ : can be `sp`, `vs`, `edit`, etc.
__*prefix*__  : will affect where the window appears (check `opening-window` for help)
__*size*__    : the height/width of the window
__*syntax*__  : the syntax that will be loaded

----------------------------------------------------------------------------
 
### Cwd selection

Disabled by default, you can enable them by setting:

    let g:xtabline_cd_commands = 1

These commands allow you to quickly change your tab CWD, and update the
tabline at the same time.

|Mapping                          | Default        |
|---------------------------------|----------------|
|\<Plug>(XT-Cd-current)         | \<leader>cdc   |
|\<Plug>(XT-Cd-down1)           | \<leader>cdd   |
|\<Plug>(XT-Cd-down2)           | \<leader>cd2   |
|\<Plug>(XT-Cd-down3)           | \<leader>cd3   |
|\<Plug>(XT-Cd-home)            | \<leader>cdh   |
|\<Plug>(XT-Restrict-cwd)       | \<leader>cdr   |

----------------------------------------------------------------------------
 
### Restrict Cwd

Run this command to temporarily restrict filter buffering to the files at the
root of the current cwd, ignoring not only the files that are outside of it,
but also the ones in subdirectories. This option is toggled on a per-tab basis
and is not persistent across sessions.

Default mapping: `<prefix>R`

----------------------------------------------------------------------------
 
### Customization

You can add any of these to your *.vimrc*, in the `g:xtabline_settings` dictionary. Eg.:

    let g:xtabline_settings.disable_keybindings = 1

|Option                   | Effect                              | Default |
|-------------------------|-------------------------------------|---------|
|disable_keybindings      |                                     |  0      |
|alt_action               | SelectBuffer alternative command    | `buffer #` |
|todo                     | todo command customization          |         |
|sessions_path            | sessions directory                  | `$HOME/.vim/session`        |

----------------------------------------------------------------------------
 

To prevent previews (eg. vim-fugitive logs) from being displayed, add:

    let g:xtabline_settings.exact_paths = 1

(You'll still be able to purge them with XTabPurge)

You can remap commands individually. You can copy this section to your
*.vimrc* and change the values to ones you prefer.

These are the mappings I use:

```vim
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " xtabline
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    nmap <F5>             <Plug>(XT-Toggle-tabs)
    nmap <leader><F5>     <Plug>(XT-Toggle-Buffers)
    nmap <BS>             <Plug>(XT-Select-Buffer)

    nnoremap <nowait> <silent> <expr> <Right> v:count? xtabline#next_buffer(v:count) : "\<Right>"
    nnoremap <nowait> <silent> <expr> <Left>  v:count? xtabline#prev_buffer(v:count) : "\<Left>"

    nmap <Space>b         <Plug>(XT-Buffers-open)
    nmap {your-prefix}d   <Plug>(XT-Buffers-delete)
    nmap {your-prefix}D   <Plug>(XT-All-Buffers-delete)
    nmap {your-prefix}r   <Plug>(XT-Reopen)
    nmap {your-prefix}p   <Plug>(XT-Purge)
    nmap {your-prefix}c   <Plug>(XT-Clean-up)
    nmap {your-prefix}C   <Plug>(XT-Wipe)
    nmap {your-prefix}l   <Plug>(XT-Bookmarks-load)
    nmap {your-prefix}s   <Plug>(XT-Bookmarks-save)
    nmap {your-prefix}L   <Plug>(XT-Session-load)
    nmap {your-prefix}S   <Plug>(XT-Session-save)
    nmap {your-prefix}t   <Plug>(XT-Tab-todo)
    nmap {your-prefix}R   <Plug>(XT-Restrict-cwd)

    let g:xtabline_settings.map_prefix    = '<leader>x'
    let g:xtabline_settings.alt_action    = "Buffers"

    let g:xtabline_settings.bookmaks_file = expand('$HOME/.vim/.XTabBookmarks')
    let g:xtabline_settings.sessions_path = '$HOME/.vim/session'

    let g:xtabline_settings.todo_file     = "/.TODO"
    let g:xtabline_settings.todo          = {'path': getcwd().g:xtabline_settings.todo_file, 'command': 'sp', 'prefix': 'below', 'size': 20, 'syntax': 'tasks'}

```

----------------------------------------------------------------------------
 
### Interaction With Airline

xtabline will override Airline's tabline by default, because it's faster. To restore it, set:

let g:xtabline_settings.override_airline = 0
let g:airline#extensions#tabline#show_buffers = 1

You will still have buffer filtering, but lose other features (custom names and icons, formatting, etc).  
But you will be able to use Airline'themes. xtabline has its own ones and is not compatible with them.

----------------------------------------------------------------------------
 

### Credits

Braam Moolenaar for Vim  
[vim-airline](https://github.com/vim-airline/vim-airline) authors  
Junegunn Choi for [fzf-vim](https://github.com/junegunn/fzf.vim)  
Tim Pope for [vim-obsession](https://github.com/tpope/vim-obsession)  
Kana Natsuno for [tabpagecd](https://github.com/kana/vim-tabpagecd)  

----------------------------------------------------------------------------
 
### License

MIT


