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

include("globals.jl")
include("agentInit.jl")
include("searchMod.jl")

agtCnt=100
modelTicks=50
headStart=.2
ddTick=100
runBool::Bool=false
setup::Bool=false

ctrlList=[]
proceed::Bool=false
secondaryHalt::Bool=false

runState=Int64[]
runOnceState=Int64[]

# the start / stop button does two things:
# it changes the proceed bool to its negative 
# it sets the secondary halt boolean to negative 

# the run once button 
# sets the secondary halt boolean to be positive 

# thus, the run state means:
    # proceed=true 
    # secondaryHalt=false 
# the halt state means:
    # proceed=false 
    # secondaryHalt=false 
# the run once state means:
    # proceed=true 
    # secondary Halt=true


function interface()
    privacyPref = slider(1.1:50.0, label = "Privacy Preference")
    agentCount = slider(10:1:200, label = "Agent Count")
    allTicks =slider(1:1:100,label="Model Ticks")
    learningTicks = slider(0.0:.01:1.0, label = "Google Head Start")
    genAgt=button("Generate Agents")
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
println("Proceeding to Generate Agents")
# we need a function that says wait for agents
plt2=plot(grid=false,axis=([],false));
plt2=annotate!(.5, .5, "Please Wait for Agents to Generate", :blue);
wdg2 = Widget()
body!(w, @layout! wdg2 hbox(plt2))
# we need a function that displayes the agents 
runInterface=function()
    global agtList 
    privacyPref=Float64[]
    for agt in agtList
        push!(privacyPref,agt.privacy)
    end
    # now introduce model controls
    runMod=button("Setup Model")

    runStatus=function(status)
        if status > 0
            global runBool
            runBool=true
        end
        return nothing
    end

    Interact.@map runStatus(&runMod)


    wdg3 = Widget(["runMod" => runMod])
    plt3=histogram(privacyPref)
    @layout! wdg3 hbox(plt3,:runMod)
end

# now generate agents 
# Step 0: Initialize all agents, Initialize Google and set the tick on which Duck Duck Go will enter 
agtList=agentMod.agent[]
for i in 1:agtCnt
    push!(agtList,agentMod.agentGen(i,privacyBeta))
    
end
agtDict::Dict{Int64,agentMod.agent}=Dict{Int64,agentMod.agent}()
for agt in agtList
    agtDict[agt.agtNum]=agt
end

searchList=searchEngine[]
# initialize Google 
googleGen()

function waitTime2()
    while true
        #println("Run Status")
        global runBool
        #println(runBool)
        
        if ! runBool
            sleep(1)
        else
            break
        end
    end
    #println("ahoy!")
    return nothing
end
println("Agents Generated")
body!(w,runInterface())
waitTime2();
# now get into the main model

# first, we need plots, 


# the visuals are the search length quantiles (line plots)

# and the Google Duck Duck Go shares (pie chart and line plot)

# also search volume on both  
for agt in agtList
    agt.currEngine=searchList[1]
    agt.prevEngine=searchList[1]
end

# prepare to collect data on percentile uses 
googleTimeTicker=Int64[]
duckTimeTicker=Int64[]
googleAgentTicker=Int64[]
duckAgentTicker=Int64[]
googleSearchTicker=Int64[]
duckSearchTicker=Int64[]
googlePercentileTracker5=Float64[]
googlePercentileTracker25=Float64[]
googlePercentileTracker50=Float64[]
googlePercentileTracker75=Float64[]
googlePercentileTracker95=Float64[]

duckPercentileTracker5=Float64[]
duckPercentileTracker25=Float64[]
duckPercentileTracker50=Float64[]
duckPercentileTracker75=Float64[]
duckPercentileTracker95=Float64[]

# we need the model set up setup interface 

# now, we display the end of tick report 
function tickInterface(plotPop::Bool)
    runButton=button("Start")
    runOnceButton=button("Run Once")
    runFunction=function(status)
        println("Run Status")
        println(status)
        global proceed
        global secondaryHalt
        println("control")
        println(ctrlList)
        push!(ctrlList,status)
        println("Max")
        println(maximum(ctrlList))
        if maximum(ctrlList) > 0 
            proceed=true
            secondaryHalt=false
        end
        return nothing
    end

    #runOnceFunction=function(status)
    #    #global runOnceState
    #    #push!(runOnceState,status)
    #    global proceed 
    #    proceed=true 
    #    global secondaryHalt
    #    secondaryHalt=false
    #    return nothing
    #end

    Interact.@map runFunction(&runButton)
    #Interact.@map runOnceFunction(&runOnceButton)
    #println(agtCnt)

    if plotPop
        # we need to generate the plots 
        # there are four plots 
        # the agent count plot using Google vs Duck Duck Go 
        agtPlot=plot(googleTimeTicker,googleAgentTicker)
        plot!(agtPlot,duckTimeTicker,duckAgentTicker)
        # the search count plot Google vs Duck Duck Go
        countPlot=plot(googleTimeTicker,googleSearchTicker)
        plot!(countPlot,duckTimeTicker,duckSearchTicker)
        # the google quantile plot 
        googleQuantilePlot=plot(googleTimeTicker,[googlePercentileTracker5,googlePercentileTracker25,googlePercentileTracker50,googlePercentileTracker75,googlePercentileTracker95])
        # the duck duck go quantile plot
        duckQuantilePlot=plot(duckTimeTicker,[duckPercentileTracker5,duckPercentileTracker25,duckPercentileTracker50,duckPercentileTracker75,duckPercentileTracker95])
    else
        # we need to generate the plots 

        # there are four plots 
        # the agent count plot using Google vs Duck Duck Go 
        agtPlot=plot()
        
        # the search count plot Google vs Duck Duck Go
        countPlot=plot()
        
        # the google quantile plot 
        googleQuantilePlot=plot()
        # the duck duck go quantile plot
        duckQuantilePlot=plot()


    end
    
    wdg = Widget(["runButton" => runButton, "runOnceButton" => runOnceButton ])
    @layout! wdg vbox(hbox(:runButton,:runOnceButton),hbox(agtPlot,countPlot,googleQuantilePlot,duckQuantilePlot))
