"=============================================================================
" Name: dm.vim
" Author: mfumi
" Email: m.fumi760@gmail.com
" Version: 0.0.1
"=============================================================================
"  How to use the DiskMapper simulator:
"  
"  Acknowledgment:
"  
"  This impressive macro setup file is the work of author "mfumi" as noted
"  above.  I have altered a few colors and changed some terms and messages
"  to barely obfuscate its original purpose if viewed in passing by a
"  casual observer, but I'm sure you'll get the idea.
"  
"  The Setup:
"  
"  Go to the directory containing this configuration file.
"  Launch vim.
"  Source the file:       :so dm.vim  
"  Launch the simulator:  [m
"  
"  The Scenario:
"  
"  You are using a data recovery utility to retrieve information
"  from a damaged section of a disk drive.  An earlier diagnostic
"  scan prior to the drive's failure produced a count of bad sectors
"  in the section, but the exact location of the bad sectors was
"  lost.
"  
"  
"  The Simulation:
"  
"  You are presented with a blank two-dimensional map of the sectors
"  in the suspect section of the disk.  You can examine any sector
"  you like, but if you examine a bad sector you will crash the disk
"  controller and possibly destroy the drive.  Fortunately, this
"  utility can report to the operator how many adjacent sectors are
"  bad, referred to as the "Adjacent Bad Sector" or ABS count.  The
"  ABS count can help you avoid examining bad sectors while you
"  continue mapping out the disk.  The ABS count includes diagonally
"  adjacent sectors, so values can range from 0 to 8.
"  
"  The simulator has a vi-style interface, so you can use vi cursor
"  positioning commands to select sectors for examination.  HINT:
"  the w/b "word forward/backward" commands can quickly jump you
"  through blocks of mapped or unmapped sectors. 
"  
"  Once you have selected a sector, you can execute one of the
"  following commands:
"  
"  x	Examine this sector.  On examination, either the sector
"  	will be marked with its ABS count, or the disk will crash
"  	if the sector itself is bad (generating the dreaded "Disk
"  	Crash!!!" message and revealing the full disk section map
"  	in its final dump - i.e., you have failed and the
"  	simulator must be reset to a new map).
"  	
"  	NOTE: If the revealed ABS count is 0, the utility will
"  	immediately examine adjacent unmapped sectors to show
"  	their ABS values.  This process will "cascade" in all
"  	directions until it reveals sectors with non-zero ABS
"  	values.  The algorithm isn't perfect, so will sometimes
"  	stop while still bordering unmapped sectors, but you can
"  	manually select a "0 ABS" sector bordering on unmapped
"  	sectors and safely execute the "zz" command (see below)
"  	to restart the cascade process.
"  
"  v	Verify that the sector should be flagged as bad.  The v
"  	key can be pressed repeatedly to toggle through "F" for
"  	"flagged bad", "?" for "possibly bad", and back to "."
"  	for "unmapped".
"  
"  zz	Zoom out and examine - This can be executed on an
"  	examined sector to immediately examine all adjacent
"  	non-flagged sectors.  This will only work if the number
"  	of adjacent flagged sectors matches the selected sector's
"  	ABS.  CAUTION: If sectors have been incorrectly flagged,
"  	this WILL crash the disk!
"     
"  
"  Your job is to flag all the bad sectors using the commands above
"  and the ABS values they reveal.  You will succeed once you have
"  flagged all the bad sectors - if your flags are all correct, you
"  will receive the message "Disk Mapped!".  Good luck!
"=============================================================================

if exists('g:loaded_diskmapper_vim')
	finish
endif
let g:loaded_diskmapper_vim = 1

let s:save_cpo = &cpo
set cpo&vim

" ----------------------------------------------------------------------------

let s:DiskMapper = {
			\ 'board1' : [],
			\ 'board2' : [],
			\ 'width'  : 0,
			\ 'height' : 0,
			\ 'num_of_diskerr' : 0,
			\ 'num_of_flag'    : 0,
			\ 'status'         : 0,
			\ 'diskerr_is_set' : 0,
			\ 'start_time'     : 0,
			\ 'end_time'       : 0,
			\}

