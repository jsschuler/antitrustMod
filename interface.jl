###########################################################################################################
#            Antitrust Model Interactive Code                                                             #
#            January 2022                                                                                 #
#            John S. Schuler                                                                              #
#                                                                                                         #
#                                                                                                         #
###########################################################################################################

# first, this code must be comprehensive, meaning, it can handle the parameter sweep itself. 
# All data can be saved in Julia file structures. 


# for now, define the parameters

# each agent has two interest parameters which are the parameters for a beta random variable. 
# each agent also has a privacy parameter from 0 to 1. 


# now, the agent's utility is how long it has to wait to find what it searches for. 
# as some agents use the internet more than others, the activation scheme is usually Poisson. 
#using Distributed
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
#cd("/Users/johnschuler/Documents/Research/AntiTrust/Interface")
include("../antitrustMod/globals.jl")
include("../antitrustMod/agentInit.jl")
include("../antitrustMod/searchMod.jl")

agtCnt=100
modelTicks=50
headStart=.2
ddTick=100

setup::Bool=false

function interface()
    privacyPref = slider(1.1:50.0, label = "Privacy Preference")
    agentCount = slider(10:1:200, label = "Agent Count")
    allTicks =slider(1:1:100,label="Model Ticks")
    learningTicks = slider(0.0:.01:1.0, label = "Google Head Start")
    genAgt=button("Run Model")
    # store the agent count to the global variable
    
    agtCntSet=function(cnt)
        global agtCnt 
        agtCnt=cnt 
        #println("Setting Agent Count")
        #println(agtCnt)
    end

    modTicksSet=function(ticks)
        global modelTicks
        modelTicks=ticks
        #println("Setting Model Ticks")
        #println(modelTicks)
    end

    headSet=function(hs)
        global headStart
        global modelTicks
        headStart=hs
        #println("Setting Headstart")
        global ddTick
        ddTick=round(Int64,headStart*modelTicks)
        #println("Setting Entrance Tick")
        #println(ddTick)
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


    Interact.@map agtCntSet(&agentCount)
    Interact.@map modTicksSet(&allTicks)
    Interact.@map headSet(&learningTicks)
    Interact.@map buttonStatus(&genAgt)
    #println(agtCnt)


    # we need a function that takes in the privacy parameter and produces the plot
    privacyDensity=function(param)
        xArray=Array(0.0:.01:1.0)
        RV=Beta(1.0,param)
        tFunc=x -> pdf(RV,x)

        plot(xArray,tFunc.(xArray),title="Privacy Distribution")
    end
    plt=Interact.@map privacyDensity(&privacyPref)
    wdg = Widget(["privacyPref" => privacyPref, "agentCount" => agentCount, "allTicks" => allTicks,"learningTicks" => learningTicks,"genAgt" => genAgt])
    @layout! wdg hbox(plt,vbox(:privacyPref, :agentCount, :allTicks,:learningTicks,:genAgt)) ## custom layout: by default things are stacked vertically
end

function waitTime()
    while true
        global setup
        if ! setup
            sleep(1)
        else
            break
        end
    end
    #println("ahoy!")
    return nothing
end

w = Window()
body!(w, interface())
waitTime()
w = Window()
# we need a function that displayes the agents 
agtInterface=function()
    global agtList 
    privacyPref=Float64[]
    for agt in agtList
        push!(privacyPref,agt.privacy)
    end
    wdg = Widget()
    plt=histogram(privacyPref)
    @layout! wdg hbox(plt) 
end

# now generate agents 
# Step 0: Initialize all agents, Initialize Google and set the tick on which Duck Duck Go will enter 
agtList=agentMod.agent[]
for i in 1:agtCnt
    push!(agtList,agentMod.agentGen(i,privacyBeta))
    body!(w,agtInterface())
end

agtDict::Dict{Int64,agentMod.agent}=Dict{Int64,agentMod.agent}()
for agt in agtList
    agtDict[agt.agtNum]=agt
end
#println(agtList)

searchList=searchEngine[]
# initialize Google 
googleGen()
# now get into the main model

# the visuals are the search length quantiles (line plots)

# and the Google Duck Duck Go shares (pie chart and line plot)

# also search volume on both  
