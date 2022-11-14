require("colorscheme")
require("options")
require("keymaps")
-- import plugin's
require("plugins.packer-setup")
require("plugins.comment")
require("plugins.nvimtree")
require("plugins.lualine")
require("plugins.telescope")
require("plugins.nvim-cmp")
require("plugins.treesitter")
require("plugins.autopair")
require("plugins.lspconfig")
require("plugins.lspsaga")
require("plugins.mason")
require("plugins.formatter")
require("plugins.gitsigns")
require("plugins.indent")
require("plugins.devicons")
-- source ~/.config/nvim/plugins.vim
-- " Section General {{{

-- " Abbreviations
-- abbr funciton function
-- abbr teh the
-- abbr tempalte template
-- abbr fitler filter

-- set nocompatible            " not compatible with vi
-- set autoread                " detect when a file is changed

-- set history=1000            " change history to 1000
-- set textwidth=120

-- set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp

-- " switch cursor to line when in insert mode, and block when not
-- let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1

-- " }}}

-- syntax on
-- set encoding=utf-8
-- set fileencodings=utf-8,ucs-bom,shift-jis,gb18030,gbk,gb2312,cp936,utf-16,big5,euc-jp,latin1

-- let g:dracula_colorterm = 0
-- colorscheme dracula
-- set number                  " show line numbers

-- set wrap                    " turn on line wrapping
-- set wrapmargin=8            " wrap lines when coming within n characters from side
-- set linebreak               " set soft wrapping
-- set showbreak=…             " show ellipsis at breaking

-- set autoindent              " automatically set indent of new line
-- set smartindent

-- set list lcs=tab:\|\
-- let g:indentLine_char = '|'
-- let g:indentLine_concealcursor = 'inc'
-- let g:indentLine_conceallevel = 2
-- let g:indentLine_setColors = 239
-- let g:hugohelper_spell_check_lang = 'en_us'

-- set list
-- set listchars=tab:→\ ,eol:¬,trail:⋅,extends:❯,precedes:❮
-- set showbreak=↪
-- " highlight conflicts
-- match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

-- " make backspace behave in a sane manner
-- set backspace=indent,eol,start

-- " Tab control
-- set expandtab				" insert space rather than tab for <Tab>
-- set smarttab                " tab respects 'tabstop', 'shiftwidth', and 'softtabstop'
-- set tabstop=4               " the visible width of tabs
-- set softtabstop=4           " edit as if the tabs are 4 characters wide
-- set shiftwidth=4            " number of spaces to use for indent and unindent
-- set shiftround              " round indent to a multiple of 'shiftwidth'
-- set completeopt+=longest

-- " code folding settings
-- set foldmethod=syntax       " fold based on indent
-- set foldnestmax=10          " deepest fold is 10 levels
-- set nofoldenable            " don't fold by default
-- set foldlevel=1

-- set clipboard=unnamed

-- set ttyfast                 " faster redrawing
-- set diffopt+=vertical
-- set laststatus=2            " show the satus line all the time
-- set so=7                    " set 7 lines to the cursors - when moving vertical
-- set wildmenu                " enhanced command line completion
-- set hidden                  " current buffer can be put into background
-- set showcmd                 " show incomplete commands
-- set noshowmode              " don't show which mode disabled for PowerLine
-- set wildmode=list:longest   " complete files like a shell
-- set scrolloff=3             " lines of text around cursor
-- set shell=$SHELL
-- set cmdheight=1             " command bar height
-- set title                   " set terminal title

-- " Searching
-- set ignorecase              " case insensitive searching
-- set smartcase               " case-sensitive if expresson contains a capital letter
-- set hlsearch                " highlight search results
-- set incsearch               " set incremental search, like modern browsers
-- set nolazyredraw            " don't redraw while executing macros

-- set magic                   " Set magic on, for regex

-- set showmatch               " show matching braces
-- set mat=2                   " how many tenths of a second to blink

-- " error bells
-- set noerrorbells
-- set visualbell
-- set t_vb=
-- set tm=500

-- if has('mouse')
-- 	set mouse=a
-- endif

-- " }}}

-- " Section Mappings {{{

-- " set a map leader for more key combos
-- let mapleader = ','

-- " remap esc
-- inoremap jk <esc>

-- " wipout buffer
-- nmap <silent> <leader>b :bw<cr>

-- " shortcut to save
-- nmap <leader>, :w<cr>

-- " set paste toggle
-- set pastetoggle=<leader>v
-- nmap <leader>rm :%s/\r//g<cr>

-- " edit ~/.config/nvim/init.vim
-- map <leader>ev :e! ~/.config/nvim/init.vim<cr>
-- " edit gitconfig
-- map <leader>eg :e! ~/.gitconfig<cr>

-- " clear highlighted search
-- noremap <space> :set hlsearch! hlsearch?<cr>

-- " activate spell-checking alternatives
-- nmap ;s :set invspell spelllang=en<cr>

-- " markdown to html
-- nmap <leader>md :%!markdown --html4tags <cr>

