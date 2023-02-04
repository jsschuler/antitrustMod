using Interact,Plots
using Blink
x=[]
y=[]


function updateButton(param)
    if param > 0
        global x 
        global y 
        plt=plot(x,y)
        println("Pushed")
    else
        plt=plot()
    end
    return plt
end



function plotString(x,y)
    xString="["
    yString="["
    for i in 1:(length(x)-1)
        xString=xString*string(x[i])*","
        yString=yString*string(y[i])*","
    end
    xString=xString*string(x[length(x)])*"]"
    yString=yString*string(y[length(y)])*"]"
    finString="plot("*xString*","*yString*")"
    return Symbol(finString)
end

function updatePlot(t::Int64)
    quote
        global plt
        global x
        global y 
        plt=plotString(x,y)
    end
    #return plt
end

function interface()
    update=button("Update Plot")
    println(update)
    global obsTick
    #plt=Interact.@map updateButton(&update)
    #plt=@map updateButton(&update)
    on(updatePlot,obsTick)
    #plt=Interact.@map &update
    #plt=Observables.@map &update
    #global plt
    global x 
    global y
    xString="["
    wdg = Widget(["update" => update,"currPlot" => updatePlot])
    @layout! wdg hbox(:update,:currPlot)
end
obsTick=Observable(0)
plt=plot()
w=Window()
body!(w, interface())
for t in 1:100
    sleep(3)
    obsTick[]=t
    push!(x,t)
    push!(y,3*t)
end
sleep(60)