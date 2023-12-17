call plug#begin()
" Place for plugins
Plug 'vim-scripts/DrawIt'
Plug 'godlygeek/tabular'
Plug 'preservim/nerdtree'
call plug#end()

" Standard vim setup. It looks pretty everywhere!

" Use 2 spaces insteand of tabs everywhere
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

" Fully disable autoformatting (I really hate it)
set noautoindent
set nosmartindent
set nocindent
set indentexpr=
set formatoptions=
filetype indent off

" Pretty visual effects
set number
set hlsearch
syntax on
highligh Search ctermbg=white ctermfg=black
highligh Visual ctermbg=white ctermfg=black
