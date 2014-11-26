" Python-mode folding functions


let s:def_regex = g:pymode_folding_regex
let s:blank_regex = '^\s*$'
let s:decorator_regex = '^\s*@'
let s:doc_begin_regex = '^\s*\%("""\|''''''\)'
let s:doc_end_regex = '\%("""\|''''''\)\s*$'
let s:doc_line_regex = '^\s*\("""\|''''''\).\+\1\s*$'
let s:symbol = matchstr(&fillchars, 'fold:\zs.')  " handles multibyte characters
if s:symbol == ''
    let s:symbol = ' '
endif


fun! pymode#folding#text() " {{{
    let fs = v:foldstart
    while getline(fs) !~ s:def_regex && getline(fs) !~ s:doc_begin_regex
        let fs = nextnonblank(fs + 1)
    endwhile
    if getline(fs) =~ s:doc_begin_regex
        let fs = nextnonblank(fs + 1)
    endif
    let line = getline(fs)

    let nucolwidth = &fdc + &number * &numberwidth
    let windowwidth = winwidth(0) - nucolwidth - 6
    let foldedlinecount = v:foldend - v:foldstart

    " expand tabs into spaces
    let onetab = strpart('          ', 0, &tabstop)
    let line = substitute(line, '\t', onetab, 'g')

    let line = strpart(line, 0, windowwidth - 2 -len(foldedlinecount))
    let line = substitute(line, '\%("""\|''''''\)', '', '')
    let fillcharcount = windowwidth - len(line) - len(foldedlinecount) + 1
    return line . ' ' . repeat(s:symbol, fillcharcount) . ' ' . foldedlinecount
endfunction "}}}


fun! pymode#folding#expr(lnum) "{{{

    let line = getline(a:lnum)
    let indent = indent(a:lnum)
    let prev_line = getline(a:lnum - 1)

    if line =~ s:decorator_regex
        return ">".(indent / &shiftwidth + 1)
    endif

    if line =~ s:def_regex
        " Check if last decorator is before the last def
        let decorated = 0
        let lnum = a:lnum - 1
        while lnum > 0
            if getline(lnum) =~ s:def_regex
                break
            elseif getline(lnum) =~ s:decorator_regex
                let decorated = 1
                break
            endif
            let lnum -= 1
        endwhile
        if decorated
            return '='
        else
            return ">".(indent / &shiftwidth + 1)
        endif
    endif

    if line =~ s:doc_begin_regex && line !~ s:doc_line_regex && prev_line =~ s:def_regex
        return ">".(indent / &shiftwidth + 1)
    endif

    if line =~ s:doc_end_regex && line !~ s:doc_line_regex
        return "<".(indent / &shiftwidth + 1)
    endif

    if line =~ s:blank_regex
        if prev_line =~ s:blank_regex
            if indent(a:lnum + 1) == 0 && getline(a:lnum + 1) !~ s:blank_regex
                return 0
            endif
            return -1
        else
            return '='
        endif
    endif

    if indent == 0
        return 0
    endif

    return '='

endfunction "}}}


" vim: fdm=marker:fdl=0
