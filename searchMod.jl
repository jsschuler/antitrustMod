abstract type searchEngine
end

abstract type tickTime
end

mutable struct Google <: searchEngine
    agentHistory::Dict{agentMod.agent,Array{Float64}}
    revenue::Dict{Int64,Int64}
end 

mutable struct DuckDuckGo <: searchEngine
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
    push!(searchList,DuckDuckGo(Dict{Int64,Int64}()))
end  


function subsearch(agt::agentMod.agent,engine::Google,searchResolution::Float64,clickProb::Float64,time::Int64)
    # first, fit the agent's history 
    #println("Agent")
    #println(agt.agtNum)
    bestDist::agentMod.probType=Uniform()
    U::Uniform=Uniform()
    if length(engine.agentHistory[agt]) >= 30 && !agt.optOut
        #println("Fitting")
        bestDist=fit(Beta,engine.agentHistory[agt])
    else
        bestDist=Uniform()
    end
    # now, begin the search process 
    # generate actual desired result
    result::Float64=rand(agt.betaObj,1)[1]
    # now prepare the loop
    tick::Int64=0
    cum::Float64=0.0
    newRevenue::Int64=0
    finGuess::Float64=0.0

    maxGuess::Float64=1.0
    minGuess::Float64=0.0

    while true
        tick=tick+1
        guess::Float64=rand(bestDist,1)[1]
        #println("Tick")
        #println(tick)
        #println("Target")
        #println(result)
        #println("Guess")
        #println(guess)
        #println("Tick\n"*string(tick)*"\nTarget\n"*string(result)*"\nGuess\n"*string(guess))
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
                # if the guess is too high then we replace the upper bound with the guess 
                maxGuess=guess
            else
                # if the guess is too low, we replace the upper bound with the guess 
                minGuess=guess
            end
            # find out the quantile of the guess for the assumed distribution
            loGuess=cdf(bestDist,minGuess)
            hiGuess=cdf(bestDist,maxGuess)
            guess=quantile(bestDist,rand(U,1)[1]*(hiGuess-loGuess)+loGuess)
        end
    end
    return Any[agt.agtNum,tick,finGuess,newRevenue]
end



function search(agt::agentMod.agent,engine::Google,time::Int64)
    global searchResolution
    # we need to know the probability of the agent clicking on an ad 
    return subsearch(agt,engine,searchResolution,clickProb,time)
    
end

function subsearch(agt::agentMod.agent,engine::DuckDuckGo,searchResolution::Float64,clickProb::Float64,time::Int64)
    # first, fit the agent's history 
    bestDist::agentMod.probType=Uniform()
    U::Uniform=Uniform()
    # now, begin the search process 
    # generate actual desired result
    result::Float64=rand(agt.betaObj,1)[1]
    # now prepare the loop
    tick::Int64=0
    cum::Float64=0.0
    newRevenue::Int64=0
    finGuess::Float64=0.0
    maxGuess::Float64=1.0
    minGuess::Float64=0.0
    while true
        tick=tick+1
        guess::Float64=rand(bestDist,1)[1]
        #println("Tick")
        #println(tick)
        #println("Target")
        #println(result)
        #println("Guess")
        #println(guess)
        #println("Tick\n"*string(tick)*"\nTarget\n"*string(result)*"\nGuess\n"*string(guess))
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
                # if the guess is too high then we replace the upper bound with the guess 
                maxGuess=guess
            else
                # if the guess is too low, we replace the upper bound with the guess 
                minGuess=guess
            end
            # find out the quantile of the guess for the assumed distribution
            loGuess=cdf(bestDist,minGuess)
            hiGuess=cdf(bestDist,maxGuess)
            guess=quantile(bestDist,rand(U,1)[1]*(hiGuess-loGuess)+loGuess)
        end
    end
    
    return Any[agt.agtNum,tick,finGuess,newRevenue]
end

function search(agt::agentMod.agent,engine::DuckDuckGo,time::Int64)
    global searchResolution
    # we need to know the probability of the agent clicking on an ad 
    return subsearch(agt,engine,searchResolution,clickProb,time)
    
end


# function to update search history
function searchUpdate(engine::Google,agt::agentMod.agent,newHist::Float64)
    push!(engine.agentHistory[agt],newHist)
    # to save computational time, cut off data at 1000 observations
    if length(engine.agentHistory[agt]) > 1000
        engine.agentHistory[agt]=engine.agentHistory[agt][(length(engine.agentHistory[agt])-1000):length(engine.agentHistory[agt])]
    end

end

function searchUpdate(engine::DuckDuckGo,agt::agentMod.agent,newHist::Float64)
end

# now we need to define a macro for any additional search engine 