-- " remove extra whitespace
-- "
-- nmap <leader><space> :%s/\s\+$<cr>

-- nmap <leader>l :set list!<cr>

-- " Textmate style indentation
-- vmap <leader>[ <gv
-- vmap <leader>] >gv
-- nmap <leader>[ <<
-- nmap <leader>] >>

-- " switch between current and last buffer
-- nmap <leader>. <c-^>

-- " enable . command in visual mode
-- vnoremap . :normal .<cr>

-- map <silent> <C-h> :call functions#WinMove('h')<cr>
-- map <silent> <C-j> :call functions#WinMove('j')<cr>
-- map <silent> <C-k> :call functions#WinMove('k')<cr>
-- map <silent> <C-l> :call functions#WinMove('l')<cr>

-- map <leader>wc :wincmd q<cr>

-- " toggle cursor line
-- nnoremap <leader>i :set cursorline!<cr>

-- " scroll the viewport faster
-- nnoremap <C-e> 3<C-e>
-- nnoremap <C-y> 3<C-y>

-- " moving up and down work as you would expect
-- nnoremap <silent> j gj
-- nnoremap <silent> k gk
-- nnoremap <silent> ^ g^
-- nnoremap <silent> $ g$

-- " search for word under the cursor
-- nnoremap <leader>/ "fyiw :/<c-r>f<cr>

-- " inoremap <tab> <c-r>=Smart_TabComplete()<CR>

-- map <leader>r :call RunCustomCommand()<cr>
-- " map <leader>s :call SetCustomCommand()<cr>
-- let g:silent_custom_command = 0

-- " helpers for dealing with other people's code
-- nmap \t :set ts=4 sts=4 sw=4 noet<cr>
-- nmap \s :set ts=4 sts=4 sw=4 et<cr>

-- nmap <leader>w :setf textile<cr> :Goyo<cr>

-- nnoremap <silent> <leader>u :call functions#HtmlUnEscape()<cr>

-- " }}}

-- " Section AutoGroups {{{
-- " file type specific settings
-- augroup configgroup
--     autocmd!

--     " automatically resize panes on resize
--     autocmd VimResized * exe 'normal! \<c-w>='
--     autocmd BufWritePost .vimrc,.vimrc.local,init.vim source %
--     autocmd BufWritePost .vimrc.local source %
--     " save all files on focus lost, ignoring warnings about untitled buffers
--     autocmd FocusLost * silent! wa

--     " make quickfix windows take all the lower section of the screen
--     " when there are multiple windows open
--     autocmd FileType qf wincmd J

--     autocmd BufNewFile,BufRead,BufWrite *.md syntax match Comment /\%^---\_.\{-}---$/

--     autocmd! BufWritePost * Neomake
-- augroup END

-- "________________________Terminal stuff__________________
-- " open new split panes to right and below
-- set splitright
-- set splitbelow
-- " turn terminal to normal mode with escape
-- tnoremap <Esc> <C-\><C-n>
-- " start terminal in insert mode
-- au BufEnter * if &buftype == 'terminal' | :startinsert | endif
-- " open terminal on ctrl+n
-- function! OpenTerminal()
--   split term://zsh
--   resize 10
-- endfunction
-- nnoremap <leader>t :call OpenTerminal()<CR>

-- " }}}

-- " Section Plugins {{{

-- " FZF
-- """""""""""""""""""""""""""""""""""""

-- " Toggle NvimTree
-- nmap <silent> <leader>k :NvimTreeFindFileToggle<cr>
-- " expand to the path of the file in the current buffer
-- " let NERDTreeShowHidden=1
-- " let NERDTreeDirArrowExpandable = '▷'
-- " let NERDTreeDirArrowCollapsible = '▼'

-- let g:fzf_layout = { 'down': '~25%' }

-- if isdirectory(".git")
--     " if in a git project, use :GFiles
--     nmap <silent> <leader>f :GFiles<cr>
-- " else
--     " otherwise, use :FZFMru
--     nmap <silent> <leader>g :FZFMru<cr>
-- endif
-- nmap <silent><leader>vc :Commits<cr>
-- nmap <silent> <leader>r :Buffers<cr>
-- nmap <silent> <leader>e :FZF<cr>
-- nmap <leader><tab> <plug>(fzf-maps-n)
-- xmap <leader><tab> <plug>(fzf-maps-x)
-- omap <leader><tab> <plug>(fzf-maps-o)

-- " Insert mode completion
-- imap <c-x><c-k> <plug>(fzf-complete-word)
-- imap <c-x><c-f> <plug>(fzf-complete-path)

-- imap <c-x><c-l> <plug>(fzf-complete-line)

-- nnoremap <silent> <Leader>C :call fzf#run({
-- \   'source':
-- \     map(split(globpath(&rtp, "colors/*.vim"), "\n"),
-- \         "substitute(fnamemodify(v:val, ':t'), '\\..\\{-}$', '', '')"),
-- \   'sink':    'colo',
-- \   'options': '+m',
-- \   'left':    30
-- \ })<CR>

