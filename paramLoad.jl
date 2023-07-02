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
# now initialize the 
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

:agtGen 