## xtabline

![Imgur](https://i.imgur.com/yU6qbU5.gif)

----------------------------------------------------------------------------

* [Introduction](#introduction)
* [Features](#features)
* [Installation](#installation)
* [Usage](#usage)
* [Themes](#themes)
* [Credits](#credits)
* [License](#license)

----------------------------------------------------------------------------
 
### Introduction

This plugin tries to give you full control on the tabline:

* buffer filtering on the base of the current CWD, or other directories
* three tabline modes: (filtered) buffers, tabs, arglist
* limit rendered buffers to the N most recently accessed (default 10)
* persistance

More advanced features:

* buffers quick navigation (next, previous, with count)
* reopen closed tabs
* clean up buffers across all tabs
* tabs/buffers formatting options (names, icons, separators, reordering)
* session management: load/save/delete sessions, with timestamping/descriptions
* tabs bookmarks: load/save customized tabs from/to disk
* tab-todo: customizable command to open a todo file for that tab

----------------------------------------------------------------------------
 
### Features

The tabline can be rendered in three different modes:

|||
|-|-|
|buffers  | up to a max of N (default 10) recent buffers |
|tabs     | tab name, CWD, or buffer name |
|arglist  | buffers contained in the arglist |

In *buffer-mode*, in the tabline will be shown buffers that belong to the tab's
CWD, or any open buffer inside the window. By using the custom buffer
navigation commands you can switch among them, while using the normal `:bnext`
command, you still cycle among the default (global) buffer list.
Formatting can be customized.

In *tabs-mode*, the tabline will show the numbered tabs. The label will be
either the tab name (if defined), the tab CWD (if using per-tab CWDs), or the
filename of the first buffer in the tab.

In *arglist-mode*, the tabline will show the files defined in the arglist. You
can switch file with the usual commands (`:next`, etc).

These modes can be cycled with a mapping (*F5* by default). You can also define
which modes to cycle with a setting.

------------------------------------------------------------------------------

Other features, besides the tabline rendering, are:

- per-tab CWD
- buffer filtering
- tabs management
- sessions management

The first one means that each tab can have its own CWD (set with |:cd|): when
switching tabs, the tab's CWD is automatically restored.

The second one means that in the tabline, only buffers that are valid for the
tab's CWD will be listed.

The last two are a series of commands that allow you to save/restore tabs and
sessions.

[vim-obsession](https://github.com/tpope/vim-obsession) is required for persistance.  
[fzf-vim](https://github.com/junegunn/fzf.vim) is required for commands related to sessions/tabs management.  

----------------------------------------------------------------------------
 
### Installation

Use [vim-plug](https://github.com/junegunn/vim-plug) or any other Vim plugin manager.

With vim-plug:

    Plug 'mg979/vim-xtabline'

----------------------------------------------------------------------------
 
### Usage

`:help xtabline.txt`

----------------------------------------------------------------------------
 

### Themes

Some details may vary, depending on color schemes and plugin version.
Here used with default bufferline formatter, and with empty formatter:

#### codedark
 
![Imgur](https://i.imgur.com/GY7Dxph.gif)
 
----------------------------------------------------------------------------
 
#### slate
 
![Imgur](https://i.imgur.com/ph3pRE4.gif)
 
----------------------------------------------------------------------------
 
#### monokai
 
![Imgur](https://i.imgur.com/9jEi0SH.gif)
 
----------------------------------------------------------------------------
 
#### seoul
 
![Imgur](https://i.imgur.com/jlhZGNc.gif)
 
----------------------------------------------------------------------------
 
#### tomorrow
 
![Imgur](https://i.imgur.com/zNAAPtT.gif)
 
----------------------------------------------------------------------------
 
#### dracula
 
![Imgur](https://i.imgur.com/orsM1bK.gif)
 


----------------------------------------------------------------------------
 

### Credits

Bram Moolenaar for Vim  
[Buftabline](https://github.com/ap/vim-buftabline) for the bufferline rendering  
[Taboo](https://github.com/gcmt/taboo.vim) for the tabline rendering  
Junegunn Choi for [fzf-vim](https://github.com/junegunn/fzf.vim)  
Tim Pope for [vim-obsession](https://github.com/tpope/vim-obsession)  
Kana Natsuno for [tabpagecd](https://github.com/kana/vim-tabpagecd)  

----------------------------------------------------------------------------
 
### License

MIT


