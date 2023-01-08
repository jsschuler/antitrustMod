abstract type searchEngine
end

mutable struct Google <: searchEngine
    agentHistory::Dict{agtModule.agent,Array{Float64}}
    revenue::Dict{Int64,Int64}
end 

mutable struct DuckDuckGo <: searchEngine
    #agentHistory::Dict{agent,Array{Float64}}
    revenue::Dict{Int64,Int64}
end 


function googleGen()
    global agtList
    global searchList
    histDict::Dict{agtModule.agent,Array{Float64}}=Dict()
    for agt in agtList
        histDict[agt]=Float64[]
    end
    push!(searchList,Google(histDict,Dict{Int64,Int64}()))

end

function duckGen()
    global searchList
    push!(searchList,DuckDuckGo(Int64[]))
end  


function subsearch(agt::agtModule.agent,engine::Google,searchResolution::Int64,clickProb::Float64,time::Int64)
    # first, fit the agent's history 
    bestdist::probType=Uniform()
    U::Uniform=Uniform()
    if length(engine.agentHistory) >= 30
        bestDist=fit(Beta,engine.agentHistory)
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
    while true
        tick=tick+1
        guess::Float64=rand(bestdist,1)[1]
        if abs(guess-result) <= searchResolution
            # add this to the agent's history 
            finGuess:Float64=guess
            # did the agent click on an ad?
            if rand(U,1)[1] <= clickProb
                newRevenue=1
            end

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
    return [tick,finGuess,newRevenue]
end



function search(agt::agtModule.agent,engine::Google)
    global searchResolution
    # we need to know the probability of the agent clicking on an ad 
    global clickProb
    global time
    return subsearch(agt,engine)
    
end