## xtabline

![Imgur](https://i.imgur.com/yU6qbU5.gif)
![pic](https://i.imgur.com/SN6FNnA.gif)

----------------------------------------------------------------------------

<!-- vim-markdown-toc GFM -->

* [Features list](#features-list)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
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
 
### Usage

`:help xtabline.txt`

----------------------------------------------------------------------------
 

### Credits

Braam Moolenaar for Vim  
[Buftabline](https://github.com/ap/vim-buftabline) for the bufferline rendering  
[Taboo](https://github.com/gcmt/taboo.vim) for the tabline rendering  
Junegunn Choi for [fzf-vim](https://github.com/junegunn/fzf.vim)  
Tim Pope for [vim-obsession](https://github.com/tpope/vim-obsession)  
Kana Natsuno for [tabpagecd](https://github.com/kana/vim-tabpagecd)  

----------------------------------------------------------------------------
 
### License

MIT


