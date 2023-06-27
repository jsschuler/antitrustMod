
using Distributed


@everywhere using Distributions
@everywhere using InteractiveUtils
@everywhere using Graphs 
@everywhere using Random
@everywhere using JLD2
@everywhere using Dates
# this code runs the parameter sweep

@everywhere include("objects3.jl")

# now, all actions work through aliases. 
# if an agent decides to use a VPN, it simply generates a new alias. 
# if an agent requests deletion, it removes records of its alias from the search engine. 
# if an agent requests data sharing, it transfers its alias data to another search engine 


# initialize model
@everywhere include("initFunctions.jl")

# generate Google

@everywhere include("searchFunctions.jl")


@everywhere include("graphPlot.jl")
@everywhere include("modelFunctions.jl")
@everywhere include("displayFunctions.jl")



function ParameterSweep(paramVec)
    global privacyVal::Float64=paramVec[1]
    global privacyBeta::Beta{Float64}=Beta(1.0,privacyVal)
    # how close does the offered search result have to be before the agent accepts it?
    global searchResolution::Float64=.05
    # we need a Poisson process for how many agents act exogenously 
    global switchPct::Float64=paramVec[2]
    global agtCnt=paramVec[3]
    # and a probability distribution for how much agents search 
    global searchCountDist::NegativeBinomial{Float64}=NegativeBinomial(1.0,.1)
    # set the Graph structure
    global pctConnected=paramVec[4]
    global expDegree=floor(Int64,pctConnected*agtCnt)
    global β=.5
    global agtGraph=watts_strogatz(agtCnt, expDegree, β)
    # Finally, we need a Poisson parameter to how much agents search
    global searchQty=Poisson{Int64}(paramVec[5])

    # get a string to identify this run
    currTime=string(now())
    run(`mkdir ../antiTrustPlots/run$strSeed-$currTime`)


    # now, we need afour of global dictionaries 
    global currentActDict=Dict{agent,Union{Nothing,Null,action}}()
    global scheduleActDict=Dict{agent,Union{Nothing,Null,action}}()
    global deletionDict=Dict{agent,Bool}()
    global sharingDict=Dict{agent,Bool}()
    
    googleGen()

    # generate agents
    global agtList=agent[]
    genAgents()

    # initialize all agents actions to nothing
    for agt in agtList
        currentActDict[agt]=nothing
        scheduleActDict[agt]=nothing
        deletionDict[agt]=false
        sharingDict[agt]=false
    end
    # we need an array to store the already generated structs to avoid redefining them 
    structTuples=Set([])

    # order of introdudction, 

    # Duck Duck Go must be introduced before data sharing 

    global duckTick=paramVec[6]
    global vpnTick=paramVec[7]
    global deletionTick=paramVec[8]
    global sharingTick=paramVec[9]
    global modRuns=paramVec[10]


    tick=0
    for ticker in 1:modRuns
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
            #println("VPN In")
            vpnGen(tick)
            @actionGen()
        end
        #println("Tick")
        #println(tick)
        if tick==deletionTick
            #println("Deletion In")
            deletionGen(tick)
            @actionGen()
        end
        #println("Tick")
        #println(tick)
        if tick==sharingTick
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

end

# now generate the data structure for the parameter sweep

sweeps=1000

# how many agents care a lot about privacy?
# higher value means fewer care 
privacyVal=rand(Uniform(1.1,5),sweeps)
privacyBeta=Beta.(1.0,privacyVal)
# how close does the offered search result have to be before the agent accepts it?
searchResolution::Float64=.05
# we need a Poisson process for how many agents act exogenously 
switchPct=rand(Uniform(0.01,0.2),sweeps)
poissonDist=Poisson.(switchPct*agtCnt)
# and a probability distribution for how much agents search 
# set the Graph structure
pctConnected=rand(Uniform(.05,.25),sweeps)
expDegree=floor.(Int64,pctConnected*agtCnt)
β=rand(Uniform(0.05,.5),sweeps)
agtGraph=watts_strogatz.(agtCnt, expDegree, β)
# Finally, we need a Poisson parameter to how much agents search
searchQty=rand(Uniform(5,100),sweeps)
searchQtyVec=Poisson.(searchQty)


for s in 1:sweeps


end