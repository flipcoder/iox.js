readline = require('readline')
async = require('async')

rl = readline.createInterface do
    input: process.stdin
    output: process.stdout

isDigit = (n)->
    return n >= '0' && n <= '9'

put = (needle,haystack,ins)->
    

class State
    chunk: ''
    ins: 0
    depth: 0
    code: ''
    wrap: false
    chain: ''
    putraw: (tk)->
        #if @wrap
        #    @chunk = tk + '(' + @chunk + ')'
        #    @wrap = false
        #else
        @chunk = @chunk.substr(0,@ins) + tk + @chunk.substr(@ins)
        @ins += tk.length
        @depth++
    put: (tk)->
        if @wrap
            @chunk = tk + '(' + @chunk + ')'
            @wrap = false
        else
            if @chain
                @chunk = @chunk.substr(0,@ins) + @chain + @chunk.substr(@ins)
                @ins += @chain.length
                @chain = ''
            @chunk = @chunk.substr(0,@ins) + tk + "()" + @chunk.substr(@ins)
        @ins += tk.length + 1
        @depth++
    push: ->
        if @chunk
            console.log @chunk+';'
            @code += @chunk + ';\n';
            @chunk = ''
        @ins = 0
        @depth = 0

code = ''
iter = (cb)->
    line <- rl.question 'iox> '
    tokens = line.split(' ')

    #if token[0] == 'def'
    #    # function

    rtokens = tokens.reverse()
    state = new State()

    i = rtokens.length-1
    for tk in rtokens

        try
            left = rtokens[i-1]
            if left[left.length-1]==','
                # combine
                void

        console.log state.chunk
        tk0 = tk[0]
        if tk0 == '$'
            if state.depth
                state.putraw(tk.substr(1))
                state.chain = ' = '
            else
                state.putraw(tk.substr(1))
        else if isDigit(tk0)
            state.put(tk)
        else if tk0 == '['
            # parse array/range
            state.put(tk)
        else if tk0 == '('
            # parse range
            void
        else if tk0 == '{'
            # parse dict
            state.put(tk)
        else if tk0 == '-'
            # flag
            void
        else if tk0 == '+'
            # flag
            void
        else # function?
            state.put(tk)

        i--

    state.push()
    return cb!

async.whilst (->true), iter

