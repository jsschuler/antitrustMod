cores=16
using Distributed
using Combinatorics
@everywhere using DataFrames
@everywhere using Distributions
@everywhere using InteractiveUtils
@everywhere using Graphs 
@everywhere using Random
@everywhere using JLD2
@everywhere using Dates
# this code runs the parameter sweep

# declare global variables 
@everywhere begin 
    privacyVal::Float64=0.1
    privacyBeta::Beta{Float64}=Beta(1.0,privacyVal)
    # how close does the offered search result have to be before the agent accepts it?
    searchResolution::Float64=.05
    # we need a Poisson process for how many agents act exogenously 
    switchPct::Float64=.2
    agtCnt::Int64=100
    # set the Graph structure
    pctConnected::Float64=.2
    expDegree::Int64=floor(Int64,pctConnected*agtCnt)
    β::Float64=.5
    agtGraph=watts_strogatz(agtCnt, expDegree, β)
    # Finally, we need a Poisson parameter to how much agents search
    searchQty=Poisson{Int64}(4.0)
end


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

@everywhere begin
    currentActDict=Dict{agent,Union{Nothing,Null,action}}()
    scheduleActDict=Dict{agent,Union{Nothing,Null,action}}()
    deletionDict=Dict{agent,Bool}()
    sharingDict=Dict{agent,Bool}()
end




function ParameterSweep(paramVec)
    Random.seed!(paramVec[2])

    privacyVal=paramVec[5]
    global privacyBeta=Beta(1.0,privacyVal)
    # how close does the offered search result have to be before the agent accepts it?
    global searchResolution=paramVec[6]
    # we need a Poisson process for how many agents act exogenously 
    global switchPct=paramVec[7]
    global agtCnt=paramVec[8]
    # set the Graph structure
    global pctConnected=paramVec[9]
    global expDegree=floor(Int64,pctConnected*agtCnt)
    global β=paramVec[10]
    global agtGraph=watts_strogatz(agtCnt, expDegree, β)
    # Finally, we need a Poisson parameter to how much agents search
    global searchQty=Poisson{Int64}(paramVec[11])

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
    order=paramVec[12]
    modRuns=100
    tickIntros=rand(DiscreteUniform(1,100),length(order))
    tickIntros=tickIntros[[order]]
    duckTick=tickIntros[1]
    vpnTick=tickIntros[2]
    deletionTick=tickIntros[3]
    sharingTick=tickIntros[4]
    

    Random.seed!(paramVec[3])

    key=paramVec[4]
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
        #svgGen(tick)
        # now save data

    end
    return key
end

# now generate the data structure for the parameter sweep

sweeps=20
reps=5

# generate a seed 
seed1=sort(repeat(rand(DiscreteUniform(1,10000),sweeps),reps))
seed2=rand(DiscreteUniform(1,10000),sweeps*reps)

# how many agents care a lot about privacy?
# higher value means fewer care 
privacyValVec=sort(repeat(rand(Uniform(1.1,30),sweeps),reps))
#privacyBeta=Beta.(1.0,privacyVal)
# how close does the offered search result have to be before the agent accepts it?
searchResolutionVec=repeat([.05],sweeps*reps)
# we need a Poisson process for how many agents act exogenously 
switchPctVec=sort(repeat(rand(Uniform(0.01,0.2),sweeps),reps))
agtCntVec=sort(repeat(rand(DiscreteUniform(1000,1000),sweeps),reps))
#poissonDist=sort(repeat(Poisson.(switchPct.*agtCnt),reps))
# and a probability distribution for how much agents search 
# set the Graph structure
pctConnectedVec=sort(repeat(rand(Uniform(.05,.25),sweeps),reps))
expDegreeVec=sort(repeat(floor.(Int64,pctConnected.*agtCntVec),reps))
βVec=sort(repeat(rand(Uniform(0.05,.5),sweeps),reps))

