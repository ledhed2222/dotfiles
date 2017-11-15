let s:editor_root=expand($XDG_CONFIG_HOME . '/nvim')
""""""""""""""""""""""""""""""
" Vundle config
""""""""""""""""""""""""""""""
" automatically install vundle and plugins if not present
let s:vundle_installed=1
let s:vundle_readme=s:editor_root . '/bundle/Vundle.vim/README.md'
if !filereadable(s:vundle_readme)
  let s:vundle_installed=0
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
Plugin 'fatih/vim-go' 				" Go development plugin
Plugin 'sbl/scvim'				" SuperCollider development plugin
Plugin 'Shougo/denite.nvim'			" Various UI tools
Plugin 'JamshedVesuna/vim-markdown-preview'	" Preview .md files
Plugin 'scrooloose/nerdtree'			" File system explorer
Plugin 'flazz/vim-colorschemes'			" A package of many color schemes
Plugin 'pangloss/vim-javascript'		" JavaScript development plugin
Plugin 'mxw/vim-jsx'				" JSX development plugin
Plugin 'cakebaker/scss-syntax.vim'		" SCSS development plugin
Plugin 'tomtom/tcomment_vim'			" File-type sensitive comments
Plugin 'neomake/neomake'			" Asynch makeprg
Plugin 'tpope/vim-fireplace'			" Clojure helpers
Plugin 'guns/vim-clojure-static'		" Basic syntax highlighting for Clojure
Plugin 'guns/vim-clojure-highlight'		" Extended syntax highlighting for Clojure
Plugin 'tpope/vim-fugitive'			" Git wrapper
Plugin 'airblade/vim-gitgutter'			" Git line annotations in gutter
" End plugins

call vundle#end()
filetype plugin indent on

if s:vundle_installed == 0
  echo "Installing plugins...\n"
  :PluginInstall
  let s:vundle_installed=1
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
" no swaps
set noswapfile
" default yanks go to clipboard
set clipboard=unnamed
" decrease time to detect macro-y things 
set timeoutlen=200
" text formatting
set textwidth=78
set nospell
set spelllang=en_us
" space tabs
set expandtab
set shiftwidth=2
set tabstop=2
" use ag for keyword lookup
if executable('ag')
  set keywordprg=ag
else
  set keywordprg=grep
endif
" Leader is <space>
let mapleader="\<space>"

" remap split switching
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" to switch between current file and last file in buffer
nnoremap <leader>, <c-^>

noremap ; :

" easily re-indent
vnoremap > >gv
vnoremap < <gv

" use <esc> to leave terminal mode
tnoremap <esc> <c-\><c-n>

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
" Autocommands
""""""""""""""""""""""""""""""
" Some nice plaintext formatting options
autocmd FileType text,gitcommit setlocal autoindent formatoptions=a2tw spell

" Spelling on for md
autocmd FileType markdown setlocal spell

" Spell in help is really annoying
autocmd FileType help setlocal nospell
""""""""""""""""""""""""""""""
" End autocommands
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" denite configuration
""""""""""""""""""""""""""""""
if executable('ag')
  call denite#custom#var('file_rec', 'command', ['ag', '--follow', '--nocolor', '--nogroup', '--hidden', '-g', ''])
  call denite#custom#var('grep', 'command', ['ag'])
  call denite#custom#var('grep', 'default_opts', ['-s', '--vimgrep', '--hidden'])
  call denite#custom#var('grep', 'recursive_opts', [])
  call denite#custom#var('grep', 'final_opts', [])
  call denite#custom#var('grep', 'pattern_opt', [])
  call denite#custom#var('grep', 'separator', ['--'])
endif
" search a file in the filetree
nnoremap <leader><space> :<c-u>Denite -auto-preview file_rec<cr>
" browse colorschemes
nnoremap <leader>colors :<c-u>Denite -auto-preview -mode=normal colorscheme<cr>
" grep for files
nnoremap <leader>/ :<c-u>Denite -auto-preview -mode=normal grep<cr>
" grep for word under cursor
nnoremap <leader>w :<c-u>DeniteCursorWord --auto-preview -mode=normal grep<cr>
" mappings w/in denite buffers
call denite#custom#map('insert', '<esc>', '<denite:enter_mode:normal>')
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

""""""""""""""""""""""""""""""
" vim-javascript configuration
""""""""""""""""""""""""""""""
let g:javascript_plugin_flow=1
""""""""""""""""""""""""""""""
" End vim-javascript configuration
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" vim-jsx configuration
""""""""""""""""""""""""""""""
let g:jsx_ext_required=0
""""""""""""""""""""""""""""""
" End vim-jsx configuration
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" neomake configuration
""""""""""""""""""""""""""""""
let g:neomake_place_signs=1
let g:neomake_echo_current_error=1
let g:neomake_highlight_columns=1

" javascript setup - only adding flow if detected and executable found
function! StrTrim(txt)
	return substitute(a:txt, '^\n*\s*\(.\{-}\)\n*\s*$', '\1', '')
endfunction
let g:neomake_javascript_enabled_makers=['eslint']
let g:flow_path = StrTrim(system('PATH=$(npm bin):$PATH && which flow'))
if findfile('.flowconfig', '.;') !=# ''
  let g:flow_path = StrTrim(system('PATH=$(npm bin):$PATH && which flow'))

  " need to have `flow-vim-quickfix`
  if g:flow_path != 'flow not found' && executable('flow-vim-quickfix')
    let g:neomake_javascript_flow_maker = {
      \ 'exe': 'sh',
      \ 'args': ['-c', g:flow_path.' --json 2> /dev/null | flow-vim-quickfix'],
      \ 'errorformat': '%E%f:%l:%c\,%n: %m',
      \ 'cwd': '%:p:h'
      \ }
    " add flow if available
    let g:neomake_javascript_enabled_makers = g:neomake_javascript_enabled_makers + ['flow']
  endif
endif

let g:neomake_ruby_enabled_makers=['rubocop']

call neomake#configure#automake('w')
""""""""""""""""""""""""""""""
" End neomake configuration
""""""""""""""""""""""""""""""



" Disable unsafe commands after this point, ie in exrc's
set secure

