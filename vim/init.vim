set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim/
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
" Plugin 'Valloric/YouCompleteMe'
Plugin 'fatih/vim-go'
Plugin 'kien/ctrlp.vim'
" Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'Yggdroot/indentLine'
Plugin 'majutsushi/tagbar'
Plugin 'fatih/molokai'
" Plugin 'Lokaltog/powerline-fonts'
Plugin 'SirVer/ultisnips'
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-easytags'
Plugin 'tomtom/tcomment_vim'
Plugin 'ervandew/supertab'
Plugin 'honza/vim-snippets'
" Plugin 'vim-scripts/indentpython.vim'
" Plugin 'nvie/vim-flake8'
Plugin 'bling/vim-airline'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-dispatch'

call vundle#end()

set t_Co=256
set encoding=utf-8
" set columns=80
"remove EOL white spaces.
autocmd BufWritePre * :%s/\s\+$//e
"set color of indent lines
let g:indentLine_color_term = 5
"ignore files in plugin ctrlp and nerdtree
let g:ctrlp_custom_ignore = {
  \ 'file': '\v\.(pyc)$',
  \ }
let NERDTreeIgnore = ['\.pyc$']
"
"hotkeys for nerdtree and tlist
map <C-k><C-b> :NERDTreeToggle<CR>
map <C-k><C-n> :TagbarToggle<CR>


let g:rehash256 = 1
set number
syntax on
set smartindent
set smartcase
set autoindent
set nobackup
set noswapfile
set tabstop=4
colorscheme molokai
set shiftwidth=4
set expandtab
set smarttab
set backspace=indent,eol,start
filetype plugin on
set omnifunc=syntaxcomplete#Complete
set splitright
set number

" markdown config
au BufRead,BufNewFile *.md set filetype=markdown
au BufNewFile,BufRead *.md noremap <silent> <Leader>b :!sh make.sh<CR><CR>

" python indentation config
au BufNewFile,BufRead *.py set tabstop=4 | set softtabstop=4 | set shiftwidth=4 | set expandtab | set autoindent | set fileformat=unix

set hlsearch
set ttyfast " u got a fast terminal
set synmaxcol=200
"set ttyscroll=3
set lazyredraw " to avoid scrolling problems

setlocal nowrap
set ruler

:nnoremap <silent> <Esc> :nohlsearch<Bar>:echo<CR>


"Activate spell checking in .md documents.
autocmd BufRead,BufNewFile *.md setlocal spell

" easytags config
let g:easytags_async = 1

"ultisnips bindings
let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
let g:SuperTabDefaultCompletionType = '<C-n>'

" better key bindings for UltiSnipsExpandTrigger
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"
let python_highlight_all=1

" vim-airline status line stuff
" let g:airline_powerline_fonts = 1
set laststatus=2

set conceallevel=0

"vim-tmux window panning
if $TMUX != ''
    " integrate movement between tmux/vim panes/windows

  fun! TmuxMove(direction)
    " Check if we are currently focusing on a edge window.
    " To achieve that,  move to/from the requested window and
    " see if the window number changed
    let oldw = winnr()
    silent! exe 'wincmd ' . a:direction
    let neww = winnr()
    silent! exe oldw . 'wincmd'
    if oldw == neww
      " The focused window is at an edge, so ask tmux to switch panes
      if a:direction == 'j'
        call system("tmux select-pane -D")
      elseif a:direction == 'k'
        call system("tmux select-pane -U")
      elseif a:direction == 'h'
        call system("tmux select-pane -L")
      elseif a:direction == 'l'
        call system("tmux select-pane -R")
      endif
    else
      exe 'wincmd ' . a:direction
    end
  endfun
endif

nnoremap <M-h>h :silent call TmuxMove('h')<cr>

nnoremap <silent> <m-c-w>j :silent call TmuxMove('j')<cr>
nnoremap <silent> <m-c-w>k :silent call TmuxMove('k')<cr>
nnoremap <silent> <m-c-w>h :silent call TmuxMove('h')<cr>
nnoremap <silent> <m-c-w>l :silent call TmuxMove('l')<cr>
nnoremap <silent> <m-c-w><down> :silent call TmuxMove('j')<cr>
nnoremap <silent> <m-c-w><up> :silent call TmuxMove('k')<cr>
nnoremap <silent> <m-c-w><left> :silent call TmuxMove('h')<cr>
nnoremap <silent> <m-c-w><right> :silent call TmuxMove('l')<cr>

"Add wrapping bindings, sublime-like movements.
noremap <silent> <Leader>w :call ToggleWrap()<CR>
function ToggleWrap()
  if &wrap
    echo "Wrap OFF"
    setlocal nowrap
    set virtualedit=all
    silent! nunmap <buffer> <Up>
    silent! nunmap <buffer> <Down>
    silent! nunmap <buffer> <Home>
    silent! nunmap <buffer> <End>
    silent! iunmap <buffer> <Up>
    silent! iunmap <buffer> <Down>
    silent! iunmap <buffer> <Home>
    silent! iunmap <buffer> <End>
    noremap  <buffer> <silent> k k
    noremap  <buffer> <silent> j j

  else
    echo "Wrap ON"
    setlocal wrap linebreak nolist
    set virtualedit=
    setlocal display+=lastline
    noremap  <buffer> <silent> <Up>   gk
    noremap  <buffer> <silent> <Down> gj
    noremap  <buffer> <silent> <Home> g<Home>
    noremap  <buffer> <silent> <End>  g<End>
    inoremap <buffer> <silent> <Up>   <C-o>gk
    inoremap <buffer> <silent> <Down> <C-o>gj
    inoremap <buffer> <silent> <Home> <C-o>g<Home>
    inoremap <buffer> <silent> <End>  <C-o>g<End>
    noremap  <buffer> <silent> k gk
    noremap  <buffer> <silent> j gj
  endif
endfunction