end
body!(w,tickInterface(false))


for time in 1:modelTicks
    println("tick")
    println(time)
    while true
        if  !proceed
            println("Not Allowed to Go :-(")
            sleep(1)
        else
            break
        end
    end    
    #println("tick is"*string(time))
    # initialize Duck Duck Go if it is time
    if time==duckTime
        duckGen()
    end
    agtTicks=Float64[]
    googTicks=Float64[]
    duckTicks=Float64[]

    # initialize histories 
    #for agt in agtList
    #    agt.history[time]=0.0
    #end
    global searchList
    for engine in searchList
        engine.revenue[time]=0
    end
    # some Poisson number of agents try a different search engine if one is available. 
    if length(searchList) > 1
        #println("Switching at time: "*string(time))
        switchAgents::Array{agentMod.agent}=sample(agtList,min(rand(poissonDist,1)[1],length(agtList)),replace=false)
        for agt in switchAgents
            # The agent chooses a search engine at randon aside from the one it is using 
            choices::searchEngine=sample(collect(setdiff(Set(searchList),Set([agt.currEngine]))),1)[1]
            agt.prevEngine=agt.currEngine
            agt.currEngine=choices
        end
    end
    # all agents search 


    googleUser=0
    duckUser=0
    googleSearchCnter=0
    duckSearchCnter=0

    googleSearchTimer=Int64[]
    duckSearchTimer=Int64[]

    for agt in agtList
        if string(typeof(agt.currEngine))=="Google"
            googleUser=googleUser+1
        else
            duckUser=duckUser+1
        end
        agtHist=Int64[]
        #agt.history[time]=Float64[]
        searchCount::Int64=100+rand(searchCountDist,1)[1]
        for k in 1:searchCount
            searchRes=search(agt,agt.currEngine,time)
            currAgt=agtDict[searchRes[1]]
            push!(agtHist,searchRes[2])
            finGuess=searchRes[3]
            newRevenue=searchRes[4]
            searchUpdate(currAgt.currEngine,currAgt,finGuess)
            # update profit
            currAgt.currEngine.revenue[time]=currAgt.currEngine.revenue[time]+newRevenue
            #println("Agent: "*string(agt.agtNum)*" is searching for the "*string(k)*"th time")
            if string(typeof(agt.currEngine))=="Google"
                googleSearchCnter=googleSearchCnter+1
                push!(googleSearchTimer,searchRes[2])
            else
                duckSearchCnter=duckSearchCnter+1
                push!(duckSearchTimer,searchRes[2])
            end
        agt.history[time]=mean(agtHist)
        end    

        

    end
    # did any agents use Google?
    if googleUser > 0
        push!(googleTimeTicker,time)
        push!(googleAgentTicker,googleUser)
        push!(googleSearchTicker,googleSearchCnter)
        googQuantiles=quantile(googleSearchTimer,[.05,.25,.5,.75,.95])
        push!(googlePercentileTracker5,googQuantiles[1])
        push!(googlePercentileTracker25,googQuantiles[2])
        push!(googlePercentileTracker50,googQuantiles[3])
        push!(googlePercentileTracker75,googQuantiles[4])
        push!(googlePercentileTracker95,googQuantiles[5])
    end

    if duckUser > 0
        push!(duckTimeTicker,time)
        push!(duckAgentTicker,duckUser)
        push!(duckSearchTicker,duckSearchCnter)
        duckQuantiles=quantile(duckSearchTimer,[.05,.25,.5,.75,.95])
        push!(duckPercentileTracker5,duckQuantiles[1])
        push!(duckPercentileTracker25,duckQuantiles[2])
        push!(duckPercentileTracker50,duckQuantiles[3])
        push!(duckPercentileTracker75,duckQuantiles[4])
        push!(duckPercentileTracker95,duckQuantiles[5])
    end

    # now run the parallel search process
    #println("Searching at time: "*string(time))
    #searchRes=pmap(search,searchAgtVector,engineList,timeVec)
    #println(searchRes[1])
    # if they prefer it, they keep using it. 
    # now, compute results 
    #println("Updating at time: "*string(time))

    # now agents decide whether to keep their new search engine 
    for agt in agtList
        #println(agt.currEngine)
        #println(agt.prevEngine)
        #println(agt.currEngine != agt.prevEngine)
        if agt.currEngine != agt.prevEngine
            # does the agent prefer its current engine?
            #println(time)
            println("Agent")
            println(agt.agtNum)
            println("History")
            println(agt.history)
            if agentMod.util(agt,mean(agt.history[time])) > agentMod.util(agt,mean(agt.history[time-1]))
                agt.prevEngine=agt.currEngine
            else 
                agt.currEngine=agt.prevEngine
            end
        end
    end
    # now output Window
    body!(w,tickInterface(true))
    # and halt if running once
    while true
        if  secondaryHalt
            println("Being Held Up Here")
            sleep(1)
        else
            break
        end
    end    
end