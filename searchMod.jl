abstract type searchEngine
end

mutable struct Google <: searchEngine
    agentHistory::Dict{agentMod.agent,Array{Float64}}
    revenue::Dict{Int64,Int64}
end 

mutable struct DuckDuckGo <: searchEngine
    #agentHistory::Dict{agent,Array{Float64}}
    revenue::Dict{Int64,Int64}
end 


function googleGen()
    global agtList
    global searchList
    histDict::Dict{agentMod.agent,Array{Float64}}=Dict()
    for agt in agtList
        histDict[agt]=Float64[]
    end
    push!(searchList,Google(histDict,Dict{Int64,Int64}()))

end

function duckGen()
    global searchList
    push!(searchList,DuckDuckGo(Int64[]))
end  


function subsearch(agt::agentMod.agent,engine::Google,searchResolution::Float64,clickProb::Float64,time::Int64)
    # first, fit the agent's history 
    bestdist::agentMod.probType=Uniform()
    U::Uniform=Uniform()
    if length(engine.agentHistory[agt]) >= 30
        
        bestDist=fit(Beta,engine.agentHistory[agt])
    else
        bestdist=Uniform()
    end
    # now, begin the search process 
    # generate actual desired result
    result::Float64=rand(agt.betaObj,1)[1]
    # now prepare the loop
    tick::Int64=0
    cum::Float64=0.0
    newRevenue::Int64=0
    finGuess::Float64=0.0
    while true
        tick=tick+1
        guess::Float64=rand(bestdist,1)[1]
        if abs(guess-result) <= searchResolution
            # add this to the agent's history 
            finGuess=guess
            # did the agent click on an ad?
            if rand(U,1)[1] <= clickProb
                newRevenue=1
            end
            #println("Flag")
            break
        else
            if guess > result
                # find out the quantile of the guess for the assumed distribution
                cum=cdf(bestdist,guess)
                guess=quantile(bestdist,rand(U,1)[1]*(1.0-cum)+cum)
            else
                cum=cdf(bestdist,guess)
                guess=quantile(bestdist,rand(U,1)[1]*(cum))
            end
        end
    end
    return Any[agt,tick,finGuess,newRevenue]
end



function search(agt::agentMod.agent,engine::Google,time::Int64)
    global searchResolution
    # we need to know the probability of the agent clicking on an ad 
    return subsearch(agt,engine,searchResolution,clickProb,time)
    
end