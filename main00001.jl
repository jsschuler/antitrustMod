###########################################################################################################
#            Antitrust Model Main Code                                                                    #
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



include("globals.jl")
include("agentInit.jl")
#include("objects.jl")
#include("functions.jl")
include("searchMod.jl")





# now it is time to build the main model 

# Step 0: Initialize all agents, Initialize Google and set the tick on which Duck Duck Go will enter 
agtList=agentMod.agent[]
for i in 1:agtCnt
    push!(agtList,agentMod.agentGen(i,privacyBeta))
end

# we need a function that returns 99999.9 when there is a null mean 
function safeMean(array::Any[])
    if is.nan(mean(array)) 
        return 99999999.9
    else
        return mean(array)
    end
end


# now save agents for later use
#save_object("myAgents.jld2", agtList)
# now try loading
#agtList=load_object("myAgents.jld2")

agtDict::Dict{Int64,agentMod.agent}=Dict{Int64,agentMod.agent}()
for agt in agtList
    agtDict[agt.agtNum]=agt
end
#println(agtList)

searchList=searchEngine[]
# initialize Google 
googleGen()

# set action seeds 
modSeeds=rand(DiscreteUniform(1,10000),modRuns)


#println("All searches")
#println(length(searchList))
# initialize search engine to Google for all agents 
for agt in agtList
    agt.currEngine=searchList[1]
    agt.prevEngine=searchList[1]
end
outPut=DataFrame()
agtSeecVec=Int64[]
runSeedVec=Int64[]
modList=Int64[]
timeList=Int64[]
agtVec=Int64[]

googPct=Float64[]
searchCnt=Int64[]

q5 =Float64[]
q25=Float64[]
q50=Float64[]
q75=Float64[]
q95=Float64[]

qG5 =Float64[]
qG25=Float64[]
qG50=Float64[]
qG75=Float64[]
qG95=Float64[]

qD5 =Float64[]
qD25=Float64[]
qD50=Float64[]
qD75=Float64[]
qD95=Float64[]



