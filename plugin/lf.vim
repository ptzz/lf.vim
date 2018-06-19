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
if exists('g:lf_choice_file')
  if empty(glob(g:lf_choice_file))
    let s:choice_file_path = g:lf_choice_file
  else
    echom "Message from *Lf.vim* :"
    echom "You've set the g:lf_choice_file variable."
    echom "Please use the path for a file that does not already exist."
    echom "Using /tmp/chosenfile for now..."
  endif
endif

if exists('g:lf_command_override')
  let s:lf_command = g:lf_command_override
else
  let s:lf_command = 'lf'
endif

if !exists('s:choice_file_path')
  let s:choice_file_path = '/tmp/chosenfile'
endif

function! OpenLfIn(path, edit_cmd)
  let oldlaststatus = &laststatus
  try
    if has('nvim')
      let currentPath = expand(a:path)
      let lfCallback = { 'name': 'lf', 'edit_cmd': a:edit_cmd }
      function! lfCallback.on_exit(job_id, code, event)
        if a:code == 0
          silent! Bclose!
        endif
        try
          if filereadable(s:choice_file_path)
            for f in readfile(s:choice_file_path)
              exec self.edit_cmd . f
            endfor
            call delete(s:choice_file_path)
          endif
        endtry
      endfunction
      enew
      if isdirectory(currentPath)
        call termopen(s:lf_command . ' -selection-path=' . s:choice_file_path . ' "' . currentPath . '"', lfCallback)
      else
        call termopen(s:lf_command . ' -selection-path=' . s:choice_file_path . ' --selectfile="' . currentPath . '"', lfCallback)
    endif
      startinsert
    else
      let currentPath = expand(a:path)
      let pbuf = bufnr('')
      let lfCallback = {'edit_cmd': a:edit_cmd, 'buf': bufnr(''), 'pbuf': pbuf, 
            \ 'lines': &lines,
            \ 'columns': &columns}
      func! lfCallback.on_exit(id, code, ...)
        call self.switch_back(1)
        if bufexists(self.buf)
            execute 'bd!' self.buf
        endif
        try
          if filereadable(s:choice_file_path)
            for f in readfile(s:choice_file_path)
              exec self.edit_cmd . f
            endfor
            call delete(s:choice_file_path)
          endif
        endtry
      endfunc

      function! lfCallback.switch_back(inplace)
        if a:inplace && bufnr('') == self.buf
          if bufexists(self.pbuf)
            execute 'keepalt b' self.pbuf
          endif
          " No other listed buffer
          if bufnr('') == self.buf
            enew
          endif
        endif
      endfunction

      " if isdirectory(currentPath)
      let cmd = s:lf_command . ' -selection-path=' . s:choice_file_path . ' "' . currentPath . '"'
      call term_start([&shell, &shellcmdflag, cmd], {'curwin': 1, 'exit_cb': function(lfCallback.on_exit)})
      if !has('patch-8.0.1261') && !has('nvim') && !s:is_win
          call term_wait(fzf.buf, 20)
      endif
      redraw!
      " reset the filetype to fix the issue that happens
      " when opening lf on VimEnter (with `vim .`)
      filetype detect
    endif
  finally
    let &laststatus=oldlaststatus
  endtry
endfun

" For backwards-compatibility (deprecated)
if exists('g:lf_open_new_tab') && g:lf_open_new_tab
  let s:default_edit_cmd='tabedit '
else
  let s:default_edit_cmd='edit '
endif

command! LfCurrentFile call OpenLfIn("%:p:h", s:default_edit_cmd)
command! LfCurrentDirectory call OpenLfIn("%:p:h", s:default_edit_cmd)
command! LfWorkingDirectory call OpenLfIn(".", s:default_edit_cmd)
command! Lf LfCurrentFile

" To open the selected file in a new tab
command! LfCurrentFileNewTab call OpenLfIn("%", 'tabedit ')
command! LfCurrentDirectoryNewTab call OpenLfIn("%:p:h", 'tabedit ')
command! LfWorkingDirectoryNewTab call OpenLfIn(".", 'tabedit ')
command! LfNewTab LfCurrentDirectoryNewTab

" For retro-compatibility
function! OpenLf()
  Lf
endfunction

" Open Lf in the directory passed by argument
function! OpenLfOnVimLoadDir(argv_path)
  let path = expand(a:argv_path)

  " Delete empty buffer created by vim
  Bclose!

  " Open Lf
  call OpenLfIn(path, 'edit')
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

