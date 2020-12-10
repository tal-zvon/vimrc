" ####################
" ##### Vim-Plug #####
" ####################

" Install vim-plug for vim if not found
if !has('nvim')
    if empty(glob('~/.vim/autoload/plug.vim'))
      silent execute "!echo Downloading and installing Vim-Plug..."
      silent !curl -sfLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
      silent execute '!echo -e "    Vim-Plug installed\n"'
      silent execute "!sleep 3"
    endif
endif

" Install vim-plug for vim if not found
if has('nvim')
    if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
      silent execute "!echo Downloading and installing Vim-Plug..."
      silent !curl -sfLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
      silent execute '!echo -e "    Vim-Plug installed\n"'
      silent execute "!sleep 3"
    endif
endif

" Define plugins
call plug#begin('~/.vim/plugged')

    " Highlight tabs, and trailing whitespace
    Plug 'jpalardy/spacehi.vim'

    " Nice color scheme
    Plug 'morhetz/gruvbox'

    " NERDTree - a filesystem explorer
    " nerdtree-git-plugin is a NERDTree plugin that adds git markings
    " to NERDTree
    Plug 'preservim/nerdtree' |
        \ Plug 'Xuyuanp/nerdtree-git-plugin'

    " Git integration
    Plug 'airblade/vim-gitgutter'

    " Tagbar
    Plug 'preservim/tagbar'

    " Powerline
    Plug 'vim-airline/vim-airline'

call plug#end()

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

" #####################
" ##### My config #####
" #####################

" Disable auto-indent enabled by vim-plug
" Note: I'll try getting used to it
filetype indent off

" Disable incremental search
" Note: I'll try getting used to it
"set noincsearch

" Enable syntax highlighting
" Technically vim-plug already does this automatically
syntax on

" Enable line numbers
set number

" Enable relative line numbers
set relativenumber

" show existing tab with 4 spaces width
set tabstop=4

" When you hit tab to add 4 spaces, with this, backspace will delete 4 spaces
set softtabstop=4

" when indenting with '>', use 4 spaces width
set shiftwidth=4

" On pressing tab, insert 4 spaces
set expandtab

" Set different settings (tab is 2 spaces) for html, css and js files
autocmd FileType html setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType css setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType javascript setlocal tabstop=2 shiftwidth=2 softtabstop=2

" Always show the status bar
set laststatus=2

" Indent/Unindent with tab/shift-tab
nmap <Tab> >>
nmap <S-tab> <<
imap <S-Tab> <Esc><<i
vmap <Tab> >gv
vmap <S-Tab> <gv

" Disable auto-comment insertion on newline
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" This disables my accidental hitting of q:
" instead of :q from opening command line history
" (http://vim.wikia.com/wiki/Using_command-line_history)
nnoremap q: <NOP>

" Length of idle time before vim writes to the swapfile
" Also controls how often vim updates git tags in gitgutter bar
set updatetime=100

" Code folding
set foldmethod=indent
set foldlevel=99

" Restore place in file from previous session
autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Allow modified buffers to be in the background without warning
set hidden

" Add shortcuts for changing buffers
nnoremap <C-N> :bnext<CR>
nnoremap <C-P> :bprev<CR>

" When vsplit is used, open the new window on the right - instead
" of the default (on the left)
set splitright

" #################
" # Mouse Support #
" #################

" Easy enable/disable mouse support

"set mouse=a
let g:is_mouse_enabled = 0

noremap <silent> <Leader>m :call ToggleMouse()<CR>
function ToggleMouse()
    if g:is_mouse_enabled == 1
        echo "Mouse OFF"
        set mouse=
        let g:is_mouse_enabled = 0
    else
        echo "Mouse ON"
        set mouse=a
        let g:is_mouse_enabled = 1
    endif
endfunction

" #################################
" # Whitespace Highlighter Plugin #
" #################################

" Enable whitespace highlighting plugin on all windows
autocmd VimEnter * :silent windo ToggleSpaceHi

" Add mapping for \w
map <silent> <Leader>w :silent windo ToggleSpaceHi<CR>

" ############
" # NERDTree #
" ############

" \n will open/close NERDTree
nnoremap <Leader>n :NERDTreeToggle<Enter>

" Fix NerdTree ^G characters on MacOS
let g:NERDTreeNodeDelimiter = "\u00a0"

" Have vim close if nerdtree is open, but you close the last file you're editing
" Without this, if you close the file, NerdTree will still be open on its own
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Ignore pyc files, and __pycache__ dirs
let NERDTreeIgnore = ['\.pyc$', '__pycache__']

" ###########
" # NumLock #
" ###########

" Fix numpad keys over Putty
inoremap <Esc>Oq 1
inoremap <Esc>Or 2
inoremap <Esc>Os 3
inoremap <Esc>Ot 4
inoremap <Esc>Ou 5
inoremap <Esc>Ov 6
inoremap <Esc>Ow 7
inoremap <Esc>Ox 8
inoremap <Esc>Oy 9
inoremap <Esc>Op 0
inoremap <Esc>On .
inoremap <Esc>OQ /
inoremap <Esc>OR *
inoremap <Esc>Ol +
inoremap <Esc>OS -
inoremap <Esc>OM <Enter>

" Stop Numlock from brining up the help menu in Putty
inoremap OP <NOP>
nnoremap OP <NOP>

