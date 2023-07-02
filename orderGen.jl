tick=0
for ticker in 1:modRun
    # principle 1: agents search no matter what 
    global tick
    tick=tick + 1
    # Step 0: new laws or search engines are introduced.
     # first, introduce any new laws or search engines 
     if tick==duckTick
        println("DuckDuckGo In")
        duckGen()
        @actionGen()
    end
    #println("Tick")
    #println(tick)
    # now introduce new laws if applicable 
    if tick==vpnTick
        println("VPN In")
        vpnGen(tick)
        @actionGen()
    end
    #println("Tick")
    #println(tick)
    if tick==deletionTick
        println("Deletion In")
        deletionGen(tick)
        @actionGen()
    end
    #println("Tick")
    #println(tick)
    if tick==sharingTick
        println("Sharing In")
        sharingGen(tick)
        @actionGen()
    end
    #println("Action List")
    #println(length(actionList))

    
    # Step 1: agents previously scheduled to act take action
    # some of these agents were chosen exogenously, 
    # some because they were neighbors of agents that did act 
    if tick > 1
        for agt in agtList
            takeAction(agt)
        end

        # now, some agents are chosen exogenously to act next time
        exogenousActs()
        # Step 2: agents search 
    end
        allSearches(tick)
    if tick > 1
        # Step 3: agents decide to reverse the action or not
        for agt in agtList
            reverseDecision(agt)
        end
        # now, make the next tick's dictionary the current one
        #schedulePrint(currentActDict)
        #schedulePrint(scheduleActDict)
        resetSchedule()

    end
    currCSV="../antiTrustData/output"*key*".csv"
    for agt in agtList
        vecOut=DataFrame(KeyCol=key,TickCol=tick,agtCol=agt.agtNum,agtEngine=typeof(agt.currEngine))
        # Create a CSV.Writer object for the file
        CSV.write(currCSV, vecOut,header = false,append=true)
    end
    # now plot data
    #svgGen(tick)
end
#println("Deletion")
#for k in keys(deletionDict)
#    println(deletionDict[k])
#end
#println("Sharing")
#for k in keys(sharingDict)
#    println(sharingDict[k])
#end

:modComplete