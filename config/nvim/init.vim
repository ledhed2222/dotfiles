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
Plugin 'sheerun/vim-polyglot'                 " Various language syntax files
Plugin 'sbl/scvim'                            " SuperCollider development plugin
Plugin 'junegunn/fzf.vim'                     " fzf integration
Plugin 'JamshedVesuna/vim-markdown-preview'   " Preview .md files
Plugin 'scrooloose/nerdtree'                  " File system explorer
Plugin 'morhetz/gruvbox'                      " Colorscheme
Plugin 'tomtom/tcomment_vim'                  " File-type sensitive comments
Plugin 'neomake/neomake'                      " Asynch makeprg
Plugin 'tpope/vim-fugitive'                   " Git integration
Plugin 'airblade/vim-gitgutter'               " Git line annotations in gutter
Plugin 'fatih/vim-go'                         " go-lang
Plugin 'majutsushi/tagbar'                    " tag bar/file outline
Plugin 'jjo/vim-cue'                          " cuefile support
Plugin 'christoomey/vim-tmux-navigator'       " vim x tmux integration
" End plugins

call vundle#end()
filetype plugin indent on

if s:vundle_installed == 0
  echo "Installing plugins...\n"
  :PluginInstall
  :GoInstallBinaries
  let s:vundle_installed=1
endif
""""""""""""""""""""""""""""""
" End Vundle config
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" General config
""""""""""""""""""""""""""""""
" set colorscheme
colorscheme gruvbox
set termguicolors "<-- only if terminal supports 24-bit colors
set background=dark
let g:gruvbox_contrast_dark='medium'
" line numbers
set number
" Allow project-specific vimrc files
set exrc
" no backups
set nobackup
" no swaps
set noswapfile
" syntax highlighting performance
set nocursorline
set nocursorcolumn
set norelativenumber
" try to use nvim's clipboard integration
set clipboard+=unnamedplus
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
" reload files changed outside of vim
set autoread
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

" remap error navigation
map <c-n> :cnext<cr>
map <c-m> :cprevious<cr>
nnoremap <leader>a ::cclose<cr>

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

" Spelling on and line lengths off for markdown
autocmd FileType markdown setlocal spell textwidth=0

" Spell in help is really annoying
autocmd FileType help setlocal nospell
""""""""""""""""""""""""""""""
" End autocommands
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
let vim_markdown_preview_browser='Google Chrome'
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
let g:javascript_plugin_jsdoc=1
""""""""""""""""""""""""""""""
" End vim-javascript configuration
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" vim-ruby configuration
""""""""""""""""""""""""""""""
let g:ruby_no_expensive=0
""""""""""""""""""""""""""""""
" End vim-ruby configuration
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" neomake configuration
""""""""""""""""""""""""""""""
let g:neomake_place_signs=1
let g:neomake_echo_current_error=1
let g:neomake_highlight_columns=1

" javascript/typescript setup - only adding eslint or flow if detected and executable found
" TODO - this may not be necessary any longer
function! StrTrim(txt)
	return substitute(a:txt, '^\n*\s*\(.\{-}\)\n*\s*$', '\1', '')
endfunction

let s:js_only_makers = []
let s:js_ts_makers = []

if findfile(glob('.eslintrc*'), '.;') !=# ''
  let s:eslint_path = StrTrim(system('PATH=$(npm bin):$PATH && which eslint'))
  if s:eslint_path != 'eslint not found'
    let s:eslint_maker = {
      \ 'exe': s:eslint_path,
      \ 'args': ['--format=compact'],
      \ 'errorformat': '%E%f: line %l\, col %c\, Error - %m,' .
      \   '%W%f: line %l\, col %c\, Warning - %m,%-G,%-G%*\d problems%#',
      \ 'cwd': '%:p:h',
      \ 'output_stream': 'stdout',
      \ }
    let g:neomake_javascript_eslint_maker = s:eslint_maker
    let g:neomake_typescript_eslint_maker = s:eslint_maker
    let s:js_ts_makers = s:js_ts_makers + ['eslint']
  endif
endif

if findfile('.flowconfig', '.;') !=# ''
  let s:flow_path = StrTrim(system('PATH=$(npm bin):$PATH && which flow'))

  " need to have `flow-vim-quickfix`
  if s:flow_path != 'flow not found' && executable('flow-vim-quickfix')
    let g:neomake_javascript_flow_maker = {
      \ 'exe': 'sh',
      \ 'args': ['-c', s:flow_path.' --json 2> /dev/null | flow-vim-quickfix'],
      \ 'errorformat': '%E%f:%l:%c\,%n: %m',
      \ 'cwd': '%:p:h',
      \ }
    " add flow if available
    let s:js_only_makers = s:js_only_makers + ['flow']
  endif
endif

let g:neomake_javascript_enabled_makers = s:js_only_makers + s:js_ts_makers
let g:neomake_typescript_enabled_makers = s:js_ts_makers

" We need to mark JS operators as Special for syntax highlighting to work
" correctly based on our syntax group
hi! link jsOperatorKeyword Special
hi! link jsOf Special
hi! link jsSpreadOperator Special
hi! link jsRestOperator Special
" end javascript setup

call neomake#configure#automake('rw')
""""""""""""""""""""""""""""""
" End neomake configuration
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" fzf configuration
""""""""""""""""""""""""""""""
if executable('fzf')
  " set this for both the Homebrew install and the $HOME install
  set rtp+=$FZF_HOME
  set rtp+=~/.fzf
  " search a file in the filetree
  command! -bang -nargs=* Files call fzf#run(fzf#wrap({'source': 'ag --hidden -f -g ""'}))
  nnoremap <leader><space> :Files<cr>
  " grep w/in files
  command! -bang -nargs=* Ag call fzf#vim#ag(<q-args>, '--hidden', <bang>0)
  nnoremap <leader>/ :Ag<space>
  " browse colorschemes
  nnoremap <leader>colors :Colors<cr>
endif
""""""""""""""""""""""""""""""
" end fzf configuration
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" tagbar configuration
""""""""""""""""""""""""""""""
nmap <leader>o :TagbarToggle<cr>
let g:tagbar_position = 'rightbelow vertical'
""""""""""""""""""""""""""""""
" end tagbar configuration
""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" vim-go/go configuration
""""""""""""""""""""""""""""""
autocmd FileType go setlocal autowrite
autocmd FileType go setlocal tabstop=4
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_metalinter_autosave = 0
let g:go_def_mode = "gopls"
let g:syntastic_go_checkers = ['gometalinter']
let g:go_fmt_options = {
  \ 'gofmt': '-s',
  \ 'goimports': '-local github.com/anchorlabsinc/anchorage',
  \ }
let g:go_fmt_command = "goimports"
let g:go_fmt_autosave = 1
let g:go_debug_address = '127.0.0.1:8999'

au FileType go nmap <Leader>m <Plug>(go-implements)
au FileType go nmap <Leader>i <Plug>(go-info)
au FileType go nmap <Leader>e <Plug>(go-rename)
au FileType go nmap <Leader>pc :GoCallers<cr>
""""""""""""""""""""""""""""""
" end vim-go/go configuration
""""""""""""""""""""""""""""""

" Disable unsafe commands after this point, ie in exrc's
set secure

" source external override rc
if filereadable("~/.config/nvim/local_overrides.vim")
  source ~/.config/nvim/local_overrides.vim
endif
