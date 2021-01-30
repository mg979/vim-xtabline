## xtabline

![Imgur](https://i.imgur.com/idI7U7P.gif)

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

In Windows, one of the pre-patched [nerd-fonts](https://github.com/ryanoasis/nerd-fonts/releases) is recommended.

----------------------------------------------------------------------------
 
### Introduction

This plugin tries to give you full control on the tabline:

* three tabline modes: tabs, buffers, arglist
* buffer filtering on the base of the CWD (also local)
* you can rename tabs and/or buffers, and assign them icons

Also:

* tab CWD/name is shown in the right corner of the tabline
* commands to quickly set/change (tab/window) working directory
* reopen closed tabs
* clean up buffers across all tabs
* session management and tabs bookmarks

----------------------------------------------------------------------------
 
### Features

The tabline can be rendered in three different modes:

|||
-|-
tabs     | tab name, CWD, or buffer name 
buffers  | up to a max of N (default 10) recent buffers 
arglist  | buffers contained in the arglist 

In *tabs-mode*, the tabline will show the numbered tabs. This looks a lot like
vim default tabline, but the CWD is shown in the top-right corner.

In *buffer-mode*, the tabline will show a filtered list of buffers that belong
to the tab's CWD, or any open buffer inside the window. By default, only the 10
most recently accessed buffers are displayed.

In *arglist-mode*, the tabline will show the files defined in the arglist. You
can switch file with the usual commands (`:next`, etc).

These modes can be cycled with a mapping (*F5* by default). You can also define
which modes to cycle with a setting.

Buffers and tabs can be renamed, and also given a custom icon.

----------------------------------------------------------------------------
 
### Installation

##### Install the plugin:

Use [vim-plug](https://github.com/junegunn/vim-plug) or any other Vim plugin manager.

With vim-plug:

    Plug 'mg979/vim-xtabline'

##### Recommendation for macOS users:

If you want to use the session management feature, you must install the GNU
core utilities, because its implementation requires the GNU version of the
`stat` and `date` commands. The corresponding GNU commands are `gstat` and
`gdate`. Install them with:

    brew install coreutils


----------------------------------------------------------------------------
 
### Usage

`:help xtabline.txt`

Some quick tips, assuming you are using default mappings:

|||
-|-
<kbd>F5</kbd> | change tabline mode
_N_ <kbd>BS</kbd> | go to _N_ tab (in tabs mode) or _N_ buffer (in buffers mode)
<kbd>[b</kbd>/<kbd>]b</kbd> | go to _count_ next/previous buffer
<kbd>cdw</kbd>/<kbd>cdl</kbd>/<kbd>cdt</kbd> | set working directory (tab/local)
<kbd>cd?</kbd> | show tab informations (cwd, git dir, tag files)
<kbd>\x?</kbd> | a list of all mappings

----------------------------------------------------------------------------
 

### Themes

Some details may vary, depending on color schemes and plugin version.
Here used with default bufferline formatter, and with empty formatter:

#### codedark
 
![Imgur](https://i.imgur.com/WP2zyPR.png)
 
----------------------------------------------------------------------------
 
#### slate
 
![Imgur](https://i.imgur.com/XAlDmqP.png)
 
----------------------------------------------------------------------------
 
#### monokai
 
![Imgur](https://i.imgur.com/9QDyCFf.png)
 
----------------------------------------------------------------------------
 
#### seoul
 
![Imgur](https://i.imgur.com/umHi9zb.png)
 
----------------------------------------------------------------------------
 
#### tomorrow
 
![Imgur](https://i.imgur.com/q28L8YX.png)
 
----------------------------------------------------------------------------
 
#### dracula
 
![Imgur](https://i.imgur.com/nLkV47A.png)
 


----------------------------------------------------------------------------
 

### Credits

Bram Moolenaar for Vim  
Aristotle Pagaltzis for [Buftabline](https://github.com/ap/vim-buftabline)  
Giacomo Comitti for [Taboo](https://github.com/gcmt/taboo.vim)  

----------------------------------------------------------------------------
 
### License

MIT


