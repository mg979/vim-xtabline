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
    * [Rearranging buffers](#rearranging-buffers)
    * [Customizing tabs and buffers](#customizing-tabs-and-buffers)
    * [Sessions management](#sessions-management)
* [Other commands, plugs and mappings](#other-commands-plugs-and-mappings)
    * [Buffers clean-up](#buffers-clean-up)
    * [Tab-Todo](#tab-todo)
* [Customization](#customization)
    * [Tabs/Buffers formatting](#tabsbuffers-formatting)
    * [Buffers formatting](#buffers-formatting)
    * [Tab formatting](#tab-formatting)
    * [Remapping commands](#remapping-commands)
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
* commands to rearrange tabs and buffers positions
* commands to clean up buffers across all tabs
* session management: load/save/delete sessions, with timestamping and descriptions
* Tab-todo: customizable command to open a todo file for that tab

Integrated with:

* *fzf-vim* (load saved tabs, sessio management)
* *vim-obsession* for automatic CWDs persistance across sessions
* additional support for *vim-airine* and *vim-devicons*

Reuses code from:

* [Buftabline](https://github.com/ap/vim-buftabline) for the bufferline
* [Taboo](https://github.com/gcmt/taboo.vim) for the tabline

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
|`count`<kbd>BS</kbd>  | `<Plug>(XT-Select-Buffer)`          |
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

    let g:xtabline_settings.selbuf_alt_action = "buffer #"    (switch to alternative buffer)
    let g:xtabline_settings.selbuf_alt_action = "Buffers"     (call fzf-vim :Buffers command)

----------------------------------------------------------------------------
 
#### Closing buffers

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
|XTabReopen   | rt      | `<Plug>(XT-Reopen)`          | lets you reopen a previosly closed tab, and is repeatable  |
|XEdit        | rt      | `<Plug>(XT-Edit)`            | llike :edit, but prompts for directory creation, if not existant. |

#### Rearranging tabs

`XTabMove` should be used to rearrange tabs, and not the regular `tabmove` command. It can be called with arguments:

|Command       | Mapping            | Plug                   | Description           |
|--------------|--------------------|------------------------|-----------------------|
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
|                |  tf     | `<Plug>(XT-Toggle-Filtering)`    | toggle buffer filtering for all tabs                 |

By default, in the bufferline will be shown buffers that belong to the tab's CWD, or any open buffer inside the window.

With `XTabDepth` you can define how many directories below the current one will be valid for buffer filtering.
    * If no [count] is given, command toggles between depth -1 (all dirs below cwd) and 0 (cwd root only)
    * If a [count] is given, filtering depth will be set to that number.

#### Rearranging buffers

|Mapping               | Plug                                |
|----------------------|-------------------------------------|
|mb                    | `<Plug>(XT-Move-Buffer)`            |
|hb                    | `<Plug>(XT-Hide-Buffer)`            |
|                      | `<Plug>(XT-Hide-Buffer-n)`          |

*Move-Buffer* accepts a [count], and will move the current buffer after [count] position.  
*Hide-Buffer* puts the current buffer last, and then selects [count] buffer, as by *Select-Buffer*. Selects first if no [count] is given.

*Hide-Buffer-n* works like *Select-Buffer*, in that it needs a [count] and has an alternative action when no [count] is given. There is no default mapping, so you have to map it yourself.  
Alternative action for this command is defined by:

    let g:xtabline_settings.hidbuf_alt_action = "buffer #"    (switch to alternative buffer)

#### Customizing tabs and buffers

|Command                | Mapping     | Plug                             | Notes                                             |
|-----------------------|-------------|----------------------------------|---------------------------------------------------|
|XTabRenameTab          |  nt         |`<Plug>(XT-Rename-Tab)`           |                                                   |
|XTabRenameBuffer       |  nb         |`<Plug>(XT-Rename-Buffer)`        |                                                   |
|XTabIcon               |  it         |`<Plug>(XT-Tab-Icon)`             |                                                   |
|XTabBufferIcon         |  ib         |`<Plug>(XT-Buffer-Icon)`          |                                                   |
|XTabFormatBuffer       |  fb         |`<Plug>(XT-Buffer-Format)`        | Change the label formatting                       |
|XTabRelativePaths      |  rp         |`<Plug>(XT-Relative-Paths)`       | Toggles between basename and relative path in the bufferline |
|XTabResetTab           |  Rt         |`<Plug>(XT-Reset-Tab)`            | Reset tab customizations, also try to find a suitable cwd for that tab |
|XTabResetBuffer        |  Rb         |`<Plug>(XT-Reset-Buffer)`         | Reset buffer customization |
|XTabCustomTabs         |  ct         |`<Plug>(XT-Custom-Tabs)`          | Toggle visibility of tab customizations (name, icon) |

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

|Command                | Mapping     | Plug                          | Notes                                                   |
|-----------------------|-------------|-------------------------------|---------------------------------------------------------|
|                       |<kbd>F5<\kbd>|`<Plug>(XT-Toggle-Tabs)`       | toggle between tabs and buffers                      |
|XTabPurge              |  pt         |`<Plug>(XT-Purge)`             | purge orphaned buffers/previews                      |
|XTabCleanUp!           |  wa         |`<Plug>(XT-Wipe-All)`          | only leaves buffers with open windows in each tab    |
|XTabCleanUp            |  cu         |`<Plug>(XT-Clean-Up)`          | clean up the global buffers list                     |
|XTabTodo               |  tt         |`<Plug>(XT-Tab-Todo)`          | open tab todo file                                   |
|                       |  cdc        |`<Plug>(XT-Cd-Current)`        | relative to the currently open buffer                |
|                       |  cdd        |`<Plug>(XT-Cd-Down)`           | [count1] directories below current buffer     |
|XTabNERDBookmarks      |             |                               | open the list of `NERDTreeBookmarks`                 |

#### Buffers clean-up

`XTabPurge`

This command is handy to close all buffers that aren't bound to a physical file (such `vim-fugitive` logs, `vim-gitgutter` previews, quickfix windows etc).
If the only window in the tab is going to be closed, the buffer switches to the first tab buffer, so that you won't lose the tab.

Default mapping: `<prefix>pt`

----------------------------------------------------------------------------

`XTabCleanUp`, `XTabCleanUp!`

This command deletes all buffers from the global buffers list, that are not valid for any of the current tabs. Useful to get rid of terminal buffers in
neovim, for example, or to keep slim your buffer list.

With a bang, it also deletes tab buffers, leaving only the currently open windows/buffers for each tab.

Default mappings: `<prefix>cu` `<prefix>wa`

----------------------------------------------------------------------------
 
#### Tab-Todo

This command opens a todo file at the tab's CWD. Default mapping is `prefix`tt

Inside the todo buffer, `q` saves and closes the buffer.

You can define the filename and other options:

```vim
let g:xtabline_settings.todo = { 'file': '.TODO', 'prefix': 'below',
                                \'command': 'sp', 'size': 20, 'syntax': 'markdown'}
```

|              |                                 |
|--------------|---------------------------------|
|__*file*__    | the filename that will be used  |
|__*prefix*__  | check `opening-window` for help |
|__*command*__ | can be `sp`, `vs`, `edit`, etc. |
|__*size*__    | the height/width of the window  |
|__*syntax*__  | the syntax that will be loaded  |

----------------------------------------------------------------------------
 
### Customization

|Command               | Mapping | Plug                       | Notes                 |
|----------------------|---------|----------------------------|-----------------------|
|XTabConfig            | C       |`<Plug>(XT-Config)` | run the configurator  |
|XTabTheme             | T       |`<Plug>(XT-Theme)`    | select a theme (`tab` autocompletion)       |

You can add any of these to your *.vimrc*, after having initialized the `g:xtabline_settings` dictionary. Some of these options can be set in the configurator.

    let g:xtabline_settings = {}
    let g:xtabline_settings.option_name = option_value

|Option                     | Notes                               |  Default                         |
|---------------------------|-------------------------------------|----------------------------------|
|disable_keybindings        | only `<Plug>`s will be defined      |   0                              |
|selbuf_alt_action          | SelectBuffer alternative command    |  `buffer #`                      |
|hidbuf_alt_action          | HideBuffer alternative command      |  `buffer #`                      |
|sessions_path              | sessions directory                  |  `$HOME/.vim/session`            |
|map_prefix                 |                                     | `<leader>x`                      | 
|close_buffer_can_close_tab |                                     | 0                                | 
|close_buffer_can_quit_vim  |                                     | 0                                | 
|unload_session_ask_confirm |                                     | 1                                | 
|depth_tree_size            |                                     | 20                               | 
|bookmarks_file             |                                     | `$HOME/.vim/.XTablineBookmarks`  | 
|sessions_data              |                                     | `$HOME/.vim/.XTablineSessions`   | 
|default_named_tab_icon     |                                     | []                               | 
|superscript_unicode_nrs    | use superscript or subscript nrs    | 0                                | 
|show_current_tab           |                                     | 1                                | 
|enable_extra_highlight     |                                     | 1                                | 
|sort_buffers_by_last_open  |                                     | 0                                | 
|override_airline           |                                     | 1                                | 

----------------------------------------------------------------------------
 
#### Tabs/Buffers formatting

|Option                     | Notes                               |  Default       |
|---------------------------|-------------------------------------|----------------|
| bufline_numbers           |                                     | 1              |
| bufline_sep_or_icon       | icon will suppress the separator    | 0              |
| bufline_separators        |                                     | `['', '']`   |
| devicon_for_all_filetypes |                                     | 0              |
| devicon_for_extensions    |                                     | `['md', 'txt']`|
| bufline_format            |                                     | ` n I< l +`    |
| tab_format                |                                     | `N - 2+ `      |
| renamed_tab_format        |                                     | `N - l+ `      |
| bufline_named_tab_format  |                                     | `N - l+ `      |
| bufline_tab_format        |                                     | `N - 2+ `      |
| modified_tab_flag         |                                     | `*`            |
| close_tabs_label          |                                     | ''             |
| tab_icon                  |                                     | `["📂", "📁"]` |

`custom_icons` are the ones that can be used when assigning an icon to a tab/buffer, and can be used in other contexts (special buffers icon).

```vim
let g:xtabline_settings.bufline_indicators = {
    \ 'modified': '[+]',
    \ 'readonly': '[🔒]',
    \ 'scratch': '[!]',
    \ 'pinned': '[📌]',
    \}

let g:xtabline_settings.custom_icons = {
    \'pin': '📌',
    \'star': '★',
    \'book': '📖',
    \'lock': '🔒',
    \'hammer': '🔨',
    \'tick': '✔',
    \'cross': '✖',
    \'warning': '⚠',
    \'menu': '☰',
    \'apple': '🍎',
    \'linux': '🐧',
    \'windows': '⌘',
    \'git': '',
    \}
```

#### Buffers formatting

Default formatting is ` n I< l +`. In this notation, each character is replaced by something, while spaces are retained as they are. Possible elements are:

|Option  | Description                                                |
|--------|------------------------------------------------------------|
| l      | custom name, filename as fallback                          |
| f      | filename                                                   |
| n      | buffer number as small unicode                             |
| N      | buffer number                                              |
| +      | indicators (modified, read only...)                        |
| i      | icon (devicon preferred)                                   |
| I      | icon (custom icon preferred)                               |
| <      | separator, can be suppressed by icon                       |
| >      | separator, can't be suppressed by icon                     |

#### Tab formatting

Default formatting is `N - 2+ ` for unnamed tabs, `N - l+ ` for named tabs. Notation rules are the same, but character meaning can be different:

|Option  | Description                                                |
|--------|------------------------------------------------------------|
| l      | custom name, short cwd as fallback                         |
| -      | icon (custom icon preferred)                               |
| +      | modified indicator                                         |
| f      | buffer filename                                            |
| a      | buffer path                                                |
| n      | tab number (current tab)                                   |
| N      | tab number (all tabs)                                      |
| w      | windows count                                              |
| W      | windows count                                              |
| u      | windows count as small unicode                             |
| U      | windows count as small unicode                             |
| P      | full cwd                                                   |
| 0      | short cwd, truncated at 0 directory separators             |
| 1      | short cwd, truncated at 1 directory separators             |
| 2      | short cwd, truncated at 2 directory separators             |

----------------------------------------------------------------------------

#### Remapping commands

You can remap commands individually. These are some easier mappings I use:

```vim
nmap <space>x          <Plug>(XT-Purge)
nmap <space>b          <Plug>(XT-List-Buffers)
nmap <space>t          <Plug>(XT-Tab-Todo)
nmap <M-q>             <Plug>(XT-Close-Buffer)
```

----------------------------------------------------------------------------
 
#### Interaction With Airline

xtabline will override Airline's tabline by default. To use Airline's tabline instead, set:

    let g:xtabline_settings.override_airline = 0

You will still have buffer filtering, but lose other features (custom names and icons, formatting, etc).  
But you will be able to use Airline's themes. xtabline has its own ones and is not compatible with them.

----------------------------------------------------------------------------
 

### Credits

Braam Moolenaar for Vim  
[Buftabline](https://github.com/ap/vim-buftabline) for the bufferline rendering  
[Taboo](https://github.com/gcmt/taboo.vim) for the tabline rendering  
Junegunn Choi for [fzf-vim](https://github.com/junegunn/fzf.vim)  
Tim Pope for [vim-obsession](https://github.com/tpope/vim-obsession)  
[vim-airline](https://github.com/vim-airline/vim-airline) authors  
Kana Natsuno for [tabpagecd](https://github.com/kana/vim-tabpagecd)  

----------------------------------------------------------------------------
 
### License

MIT


