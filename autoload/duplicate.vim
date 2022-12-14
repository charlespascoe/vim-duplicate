let s:duplicate_count = 1
let s:prev_opfunc = ''

" Keep track of the current cursor position in the active buffer
au CursorMoved,InsertLeave,BufEnter * let s:curpos = getpos('.')

" TODO: Handle registers for nested commands?

let s:default_opts = #{
    \ oneline: 0,
\}

fun duplicate#with(op, opts={})
    let s:duplicate_count = v:count1

    let opts = extend(copy(s:default_opts), a:opts)

    " Clear opfunc
    set opfunc=
    let s:prev_op = a:op
    let s:curpos = getpos('.')

    return a:op."\<Esc>\<Cmd>call ".string(function("s:SetOpfunc"))."()\<CR>g@".(opts.oneline ? 'V0' : '')
endfun


fun duplicate#mappings()
    nmap <expr> gd  duplicate#with('')
    nmap <expr> gdd duplicate#with('', #{oneline: 1})
endfun


fun s:SetOpfunc()
    let s:prev_opfunc = &opfunc
    let &opfunc = expand('<SID>').'Opfunc'
endfun


fun s:Opfunc(type)
    " TODO: Figure out best way of dealing with block selection
    if a:type == 'block'
        echoerr "block selection not supported"
        return
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
