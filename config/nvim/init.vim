let s:editor_root=expand($XDG_CONFIG_HOME . '/nvim')
""""""""""""""""""""""""""""""
" Vundle config
""""""""""""""""""""""""""""""
" automatically install vundle and plugins if not present
let vundle_installed=1
let vundle_readme=s:editor_root . '/bundle/Vundle.vim/README.md'
if !filereadable(vundle_readme)
	let vundle_installed=0
	echo "Installing Vundle...\n"
	silent execute "!mkdir -p " . s:editor_root . "/bundle"
	silent execute "!git clone https://github.com/VundleVim/Vundle.vim.git " . s:editor_root . "/bundle/Vundle.vim"
endif
if !has('python3')
	echo "Installing neovim python3 support...\n"
	silent execute "!pip3 install neovim"
	:UpdateRemotePlugins
endif

filetype off
let &rtp=&rtp . ',' . s:editor_root . '/bundle/Vundle.vim'
call vundle#begin(s:editor_root . '/bundle')
Plugin 'VundleVim/Vundle.vim'

" Add plugins here
Plugin 'vim-ruby/vim-ruby'			" Ruby development plugin
Plugin 'tpope/vim-rails' 			" Rails development plugin
Plugin 'fatih/vim-go' 				" Go development plugin
Plugin 'sbl/scvim'				" SuperCollider development plugin
Plugin 'Shougo/denite.nvim'			" Various UI tools
Plugin 'JamshedVesuna/vim-markdown-preview'	" Preview .md files
Plugin 'scrooloose/nerdtree'			" File system explorer
Plugin 'flazz/vim-colorschemes'			" A package of many color schemes
Plugin 'pangloss/vim-javascript'		" JavaScript development plugin
Plugin 'mxw/vim-jsx'				" JSX development plugin
Plugin 'cakebaker/scss-syntax.vim'		" SCSS development plugin
" End plugins

call vundle#end()
filetype plugin indent on

if vundle_installed == 0
	echo "Installing plugins...\n"
	:PluginInstall
	let vundle_installed=1
endif
""""""""""""""""""""""""""""""
" End Vundle config
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" General config
""""""""""""""""""""""""""""""
" set colorscheme
colorscheme benokai
" line numbers
set number
" Allow project-specific vimrc files
set exrc
" no backups
set nobackup
" default yanks go to clipboard
set clipboard=unnamed
" text formatting
set textwidth=78
set nospell
set spelllang=en_us

" Leader is <space>
let mapleader="\<space>"

" remap split switching
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
	set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
	syntax on
	set hlsearch
endif

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
	command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis 
				\ | wincmd p | diffthis | wincmd p
endif
""""""""""""""""""""""""""""""
" End general config
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" Autocommands (only if compiled with support for them)
""""""""""""""""""""""""""""""
if has('autocmd')
	" Set Ruby, JS, JSON indents to two spaces
	autocmd FileType ruby,javascript,javascript.jsx,json setlocal expandtab shiftwidth=2 tabstop=2

	" Some nice plaintext formatting options
	autocmd FileType text,gitcommit setlocal autoindent formatoptions=a2tw spell

	" Spelling on for md
	autocmd FileType markdown setlocal spell

	" Spell in help is really annoying
	autocmd FileType help setlocal nospell
endif
""""""""""""""""""""""""""""""
" End autocommands
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" denite configuration
""""""""""""""""""""""""""""""
if executable('ag')
	call denite#custom#var('file_rec', 'command', ['ag', '--follow', '--nocolor', '--nogroup', '--hidden', '-g', ''])
	call denite#custom#var('grep', 'command', ['ag'])
	call denite#custom#var('grep', 'default_opts', ['-i', '--vimgrep', '--hidden'])
	call denite#custom#var('grep', 'recursive_opts', [])
	call denite#custom#var('grep', 'final_opts', [])
	call denite#custom#var('grep', 'pattern_opt', [])
endif
" search a file in the filetree
nnoremap <leader><space> :<c-u>Denite -auto-preview file_rec<cr>
" browse colorschemes
nnoremap <leader>colors :<c-u>Denite -mode=normal colorscheme<cr>
" grep for files
nnoremap <leader>/ :<c-u>Denite -auto-preview -mode=normal grep<cr>
""""""""""""""""""""""""""""""
" End denite configuration
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" vim-markdown-preview configuration
""""""""""""""""""""""""""""""
if executable('grip')
	" github rendering mode using grip
	let vim_markdown_preview_github=1
endif
" shortcut for seeing preview
let vim_markdown_preview_hotkey='<leader>pre'
""""""""""""""""""""""""""""""
" End vim-markdown-preview configuration
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" NERDtree configuration
""""""""""""""""""""""""""""""
" toggle NERDtree
nnoremap <leader>t :NERDTreeToggle .<cr>
" by default show hidden files
let NERDTreeShowHidden=1
""""""""""""""""""""""""""""""
" End NERDtree configuration
""""""""""""""""""""""""""""""

" Disable unsafe commands after this point, ie in exrc's
set secure
