

abstract type searchEngine
end

abstract type tickTime
end


# we need two macros

# one of them generates a named search engine

# the other simply generates a search engine with a number 

macro engineGen(engineName,mixingParameter)
    structName=Symbol(engineName)
    genFuncName=Symbol(engineName,"Gen")
    mixingParameter=Symbol(mixingParameter)
    finExpr=quote
        mutable struct $structName <: searchEngine
            agentHistory::Dict{agentMod.agent,Array{Float64}}
        end

        function $genFuncName()
            global agtList
            global searchList
            histDict::Dict{agentMod.agent,Array{Float64}}=Dict()
            for agt in agtList
                histDict[agt]=Float64[]
            end
            push!(searchList,$structName(histDict,Dict{Int64,Int64}()))
        
        end


        function subsearch(agt::agentMod.agent,engine::$structName,searchResolution::Float64,clickProb::Float64,time::Int64)
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
        
        
        
        function search(agt::agentMod.agent,engine::$structName,time::Int64)
            global searchResolution
            # we need to know the probability of the agent clicking on an ad 
            return subsearch(agt,engine,searchResolution,clickProb,time)
            
        end
        #function util(agt::agent,arg::Float64)
        #    return pdf(agt.gammaObj,arg)
        #end
        ## and we need a function that simply evaluates the agent's utility at the expected weight time under uniformity
        #function util(agt::agent)
        #    return pdf(agt.gammaObj,agt.waitUnif)
        #end
        
        # we need to alter these utility functions so agents have a search engine preference all else equal.

        function util(agt::agent,arg::Float64,engine::$structName)
            return util(agt,arg)
        end

        function util(agt::agent,engine::$structName)
            return util(agt)
        end




    end

    return eval(finExpr)
end