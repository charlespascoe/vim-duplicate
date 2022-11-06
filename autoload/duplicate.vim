let s:duplicate_count = 1
let s:prev_opfunc = ''

" TODO: Handle registers for nested commands?

fun duplicate#with(op, oneline=0)
    let s:duplicate_count = v:count1

    " Clear opfunc
    set opfunc=
    let s:prev_op = a:op

    " <Esc> is needed so that v:count doesn't get passed to the motion or
    " text object
    return a:op."\<Esc>\<Cmd>call ".string(function("s:SetOpfunc"))."()\<CR>g@".(a:oneline ? 'Vl' : '')
endfun


fun duplicate#mappings()
    nmap <expr> gd duplicate#with('')
    nmap gdd <Cmd>exec 'normal yy'.v:count1.'p'<CR>
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
    let end = motype == 'line' ? "']" : "`]"

    exec "normal!" start."y".inclusive.end

    if s:prev_opfunc != ''
        call call(s:prev_opfunc, [motype])
    elseif s:prev_op != ''
        exec "normal" start.s:prev_op.end
    endif

    exec "normal!" end.s:duplicate_count."p"
endfun
