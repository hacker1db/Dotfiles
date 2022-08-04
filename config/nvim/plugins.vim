if has("nvim")
  let g:plug_home = stdpath('data') . '/plugged'
endif



call plug#begin('~/.config/nvim/plugged')

" colorschemes
Plug 'dracula/vim', { 'as': 'dracula' }
" utilities
Plug 'Yggdroot/indentLine'
" regular plugins
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim' " fuzzy file finder and so much more
Plug 'mileszs/ack.vim' " search inside files using ack. Same as command line ack utiliey, but use :Ack
Plug 'Raimondi/delimitMate' " automatic closing of quotes, parenthesis, brackets, etc.
Plug 'tpope/vim-commentary' " comment stuff out
Plug 'tpope/vim-unimpaired' " mappings which are simply short normal mode aliases for commonly used ex commands
Plug 'tpope/vim-endwise' " automatically add end in ruby
Plug 'tpope/vim-ragtag' " endings for html, xml, etc. - ehances surround
Plug 'tpope/vim-surround' " mappings to easily delete, change and add such surroundings in pairs, such as quotes, parens, etc.
Plug 'benmills/vimux' " tmux integration for vim
Plug 'neomake/neomake' " neovim replacement for syntastic using neovim's job control functonality
Plug 'vim-syntastic/syntastic' "syntastic returns! 
Plug 'tpope/vim-fugitive' " amazing git wrapper for vim
Plug 'airblade/vim-gitgutter' " git integration
Plug 'tpope/vim-repeat' " enables repeating other supported plugins with the . command
Plug 'editorconfig/editorconfig-vim' " .editorconfig support
Plug 'MarcWeber/vim-addon-mw-utils' " interpret a file by function and cache file automatically
Plug 'tomtom/tlib_vim' " utility functions for vim
Plug 'sotte/presenting.vim', { 'for': 'markdown' } " a simple tool for presenting slides in vim based on text files
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']} "markdown testing
Plug 'tpope/vim-dispatch' " asynchronous build and test dispatcher
Plug 'tpope/vim-vinegar'
Plug 'AndrewRadev/splitjoin.vim' " single/multi line code handler: gS - split one line into multiple, gJ - combine multiple lines into one
Plug 'vim-scripts/matchit.zip' " extended % matching
Plug 'tpope/vim-sleuth' " detect indent style (tabs vs. spaces)
Plug 'sickill/vim-pasta' " context-aware pasting
Plug 'junegunn/goyo.vim', { 'on': 'Goyo' } " distraction-free writing
Plug 'junegunn/limelight.vim', { 'on': 'Limelight' } " focus tool. Good for presentating with vim
Plug 'Xuyuanp/nerdtree-git-plugin' 
Plug 'kyazdani42/nvim-web-devicons' " optional, for file icons
Plug 'kyazdani42/nvim-tree.lua'
Plug 'ryanoasis/vim-devicons' 
Plug 'mklabs/split-term.vim' "better splits in vim.
" Testing in VIM 
Plug 'janko-m/vim-test'
" html / templates
Plug 'mattn/emmet-vim', { 'for': 'html' } " emmet support for vim - easily create markdup wth CSS-like syntax
Plug 'gregsexton/MatchTag', { 'for': 'html' } " match tags in html, similar to paren support
Plug 'othree/html5.vim', { 'for': 'html' } " html5 support
Plug 'mustache/vim-mustache-handlebars' " mustach support
Plug 'digitaltoad/vim-jade', { 'for': ['jade', 'pug'] } " jade support

" JavaScript
Plug 'gavocanov/vim-js-indent', { 'for': 'javascript' } " JavaScript indent support
Plug 'moll/vim-node', { 'for': 'javascript' } " node support
Plug 'othree/yajs.vim', { 'for': 'javascript' } " JavaScript syntax plugin
Plug 'mxw/vim-jsx', { 'for': 'jsx' } " JSX support
Plug 'othree/es.next.syntax.vim', { 'for': 'javascript' } " ES6 and beyond syntax
Plug 'HerringtonDarkholme/yats.vim' " yats for JavaScript

