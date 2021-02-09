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
let s:choice_file_path = tempname()

if exists('g:lf_command_override')
  let s:lf_command = g:lf_command_override
else
  let s:lf_command = 'lf'
endif

function! OpenLfIn(path, edit_cmd)
  let oldguioptions = &guioptions
  let s:oldlaststatus = &laststatus
  let s:oldshowmode = &showmode
  let s:oldrelativenumber = &relativenumber
  try
    if has('nvim')
      set laststatus=0
      set noshowmode norelativenumber
      let currentPath = expand(a:path)
      let lfCallback = { 'name': 'lf', 'edit_cmd': a:edit_cmd }
      function! lfCallback.on_exit(job_id, code, event)
        silent exe ":buffer #|bdelete! #"
        try
          if filereadable(s:choice_file_path)
            for f in readfile(s:choice_file_path)
              exec self.edit_cmd . f
            endfor
            call delete(s:choice_file_path)
          endif
        endtry
        let &laststatus=s:oldlaststatus
        let &showmode=s:oldshowmode
        let &relativenumber=s:oldrelativenumber
      endfunction
      enew
      call termopen(s:lf_command . ' -selection-path=' . s:choice_file_path . ' "' . currentPath . '"', lfCallback)
      startinsert
    else
      set guioptions+=! " Make it work with MacVim
      let currentPath = expand(a:path) != "" ? expand(a:path) : getcwd()
      silent exec '!' . s:lf_command . ' -selection-path=' . s:choice_file_path . ' "' . currentPath . '"'
      if filereadable(s:choice_file_path)
        for f in readfile(s:choice_file_path)
          exec a:edit_cmd . f
        endfor
        call delete(s:choice_file_path)
      endif
      redraw!
      " reset the filetype to fix the issue that happens
      " when opening lf on VimEnter (with `vim .`)
      filetype detect
    endif
  endtry
  let &guioptions=oldguioptions
endfun

" For backwards-compatibility (deprecated)
if exists('g:lf_open_new_tab') && g:lf_open_new_tab
  let s:default_edit_cmd='tabedit '
else
  let s:default_edit_cmd='edit '
endif

command! LfCurrentFile call OpenLfIn("%", s:default_edit_cmd)
command! LfCurrentDirectory call OpenLfIn("%:p:h", s:default_edit_cmd)
command! LfWorkingDirectory call OpenLfIn(".", s:default_edit_cmd)
command! Lf LfCurrentFile

" To open the selected file in a new tab
command! LfCurrentFileNewTab call OpenLfIn("%", 'tabedit ')
command! LfCurrentFileExistingOrNewTab call OpenLfIn("%", 'tab drop ')
command! LfCurrentDirectoryNewTab call OpenLfIn("%:p:h", 'tabedit ')
command! LfCurrentDirectoryExistingOrNewTab call OpenLfIn("%:p:h", 'tab drop ')
command! LfWorkingDirectoryNewTab call OpenLfIn(".", 'tabedit ')
command! LfWorkingDirectoryExistingOrNewTab call OpenLfIn(".", 'tab drop ')
command! LfNewTab LfCurrentDirectoryNewTab

" For retro-compatibility
function! OpenLf()
  Lf
endfunction

" Open Lf in the directory passed by argument
function! OpenLfOnVimLoadDir(argv_path)
  let path = expand(a:argv_path)

  " Delete empty buffer created by vim
  silent exe "buffer #|bdelete! #"

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