function! s:DiskMapper.run(width,height,num_of_diskerr)

	if a:width*a:height < (a:num_of_diskerr+1)
		echoerr "number of diskerr is too big"
		return
	endif

	if !exists("g:diskmapper_title")
		let g:diskmapper_title = "==DiskMapper=="
	endif

	let winnum = bufwinnr(bufnr(g:diskmapper_title))
	if winnum != -1
		if winnum != bufwinnr('%')
			exe "normal \<c-w>".winnum."w"
		endif
	else
		exec 'silent split ' . g:diskmapper_title
	endif

	call s:srand(localtime())

	let self.width = a:width
	let self.height = a:height
	let self.num_of_diskerr = a:num_of_diskerr
	call self.initialize_board()
	call self.draw()

	if has("conceal")
		syn match DiskMapperStatusBar contained "|" conceal
	else
		syn match DiskMapperStatusBar contained "|"
	endif
	syn match DiskMapperStatus '.*' contains=DiskMapperStatusBar
	syn match DiskMapperBomb   '\*'
	syn match DiskMapperField  '\.'
	syn match DiskMapperFlag   'F'
	syn match DiskMapperHatena '?'
	syn match DiskMapper0      '0'
	syn match DiskMapper1      '1'
	syn match DiskMapper2      '2'
	syn match DiskMapper3      '3'
	syn match DiskMapper4      '4'
	syn match DiskMapper5      '5'
	syn match DiskMapper6      '6'
	syn match DiskMapper7      '7'
	syn match DiskMapper8      '8'
	if !exists("g:diskmapper_custom_colors")
		let g:diskmapper_custom_colors = 0
	endif
	if g:diskmapper_custom_colors == 0
		hi DiskMapperStatus ctermfg=darkyellow  guifg=magenta
		hi DiskMapperBomb   ctermfg=red       ctermbg=black     guifg=red        guibg=black
		hi DiskMapperField  ctermfg=black     ctermbg=darkgreen guifg=black      guibg=darkgreen
		hi DiskMapperFlag   ctermfg=red       ctermbg=black     guifg=red        guibg=black
		hi DiskMapperHatena ctermfg=green     ctermbg=darkblue  guifg=green      guibg=darkblue
		hi DiskMapper0      ctermfg=cyan      ctermbg=gray      guifg=cyan       guibg=gray
		hi DiskMapper1      ctermfg=blue      ctermbg=gray      guifg=blue       guibg=gray
		hi DiskMapper2      ctermfg=darkred   ctermbg=gray      guifg=darkred    guibg=gray
		hi DiskMapper3      ctermfg=darkred   ctermbg=gray      guifg=darkred    guibg=gray
		hi DiskMapper4      ctermfg=red       ctermbg=gray      guifg=red        guibg=gray
		hi DiskMapper5      ctermfg=red       ctermbg=gray      guifg=red        guibg=gray
		hi DiskMapper6      ctermfg=red       ctermbg=gray      guifg=red        guibg=gray
		hi DiskMapper7      ctermfg=red       ctermbg=gray      guifg=red        guibg=gray
		hi DiskMapper8      ctermfg=red       ctermbg=gray      guifg=red        guibg=gray
	endif

	nnoremap <silent> <buffer> x  			:call <SID>_click()<CR>
	nnoremap <silent> <buffer> <LeftMouse>  :call <SID>_click()<CR>
	nnoremap <silent> <buffer> v  			:call <SID>_right_click()<CR>
	nnoremap <silent> <buffer> <RightMouse> :call <SID>_right_click()<CR>
	nnoremap <silent> <buffer> zz 			:call <SID>_wheel_click()<CR>
	
	augroup DiskMapper
		autocmd!
		autocmd  CursorMoved <buffer> call <SID>_set_caption()
	augroup END
	
	if exists("g:diskmapper_statusline")
		let &l:statusline = g:diskmapper_statusline
	endif

"	setl conceallevel=2
	setl nocursorline
	setl nonumber
"	setl norelativenumber
	setl noswapfile
	setl nomodified
	setl nomodifiable
	setl buftype=nofile
	setl bufhidden=delete
endfunction


