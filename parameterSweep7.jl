###########################################################################################################
#            Antitrust Model Parameter Sweep                                                              #
#            April 2022                                                                                   #
#            John S. Schuler                                                                              #
#            OECD Version                                                                                 #
#                                                                                                         #
###########################################################################################################
cores=8
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

# let's test some objects
@everywhere include("objects3.jl")

# now, all actions work through aliases. 
# if an agent decides to use a VPN, it simply generates a new alias. 
# if an agent requests deletion, it removes records of its alias from the search engine. 
# if an agent requests data sharing, it transfers its alias data to another search engine 


# initialize model
#@everywhere  include("initFunctions.jl")

# generate Google
#@everywhere googleGen()
#@everywhere  include("searchFunctions.jl")

#@everywhere include("graphPlot.jl")
#@everywhere include("modelFunctions.jl")
#@everywhere include("displayFunctions.jl")


sweeps=5
reps=1

# generate a seed 
seed1Vec=sort(repeat(rand(DiscreteUniform(1,10000),sweeps),reps))
seed2Vec=rand(DiscreteUniform(1,10000),sweeps*reps)

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
expDegreeVec=floor.(Int64,pctConnectedVec.*agtCntVec)
βVec=sort(repeat(rand(Uniform(0.05,.5),sweeps),reps))

# Finally, we need a Poisson parameter to how much agents search
searchQtyVec=sort(repeat(rand(Uniform(5,100),sweeps),reps))
modRunVec=repeat([100],sweeps*reps)

currTime=now()

ctrlFrame=DataFrame()
ctrlFrame[!,"dateTime"]=repeat([currTime],sweeps*reps)
ctrlFrame[!,"seed1"]=seed1Vec
ctrlFrame[!,"seed2"]=seed2Vec
ctrlFrame[!,"key"]=string.(repeat([currTime],sweeps*reps)).*"-".*string.(seed1Vec) .*"-".*string.(seed2Vec).*"-"
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
        #println(allOrders[i][j])
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
ctrlFrame[!,"initialized"]=repeat([false],size(ctrlFrame)[1])
ctrlFrame[!,"complete"]=repeat([false],size(ctrlFrame)[1])
# now shuffle the frame so partial runs are more useful
#CSV.write("../antiTrustData/ctrl.csv", ctrlFrame,header = true,append=true)
println(ctrlFrame)

# now, we need a pair of functions to pull top incomplete ctrlRow

coreDict=Dict()
keyDict=Dict()
for k in 2:cores
    coreDict[k]=nothing
    keyDict[k]=nothing
end
@everywhere paramVec=[]
function firstRow()
    global ctrlFrame
    ctrlWorking=ctrlFrame[ctrlFrame[:,:initialized].==false,:]
    paramVec=ctrlWorking[1,:]
    currKey=paramVec[4]
    ctrlFrame[ctrlFrame.key.==currKey,:initialized].=true
return paramVec

end

@everywhere function pullFirst()
    global paramVec
    paramVec=fetch(@spawnat 1 firstRow())
    return :rowLoad
end

testT=0
while testT <20
    global testT
    testT=testT+1
    for c in 2:cores
        if isnothing(coreDict[c])
            coreDict[c]=@spawnat c pullFirst()
            ctrlWorking=ctrlFrame[ctrlFrame[:,:initialized].==false,:]
            currKey=ctrlWorking[1,:key]
            keyDict[c]=currKey

        elseif isready(coreDict[c])
            res=fetch(coreDict[c])
            println(res)
            if res==:rowLoad
                # load global parameters from paramVec
                # set first seed 
                # generate agents
                coreDict[c]=@spawnat c include("paramLoad.jl")
            elseif res==:agtGen 
                # run main model 
                coreDict[c]=@spawnat c include("orderGen.jl")
            elseif res==:modComplete
                ctrlFrame[ctrlFrame.key.==currKey,:initialized].=true
            end
        end
    end
end

