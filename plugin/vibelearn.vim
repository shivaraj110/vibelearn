if exists('g:loaded_vibelearn')
  finish
endif
let g:loaded_vibelearn = 1

" Commands are registered in lua/vibelearn/init.lua setup()
" This file ensures the plugin is loaded lazily