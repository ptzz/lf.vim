function! floaterm#wrapper#lf#(cmd) abort
  let lf_tmpfile = tempname()
  let lastdir_tmpfile = tempname()
  let original_dir = getcwd()
  lcd %:p:h

  let cmdlist = split(a:cmd)
  let cmd = 'lf -last-dir-path="' . lastdir_tmpfile . '" -selection-path="' . lf_tmpfile . '"'
  if len(cmdlist) > 1
    let cmd .= ' ' . join(cmdlist[1:], ' ')
  else
    let cmd .= ' "' . getcwd() . '"'
  endif

  exe "lcd " . original_dir
  let cmd = [&shell, &shellcmdflag, cmd]
  return [cmd, {'on_exit': funcref('LfCallback', [lf_tmpfile, lastdir_tmpfile])}, v:false]
endfunction
