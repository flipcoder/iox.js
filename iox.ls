readline = require('readline')
async = require('async')

rl = readline.createInterface do
    input: process.stdin
    output: process.stdout

isDigit = (n)->
    return n >= '0' && n <= '9'

class State
    line: ''
    ins: 0
    depth: 0
    chunk: ''
    wrap: false
    chain: ''
    pending: []
    put: (tk,chain)->
        #if @wrap
        #    @line = tk + '(' + @line + ')'
        #    @wrap = false
        #else
        if @chain
            @line = @line.substr(0,@ins) + @chain + @line.substr(@ins)
            @ins += @chain.length
            @chain = ''
        @line = @line.substr(0,@ins) + tk + @line.substr(@ins)
        @ins += tk.length
        @chain = chain
        @depth++
    putfunc: (tk)->
        if @wrap
            @line = tk + '(' + @line + ')'
            @wrap = false
        else
            if @chain
                @line = @line.substr(0,@ins) + @chain + @line.substr(@ins)
                @ins += @chain.length
                @chain = ''
            @line = @line.substr(0,@ins) + tk + "()" + @line.substr(@ins)
        @ins += tk.length + 1
        @depth++
    pend: ->
        if @line
            @pending.unshift(@line + ';')
            @line = ''
        @ins = 0
        @depth = 0
        @chain = ''
        @wrap = false
    push: ->
        if @line
            console.log @line+';'
            @chunk += @line + ';\n'
            @line = ''
        if @pending
            for line in @pending
                console.log line
            #console.log @pending.join('\n')
            @chunk += @pending.join('\n')
            @pending = []
        @ins = 0
        @depth = 0
        @chain = ''
        @wrap = false

iter = (cb)->
    line <- rl.question 'iox> '
    tokens = line.split(' ')

    #if token[0] == 'def'
    #    # function

    rtokens = tokens.reverse()
    state = new State()

    i = rtokens.length-1
    for i from 0 to rtokens.length-1
        tk = rtokens[i]

        left = void
        try
            left = rtokens[i+1]
            if left[left.length-1]==','
                # combine
                void

        tk0 = tk[0]
        tke = tk[tk.length-1]
        if tk0 == '$'
            #if state.depth
            state.put(tk.substr(1), ' = ')
            #else
            #    state.put(tk.substr(1))
        else if isDigit(tk0)
            state.put(tk)
            state.pend()
        else if tk0 == '\\'
            state.put("'" + tk.substr(1) + "'")
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
        else if tk0 == ';'
            state.pend()
        else # function
            if tk=='out'
                state.putfunc('console.log')
            else
                state.putfunc(tk)

    state.push()
    return cb!

async.whilst (->true), iter

