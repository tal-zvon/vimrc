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

    " Coc
    Plug 'neoclide/coc.nvim'

    " Coc Rust Analyzer
    Plug 'fannheyward/coc-rust-analyzer'

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
autocmd FileType htmldjango setlocal tabstop=2 shiftwidth=2 softtabstop=2
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

" Set encoding
set encoding=utf8

" Set text width
" For gt and gw, the number of characters to consider a single line
" 75 replicates GNU fmt, and works well. The default is too long in
" my vim, where I have a gutter with line numbers showing
" Note: Setting textwidth also enables automatic newlines as you type.
" fo-=tc disables that. See: https://vi.stackexchange.com/a/28725/32517
set textwidth=75
set fo-=tc

" Change Auto-Complete Mode
" This is when you type ":e WORD" and hit tab
" The default will complete the first possibly guess, instead
" of just before the first ambiguous character like bash does
" This makes it closer to bash
set wildmode=longest:full,list:full

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

" Make \t toggle Tagbar
map <leader>t :TagbarToggle<CR>

" If we're not open in vimdiff, and the filetype is Python,
" open Tagbar automatically
autocmd VimEnter * if !&diff && winnr('$') == 1 && &filetype ==# 'python' | execute 'TagbarToggle' | endif

" Disable sorting
" With this, items appear as they do in the file, instead of sorted by name
let g:tagbar_sort = 0

" ########################################
" # Disable Autoindent When Pasting Text #
" ########################################

" Source: https://coderwall.com/p/if9mda/automatically-set-paste-mode-in-vim-when-pasting-in-insert-mode
" Update: I've had trouble with pasting. This might be the problem, so I commented it out for now

"let &t_SI .= "\<Esc>[?2004h"
"let &t_EI .= "\<Esc>[?2004l"

"function! XTermPasteBegin()
"    set pastetoggle=<Esc>[201~
"    set paste
"    return ""
"endfunction

"inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

" #############
" # Powerline #
" #############

" Show buffers at the top
let g:airline#extensions#tabline#enabled = 1

" ###############################
" # Copy to Clipboard Shortcuts #
" ###############################

" Copy to clipboard
vnoremap  <leader>y  "+y
nnoremap  <leader>Y  "+yg_
nnoremap  <leader>y  "+y

" Paste from clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P

" ################
" # Buffer Close #
" ################

" Delete buffer while keeping window layout (don't close buffer's windows).
" Version 2008-11-18 from http://vim.wikia.com/wiki/VimTip165

if v:version < 700 || exists('loaded_bclose') || &cp
  finish
endif
let loaded_bclose = 1
if !exists('bclose_multiple')
  let bclose_multiple = 1
endif

" Display an error message.
function! s:Warn(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl NONE
endfunction

" Command ':Bclose' executes ':bd' to delete buffer in current window.
" The window will show the alternate buffer (Ctrl-^) if it exists,
" or the previous buffer (:bp), or a blank buffer if no previous.
" Command ':Bclose!' is the same, but executes ':bd!' (discard changes).
" An optional argument can specify which buffer to close (name or number).
function! s:Bclose(bang, buffer)
  if empty(a:buffer)
    let btarget = bufnr('%')
  elseif a:buffer =~ '^\d\+$'
    let btarget = bufnr(str2nr(a:buffer))
  else
    let btarget = bufnr(a:buffer)
  endif
  if btarget < 0
    call s:Warn('No matching buffer for '.a:buffer)
    return
  endif
  if empty(a:bang) && getbufvar(btarget, '&modified')
    call s:Warn('No write since last change for buffer '.btarget.' (use :Bclose!)')
    return
  endif
  " Numbers of windows that view target buffer which we will delete.
  let wnums = filter(range(1, winnr('$')), 'winbufnr(v:val) == btarget')
  if !g:bclose_multiple && len(wnums) > 1
    call s:Warn('Buffer is in multiple windows (use ":let bclose_multiple=1")')
    return
  endif
  let wcurrent = winnr()
  for w in wnums
    execute w.'wincmd w'
    let prevbuf = bufnr('#')
    if prevbuf > 0 && buflisted(prevbuf) && prevbuf != btarget
      buffer #
    else
      bprevious
    endif
    if btarget == bufnr('%')
      " Numbers of listed buffers which are not the target to be deleted.
      let blisted = filter(range(1, bufnr('$')), 'buflisted(v:val) && v:val != btarget')
      " Listed, not target, and not displayed.
      let bhidden = filter(copy(blisted), 'bufwinnr(v:val) < 0')
      " Take the first buffer, if any (could be more intelligent).
      let bjump = (bhidden + blisted + [-1])[0]
      if bjump > 0
        execute 'buffer '.bjump
      else
        execute 'enew'.a:bang
      endif
    endif
  endfor
  execute 'bdelete'.a:bang.' '.btarget
  execute wcurrent.'wincmd w'
endfunction
command! -bang -complete=buffer -nargs=? Bclose call <SID>Bclose(<q-bang>, <q-args>)
nnoremap <silent> <Leader>bd :Bclose<CR>

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
