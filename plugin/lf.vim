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
  let currentPath = shellescape(expand(a:path))
  let s:edit_cmd = a:edit_cmd
  if exists(":FloatermNew")
    exec 'FloatermNew ' . '--height=' . string(get(g:, 'lf_height', g:floaterm_height)) . ' --width=' . string(get(g:, 'lf_width', g:floaterm_width)) . ' ' . s:lf_command . ' ' . currentPath
  else
    echoerr "Failed to open a floating terminal. Make sure `voldikss/vim-floaterm` is installed."
  endif
endfun

function! LfCallback(lf_tmpfile, lastdir_tmpfile, ...) abort
  let edit_cmd = get(s:, 'edit_cmd', 'default')
  if (edit_cmd == 'cd' || edit_cmd == 'lcd') && filereadable(a:lastdir_tmpfile)
    let lastdir = readfile(a:lastdir_tmpfile, '', 1)[0]
    if lastdir != getcwd()
      exec edit_cmd . ' ' . lastdir
      return
    endif
  elseif filereadable(a:lf_tmpfile)
    let filenames = readfile(a:lf_tmpfile)
    if !empty(filenames)
      if has('nvim')
        call floaterm#window#hide(bufnr('%'))
      endif
      let locations = []
      if edit_cmd != 'default'
        for filename in filenames
          let dict = {'filename': fnamemodify(filename, ':p')}

          call add(locations, dict)
        endfor
        call floaterm#util#open(s:edit_cmd, locations)
        unlet s:edit_cmd
      else
        for filename in filenames
          let dict = {'filename': fnamemodify(filename, ':p')}

          call add(locations, dict)
        endfor
        call floaterm#util#open(g:floaterm_open_command, locations)
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

command! Lfcd call OpenLfIn(".", 'cd')
command! Lflcd call OpenLfIn(".", 'lcd')
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

" To open lf when vim load a directory
if exists('g:lf_replace_netrw') && g:lf_replace_netrw
  augroup ReplaceNetrwByLfVim
    autocmd VimEnter * silent! autocmd! FileExplorer
    autocmd BufEnter * let s:buf_path = expand("%") | if isdirectory(s:buf_path) | bdelete! | call timer_start(100, {->OpenLfIn(s:buf_path, s:default_edit_cmd)}) | endif
  augroup END
endif

if !exists('g:lf_map_keys') || g:lf_map_keys
  map <leader>f :Lf<CR>
endif
