# iox.js
Flow-based language that compiles into js
(Ported to js from http://github.com/flipcoder/iox)

## Basics

### Input/Output

```
'hello, world' out
```

The above takes a string "hello, world" and pipes it to the function "out"
Note there is no "|" for piping like in bash.  It is implied between each token.

iox code reads from left-to-right.

```
0 $x
```

This pipes a value (0) into $x.

To read a value, you pipe it into something else, in this case, we pipe it to *out*, which outputs it:

```
$x out
```

To get line-based input, use "in".

```
"Enter your name: " in $name
'Hello, ', $name out
```

The message "Enter your name: " is passed to *in*, which is displayed as a prompt.
*in* will pipe the string it receives from the user on to the next token.
In this case, it is stored in $name.

The next line sends two strings to *out* which prints the appended greeting.

### Variables

By piping from a value into a named variable, we created a variable of that type
Variable types (*int*, etc.) are both constructors (pipe from) and casters (pipe to and from).

We can cast values as we're storing them.  In this case, it is redundant, since
0 is already an interger.
    
```
0 int $x
```

This pipes 0 into $x, ensuring it is stored as an int.

This is similar to x = int(0) in other languages.

Now, Let's write a basic program addition calculator:

First let's get two numbers from the user:

```
'Number: ' in int $num1
'Number: ' in int $num2
```

Now let's sum them and print:

```
$num1,$num2 + out
```

Notice the comma.  Commas are used to batch multiple things to send to a pipe.
The *+* function sums all the parameters together, and returns this number

### Branching

First let's make a boolean called test, and branch based on its value.

Conditions are done with "?" representing the initial test,
and the code to run in either scenario

```
'Enter a string (may be blank): ' in $s

$s ?
    'String was not empty' out
else
    'String was empty' out

# or store as bool
$s bool $was_empty

```

The *?* symbol is used for branching based on the contents of a stream.
The first branch is taken if the stream contains the boolean equivalent of *true*.
The else clause follows.

Because of the pipe-like order of tokens,
function parameters are written in suffix notation, meaning, we supply the
parameters first, separated by commas, then we call the function.

```
1,2,3 + out
```

This takes the 3 numbers, calls "+", which adds them all, then pipes that to out, which prints them.

### Looping

for each example

```
[1,2,3] each
    out
```

for loop example

```
0..5 each
    out
```

turns into:

```
for(var i = 0; i < 5; ++i)
{
    out(i);
}
```

also async:

```
[1,2,3] async each
    out
```

turns into:

```
async.each([1,2,3],function(i,cb){
    out(i);
    return cb();
});
```

callbacks trigger at end of scope unless you take control of the callback object using @

```
[1,2,3] async each
    'blah' @ another_function
```
Using '@' either prefixed or before a function call adds the current callback to the params

in this case:

```
async.each([1,2,3],function(i,cb){
    another_function('blah',cb);
});

```

### Backcalls

```
test then
    blah
```
    
This is equivalent to test(function(){ return blah(); })

```
test ready
blah
```

This is also equivalent to test(function(){ return blah(); })

### Packing/Unpacking

iox is based around temporary variables being passed down "the stream".  Generally these are single values or a list of values.

Variables are composite, meaning they can hold more than one value without being considered a special list type.
Because of this, they are unpacked consecutively.

For example,

```
# unpacking:
1,2,3 $numbers
0, $numbers, 4

1 type out
# -> int

1,2 type out
# -> int,int

```

The underscore (*_*) symbol indicates the insertion point for the pipe contents.
We can use this for appending and reordering values.

```
1,2,3
# is equivalent to:
2,3 1,_

#example using string formating
$name 'Hello ',_,'!' out
```

### Functions

Functions in iox take any number of inputs and give any number of outputs.

Here is a basic function declaration:

```
message: "Hello there, ", _

# Usage:
"What's your name? " in message out
```

Notice the *_* symbol represents the incoming data (unpacked) when piped from

The function automatically returns the content of the pipe on the last
effective line of the function.
We can block this behavior with the *;* symbol at the end of the line.

### Coroutines
Note: this section is being rethought for js await/async

The below features have no not yet been implemented.

The *&* symbol represents an async call, and you can tell a section of code to run in the background
The *&* symbol tells us to start any following code as a coroutine.

Let's have two threads sleep, then print something

```
& 2 sleep "2 second passed" out
& 1 sleep "1 second passed" out
```

The output will be 

```
1 second passed
2 second passed
```

All threads must finish for a program to complete, or a program must call quit for a program to
finish.

Contexts are named or numbered. and you can sequence many operations on the same thread.

```
0 & "do this first" out
0 & "do this second" out
```

Since we need a handle to access data that becomes available after an async call,

```
alarm: & 5 sleep "I just slept!"

alarm out # wake-up on event (availability of future 'alarm')
```

### Events

a keypress
	'a pressed!' out

### What now?

Work in progress :)