" Keys to remap gnome terminal numpad keys when numlock is off
" Works, but also remaps regular buttons, like arrow keys
"inoremap OF 1
"inoremap OB 2
"inoremap [6~ 3
"inoremap OD 4
"inoremap OE 5
"inoremap OC 6
"inoremap OH 7
"inoremap OA 8
"inoremap [5~ 9
"inoremap [2~ 0
"inoremap [3~ .
"inoremap Oo /
"inoremap Oj *
"inoremap Ok +
"inoremap Om -
"inoremap OM <Enter>

" ###########
" # Gruvbox #
" ###########

" Set color scheme
silent! colorscheme gruvbox
set bg=dark

" ##########
" # Tagbar #
" ##########

map <leader>t :TagbarToggle<CR>
autocmd FileType python :TagbarToggle

" If opening a python file, the tagbar will be the focus
" This changes the focus on start. There may be a better way to do this
autocmd FileType python call timer_start(100, { -> execute( "wincmd h") })

" ########################################
" # Disable Autoindent When Pasting Text #
" ########################################

" Source: https://coderwall.com/p/if9mda/automatically-set-paste-mode-in-vim-when-pasting-in-insert-mode

let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

function! XTermPasteBegin()
    set pastetoggle=<Esc>[201~
    set paste
    return ""
endfunction

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

" #############
" # Powerline #
" #############

" Show buffers at the top
let g:airline#extensions#tabline#enabled = 1

" #############
" # Copy Mode #
" #############

" Ctrl-C to enter/exit copy mode
" Useful if you want to copy something to clipboard
" This closes everything that might get in your way
" Note: Copy mode is just something I came up with - not a real thing

let g:CopyMode = 0
let g:NERDTreeWasOpen = 0
let g:TagbarWasOpen = 0
let g:MouseWasEnabled = 0

" Function that figures out if Tagbar is open
" Returns 1 if it's open, or 0 if it's closed
function TagbarIsOpen()
    let windows = []
    windo call add(windows, bufname('%'))

    for item in windows
        if stridx(item, "Tagbar") != -1
            return 1
        endif
    endfor

    return 0
endfunction

function ToggleCopyMode()
    if !g:CopyMode
        let g:CopyMode = 1
        echo "Copy Mode Enabled"

        :windo if &filetype != 'nerdtree' && &filetype != 'tagbar' | set nonumber | endif
        :windo if &filetype != 'nerdtree' && &filetype != 'tagbar' | set norelativenumber | endif
        :windo if &filetype != 'nerdtree' && &filetype != 'tagbar' | :GitGutterDisable | endif

        if exists("g:NERDTree") && g:NERDTree.IsOpen()
            let g:NERDTreeWasOpen = 1
            :NERDTreeClose
        else
            let g:NERDTreeWasOpen = 0
        endif

        if TagbarIsOpen()
            let g:TagbarWasOpen = 1
            :TagbarClose
        else
            let g:TagbarWasOpen = 0
        endif

        if g:is_mouse_enabled
            " Write down that it was enabled
            let g:MouseWasEnabled = 1

            " Disable mouse
            set mouse=
            let g:is_mouse_enabled = 0
        else
            let g:MouseWasEnabled = 0
        endif
    else
        let g:CopyMode = 0
        echo "Copy Mode Disabled"

        :windo if &filetype != 'nerdtree' && &filetype != 'tagbar' | set number | endif
        :windo if &filetype != 'nerdtree' && &filetype != 'tagbar' | set relativenumber | endif
        :windo if &filetype != 'nerdtree' && &filetype != 'tagbar' | :GitGutterEnable | endif

        if g:NERDTreeWasOpen
            :NERDTree
        endif

        if g:TagbarWasOpen
            :TagbarOpen
        endif

        if g:MouseWasEnabled
            set mouse=a
            let g:is_mouse_enabled = 1
        endif
    endif
endfunction

" Create a command that calls the function
" Without this, you'd need to run ":call ToggleCopyMode" in vim
command! ToggleCopyMode call ToggleCopyMode()

" If you click Ctrl+L, run :ToggleLineNumbers
nnoremap <C-C> :ToggleCopyMode<CR>

" ###############################################
" # Ignore Cached Entries in Adobe Animate File #
" ###############################################

" Ctrl-A in vimdiff to use

" I could, but didn't want to make this happen transparently, because
" a diff should always tell me the actual difference, and not ignore
" anything, unless I specifically ask it to. If a vimdiff showed no
" differences between two files that had differences, it would be
" super difficult to figure out that something was being ignored that I
" wasn't expecting

" Ignore CachedBmp lines in Adobe files
let g:diffignore='"CachedBmp.*"'

" Define expression that will be used to generate diff, rather than
" the default 'diff' binary
function MyDiff()
   let opt = ""
   if exists("g:diffignore") && g:diffignore != ""
     let opt = "-I " . g:diffignore . " "
   endif
   if &diffopt =~ "icase"
     let opt = opt . "-i "
   endif
   if &diffopt =~ "iwhite"
     let opt = opt . "-b "
   endif
   silent execute "!diff -a --binary " . opt . v:fname_in . " " . v:fname_new .
    \  " > " . v:fname_out
   redraw!
endfunction

" Define function that will enable the above expression
function AA()
    set diffexpr=MyDiff()
    diffupdate
endfunction

" Create a command that calls the function
" Without this, you'd need to run ":call AA()" in vim
command! AA call AA()

" If you hit \a, run :AA
map <leader>a :AA<CR>
