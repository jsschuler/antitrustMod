function subsearch(agt::agent,engine::Google,searchResolution::Int64,t::Int64)
    # set globals 
    # first, fit the agent's history 
    #println("Agent")
    #println(agt.agtNum)
    bestDist::probType=Uniform()
    U::Uniform=Uniform()
    if length(engine.aliasData[agt.mask]) >= 30 && !agt.mask.optOut
        #println("Fitting")
        bestDist=fit(Beta,engine.aliasData[mask])
    else
        bestDist=Uniform()
    end
    # now, begin the search process 
    # generate actual desired result
    result::Float64=rand(agt.mask.betaObj,1)[1]
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
    return Any[agt.mask,agt.agtNum,tick,finGuess]
end



function subsearch(agt::agent,engine::DuckDuckGo,searchResolution::Float64,time::Int64)
      # set globals 
    # first, fit the agent's history 
    #println("Agent")
    #println(agt.agtNum)
    bestDist::probType=Uniform()
    U::Uniform=Uniform()
    if length(engine.aliasData[agt.mask]) >= 30 && !agt.mask.optOut
        #println("Fitting")
        bestDist=fit(Beta,engine.aliasData[mask])
    else
        bestDist=Uniform()
    end
    # now, begin the search process 
    # generate actual desired result
    result::Float64=rand(agt.mask.betaObj,1)[1]
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
    return Any[agt.mask,agt.agtNum,tick,finGuess]
end

function search(agt::agent,time::Int64)
    global searchResolution
    # we need to know the probability of the agent clicking on an ad 
    return subsearch(agt,agt.currEngine,searchResolution,time)
    
end

# now, we need functions whereby the search engine updates its data 
# Google records
function update(result::Float64,mask::alias,engine::Google)
    push!(engine.aliasData[mask],result)
end
# Duck Duck Go does not
function update(result::Float64,mask::alias,engine::DuckDuckGo)
end

# we need to add a macro to generate functions for any additional search engine.