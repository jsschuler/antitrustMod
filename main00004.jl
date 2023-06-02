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

# Update: did I do this? 
# There is still some weirdness around agents sharing data with their own search engine



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

include("graphPlot.jl")
include("modelFunctions.jl")
include("displayFunctions.jl")

# now, we need afour of global dictionaries 
currentActDict=Dict{agent,Union{Nothing,Null,action}}()
scheduleActDict=Dict{agent,Union{Nothing,Null,action}}()
deletionDict=Dict{agent,Bool}()
sharingDict=Dict{agent,Bool}()


# initialize all agents actions to nothing
for agt in agtList
    currentActDict[agt]=nothing
    scheduleActDict[agt]=nothing
    deletionDict[agt]=false
    sharingDict[agt]=false
end
# we need an array to store the already generated structs to avoid redefining them 
structTuples=Set([])


tick=0
for ticker in 1:modRuns
    # principle 1: agents search no matter what 
    global tick
    tick=tick + 1
    # Step 0: new laws or search engines are introduced.
     # first, introduce any new laws or search engines 
     if tick==10
        #println("DuckDuckGo In")
        duckGen()
        @actionGen()
    end
    #println("Tick")
    #println(tick)
    # now introduce new laws if applicable 
    if tick==15
        #println("VPN In")
        #vpnGen(tick)
        #@actionGen()
    end
    #println("Tick")
    #println(tick)
    if tick==20
        #println("Deletion In")
        #deletionGen(tick)
        #@actionGen()
    end
    #println("Tick")
    #println(tick)
    if tick==16
        #println("Sharing In")
        sharingGen(tick)
        @actionGen()
    end
    #println("Action List")
    #println(length(actionList))
    
    # Step 1: agents previously scheduled to act take action
    # some of these agents were chosen exogenously, 
    # some because they were neighbors of agents that did act 
    for agt in agtList
        takeAction(agt)
    end

    # now, some agents are chosen exogenously to act next time
    exogenousActs()
    # Step 2: agents search 

    allSearches(tick)

    # Step 3: agents decide to reverse the action or not
    for agt in agtList
        reverseDecision(agt)
    end
    # now, make the next tick's dictionary the current one
    #schedulePrint(currentActDict)
    #schedulePrint(scheduleActDict)
    resetSchedule()
    # now plot data
    svgGen(tick)
end
println("Deletion")
for k in keys(deletionDict)
    println(deletionDict[k])
end
println("Sharing")
for k in keys(sharingDict)
    println(sharingDict[k])
end