function! s:DiskMapper.click()
	let pos = getpos('.')
	let x = pos[2]-1
	let y = pos[1]-2
	if y < 0 | return | endif
	if !self.diskerr_is_set
		let self.diskerr_is_set = 1
		call self.set_diskerr(x,y)
		let self.start_time = reltime()
	endif

	if self.board2[y][x] == 'F' ||
				\ self.board2[y][x] == '?' 
		return
	elseif self.board1[y][x] == '*'
		let self.board2 = copy(self.board1)
		let self.status = 1
		let self.end_time = reltime()
		" call s:message("Disk Crash!!!")
	else
		try
			call self.expand(x,y)
		catch /E132/
		endtry
		if self.check_board()
			let self.status = 2
			let self.end_time = reltime()
			" call s:message("Disk Mapped!")
		endif
	endif
	call self.draw()
	call setpos('.',pos)
endfunction

function! s:DiskMapper.right_click()
	let pos = getpos('.')
	let x = pos[2]-1
	let y = pos[1]-2
	if y < 0 | return | endif
	let c = ['.','F','?']
	if self.board2[y][x] == '.'
		let self.num_of_flag += 1
	elseif self.board2[y][x] == 'F'
		let self.num_of_flag -= 1
	endif
	let idx = index(c,self.board2[y][x])
	if idx != -1 
		let self.board2[y][x] = c[(idx+1)%3]
	endif
	call self.draw()
	call setpos('.',pos)
endfunction

function! s:DiskMapper.wheel_click()
	let pos = getpos('.')
	let x = pos[2]-1
	let y = pos[1]-2
	if y < 0 | return | endif
	if self.board2[y][x] == '.' ||
	\  self.board2[y][x] == 'F' ||
	\  self.board2[y][x] == '?' 
		return
	endif

	let cnt = 0
	for i in range(-1,1)
		for j in range(-1,1)
			if self.check_coord(x+j,y+i)
				if self.board2[y+i][x+j] == 'F'
					let cnt += 1
				endif
			endif 
		endfor
	endfor
	
	if cnt != self.board1[y][x]
		return
	endif
	
	for i in range(-1,1)
		for j in range(-1,1)
			try
				if self.check_coord(x+j,y+i) &&
				\  self.board2[y+i][x+j] != 'F'
			 		if self.board1[y+i][x+j] == '*'
						let self.board2 = copy(self.board1)
						let self.status = 1
						let self.end_time = reltime()
						break
					endif
					call self.expand(x+j,y+i)
				endif
			catch /E132/
			endtry
		endfor
		if self.status == 1 | break | endif
	endfor

	if self.check_board()
		let self.status = 2
		let self.end_time = reltime()
	endif
	
	call self.draw()
	call setpos('.',pos)
endfunction

function! s:DiskMapper.check_coord(x,y)
	return  a:x >= 0 && a:y >= 0 && a:x < self.width && a:y < self.height
endfunction

function! s:DiskMapper.check_board()
	let cnt = 0
	for i in range(self.height)
		for j in range(self.width)
			if  self.board2[i][j] != 'F' &&
						\ self.board2[i][j] != '.'
				let cnt += 1
			endif
		endfor
	endfor
	return (self.width * self.height - cnt) == self.num_of_diskerr
endfunction

function! s:DiskMapper.expand(x,y)
	let self.board2[a:y][a:x] = self.board1[a:y][a:x]
	if self.board1[a:y][a:x] != '0'
		return
	endif
	for i in range(-1,1)
		for j in range(-1,1)
			if (i != 0 || j != 0) &&
						\ self.check_coord(a:x+j,a:y+i) && 
						\ self.board1[a:y+i][a:x+j] != 'x' &&
						\ self.board2[a:y+i][a:x+j] == '.'
				call s:DiskMapper.expand(a:x+j,a:y+i)
			endif
		endfor
	endfor
endfunction

function! s:DiskMapper.initialize_board()
	let self.start_time =  0
	let self.end_time   =  0
	let self.diskerr_is_set = 0
	let self.num_of_flag = 0
	let self.status = 0
	let self.board1 = []
	let self.board2 = []
	for i in range(self.height)
		call add(self.board1,[])
		call add(self.board2,[])
		for j in range(self.width)
			call add(self.board1[i],'0')
			call add(self.board2[i],'.')
		endfor
	endfor
