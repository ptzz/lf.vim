" Copyright (c) 2015 François Cabrol
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


" ================ Lf =======================
if exists('g:lf_command_override')
  let s:lf_command = g:lf_command_override
else
  let s:lf_command = 'lf'
endif

function! OpenLfIn(path, edit_cmd)
  let currentPath = expand(a:path)
  let s:edit_cmd = a:edit_cmd
  if exists(":FloatermNew")
    exec 'FloatermNew ' . s:lf_command . ' ' . currentPath
  else
    echoerr "Failed to open a floating terminal. Make sure `voldikss/vim-floaterm` is installed."
  endif
endfun

function! LfCallback(lf_tmpfile, ...) abort
  if filereadable(a:lf_tmpfile)
    let filenames = readfile(a:lf_tmpfile)

    if !empty(filenames)
      if has('nvim')
        call floaterm#window#hide_floaterm(bufnr('%'))
      endif

      if get(s:, 'edit_cmd', 'default') != 'default'
        if s:edit_cmd == 'edit'
          if exists(':Bclose')
            silent! Bclose!
          else
            echoerr "Failed to close buffer. make sure `rbgrouleff/bclose.vim` plugin is installed!"
          endif
        endif

        for filename in filenames
          execute s:edit_cmd . ' ' . fnameescape(filename)
        endfor

        unlet s:edit_cmd
      else
        for filename in filenames
          execute g:floaterm_open_command . ' ' . fnameescape(filename)
        endfor
      endif
    endif
  endif
endfunction

" For backwards-compatibility (deprecated)
if exists('g:lf_open_new_tab') && g:lf_open_new_tab
  let s:default_edit_cmd='tabedit'
else
  let s:default_edit_cmd='edit'
endif

command! LfCurrentFile call OpenLfIn("%", s:default_edit_cmd)
command! LfCurrentDirectory call OpenLfIn("%:p:h", s:default_edit_cmd)
command! LfWorkingDirectory call OpenLfIn(".", s:default_edit_cmd)
command! Lf LfCurrentFile

" To open the selected file in a new tab
command! LfCurrentFileNewTab call OpenLfIn("%", 'tabedit')
command! LfCurrentFileExistingOrNewTab call OpenLfIn("%", 'tab drop')
command! LfCurrentDirectoryNewTab call OpenLfIn("%:p:h", 'tabedit')
command! LfCurrentDirectoryExistingOrNewTab call OpenLfIn("%:p:h", 'tab drop')
command! LfWorkingDirectoryNewTab call OpenLfIn(".", 'tabedit')
command! LfWorkingDirectoryExistingOrNewTab call OpenLfIn(".", 'tab drop')
command! LfNewTab LfCurrentDirectoryNewTab

" For retro-compatibility
function! OpenLf()
  Lf
endfunction

" Open Lf in the directory passed by argument
function! OpenLfOnVimLoadDir(argv_path)
  let path = expand(a:argv_path)

  " Delete empty buffer created by vim
  if exists(":Bclose")
    silent! Bclose!
  else
    echoerr "Failed to close buffer. Make sure `rbgrouleff/bclose.vim` plugin is installed."
  endif

  " Open Lf
  call OpenLfIn(path, s:default_edit_cmd)
endfunction

" To open lf when vim load a directory
if exists('g:lf_replace_netrw') && g:lf_replace_netrw
  augroup ReplaceNetrwByLfVim
    autocmd VimEnter * silent! autocmd! FileExplorer
    autocmd BufEnter * if isdirectory(expand("%")) | call OpenLfOnVimLoadDir("%") | endif
  augroup END
endif

if !exists('g:lf_map_keys') || g:lf_map_keys
  map <leader>f :Lf<CR>
endif
