###########################################################################################################
#            Antitrust Model Parameter Sweep                                                              #
#            April 2022                                                                                   #
#            John S. Schuler                                                                              #
#            OECD Version                                                                                 #
#                                                                                                         #
###########################################################################################################
cores=2
using Distributed
using Combinatorics
@everywhere using CSV
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
    modeGen::Beta{Float64}=Beta(5,5)
    betaGen::Exponential{Float64}=Exponential(5)
    poissonDist::Poisson{Float64}=Poisson(.5)
    modRun::Int64=100

    duckTick=-10
    vpnTick=-10
    deletionTick=-10
    sharingTick=-10
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

@everywhere function loadParameters(paramVec)
    # create a file to hold data 
    
    Random.seed!(paramVec[2])
    global modeGen
    global key=paramVec[4]
    
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
    global searchQty=Poisson{Float64}(paramVec[11])
    global poissonDist=Poisson(switchPct*agtCnt)
    # get a string to identify this run
    currTime=string(now())
    #run(`mkdir ../antiTrustPlots/plot$key`)
    global modrun=paramVec[13]


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

    
    global seed2=paramVec[3]
    global key=paramVec[4]

    # now, given the model run count, determine ticks on which to enter laws and Duck Duck Go
    global orderVec=paramVec[14]
    tickIntros=rand(DiscreteUniform(1,100),length(orderVec))



    if 1 in orderVec
        global duckTick=tickIntros[orderVec.==1][1]
    else 
        global duckTick=-10
    end
    if 2 in orderVec
        global vpnTick=tickIntros[orderVec.==2][1]
    else
        global vpnTick=-10
    end
    if 3 in orderVec
        global deletionTick=tickIntros[orderVec.==3][1]
    else
        global deletionTick=-10
    end
    if 4 in orderVec
        global sharingTick=tickIntros[orderVec.==4][1]
    else
        global sharingTick=-10
    end

    # now save the order of entrance data
    
    orderCSV="../antiTrustData/order.csv"
    CSV.write(orderCSV, DataFrame([:Key => key,:Duck => duckTick, :VPN => vpnTick,:Delete => deletionTick,:Sharing => sharingTick]),header = false,append=true)
    return :parametersSet
end

sweeps=10
reps=1

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
agtCntVec=sort(repeat(rand(DiscreteUniform(100,100),sweeps),reps))
#poissonDist=sort(repeat(Poisson.(switchPct.*agtCnt),reps))
# and a probability distribution for how much agents search 
# set the Graph structure
pctConnectedVec=sort(repeat(rand(Uniform(.05,.25),sweeps),reps))
expDegreeVec=floor.(Int64,pctConnected.*agtCntVec)
βVec=sort(repeat(rand(Uniform(0.05,.5),sweeps),reps))

# Finally, we need a Poisson parameter to how much agents search
searchQtyVec=sort(repeat(rand(Uniform(5,100),sweeps),reps))
modRunVec=repeat([100],sweeps*reps)

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
#println("Debug")
#println(size(ctrlFrame))
#println(length(expDegreeVec))
ctrlFrame[!,"expDegree"]=expDegreeVec
ctrlFrame[!,"β"]=βVec
ctrlFrame[!,"searchQty"]=searchQtyVec
ctrlFrame[!,"modRun"]=modRunVec

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
            
        elseif allOrders[i][j]==4
            share=true
            shareIdx=j
            
        else
            nothing
        end
        println(allOrders[i][j])
    end

    if duckGo & share & (shareIdx < duckIdx)
        push!(remDex,i)
        

    end

end

splice!(allOrders,remDex)

#println(allOrders)

orderFrame=DataFrame(:order=>allOrders)

# now join these 
ctrlFrame=crossjoin(ctrlFrame,orderFrame)
ctrlFrame.key=ctrlFrame.key.*string.(1:size(ctrlFrame)[1])
ctrlFrame[!,"complete"]=repeat([false],size(ctrlFrame)[1])
# now shuffle the frame so partial runs are more useful
CSV.write("../antiTrustData/ctrl.csv", ctrlFrame,header = true,append=true)
shuffle!(ctrlFrame)

#now, we have 16 cores 
@everywhere t=0
@everywhere tick=0
@everywhere structTuples=Set([])


coreDict=Dict()
keyDict=Dict()
for k in 2:cores
    coreDict[k]=nothing
    keyDict[k]=nothing
end
t=0

while maximum(ctrlFrame.complete.==false)==true
    global t
    t=t+1
    for c in 2:cores
        if isnothing(coreDict[c])
            println("Initial Spawn")
            ctrlWorking=ctrlFrame[ctrlFrame[:,"complete"].==false,:]
            coreDict[c]=@spawnat c loadParameters(ctrlWorking[1,:])
            keyDict[c]=ctrlWorking[1,:key]

        elseif isready(coreDict[c])
            res=fetch(coreDict[c])
            if res==:parametersSet
                println("Spawn Main Model")
                coreDict[c]=@spawnat c include("orderGen.jl")
            elseif res==:final
                println("Clean Up")
                ctrlFrame[ctrlFrame.key.==keyDict[c],:complete].=true
                coreDict[c]=nothing
                keyDict[c]=nothing
            end
            
        end
    end
end