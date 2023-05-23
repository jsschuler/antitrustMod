using Distributed
using Random
using StatsBase
using Distributions
using Plots
using JLD2
using Statistics
using DataFrames
using CSV
using StatsBase
using Interact
using Blink
import Colors
using Plots

# make a basic window with a plot

function interface()
    privacyPref = slider(1.1:50.0, label = "Privacy Preference")
    agentCount = slider(10:1:200, label = "Agent Count")
    allTicks =slider(1:1:100,label="Model Ticks")
    learningTicks = slider(0.0:.01:1.0, label = "Google Head Start")
    genAgt=button("Generate Agents")
    # store the agent count to the global variable
    
    agtCntSet=function(cnt)
    end

    modTicksSet=function(ticks)
    end

    headSet=function(hs)
    end

    buttonStatus=function(status)
        println("Please never push this button again")
        println(status)
        if status > 0
            global setup
            setup=true
        end
        return nothing
    end


    #Interact.@map agtCntSet(&agentCount)
    #Interact.@map modTicksSet(&allTicks)
    #Interact.@map headSet(&learningTicks)
    #Interact.@map buttonStatus(&genAgt)
    #println(agtCnt)


    # we need a function that takes in the privacy parameter and produces the plot
    privacyDensity=function(param)
        xArray=Array(0.0:.01:1.0)
        RV=Beta(1.0,param)
        tFunc=x -> pdf(RV,x)

        plot(xArray,tFunc.(xArray),title="Privacy Distribution")
    end
    plt=Interact.@map privacyDensity(&privacyPref)

    #update plot 
    function plotDate()
        #global pltTest 
        global x 
        global y
        pltTest=plot(x,y)
    return pltTest
    end

    pltTest=Interact.@map plotDate()


end

# make and display line plot
x=Array(1:10)
y=Array(1:10)
yObs=Observable(y)
plt=plot(x,y)
genAgt=button("Generate Agents")
wdg = Widget(["genAgt" => genAgt])
#global pltTest
@layout! wdg hbox(plt,:genAgt) ## custom layout: by default things are stacked vertically

w = Window()
w2=Window()
body!(w, wdg)
plot!(plt,x,Array[2:2:20])
obs1=Observable(x)


genAgt=button("Generate Agents")
