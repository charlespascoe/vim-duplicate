let s:duplicate_count = 1
let s:prev_opfunc = ''

" TODO: Handle registers for nested commands?

fun duplicate#with(op, oneline=0)
    let s:duplicate_count = v:count1
    " Clear opfunc first
    set opfunc=

    if a:op != ''
        call feedkeys(a:op, 'x')
    endif

    let s:prev_opfunc = &opfunc
    let s:prev_op = a:op

    set opfunc=duplicate#opfunc

    " <Esc> is needed so that v:count doesn't get passed to the motion or
    " text object
    return "\<Esc>g@".(a:oneline ? 'Vl' : '')
endfun


fun duplicate#mappings()
    nmap <expr> gd duplicate#with('')
    nmap gdd <Cmd>exec 'normal yy'.v:count1.'p'<CR>
endfun


fun duplicate#opfunc(type)
    " TODO: Figure out best way of dealing with block selection
    if a:type == 'block'
        echoerr "block selection not supported"
    endif

    let motype = a:type

    if motype == 'char' && line("'[") != line("']") && get(g:, 'duplicate_smart_line', 1)
        let motype = 'line'
    endif

    let start = motype == 'line' ? "'[" : "`["
    let end = motype == 'line' ? "']" : "`]"

    echom start."y".end
    exec "normal!" start."y".end

    if s:prev_opfunc != ''
        call call(s:prev_opfunc, [motype])
    elseif s:prev_op != ''
        exec "normal" start.a:prev_op.end
    endif

    exec "normal!" end.s:duplicate_count."p"
endfun
