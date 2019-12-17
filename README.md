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

**Note**: you may need some patched font for icons. In a Debian-based
distribution you can install the following packages:

- ttf-ancient-fonts-symbola
- fonts-powerline

----------------------------------------------------------------------------
 
### Introduction

This plugin tries to give you full control on the tabline:

* buffer filtering on the base of the current CWD
* three tabline modes: tabs, (filtered) buffers, arglist
* limit rendered buffers to the N most recently accessed (default 10)
* persistance in sessions

More features:

* tab CWD/name is shown in the right corner of the tabline
* commands to quickly set/change (tab/window) working directory
* buffers quick navigation (next, previous, with count)
* reopen closed tabs
* clean up buffers across all tabs
* session management: load/save/delete sessions, with timestamping/descriptions
* tabs bookmarks: load/save customized tabs from/to disk
* tab-todo: customizable command to open a todo file for that tab

----------------------------------------------------------------------------
 
### Features

The tabline can be rendered in three different modes:

|||
-|-
tabs     | tab name, CWD, or buffer name 
buffers  | up to a max of N (default 10) recent buffers 
arglist  | buffers contained in the arglist 

In *tabs-mode*, the tabline will show the numbered tabs. The label can be
customized as well (to show buffer name, tab cwd, etc).

In *buffer-mode*, the tabline will show a filtered list of buffers that belong
to the tab's CWD, or any open buffer inside the window. Formatting and number
of (recently accessed) buffers can be customized.

In *arglist-mode*, the tabline will show the files defined in the arglist. You
can switch file with the usual commands (`:next`, etc).

These modes can be cycled with a mapping (*F5* by default). You can also define
which modes to cycle with a setting.

------------------------------------------------------------------------------

Other features, besides the tabline rendering, are:

- buffer filtering
- tabs management
- sessions management

*Buffer filtering* means that in *buffer-mode*, only buffers that are valid
for the tab's CWD will be listed.

The last two are a series of commands that allow you to save/restore tabs and
sessions, using a fuzzy finder ([fzf-vim](https://github.com/junegunn/fzf.vim)
or a built-in one).

[vim-obsession](https://github.com/tpope/vim-obsession) is required for persistance.  

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


