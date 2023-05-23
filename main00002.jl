###########################################################################################################
#            Antitrust Model Main Code                                                                    #
#            April 2022                                                                                   #
#            John S. Schuler                                                                              #
#            OECD Version                                                                                 #
#                                                                                                         #
###########################################################################################################

### ! the source of the bug is that agents who already use Google are still "switching"
## When they have an inferior run of luck, they switch back and get nothing as their search engine. 
# we need to make it so that agents only undertake actions different from what they 
# are currently doing. 
# also, change the VPN logic such that if an agent takes the action twice, they stop using a vpn 





### Model Description ####

# Agents have preferences for privacy meaning their bliss point is somewhere between the 
# expected wait time for a result given perfect information and the expected wait time for 
# a result given uniform information.

# agents also have a parameter  determining how often they "Act" (try a new search engine)
# The possible actions depend on the environment 
    # if a data sharing law is available, agents can copy their data across search engines 
    # if a data deletion rule is available, agents may delete their data 
    # agents can switch across any available search engines 

# agents are connected by a network. When an agent undertakes an action, adjacent agents in the network also try the action 
# and maintain it if they prefer it. 

# include global parameters
include("globals.jl")

# let's test some objects
include("objects3.jl")

# now, all actions work through aliases. 
# if an agent decides to use a VPN, it simply generates a new alias. 
# if an agent requests deletion, it removes records of its alias from the search engine. 
# if an agent requests data sharing, it transfers its alias data to another search engine 


# initialize model
include("initFunctions.jl")

# generate Google
googleGen()
include("searchFunctions.jl")
# generate agents
agtList=agent[]
genAgents()


# we need a vector of agents to act 
agtActVec=agent[]
# and a vector of nothing unioned with actions 
# nothing implies the agent chooses an action at random
actionVec=Union{action,Nothing}[]



include("graphPlot.jl")

println("Debug: Search Engine List ")
println(engineList)

for tick in 1:modRuns
    # First, have all agents set themselves up. 
    # this function gets rewritten depending on the actions the agents take
    for t in 1:modTime
        #println("Timing")
        #println(tick)
        #println(t)
        # have agents search 
        # randomize agt search amount 
        searchCnt=rand(searchQty,agtCnt)
        # randomize agent ordering
        searchOrder=sample(1:agtCnt,agtCnt,replace=false)
        for i in searchOrder
            # we need an array for how long it took
            searchWait=Int64[]
            #println(searchCnt[i])
            searchRes=search(agtList[i],searchCnt[i])
            # now for each agent, we need to know the final target of the search result 
            for res in searchRes
            # update search engine records for the alias with the search target
                update(res[4],agtList[i].mask,agtList[i].currEngine)
                push!(searchWait,res[3])
            end
            # now update agent's history
            agtList[i].history[t]=mean(searchWait)
        end
        
    end
    println("Loop Finished")
    println("Current Tick")
    println(tick)
    # now, agents decide whether to maintain their current behavior or revert
    if tick > 1
        println("I am running")
        for agt in agtList
            if !isnothing(agt.lastAct)
                println("Comparison")
                result=util(agt,agt.history[tick]) > util(agt,agt.history[tick-1])
                if result
                    println("Behavior Change")
                end
                afterAct(agt,result,agt.lastAct)
            end
        end
    end
    # now, introduce new search engines if applicable
    if tick==10
        println("DuckDuckGo In")
        duckGen()
        @actionGen()
    end
    println("Tick")
    println(tick)
    # now introduce new laws if applicable 
    if tick==15
        println("VPN In")
        vpnGen(tick)
        @actionGen()
    end
    println("Tick")
    println(tick)
    if tick==20
        println("Deletion In")
        deletionGen(tick)
        @actionGen()
    end
    println("Tick")
    println(tick)
    if tick==30
        println("Sharing In")
        sharingGen(tick)
        @actionGen()
    end
    println("Tick")
    println(tick)
    # now, run any scheduled agent actions from the previous step
    # we need a temporary array to hold the adjacent agents in the network
    # and their actions
    # if the same agent is the neighbor of more than one acting agent, we go 
    # with the first assigned action
    println("action list")
    println(length(actionList))
    if length(actionList) > 0
        tmpAgts=agent[]
        tmpActs=action[]
        while length(agtActVec) > 0
            currAgt=pop!(agtActVec)
            currAct=pop!(actionVec)
            if isnothing(currAct)
                # select an action at random
                currAct=sample(actionList,1)[1]
                beforeAct(currAgt,currAct)
            else
                beforeAct(currAgt,currAct)
            end
            # now, what are the neighbors of the current agent?
            neighborNumbers=collect(neighbors(agtGraph,currAgt.agtNum))
            agtNeighbors=agent[]
            for i in neighborNumbers
                push!(agtNeighbors,agtList[i])
            end
            # now, remove any agent already scheduled for an action 
            for prevAgt in tmpAgts
                filter!(x-> x==prevAgt,agtNeighbors)
            end
            actAdd=repeat([currAct],length(agtNeighbors))
            tmpAgts=vcat(tmpAgts,agtNeighbors)
            tmpActs=vcat(tmpActs,actAdd)
        end
        global agtActVec
        global actionVec
        agtActVec=tmpAgts
        for act in tmpActs
            push!(actionVec,act)
        end
        # now randomly select agents to act exogenously next time
        # how many agents should act?
        # how many agents aren't scheduled to act?
        newActCnt=min(rand(poissonDist,1)[1],agtCnt-length(agtActVec))
        remainingAgts=collect(setdiff(Set(agtList),Set(agtActVec)))
        newActAgts=sample(remainingAgts,newActCnt,replace=false)
        println("How many exogenous actions?")
        println(newActCnt)
        println("Who will Act Exogenously?")
        println(length(newActAgts))

        # now randomly select acts 
        newActs=sample(actionList,length(newActAgts),replace=true)
        # append these agents and actions to the vectors
        agtActVec=vcat(agtActVec,newActAgts)
        for act in newActs
            push!(actionVec,act)
        end  
        
        
    end
    svgGen(tick)
end