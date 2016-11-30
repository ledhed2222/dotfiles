" Be improved
set nocompatible

""""""""""""""""""""""""""""""
" Vundle config
""""""""""""""""""""""""""""""
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'

" Add plugins here
Plugin 'vim-ruby/vim-ruby'			" Ruby development plugin
Plugin 'tpope/vim-rails' 			" Rails development plugin
Plugin 'fatih/vim-go' 				" Go development plugin
Plugin 'sbl/scvim'				" SuperCollider development plugin
Plugin 'shawncplus/phpcomplete.vim'		" PHP autocompletion
Plugin 'dsawardekar/wordpress.vim'		" Wordpress development plugin
Plugin 'Shougo/vimproc.vim'			" Async command execution
						" NOTE you need to `make` the
						" install directory of this
						" plugin
Plugin 'Shougo/unite.vim'			" Source code search
Plugin 'Shougo/neocomplete.vim'			" Autocompletion
Plugin 'JamshedVesuna/vim-markdown-preview'	" Preview .md files
Plugin 'scrooloose/nerdtree'			" File system explorer
Plugin 'flazz/vim-colorschemes'			" A package of many color schemes
Plugin 'pangloss/vim-javascript'		" JavaScript development plugin
Plugin 'mxw/vim-jsx'				" JSX development plugin
" End plugins

call vundle#end()
filetype plugin indent on
""""""""""""""""""""""""""""""
" End Vundle config
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" General config
""""""""""""""""""""""""""""""
" set colorscheme
colorscheme benokai
" allow backspacing over everything in insert mode
set backspace=indent,eol,start
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
	" Set Ruby indents to two spaces
	autocmd FileType ruby setlocal expandtab shiftwidth=2 tabstop=2

	" Some nice plaintext formatting options
	autocmd FileType text,gitcommit setlocal autoindent spell formatoptions=a2t

	" For some reason, the above autocmd adds spell to help too
	autocmd FileType help setlocal nospell
endif
""""""""""""""""""""""""""""""
" End autocommands
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" unite configuration
""""""""""""""""""""""""""""""
if executable('ag')
	let g:unite_source_rec_async_command=['ag', '--nocolor', '--nogroup', '-g', '']
	let g:unite_source_grep_command='ag'
	let g:unite_source_grep_default_opts='-i --vimgrep --hidden'
	let g:unite_source_grep_recursive_opt=''
endif
call unite#filters#matcher_default#use(['matcher_fuzzy'])
call unite#filters#sorter_default#use(['sorter_rank'])
" search a file in the filetree
nnoremap <leader><space> :<c-u>Unite -start-insert -auto-preview file_rec/async<cr>
" grep for files
nnoremap <leader>/ :<c-u>Unite -auto-preview grep:.<cr>
" grep for files containing word under cursor
nnoremap <leader>f :<c-u>UniteWithCursorWord -auto-preview grep:.<cr> 
" reset unite cache
nnoremap <leader>r <Plug>(unite_redraw)
""""""""""""""""""""""""""""""
" End unite configuration
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

