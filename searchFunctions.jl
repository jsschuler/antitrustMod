function subsearch(mask::alias,engine::Google,searchResolution::Int64,t::Int64)
    # set globals 
    # first, fit the agent's history 
    #println("Agent")
    #println(agt.agtNum)
    bestDist::probType=Uniform()
    U::Uniform=Uniform()
    if length(engine.aliasData[mask]) >= 30 && !agt.optOut
        #println("Fitting")
        bestDist=fit(Beta,engine.aliasData[mask])
    else
        bestDist=Uniform()
    end
    # now, begin the search process 
    # generate actual desired result
    result::Float64=rand(mask.agt.betaObj,1)[1]
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
    return Any[mask,mask.agt.agtNum,tick,finGuess]
end



function search(mask::alias,engine::Google,time::Int64)
    global searchResolution
    # we need to know the probability of the agent clicking on an ad 
    return subsearch(mask,engine,searchResolution,time)
    
end

function subsearch(mask::alias,engine::DuckDuckGo,searchResolution::Float64,time::Int64)
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
    return Any[mask,mask.agt.agtNum,tick,finGuess]
end
