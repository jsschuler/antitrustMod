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
@everywhere using Random
@everywhere using StatsBase
@everywhere using Distributions
@everywhere using Plots
@everywhere using JLD2
@everywhere using Statistics
#Random.seed!(1234)
Random.seed!(123)

@everywhere include("globals.jl")
@everywhere include("agentInit.jl")
#include("objects.jl")
#include("functions.jl")
@everywhere include("searchMod.jl")
# test functions
#alphaTest=alphaGen(.4,10.0)
#alphaTest=alphaGen(.2,5.0)
#alphaTest=alphaGen(.9,1.3)



#agentMod.agentGen(privacyBeta)

#println(util(agtList[1],3.0))
#println(util(agtList[1],13.0))
#println(util(agtList[1],agtList[1].blissPoint-.05))
#println(util(agtList[1],agtList[1].blissPoint))
#println(util(agtList[1],agtList[1].blissPoint+0.05))

#searchList=searchEngine[]
#time=1
#googleGen()
#duckGen()
#println(typeof(searchList[1]))
#println(fieldnames(Google))
#searchList[1].revenue[time]=0
#for t in 1:1000
#    search(agtList[1],searchList[1])
#end
#println(searchList[1].revenue)

# now it is time to build the main model 

# Step 0: Initialize all agents, Initialize Google and set the tick on which Duck Duck Go will enter 
#agtList=agent[]
#for i in 1:agtCnt
#    agentGen()
#end

#addprocs(16)
#check(1)
#pmap(check,[1])
#agtList=pmap(agentMod.agentGen,1:agtCnt,repeat([privacyBeta],agtCnt))
# now generate a dictionary that points the agent number to the agent. 



#println(agtList)
# now save agents for later use
#save_object("myAgents.jld2", agtList)
# now try loading
agtList=load_object("myAgents.jld2")

agtDict::Dict{Int64,agentMod.agent}=Dict{Int64,agentMod.agent}()
for agt in agtList
    agtDict[agt.agtNum]=agt
end
#println(agtList)

searchList=searchEngine[]
# initialize Google 
googleGen()

# now, at what time do we initialize Duck Duck Go?
duckTime::Int64=5



#println("All searches")
#println(length(searchList))
# initialize search engine to Google for all agents 
for agt in agtList
    agt.currEngine=searchList[1]
    agt.prevEngine=searchList[1]
end


modTime::Int64=10
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
    for agt in agtList
        searchCount::Int64=100+rand(searchCountDist,1)[1]
        #println(searchCount)
        for k in 1:searchCount
            #println("Searching")
            push!(searchAgtVector,agt)
            push!(engineList,agt.currEngine)
            push!(timeVec,time)
            #println(search(agt,agt.currEngine,time))
        end    
    end
    # now run the parallel search process
    println("Searching at time: "*string(time))
    searchRes=pmap(search,searchAgtVector,engineList,timeVec)
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
for agt in agtList
    println(agt.history)
end
println(length(keys(searchList[1].revenue)))
println(length(keys(searchList[2].revenue)))