# Finally, we need a Poisson parameter to how much agents search
searchQtyVec=sort(repeat(rand(Uniform(5,100),sweeps),reps))


currTime=now()

ctrlFrame=DataFrame()
ctrlFrame[!,"dateTime"]=repeat([currTime],sweeps*reps)
ctrlFrame[!,"seed1"]=seed1
ctrlFrame[!,"seed2"]=seed2
ctrlFrame[!,"key"]=string.(repeat([currTime],sweeps*reps)).*"-".*string.(seed1) .*"-".*string.(seed2).*"-"
ctrlFrame[!,"privacyVal"]=privacyValVec
ctrlFrame[!,"searchResolution"]=searchResolutionVec
ctrlFrame[!,"switchPct"]=switchPctVec
ctrlFrame[!,"agtCnt"]=agtCntVec
ctrlFrame[!,"pctConnected"]=pctConnectedVec
ctrlFrame[!,"expDegree"]=expDegreeVec
ctrlFrame[!,"β"]=βVec
ctrlFrame[!,"searchQty"]=searchQtyVec



# now, we need to determine the behavior

#global duckTick=paramVec[6]
#global vpnTick=paramVec[7]
#global deletionTick=paramVec[8]
#global sharingTick=paramVec[9]


# rule: sharing must come after Duck Duck Go
# duck duck go always enters eventually 
# thus, we choose the combinations of vpn, deletion, sharing
# thus, enumerate the combinations
# Duck Duck Go: 1 
# vpn :2
# deletion :3 
# sharing :4
introCombos=lpad.(string.(1:1:2^4, base = 2),4,"0")

allOrders=[]
for combo in introCombos
    currOrder=[]
    for k in 1:length(combo)
        #println(SubString(combo,k,k))
        if SubString(combo,k,k)=="1"
            push!(currOrder,k)
        end
    end
    for perm in  collect(permutations(currOrder))
        push!(allOrders,perm)
    end
end

remDex=[]
for i in 1:length(allOrders)
    # check if it contains sharing =4 
    # and Duck Duck Go=1
    duckGo=false
    share=false
    duckIdx=0
    shareIdx=0
    
    for j in 1:length(allOrders[i])
        
        if allOrders[i][j]==1
            duckGo=true
            duckIdx=j
            println("Hit1")
        elseif allOrders[i][j]==4
            share=true
            shareIdx=j
            println("Hit4")
        else
            nothing
        end
        println(allOrders[i][j])
    end

    if duckGo & share & (shareIdx < duckIdx)
        push!(remDex,i)
        println("Hit!")

    end

end

splice!(allOrders,remDex)
allOrders=tuple.(allOrders)
orderFrame=DataFrame(allOrders)
rename!(orderFrame,:1 => :order)
# now join these 
ctrlFrame=crossjoin(ctrlFrame,orderFrame)
ctrlFrame.key=ctrlFrame.key.*string.(1:size(ctrlFrame)[1])
ctrlFrame[!,"complete"]=repeat([false],size(ctrlFrame)[1])
# now shuffle the frame so partial runs are more useful
shuffle!(ctrlFrame)

# now, we have 16 cores 
t=0
coreDict=Dict()
for k in 2:cores
    coreDict[k]=nothing
end

while true
    if size(ctrlFrame[ctrlFrame[:,"complete"].==false,:])[1]==0
        break
    end
    t=t+1
    for c in 2:cores
        if isnothing(coreDict[c])
            ctrlWorking=ctrlFrame[ctrlFrame[:,"complete"].==false,:]
            @spawnat c ParameterSweep(ctrlWorking[1,:])

        elseif isready(coreDict[c])
            res=fetch(coreDict[c])
            ctrlWorking=ctrlFrame[ctrlFrame[:,"complete"].==false,:]
            @spawnat c ParameterSweep(ctrlWorking[1,:])
            ctrlFrame[ctrlFrame.key.==res,:complete].=true
        end
    end
end