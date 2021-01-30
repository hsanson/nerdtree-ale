if exists('g:nerdtree_ale_loaded')
  finish
endif

let g:nerdtree_ale_loaded = 1

if ! exists('g:nerdtree_ale_glyph')
  let g:nerdtree_ale_glyph='○'
endif

call g:NERDTreePathNotifier.AddListener('init', 'NERDTreeAleIssues')
call g:NERDTreePathNotifier.AddListener('refresh', 'NERDTreeAleIssues')
call g:NERDTreePathNotifier.AddListener('refreshFlags', 'NERDTreeAleIssues')

function! s:split(pathname) abort
  let parts = (strpart(a:pathname, 0, 1) =~# '[/\\]' ? [''] : [])
        \ + split(a:pathname, '[/\\]')
  return parts
endfunction

function! s:Refresh()
  if g:NERDTree.IsOpen() && !exists('s:stop_recursion')
    let s:stop_recursion = 1
    let l:winnr = winnr()
    let l:altwinnr = winnr('#')
    call g:NERDTree.CursorToTreeWin()
    call b:NERDTree.root.refreshFlags()
    call NERDTreeRender()
    execute l:altwinnr . 'wincmd w'
    execute l:winnr . 'wincmd w'
  endif
  unlet! s:stop_recursion
endfunction

" Get list of all the reported issue paths
function! NERDTreeAleGetPaths()
  let l:buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')

  let l:paths = []

  for l:buffer in l:buffers
      let l:problems = ale#engine#GetLoclist(l:buffer)
      for l:problem in l:problems

        if has_key(l:problem, 'bufnr')
          let l:bufnr = l:problem['bufnr']
          let l:path = expand('#' . l:bufnr . ':p')
        elseif has_key(l:problem, 'filename')
          let l:path = l:problem['filename']
        endif

        call add(l:paths, l:path)
      endfor
  endfor

  return uniq(sort(l:paths))
endfunction

" Function iterates over all buffers and extracts any issues reported by ALE
" creating a hash with the paths and counter of errors per path.
function! NERDTreeAleGetIssues()

  let l:result = {}
  let l:paths = NERDTreeAleGetPaths()

  for l:path in l:paths
    let l:full_path = []
    for l:part in s:split(l:path)
      call add(l:full_path, l:part)
      let l:key = join(l:full_path, '/')
      if has_key(l:result, l:key)
          let l:result[l:key] = l:result[l:key] + 1
      else
          let l:result[l:key] = 1
      endif
    endfor
  endfor

  return l:result
endfunction

function! NERDTreeAleIssues(event)
    let l:problems = NERDTreeAleGetIssues()
    let l:path = a:event.subject
    let l:key = '/' . join(l:path.pathSegments, '/')

    if has_key(l:problems, l:key)
      call l:path.flagSet.clearFlags('ale')
      call l:path.flagSet.addFlag('ale', g:nerdtree_ale_glyph)
    else
      call l:path.flagSet.clearFlags('ale')
    endif
endfunction

" Autocmds to trigger NERDTree flag refreshes
augroup NERDTreeAlePlugin
    autocmd User ALELintPost call s:Refresh()
augroup END
