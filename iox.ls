DEBUG = true

readline = require('readline')
async = require('async')

rl = readline.createInterface do
    input: process.stdin
    output: process.stdout

isDigit = (n)->
    return n >= '0' && n <= '9'

trace = (s)->
    if DEBUG
        console.log '// ' + s

indent = (s,ch,lvl)->
    if not ch
        ch = '\t'
    if not lvl
        lvl = 1
    lines = s.split('\n')
    for line in @lines
        line = ch.repeat(lvl) + line
    return lines.join('\n')

class State
    line: ''
    ins: 0 # line insert index for next token -- parser reads backwards

    # call (parens) depth
    depth: 0
    chunk: ''
    par: false
    chain: ''
    pending: []
    indents: 0
    spaces: 4
    args: []
    #link: ''

    # context: wrapping text showing where we're currently nested
    line_ctx_before: ''
    line_ctx_after: ''
    line_ctx_depth: 0
    ctx_before: ''
    ctx_after: ''

    # current nested function depth on single line
    # this returns to 0 after line
    line_wrap: 0

    put: (tk,chain)->
        trace 'PUT ' + tk
        if chain
            trace 'CHAIN' + chain

        #if @par
        #    @line = tk + '(' + @line + ')'
        #    @par = false
        #else
        if @chain
            @line = @line.substr(0,@ins) + @chain + @line.substr(@ins)
            @ins += @chain.length
            @chain = ''
        @line = @line.substr(0,@ins) + tk + @line.substr(@ins)
        @ins += tk.length
        @chain = chain
        @depth++

    # function call
    call: (tk)->
        trace 'CALL ' + tk
        if @par
            @line = tk + '(' + @line + ')'
            @par = false
        else
            if @chain
                @line = @line.substr(0,@ins) + @chain + @line.substr(@ins)
                @ins += @chain.length
                @chain = ''
            @line = @line.substr(0,@ins) + tk + "()" + @line.substr(@ins)
        @ins += tk.length + 1
        @depth++

    # tracking the input indent level
    indent: ->
        @indents += @spaces
    outdent: ->
        @indents -= @spaces

    pend: ->
        trace 'PEND'

        if @line
            @pending.unshift(@line + ';')
            @line = ''
        @ins = 0
        @depth = 0
        @chain = ''
        @par = false
    def: (name,sameline)->
        trace 'DEF '+name
        if @line_ctx_before
            @line_ctx_before = '\n' + indent(@line_ctx_before, ' ', spaces)
        @line_ctx_before = "function "+name+"(){" + @line_ctx_before
        if @line_ctx_after
            @line_ctx_after = '\n' + @line_ctx_after
        @line_ctx_after += '}'
        @line_ctx_depth += 1
        # outgoing indent?
    cls: (name,sameline)->
        trace 'CLASS '+name
        @line_ctx_before = "class "+name+" {" + @line_ctx_before
        @line_ctx_after += "}"
        @line_ctx_depth += 1
        # outgoing indent?
    #wrap: ->
    #    tk = "function(){}"
    #    @line = @line.substr(0,@ins) + tk + @line.substr(@ins)
    #    @ins += tk.length - 1
    #unwind: ->
        #if @pending
        #    @link += @pending.join('\n')
        #    @pending = []
    flush: ->
        #console.log @ctx_before
        trace 'FLUSH'
        console.log @line_ctx_before
        infunc = false
        if @line_ctx_before
            trace 'PREFIX'
            infunc = true
        if @line
            trace 'LINE'
            prefix = ''
            trace @pending.length
            if infunc and @pending.length==0
                trace 'RETURN'
                prefix = 'return '
            console.log (' '.repeat(@line_ctx_depth * @spaces)) + prefix + @line + ';'
            @chunk += @line + ';\n'
            @line = ''
        if @pending
            trace 'PENDING'
            i = 0
            for line in @pending
                prefix=''
                if infunc and i == @pending.length - 1
                    prefix = 'return '
                console.log (' '.repeat(@line_ctx_depth * @spaces)) + prefix + line
                ++i
            #@link += @pending.join('\n')
            @pending = []
        console.log @line_ctx_after
        @line_ctx_depth = 0
        @line_ctx_before = ''
        @line_ctx_after = ''
        #console.log @ctx_after
        @ins = 0
        @depth = 0
        @chain = ''
        @par = false
    #push: (tk)->
    #    @args.unshift(tk)

state = new State()
iter = (cb)->
    line <- rl.question 'iox> '
    tokens = line.split(' ')

    # todo: read indent level

    rtokens = tokens.reverse()

    i = rtokens.length - 1
    for i from 0 to rtokens.length - 1
        tk = rtokens[i]
        if tk==''
            continue

        left = void
        try
            left = rtokens[i+1]
            if left[left.length - 1]==','
                # combine
                void

        tk0 = tk[0]
        tke = tk[tk.length - 1]
        if tk=='def' or tk=='class'
            void # checked by adjacent tokens
        else if tke==':'
            name = tk.substr(0,tk.length - 1)
            typ = rtokens[i+1]
            if typ=='def'
                state.def(name, true)
            else if typ=='class'
                state.cls(name, true)
        else if tk =='$' # special case for $ (jquery) var
            state.put(tk, ' = ')
        else if tk =='!'
            state.call('!')
        else if tk0 == '$'
            state.put(tk.substr(1), ' = ')

        # unquoted filenames
        else if tk0 == '\\'
            state.put("'" + tk.substr(1) + "'")
        else if tk0 == '/'
            state.put("'" + tk + "'")
        else if isDigit(tk0)
            state.put(tk)
            state.pend()
        else if tk0=='.'
            # decimal number
            if isDigit(tk[1])
                state.put(tk)
                state.pend()

            # more dot filenames
            else if tk.length == 1
                state.put("'.'")
            else if tk[1] == '/'
                state.put("'" + tk + "'")
            else if tk.substr(1,2) == '\\'
                state.put("'" + tk + "'")
        else if tke == '"'
            void
            #t = tk
            #s = ''
            #until t[0]=='"'
            #    s += t
            #    i += 1
            #    t = rtokens[i]
            #state.put(tk)
        else if tk0 == '['
            # parse array/range
            void
        else if tk0 == '('
            # parse range
            void
        else if tk0 == '{'
            # parse dict
            void
        else if tk0 == '-'
            # flag
            void
        else if tk0 == '+'
            # flag
            void

        # flush stream
        else if tk0 == ';'
            state.pend()

        # recall
        else if tk == '_'
            void

        # function call
        else
            state.call(tk)

    state.flush()
    return cb!

async.whilst (->true), iter

