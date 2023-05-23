function structGen(name)
    string="struct "*name*" end"
end

eval(Meta.parse(structGen("Hello")))

function funcGen(name)
    string="function func"*name*"(arg::"*name*") println(5) end" 
end

eval(Meta.parse(funcGen("Hello")))

# now a macro that generates both of these things

macro twoGen(arg)
    quote
        eval(Meta.parse(structGen($(esc(arg)))))
        eval(Meta.parse(funcGen($(esc(arg)))))
    end
end

x=quote 
    function tst()
        println("hi")
    end
end
    
eval(Meta.parse(x))

function quoteSub(varb)
    quote 
        function $varb()
            println("Boo Boo")
        end
    end
end

abstract type letter end
struct a <: letter end
struct b <: letter end
subtype(letter)
