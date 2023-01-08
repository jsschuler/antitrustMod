
# now, we need a utility function for the agent
function util(agt::agtModule.agent,arg::Float64)
    return pdf(agt.gammaObj,arg)
end

function googleGen()
    global agtList
    global searchList
    histDict::Dict{agent,Array{Float64}}=Dict()
    for agt in agtList
        histDict[agt]=Float64[]
    end
    push!(searchList,Google(histDict,Dict{Int64,Int64}()))

end

function duckGen()
    global searchList
    push!(searchList,DuckDuckGo(Int64[]))
end  

# now we need a search function

function search(agt::agtModule.agent,engine::Google)
    # first, fit the agent's history 
    bestdist::probType=Uniform()
    U::Uniform=Uniform()
    if length(engine.agentHistory) >= 30
        bestDist=fit(Beta,engine.agentHistory)
    else
        bestdist=Uniform()
    end
    # now, begin the search process 
    global searchResolution
    # we need to know the probability of the agent clicking on an ad 
    global clickProb
    global time
    # generate actual desired result
    result::Float64=rand(agt.betaObj,1)[1]
    # now prepare the loop
    tick::Int64=0
    cum::Float64=0.0
    while true
        tick=tick+1
        guess::Float64=rand(bestdist,1)[1]
        if abs(guess-result) <= searchResolution
            # add this to the agent's history 
            push!(engine.agentHistory[agt],guess)
            # did the agent click on an ad?
            if rand(U,1)[1] <= clickProb
                engine.revenue[time]=engine.revenue[time]+1
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
    return tick

end


function search(agt::agtModule.agent,engine::DuckDuckGo)
    # first, fit the agent's history 
    bestdist::probType=Uniform()
    U::Uniform=Uniform()
    bestdist=Uniform()
    # now, begin the search process 
    global searchResolution
    # we need to know the probability of the agent clicking on an ad 
    global clickProb
    global time
    # generate actual desired result
    result::Float64=rand(agt.betaObj,1)[1]
    # now prepare the loop
    tick::Int64=0
    cum::Float64=0.0
    while true
        tick=tick+1
        guess::Float64=rand(bestdist,1)[1]
        if abs(guess-result) <= searchResolution
            # did the agent click on an ad?
            if rand(U,1)[1] <= clickProb
                engine.revenue[time]=engine.revenue[time]+1
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
    return tick
end