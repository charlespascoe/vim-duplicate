let s:duplicate_count = 1
let s:prev_opfunc = ''
let s:curpos = []

" TODO: Handle registers for nested commands?

fun duplicate#with(op, oneline=0)
    let s:duplicate_count = v:count1

    " Clear opfunc
    set opfunc=
    let s:prev_op = a:op
    let s:curpos = getpos('.')

    " <Esc> is needed so that v:count doesn't get passed to the motion or
    " text object
    return a:op."\<Esc>\<Cmd>call ".string(function("s:SetOpfunc"))."()\<CR>g@".(a:oneline ? 'Vl' : '')
endfun


fun duplicate#mappings()
    nmap <expr> gd  duplicate#with('')
    nmap <expr> gdd duplicate#with('', 1)
endfun


fun s:SetOpfunc()
    let s:prev_opfunc = &opfunc
    set opfunc=<SID>Opfunc
endfun


fun s:Opfunc(type)
    " TODO: Figure out best way of dealing with block selection
    if a:type == 'block'
        echoerr "block selection not supported"
    endif

    let motype = a:type
    let inclusive = ''

    if motype == 'char'
        if line("'[") != line("']") && get(g:, 'duplicate_smart_line', 1)
            let motype = 'line'
        else
            let inclusive = 'v'
        endif
    endif

    let start = motype == 'line' ? "'[" : "`["
    let end   = motype == 'line' ? "']" : "`]"

    exec "normal!" start."y".inclusive.end

    " Note: yanking the text moves the `[ and `] marks to the start/end of their
    " respective lines (see ":help '["). This is used to our advantange because
    " it means that when a charwise motion is forced to be linewise, '[ will now
    " be the start of the line, so GetRelCurpos() will return the correct
    " relative position.
    let curoffset = s:GetRelCurpos("'[")

    if s:prev_opfunc != ''
        call call(s:prev_opfunc, [motype])
    elseif s:prev_op != ''
        exec "normal" start.s:prev_op.end
    endif

    " Note: paste also moves `[ and `] to surround the pasted text; this makes
    " it easy to restore the cursor position.
    exec "normal!" end.s:duplicate_count."p"

    call s:SetRelCurpos("'[", curoffset)
    let s:curpos = []
endfun


fun s:GetRelCurpos(mark)
    let cpos = s:curpos
    let mpos = getpos(a:mark)

    if cpos[1] == mpos[1]
        " Same line; calculate relative column offset
        return [0, cpos[2] - mpos[2]]
    else
        " Different lines; use cursor column but relative line offset
        return [cpos[1] - mpos[1], cpos[2]]
    endif
endfun


fun s:SetRelCurpos(mark, offset)
    " Note: offset = [line, col], but getpos() = [bufnr, line, col, off]
    let pos = getpos(a:mark)

    if a:offset[0] == 0
        let pos[2] += a:offset[1]
    else
        let pos[1] += a:offset[0]
        let pos[2] = a:offset[1]
    endif

    call setpos('.', pos)
endfun