" Reactjs
Plug 'pangloss/vim-javascript'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

" For func argument completion
Plug 'Shougo/neosnippet'
Plug 'Shougo/neosnippet-snippets'
" styles
Plug 'wavded/vim-stylus', { 'for': ['stylus', 'markdown'] } " markdown support
Plug 'groenewege/vim-less', { 'for': 'less' } " less support
Plug 'ap/vim-css-color', { 'for': ['css','stylus','scss'] } " set the background of hex color values to the color
Plug 'hail2u/vim-css3-syntax', { 'for': 'css' } " CSS3 syntax support
Plug 'cakebaker/scss-syntax.vim', { 'for': 'scss' } " sass scss syntax support

" markdown
Plug 'itspriddle/vim-marked', { 'for': 'markdown', 'on': 'MarkedOpen' } " Open markdown files in Marked.app - mapped to <leader>m
Plug 'tpope/vim-markdown', { 'for': 'markdown' } " markdown support

" language-specific plugins
Plug 'elzr/vim-json', { 'for': 'json' } " JSON support
Plug 'Shougo/vimproc.vim', { 'do': 'make' } " interactive command execution in vim
Plug 'fatih/vim-go', { 'for': 'go' } " go support
Plug 'timcharper/textile.vim', { 'for': 'textile' } " textile support
Plug 'tclem/vim-arduino' " arduino support - compile wihtout needing to open the arduino IDE
Plug 'elzr/vim-json', { 'for': 'json' } " JSON support
Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' } " ruby support

" Python
Plug 'jmcomets/vim-pony'
Plug 'Vimjas/vim-python-pep8-indent'
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}

"Powershell
Plug 'PProvost/vim-ps1'
" GO
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'nsf/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }
" emmet
Plug 'mattn/emmet-vim'
" Rainbow braces
Plug 'frazrepo/vim-rainbow'
" C#
Plug 'OmniSharp/omnisharp-vim'
" Terrafrom
Plug 'hashivim/vim-terraform'
"Md Preview
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
Plug 'robertbasic/vim-hugo-helper'
" Vue
Plug 'leafOfTree/vim-vue-plugin'
Plug 'groenewege/vim-less', { 'for': 'less' }
Plug 'editorconfig/editorconfig-vim'

if has('nvim')
    Plug 'neovim/nvim-lspconfig'
    Plug 'glepnir/lspsaga.nvim'
    Plug 'hoob3rt/lualine.nvim'
    Plug 'kristijanhusak/defx-git'
    Plug 'kristijanhusak/defx-icons'
    Plug 'Shougo/defx.nvim', { 'do': ':UpdateRemotePlugins' }
    Plug 'neovim/nvim-lspconfig'
    Plug 'williamboman/nvim-lsp-installer'
    Plug 'tami5/lspsaga.nvim'
    Plug 'folke/lsp-colors.nvim'
    Plug 'L3MON4D3/LuaSnip'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'hrsh7th/cmp-buffer'
    Plug 'hrsh7th/nvim-cmp'
    Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
    Plug 'kyazdani42/nvim-web-devicons'
    Plug 'onsails/lspkind-nvim'
    Plug 'nvim-lua/popup.nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-telescope/telescope.nvim'
    Plug 'windwp/nvim-autopairs'
    Plug 'windwp/nvim-ts-autotag'
    Plug 'kyazdani42/nvim-web-devicons'
    Plug 'nvim-lualine/lualine.nvim'
    Plug 'kyazdani42/nvim-tree.lua'
endif

"Dart/Flutter
Plug 'dart-lang/dart-vim-plugin'
Plug 'akinsho/flutter-tools.nvim'
Plug 'JoosepAlviste/nvim-ts-context-commentstring'
call plug#end()

