# now, the takeAction function

function takeAction(agt::agent)
    global currentActDict
    global scheduleActDict

    if isnothing(currentActDict[agt])
        return false
    else
        currAct=currentActDict[agt]
        beforeAct(agtcurrAct,)
        # now, schedule actions for neighbors 
        global agtGraph
        neighborNums=collect(neighbors(agtGraph,currAgt.agtNum))
        agtVec=agent[]
        for n in neighborNums
            push!(agtVec,agtList[n])
        end
        # now, if the agent was previously scheduled to act next time
        # we do not overwrite this assignment 
        for agt in agtVec
            if isnothing(scheduleActDict[agt])
                scheduleActDict[agt]=currAct
            end
        end
        return true
    end
end

function exogenousActs()
    global actionList
    # pick a random number of agents to act
    if length(actionList)==0
        return false
    else
        println("Exogenous!")
        global poissonDist
        exogCnt=rand(poissonDist,1)[1]
        exogAgts=sample(agtList,min(exogCnt,length(agtList)),replace=false)
        # now, assign these agents actions if they do not already have them
        global actionList
        global scheduleActDict
        for agt in exogAgts
            if isnothing(scheduleActDict[agt])
                newAct=sample(actionList,1)[1]
                scheduleActDict[agt]=newAct
            end
        end
        return true
    end
end

function allSearches(tick)
    global agtCnt
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
end

function reverseDecision(agt::agent)
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

function resetSchedule()
    global currentActDict
    global scheduleActDict
    global agtList
    currentActDict=scheduleActDict
    for agt in agtList
        scheduleActDict[agt]=nothing
    end
end