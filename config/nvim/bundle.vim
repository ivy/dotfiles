"""""""""""""""""""""""""""""""""""""""""""""""""
" => Settings
"""""""""""""""""""""""""""""""""""""""""""""""""

if $VIMHOME == ''
  let $VIMHOME=fnamemodify(expand('<sfile>:p'), ':h')
endif

" Initialize Vundle
call plug#begin("$VIMHOME/plugged")

"""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugs
"""""""""""""""""""""""""""""""""""""""""""""""""

" Color schemes
Plug 'altercation/vim-colors-solarized'

" General
Plug 'Raimondi/delimitMate'
Plug 'airblade/vim-gitgutter'
Plug 'godlygeek/tabular'
Plug 'jamessan/vim-gnupg'
Plug 'jgdavey/tslime.vim'
Plug 'scrooloose/syntastic'
Plug 'moll/vim-bbye'
Plug 'scrooloose/nerdtree'
Plug 'sjl/gundo.vim'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-projectionist'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Snippets
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'garbas/vim-snipmate'
Plug 'tomtom/tlib_vim'

" Config & Domain-Specific Languages
Plug 'Matt-Deacalion/vim-systemd-syntax'
Plug 'hashivim/vim-terraform'
Plug 'honza/dockerfile.vim'
Plug 'yaml.vim'

" C
Plug 'brookhong/cscope.vim'
Plug 'rhysd/vim-clang-format'
Plug 'vim-scripts/c.vim'

" CSS
Plug 'groenewege/vim-less'
Plug 'hail2u/vim-css3-syntax'

" JavaScript
Plug 'digitaltoad/vim-jade'
Plug 'kchmck/vim-coffee-script'
Plug 'moll/vim-node'
Plug 'mxw/vim-jsx'
Plug 'pangloss/vim-javascript'
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }

" Go
Plug 'benmills/vim-golang-alternate'
Plug 'fatih/vim-go'
Plug 'gevans/vim-ginkgo'
Plug 'nsf/gocode', {'rtp': 'vim/'}
Plug 'yosssi/vim-ace'

" Ruby
Plug 'GutenYe/gem.vim'
Plug 'Keithbsmiley/rspec.vim'
Plug 'slim-template/vim-slim'
Plug 'thoughtbot/vim-rspec'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-cucumber'
Plug 'tpope/vim-haml'
Plug 'tpope/vim-rails'
Plug 'vim-ruby/vim-ruby'

" Miscellaneous
Plug 'LnL7/vim-nix'
Plug 'plasticboy/vim-markdown'
Plug 'rhysd/vim-crystal'
Plug 'rust-lang/rust.vim'

call plug#end()
