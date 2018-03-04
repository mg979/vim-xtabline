### Xtabline

![pic](https://i.imgur.com/SN6FNnA.gif)

    Introduction
    Features
    Requirements
    Installation
    Interaction with vim-airline
    Tab Buffers navigation
    Toggling
    Persistance
    Bookmarks
    TabTodo
    fzf commands
    Customization
    Warnings
    Credits
    License

  
  
#### Introduction

*This README won't be updated as often as the main help file. If you install
the plugin, refer to that one instead.*

XTabline is an extension for *vim-airline*

Its main purpose is to provide a way to filter buffers in the tabline,
depending on the current working directory. Since switching tabs without
switching the CWD would cause wrong buffers to be displayed in the tabline,
XTabline also remembers the CWD for each tab, so that when you switch them,
the CWD is automatically set to the last path that specific tab was set to.

    Eg. you have 2 tabs, you set a CWD with `:cd` in the second tab; switching
    to #1 would set back the old CWD. Switching back to #2 would set the path
    you defined for that tab.

Since each tab has its own CWD, XTabline filters the buffers to be shown on
it, to display only the buffers whose path is within the CWD for that tab.

  
  
---

#### Features List

With *Tab Buffer* is meant a buffer that is associated with a tab, because its
path is within that tab's CWD.

* Per project/tab buffers filtering in the tabline

* Per project/tab CWD persistance

* Toggle display of tabs/buffers

* Toggle buffer filtering on/off

* Tab buffers quick navigation (next, previous, with *[count]*)

* Tab bookmarks: save and reload a tab with all its buffers and its CWD

* Tab-todo: customizable command to open a todo file for that tab

* *fzf-vim* integration:
    - open/delete multiple *Tab Buffers* at once.
    - access *Tab Bookmarks* or *NERDTreeBookmarks*.

* *vim-obsession* support for CWDs persistance across sessions

  
  
---

#### Requirements

[vim-airline](https://github.com/vim-airline/vim-airline) is required.  
[vim-obsession](https://github.com/tpope/vim-obsession) is required for persistance.  
[fzf-vim](https://github.com/junegunn/fzf.vim) is required for bookmarks commands.  

  
  
---

#### Installation

Use [vim-plug](https://github.com/junegunn/vim-plug) or any other Vim plugin manager.

With vim-plug:

    Plug 'mg979/vim-xtabline'

  
  
---

#### Interaction With Airline

XTabline exploits the built-in Airline 'excludes' list to achieve buffer
filtering. The *g:airline#extensions#tabline#excludes* variable is overwritten
at every tab switch, therefore if you use it, you will need to use this new
variable instead:

    let g:xtabline_excludes = []

  
  
---

#### Tab Buffers Navigation

If you use the normal *:bnext* command, you still cycle among the default
(global) buffer list. If that buffer doesn't 'belong' to that tab, because its
path is outside the current CWD, the buffer will be loaded, but it won't be
shown in the tabline. Only the buffers that are relevant to that tab will be
shown there.

There are new commands that allow you to cycle *Tab Buffers*; these commands
also work when in *tabs mode* (see 'xtabline-toggle' ).

|Mapping                          | Default|
|---------------------------------|------------------------------------------|
|\<Plug>XTablineSelectBuffer       | [count]\<leader>l|
|\<Plug>XTablineNextBuffer         | \<S-PageDown>|
|\<Plug>XTablinePrevBuffer         | \<S-PageUp>|

*XTablineSelectBuffer* has two peculiarities:

* it needs a *[count]* to work, eg. 2<leader>l would bring you to buffer #2
* when not using a *[count]*, it will execute a command of your choice

Define this command by setting the *g:xtabline_alt_action* variable.
Default is `buffer #`

Examples:

    let g:xtabline_alt_action = "buffer #"    (switch to alternative buffer)
    let g:xtabline_alt_action = "Buffers"     (call fzf-vim :Buffers command)

  
  
---

#### Toggling Options

You can toggle both between tabs and buffers, and buffers filtering on and off
(going back to default behaviour). Default mappings are:

|Mapping                          | Default     |
|---------------------------------|------------------------------------------|
|\<Plug>XTablineToggleTabs         | \<F5>|
|\<Plug>XTablineToggleBuffers      | \<leader>\<F5>|

  
  
---

#### Persistance

If you use *vim-obsession* your tabs CWDs will be remembered inside a session
that is currently tracked. It's an automatic process and you don't need to do
or set anything.

  
  
---

#### Fzf Commands

These commands require *fzf-vim*.
With most of them you can select multiple items by pressing <Tab>.

 Command                      | Effect                                           |
 -----------------------------|-------------------------------------------------|
 XTabBuffersOpen              | Open a list of *Tab Buffers* to choose from|
 XTabBuffersDelete            | Same list, but use `bdelete` command on them|
 XTabAllBuffersDelete         | `bdelete`, but choose from the global buffers list|
 XTabBookmarksLoad            | Open the *Tab Bookmarks* list|
 XTabBookmarksSave            | Save the current tab as a bookmark (custom naming)|
 XTabNERDBookmarks            | Open the list of *NERDTreeBookmarks*|

  
  
---

#### Tab-Todo

This command opens a todo file at the tab's CWD. Default mapping is <leader>TT

If you change the following options, make sure that both of them appear in
your *.vimrc* file.

You can define the filename (include the directory separator!):

    let g:xtabline_todo_file = "/.TODO"

And you can define other options:
```vim
    let g:xtabline_todo = {'path': getcwd().g:xtabline_todo_file,
                         \ 'command': 'sp', 'prefix': 'below',
                         \ 'size': 20, 'syntax': 'markdown'}
```
    *path*    : you shouldn't change this, only change *g:xtabline_todo_file*
    *command* : can be `sp`, `vs`, `edit`, etc.
    *prefix*  : will influence where the window appears (check `opening-window` for help)
    *size*    : the height/width of the window
    *syntax*  : the syntax that will be loaded
  
  
---

#### Customization

    let g:xtabline_autodelete_empty_buffers = 0

This option has the effect of automatically deleting (by `bdelete`) unnamed
empty buffers that may be created for different reasons. If disabled, these
buffers will show up in every tab. If enabled, they will be gone when you
switch tab. It is disabled by default.

To disable default mappings, add to your *.vimrc*

    `let g:xtabline_disable_keybindings = 1`

You can remap commands individually. These are the customizable options with
their defaults. You can copy this section to your *.vimrc* and change the
values to ones you prefer.

```vim
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " xtabline
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    nmap <F5>              <Plug>XTablineToggleTabs
    nmap <leader><F5>      <Plug>XTablineToggleBuffers
    nmap <leader>l         <Plug>XTablineSelectBuffer
    nmap <S-PageDown>      <Plug>XTablineNextBuffer
    nmap <S-PageUp>        <Plug>XTablinePrevBuffer
    nmap <leader>BB        <Plug>XTablineBuffersOpen
    nmap <leader>BD        <Plug>XTablineBuffersDelete
    nmap <leader>BA        <Plug>XTablineAllBuffersDelete
    nmap <leader>BL        <Plug>XTablineBookmarksLoad
    nmap <leader>BS        <Plug>XTablineBookmarksSave
    nmap <leader>TT        <Plug>XTablineTabTodo

    let g:xtabline_todo_file = "/.TODO"
    let g:xtabline_todo = {'path': getcwd().g:xtabline_todo_file, 'command': 'sp', 'prefix': 'below', 'size': 20, 'syntax': 'markdown'}

    let g:xtabline_autodelete_empty_buffers = 0
    let g:xtabline_excludes = []
    let g:xtabline_alt_action = "buffer #"
    let g:xtabline_bookmaks_file  = expand('$HOME/.vim/.XTablineBookmarks')
```
  
  
---

#### Warnings

This is the first version and there may be bugs and imprecisions.

Of special note, is that I called the `doautocmd BufAdd` command in a couple
of occasions, to force the redrawing of the tabline (this is handled by
Airline). I couldn't find another method to force the redraw, this may change
in the future. I don't think that calling it can cause much trouble, though.

  
  
---

#### Credits

Braam Moolenaar for Vim  
*vim-airline* authors  
Junegunn Choi for *fzf.vim*  
Tim Pope for *vim-obsession*  

  
  
---

#### License

MIT