-- command! FZFMru call fzf#run({
-- \  'source':  v:oldfiles,
-- \  'sink':    'e',
-- \  'options': '-m -x +s',
-- \  'down':    '40%'})

-- " Fugitive Shortcuts
-- """""""""""""""""""""""""""""""""""""
-- nmap <silent> <leader>gs :Git<cr>
-- nmap <leader>ge :Gedit<cr>
-- nmap <silent><leader>gr :Gread<cr>
-- nmap <silent><leader>gb :Gblame<cr>

-- nmap <leader>m :MarkdownPreview<cr>
-- nmap <leader>mq :MarkedQuit<cr>
-- nmap <leader>* *<c-o>:%s///gn<cr>

-- let g:neomake_javascript_jshint_maker = {
--     \ 'args': ['--verbose'],
--     \ 'errorformat': '%A%f: line %l\, col %v\, %m \(%t%*\d\)',
-- \ }

-- let g:neomake_typescript_tsc_maker = {
--     \ 'args': ['-m', 'commonjs', '--noEmit' ],
--     \ 'append_file': 0,
--     \ 'errorformat':
--         \ '%E%f %#(%l\,%c): error %m,' .
--         \ '%E%f %#(%l\,%c): %m,' .
--         \ '%Eerror %m,' .
--         \ '%C%\s%\+%m'
-- \ }

-- """""""""""""" Markdown Preview"

-- " Mardown Config
-- " set to 1, nvim will open the preview window after entering the markdown buffer
-- " default: 0
-- let g:mkdp_auto_start = 0

-- " set to 1, the nvim will auto close current preview window when change
-- " from markdown buffer to another buffer
-- " default: 1
-- let g:mkdp_auto_close = 1

-- " set to 1, the vim will refresh markdown when save the buffer or
-- " leave from insert mode, default 0 is auto refresh markdown as you edit or
-- " move the cursor
-- " default: 0
-- let g:mkdp_refresh_slow = 0

-- " set to 1, the MarkdownPreview command can be use for all files,
-- " by default it can be use in markdown file
-- " default: 0
-- let g:mkdp_command_for_global = 0

-- " set to 1, preview server available to others in your network
-- " by default, the server listens on localhost (127.0.0.1)
-- " default: 0
-- let g:mkdp_open_to_the_world = 0

-- " use custom IP to open preview page
-- " useful when you work in remote vim and preview on local browser
-- " more detail see: https://github.com/iamcco/markdown-preview.nvim/pull/9
-- " default empty
-- let g:mkdp_open_ip = ''

-- " specify browser to open preview page
-- " for path with space
-- " valid: `/path/with\ space/xxx`
-- " invalid: `/path/with\\ space/xxx`
-- " default: ''
-- let g:mkdp_browser = ''

-- " set to 1, echo preview page url in command line when open preview page
-- " default is 0
-- let g:mkdp_echo_preview_url = 0

-- " a custom vim function name to open preview page
-- " this function will receive url as param
-- " default is empty
-- let g:mkdp_browserfunc = ''

-- " options for markdown render
-- " mkit: markdown-it options for render
-- " katex: katex options for math
-- " uml: markdown-it-plantuml options
-- " maid: mermaid options
-- " disable_sync_scroll: if disable sync scroll, default 0
-- " sync_scroll_type: 'middle', 'top' or 'relative', default value is 'middle'
-- "   middle: mean the cursor position alway show at the middle of the preview page
-- "   top: mean the vim top viewport alway show at the top of the preview page
-- "   relative: mean the cursor position alway show at the relative positon of the preview page
-- " hide_yaml_meta: if hide yaml metadata, default is 1
-- " sequence_diagrams: js-sequence-diagrams options
-- " content_editable: if enable content editable for preview page, default: v:false
-- " disable_filename: if disable filename header for preview page, default: 0
-- let g:mkdp_preview_options = {
--     \ 'mkit': {},
--     \ 'katex': {},
--     \ 'uml': {},
--     \ 'maid': {},
--     \ 'disable_sync_scroll': 0,
--     \ 'sync_scroll_type': 'middle',
--     \ 'hide_yaml_meta': 1,
--     \ 'sequence_diagrams': {},
--     \ 'flowchart_diagrams': {},
--     \ 'content_editable': v:false,
--     \ 'disable_filename': 0,
--     \ 'toc': {}
--     \ }

-- " use a custom markdown style must be absolute path
-- " like '/Users/username/markdown.css' or expand('~/markdown.css')
-- let g:mkdp_markdown_css = ''

-- " use a custom highlight style must absolute path
-- " like '/Users/username/highlight.css' or expand('~/highlight.css')
-- let g:mkdp_highlight_css = ''

-- " use a custom port to start server or empty for random
-- let g:mkdp_port = ''

-- " preview page title
-- " ${name} will be replace with the file name
-- let g:mkdp_page_title = '「${name}」'

-- " recognized filetypes
-- " these filetypes will have MarkdownPreview... commands
-- let g:mkdp_filetypes = ['markdown']
