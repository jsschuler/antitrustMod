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


# We need two sets of vectors 
# nothing implies choose an act at random
nextAgt=agent[]
timeAfterAgent=agent[]

nextActs=Union{action,Nothing}[]
timeAfterActs=Union{action,Nothing}[]




include("graphPlot.jl")

println("Debug: Search Engine List ")
println(engineList)


for tick in 1:modRuns
    println("action test")
    println(length(actionList))

    # first, introduce any new laws or search engines 
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
    # second, if we are at least two ticks into the model, agents act 
    # to change their search behavior 


    if tick > 2
        # First, agents scheduled to act from the previous round act 
        # then, of the remaining agents who have not acted, some act exogenously 
        println("Acts")
        println(length(nextActs))
        println(length(nextAgt))
        println(length(actionList))
        if length(nextActs) > 0 & length(actionList) > 0
            while length(nextAgt) > 0
                currAgt=pop!(nextAgt)
                currAct=pop!(nextActs)
                println("debug")
                println(currAct)
                if isnothing(currAct)
                    # select an action at random
                    currAct=sample(actionList,1)[1]
                    #println(currAct.engine)
                    beforeAct(currAgt,currAct)
                else
                    beforeAct(currAgt,currAct)
                end
            # now what are the neighbors of the agent? 
            neighborNumbers=collect(neighbors(agtGraph,currAgt.agtNum))
            println("Graph Info")
            println(neighborNumbers)
            global timeAfterAgent
            global timeAfterActs
                for i in neighborNumbers
                    push!(timeAfterAgent,agtList[i])
                    push!(timeAfterActs,currAct)
                end
            end
        end
    end 
    println("Arrays")
    println(timeAfterAgent)
    println(timeAfterActs)

    # now how many agents act exogenously the next time?
    if length(actionList) > 0
        exogCnt=rand(poissonDist,1)[1]
        exogAgts=sample(agtList,min(exogCnt,length(agtList)),replace=false)
        # stack these vectors 
        global timeAfterAgent
        global timeAfterActs
        for j in 1:length(exogAgts)
            push!(timeAfterAgent,exogAgts[j])
            push!(timeAfterActs,nothing)
        end
    end


    
    # now all agents search 
# have agents search 
    # randomize agt search amount 
    searchCnt=rand(searchQty,agtCnt)
    # randomize agent ordering
    searchOrder=sample(1:agtCnt,agtCnt,replace=false)
    for i in searchOrder
        # we need an array for how long it took
        searchWait=Int64[]
        #println(searchCnt[i])
        #println("searching")
        #println(agtList[i].agtNum)
        #println(typeof(agtList[i].currEngine))
        #println(typeof(agtList[i].prevEngine))
        searchRes=search(agtList[i],searchCnt[i])
        # now for each agent, we need to know the final target of the search result 
        for res in searchRes
        # update search engine records for the alias with the search target
            update(res[4],agtList[i].mask,agtList[i].currEngine)
            push!(searchWait,res[3])
        end
        # now update agent's history
        agtList[i].history[tick]=mean(searchWait)
    end

    # if agents prefer their search experience at this tick to that of the previous, they maintain it
    if tick > 2
        for agt in agtList
            if !isnothing(agt.lastAct)
                println("Comparison")
                result=util(agt,agt.history[tick]) > util(agt,agt.history[tick-1])
                if result
                    println("Behavior Change")
                    println(typeof(agt.currEngine))
                end
                afterAct(agt,result,agt.lastAct)
            end
        end

    end
    svgGen(tick)
    if length(actionList) > 0
        # now process the next acts and replace the current acts 
        # an agent undertakes prefers to mimic another agent to act exogenously 
        finAgtVec=agent[]
        finActVec=Union{action,Nothing}[]

        for agt in Set(timeAfterAgent)
            aDex=findfirst(x->x==agt,timeAfterAgent)
            actDex=timeAfterActs[aDex]
            if !isnothing(actDex)
                push!(finAgtVec,agt)
                push!(finActVec,timeAfterActs[aDex])
            end
        end
        # now find any remaining agents who need to act
        remnants=collect(setdiff(Set(timeAfterAgent),Set(finAgtVec)))
        for rm in remnants
            push!(finAgtVec,rm)
            push!(finActVec,nothing)
        end
        # now randomize order 
        ord=sample(1:length(finActVec),length(finActVec),replace=false)
        for k in ord 
            push!(nextAgt,finAgtVec[k])
            push!(nextActs,finActVec[k])
        end
        # now reset the holding pen for future actions
        timeAfterAgent=agent[]
        timeAfterActs=Union{action,Nothing}[]
    end
end