endfunction

function! s:DiskMapper.set_diskerr(cur_x,cur_y)
	let i = 0
	while i < self.num_of_diskerr
		let x = s:rand() % self.width
		let y = s:rand() % self.height
		if (x != a:cur_x || y != a:cur_y) && 
					\ self.board1[y][x] == '0' 
			let self.board1[y][x] = '*'
			let i+= 1
		endif
	endwhile

	for i in range(self.height)
		for j  in range(self.width)

			if self.board1[i][j] != '*' 
				let cnt = 0
				for k in range(-1,1)
					for l in range(-1,1)
						if (k != 0 || l != 0) && 
									\ self.check_coord(j+l,i+k)
							if self.board1[i+k][j+l] == '*'
								let cnt += 1
							endif
						endif
					endfor 
				endfor
				let self.board1[i][j] = string(cnt)
			endif

		endfor
	endfor
endfunction

function! s:DiskMapper.set_caption()
	setl modifiable

	let status = ['',"Disk Crash!!!","Disk Mapped!"]
	if type(self.start_time) == type([])
		if type(self.end_time) == type([])
			let _time = reltimestr(reltime(self.start_time,self.end_time))
		else
			let _time = reltimestr(reltime(self.start_time))
		endif
		let match_end = matchend(_time, '\d\+\.') - 2
		let time = _time[:match_end]
	else
		let time = 0 
	endif
	let str = printf("| %3s - %2d/%2d %s |", 
				\ time,self.num_of_flag,
				\ self.num_of_diskerr,status[self.status])
	call setline(1,str)
	
	setl nomodified
	setl nomodifiable
endfunction

function! s:DiskMapper.draw()
	setl modifiable
	silent %d _

	call self.set_caption()

	setl modifiable
	for i in range(self.height)
		let str = join(self.board2[i],'')
		call append(line('$'),str)
	endfor

	setl nomodified
	setl nomodifiable
endfunction

let s:seed = 0
function! s:srand(seed)
	let s:seed = a:seed
endfunction

function! s:rand()
	let s:seed = s:seed * 214013 + 2531011
	return (s:seed < 0 ? s:seed - 0x80000000 : s:seed) / 0x10000 % 0x8000
endfunction

function! s:message(msg)
	echohl WarningMsg
	echo a:msg
	echohl None
endfunction

function! s:_diskmapper(...)
	if a:0 == 0
		call s:DiskMapper.run(9,9,10)
	elseif a:1 == 'easy'
		call s:DiskMapper.run(9,9,10)
	elseif a:1 == 'normal'
		call s:DiskMapper.run(16,16,40)
	elseif a:1 == 'hard'
		call s:DiskMapper.run(30,16,99)
	elseif a:1 == 'custom'
		if a:0 >= 4
			call s:DiskMapper.run(a:2,a:3,a:4)
		else
			call s:message("usage: DiskMapper [easy,normal,hard]")
			call s:message("       DiskMapper  custom {width} {height} {num_of_diskerr}")
		endif
	else
		call s:message("usage: DiskMapper [easy,normal,hard]")
		call s:message("       DiskMapper  custom {width} {height} {num_of_diskerr}")
	endif
endfunction

function! s:_click()
	call call(s:DiskMapper.click,[],s:DiskMapper)
endfunction

function! s:_right_click()
	call call(s:DiskMapper.right_click,[],s:DiskMapper)
endfunction

function! s:_wheel_click()
	call call(s:DiskMapper.wheel_click,[],s:DiskMapper)
endfunction

function! s:_set_caption()
	call call(s:DiskMapper.set_caption,[],s:DiskMapper)
endfunction

function! s:level(ArgLead,CmdLine,CursorPos)
	return ["easy","normal","hard","custom"]
endfunction

command! -nargs=* -complete=customlist,s:level 
			\ DiskMapper call s:_diskmapper(<f-args>)

" ----------------------------------------------------------------------------

let &cpo = s:save_cpo
unlet s:save_cpo

map [m :DiskMapper custom 60 15 100
