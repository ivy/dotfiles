" NWScript (KotOR .nss): C's highlighting plus NWScript's own types and
" constants. Engine structure types are KotOR 1's; nwscript.nss defines them.
if exists("b:current_syntax")
  finish
endif

runtime! syntax/c.vim
unlet! b:current_syntax

syn keyword nwscriptType object vector action
syn keyword nwscriptType effect event location talent
syn keyword nwscriptConstant OBJECT_SELF OBJECT_INVALID TRUE FALSE

hi def link nwscriptType Type
hi def link nwscriptConstant Constant

let b:current_syntax = "nwscript"