for mod in 1:modRuns
    # seed new seed
    println("mod is"*string(mod))
    Random.seed!(modSeeds[mod])
    # now, for each tick 
    for time in 1:modTime
        println("tick is"*string(time))
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

        searchAgtVector::Array{agentMod.agent}=agentMod.agent[]
        engineVec::Array{Bool}=Bool[]
        timeVec::Array{Int64}=Int64[]


        searchAgtVector=agentMod.agent[]
        engineVec=Bool[]
        timeVec=Int64[]
        searchRes=Float64[]

        for agt in agtList
            searchCount::Int64=100+rand(searchCountDist,1)[1]
            println("Agent: "*string(agt.agtNum)*" is searching")
            allTicks=Int64[]
            gTicks=Int64[]
            dTicks=Int64[]
            for k in 1:searchCount
                #println("Agent: "*string(agt.agtNum)*" is searching for the "*string(k)*"th time")
                searchRes=search(agt,agt.currEngine,time)
                currAgt=agtDict[searchRes[1]]
                # save ticks
                push!(allTicks,searchRes[2])
                if string(typeof(agt.currEngine))=="Google"
                    push!(gTicks,searchRes[2])
                else
                    push!(dTicks,searchRes[2])
                end
                #push!(agt.history[time],tick)
                finGuess=searchRes[3]
                newRevenue=searchRes[4]
                searchUpdate(currAgt.currEngine,currAgt,finGuess)
                # update profit
                currAgt.currEngine.revenue[time]=currAgt.currEngine.revenue[time]+newRevenue
                


            end    
            
            #println("After History")
            #println(currAgt.history[time])

            #push!(agtVec,agt.agtNum)
            push!(agtTicks,safeMean(allTicks))
            push!(googTicks,safeMean(gTicks))
            push!(duckTicks,safeMean(dTicks))
            
            agt.history[time]=mean(allTicks)
            push!(engineVec,string(typeof(agt.currEngine))=="Google")
            

        end
        global agtSeed
        push!(agtSeecVec,agtSeed)
        global modSeeds
        push!(runSeedVec,modSeeds[mod])
        push!(modList,mod)
        push!(timeList,time)
        # now get sums and quantiles at each time
        push!(googPct,mean(engineVec))
        push!(searchCnt,length(engineVec))
        println("Debug")
        println(agtTicks)
        println(googTicks)
        println(duckTicks)
    
        push!(q5, quantile(agtTicks,[.05])[1])
        push!(q25,quantile(agtTicks,[.25])[1])
        push!(q50,quantile(agtTicks,[.5])[1])
        push!(q75,quantile(agtTicks,[.75])[1])
        push!(q95,quantile(agtTicks,[.95])[1])
    
        push!(qG5, quantile(googTicks,[.05])[1])
        push!(qG25,quantile(googTicks,[.25])[1])
        push!(qG50,quantile(googTicks,[.5])[1])
        push!(qG75,quantile(googTicks,[.75])[1])
        push!(qG95,quantile(googTicks,[.95])[1])
    
        push!(qD5, quantile(duckTicks,[.05])[1])
        push!(qD25,quantile(duckTicks,[.25])[1])
        push!(qD50,quantile(duckTicks,[.5])[1])
        push!(qD75,quantile(duckTicks,[.75])[1])
        push!(qD95,quantile(duckTicks,[.95])[1])
    
        # now run the parallel search process
        #println("Searching at time: "*string(time))
        #searchRes=pmap(search,searchAgtVector,engineList,timeVec)
        #println(searchRes[1])
        # if they prefer it, they keep using it. 
        # now, compute results 
        #println("Updating at time: "*string(time))


        outPut[!,"agtSeed"]=agtSeecVec
        outPut[!,"runSeed"]=runSeedVec
        outPut[!,"mod"]=modList
        outPut[!,"time"]=timeList
        outPut[!,"googPct"]=googPct
        outPut[!,"searchCnt"]=searchCnt
        
        outPut[!,"g5"]= q5
        outPut[!,"q25"]=q25
        outPut[!,"q50"]=q50
        outPut[!,"q75"]=q75
        outPut[!,"q95"]=q95

        outPut[!,"qG5"]= qG5
        outPut[!,"qG25"]=qG25
        outPut[!,"qG50"]=qG50
        outPut[!,"qG75"]=qG75
        outPut[!,"qG95"]=qG95

        outPut[!,"qG5"]= qD5
        outPut[!,"qG25"]=qD25
        outPut[!,"qG50"]=qD50
        outPut[!,"qG75"]=qD75
        outPut[!,"qG95"]=qD95
        
        if any(readdir().=="modOutput.csv") 
            CSV.write("modOutput.csv", outPut,header = false,append=true)
        else 
            CSV.write("modOutput.csv", outPut,header = true,append=false)
        end


        # now agents decide whether to keep their new search engine 
        for agt in agtList
            #println(agt.currEngine)
            #println(agt.prevEngine)
            #println(agt.currEngine != agt.prevEngine)
            if agt.currEngine != agt.prevEngine
                # does the agent prefer its current engine?
                #println(time)
                if agentMod.util(agt,mean(agt.history[time])) > agentMod.util(agt,mean(agt.history[time-1]))
                    agt.prevEngine=agt.currEngine
                else 
                    agt.currEngine=agt.prevEngine
                end
            end
        end
        
    end
    # report all data and reset
    println("Resetting")
    repFrame=DataFrame()
    agtSeedVec=Int64[]
    eventSeedVec=Int64[]
    agtNumVec=Int64[]
    tVec=Int64[]
    hVec=Int64[]
    searchVec=[]


    for agt in agtList    
        agt.history=Dict{Int64,Int64}()
        agt.currEngine=searchList[1]
        agt.prevEngine=searchList[1]
        searchList[1].agentHistory[agt]=Float64[]
    end

    for engine in searchList
        engine.revenue=Dict{Int64,Int64}()
    end 

    # Remove DuckDuckGo
    global searchList
    searchList=searchList[1:1]
end
#for agt in agtList
#    println(agt.history)
#end
#println(length(keys(searchList[1].revenue)))
#println(length(keys(searchList[2].revenue)))