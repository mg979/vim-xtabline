
fun! xtabline#config#start()
  """Call xtabline configurator."""

  redraw!
  let opt = [
            \['Sort buffers by last open',   "sort_buffers_by_last_open"],
            \['Show current tab',            "show_current_tab"],
            \['Superscript unicode nrs',     "superscript_unicode_nrs"],
            \['Close buffer can close tab',  "close_buffer_can_close_tab"],
            \['Close buffer can quit vim',   "close_buffer_can_quit_vim"],
            \['Unload session ask confirm',  "unload_session_ask_confirm"],
            \['Depth tree size',             "depth_tree_size"],
            \['Current theme',               "theme"],
            \]

  echohl Special    | echo "\nxtabline configuration. Select an option you want to change, or '?' for help.\n\n"
  for i in range(len(opt))
    let st = i.". ".opt[i][0] | let lst = len(st) | let tabs = ''
    for n in range(5-lst/8)
      let tabs .= "\t"
    endfor

    echohl WarningMsg | echo i.". "
    echohl Type       | echon opt[i][0].tabs
    echohl Number     | echon eval("g:xtabline_settings.".opt[i][1])
  endfor
  echohl None

  echo "\nEnter an option to change, <esc> to quit, <cr> to generate configuration > "
  let o = nr2char(getchar())

  if     o == "\<esc>"  | redraw! | return
  elseif o == "\<cr>"   | call xtabline#config#generate() | return
  elseif o == '?'       | call xtabline#config#help() | return
  elseif match(o, "\D") >= 0
    echohl WarningMsg | redraw! | echo "Wrong input." | echohl None | return
  elseif o == 6
    let new = input("\nEnter a new value for depth_tree_size (0 disables it) > ")
    if !empty(new) | let g:xtabline_settings.depth_tree_size = new | endif
  elseif o == 7
    call feedkeys("\<Plug>(XT-Apply-Theme)")
    return
  else
    exe "let g:xtabline_settings.".opt[o][1]." = ".!eval("g:xtabline_settings.".opt[o][1])
  endif
  redraw!
  call xtabline#config#start()
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#config#generate()
  """Copy the current config to registers."""
  echohl WarningMsg | echo "\n\nYour configuration has been copied to the \" and + registers.\n"

  let config = [
        \'"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""',
        \'" xtabline configuration',
        \'',
        \'let g:xtabline_settings = {}',
        \'let g:xtabline_settings.sort_buffers_by_last_open  = '.g:xtabline_settings.sort_buffers_by_last_open,
        \'let g:xtabline_settings.show_current_tab           = '.g:xtabline_settings.show_current_tab,
        \'let g:xtabline_settings.superscript_unicode_nrs    = '.g:xtabline_settings.superscript_unicode_nrs,
        \'let g:xtabline_settings.close_buffer_can_close_tab = '.g:xtabline_settings.close_buffer_can_close_tab,
        \'let g:xtabline_settings.close_buffer_can_quit_vim  = '.g:xtabline_settings.close_buffer_can_quit_vim,
        \'let g:xtabline_settings.unload_session_ask_confirm = '.g:xtabline_settings.unload_session_ask_confirm,
        \'let g:xtabline_settings.depth_tree_size            = '.g:xtabline_settings.depth_tree_size,
        \'let g:xtabline_settings.theme                      = '.g:xtabline_settings.theme,
        \'',
        \'"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""',
        \'',
        \]

  let @" = join(config, "\n")
  let @+ = @"
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! xtabline#config#help()
  """Options help."""

  redraw!
  let _ = "-------------------------------------"
  echohl WarningMsg | echo _._._."\n" | echohl None

  echohl Special | echo "sort_buffers_by_last_open\t\t"   | echohl None | echon "keep the last open buffers first in the bufferline"
  echohl Special | echo "show_current_tab\t\t\t"          | echohl None | echon "in the right corner of the bufferline"
  echohl Special | echo "superscript_unicode_nrs\t\t\t"   | echohl None | echon "when using small unicode numbers, use superscript or subscript"
  echohl Special | echo "close_buffer_can_close_tab\t\t"  | echohl None | echon "close buffer command can close a tab, if only one buffer left"
  echohl Special | echo "close_buffer_can_quit_vim\t\t"   | echohl None | echon "close buffer command can also quit vim"
  echohl Special | echo "unload_session_ask_confirm\t\t"  | echohl None | echon "ask for confirmation before unloading a session"

  echohl Special | echo "depth_tree_size\t\t\t\t"         | echohl None | echon "controls the output of the 'tree' command, when changing filtering depth"
  echohl Special | echo "theme\t\t\t\t\t"                 | echohl None | echon "theme in use\n"

  echohl WarningMsg | echo "\nPress a key to go back\n" | echohl None
  call getchar()
  call xtabline#config#start()
endfun


