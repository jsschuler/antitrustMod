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




include("globals.jl")
include("agentInit.jl")
#include("objects.jl")
#include("functions.jl")
include("searchMod.jl")





# now it is time to build the main model 

# Step 0: Initialize all agents, Initialize Google and set the tick on which Duck Duck Go will enter 
agtList=agentMod.agent[]
for i in 1:agtCnt
    agentMod.agentGen(i,privacyBeta)
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

for mod in 1:modRuns
    # seed new seed
    Random.seed!(modSeeds[mod])
    # now, for each tick 
    for time in 1:modTime
        # initialize Duck Duck Go if it is time
        if time==duckTime
            duckGen()
        end

        # initialize histories 
        for agt in agtList
            agt.history[time]=Int64[]
        end

        for engine in searchList
            engine.revenue[time]=0
        end
    # some Poisson number of agents try a different search engine if one is available. 
        if length(searchList) > 1
            println("Switching at time: "*string(time))
            switchAgents::Array{agentMod.agent}=sample(agtList,rand(poissonDist,1)[1],replace=false)
            for agt in switchAgents
                # The agent chooses a search engine at randon aside from the one it is using 
                choices::searchEngine=sample(collect(setdiff(Set(searchList),Set([agt.currEngine]))),1)[1]
                agt.prevEngine=agt.currEngine
                agt.currEngine=choices
            end
        end
        # all agents search 

        searchAgtVector::Array{agentMod.agent}=agentMod.agent[]
        engineList::Array{searchEngine}=searchEngine[]
        timeVec::Array{Int64}=Int64[]


        searchAgtVector=agentMod.agent[]
        engineList=searchEngine[]
        timeVec=Int64[]
        searchRes=[]
        for agt in agtList
            searchCount::Int64=100+rand(searchCountDist,1)[1]
            #println(searchCount)
            for k in 1:searchCount
                #println("Searching")
                push!(searchAgtVector,agt)
                push!(engineList,agt.currEngine)
                push!(timeVec,time)
                push!(searchRes,search(agt,agt.currEngine,time))
            end    
        end
        # now run the parallel search process
        #println("Searching at time: "*string(time))
        #searchRes=pmap(search,searchAgtVector,engineList,timeVec)
        #println(searchRes[1])
        # if they prefer it, they keep using it. 
        # now, compute results 
        println("Updating at time: "*string(time))
        for el in searchRes

            #Any[agt,tick,finGuess,newRevenue]
            #update search history with agent if applicable 
            currAgt=agtDict[el[1]]
            tick=el[2]
            finGuess=el[3]
            newRevenue=el[4]
            searchUpdate(currAgt.currEngine,currAgt,finGuess)
            # update profit
            currAgt.currEngine.revenue[time]=currAgt.currEngine.revenue[time]+newRevenue
            # update agent's utility history
            #println("time")
            #println(time)
            #println("tick")
            #println(tick)
            #println("Agent")
            #println(currAgt.agtNum)
            #println("Before History")
            #println(currAgt.history[time])

            push!(currAgt.history[time],tick)
            #println("After History")
            #println(currAgt.history[time])
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
    repFrame=DateFrame()
    agtSeedVec=Int64[]
    eventSeedVec=Int64[]
    tVec=Int64[]
    hVec=Int64[]
    searchVec=[]
    for agt in agtList
        for timer in keys(agt.history)
            agtSeedVec=cat(agtSeedVec,repeat([agtSeedVec],length(agt.history[timer])),dims=1)
            eventSeedVec=cat(eventSeedVec,repeat([modSeeds],length(agt.history[timer])),dims=1)
            agtNumVec=cat(repeat([agt.agtNum],length(agt.history[timer])),dims=1)
            tVec=cat(tVec,repeat([timer],length(agt.history[timer])),dims=1)
            hVec=cat(hVec,agt.history[timer],dims=1)
            searchVec=cat(searchVec,repeat([string(typeof(agt.currEngine))],length(agt.history[timer])),dims=1)
        end
        repFrame[!,"agtSeed"]=agtSeedVec
        repFrame[!,"modSeed"]=eventSeedVec
        repFrame[!,"agtNum"]=agtNumVec
        repFrame[!,"time"]=tVec
        repFrame[!,"history"]=hVec
        repFrame[!,"engine"]=searchVec
        if any(readdir().=="modOutput.csv") 
            CSV.write("modOutput.csv", repFrame,header = false,append=true)
        else 
            CSV.write("modOutput.csv", repFrame,header = true,append=false)
        end
        agt.history=Dict{Int64,Int64}()
        agt.currEngine=searchList[1]
        agt.prevEngine=searchList[1]
        histDict[agt]=Float64[]
    end

    for engine in searchList
        engine.revenue=Dict{Int64,Int64}()
    end 

    # Remove DuckDuckGo
    searchList=searchList[1:1]
end
#for agt in agtList
#    println(agt.history)
#end
#println(length(keys(searchList[1].revenue)))
#println(length(keys(searchList[2].revenue)))