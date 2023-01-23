module agentMod
    #using Distributed
    using Random
    using StatsBase
    using Distributions
    using Plots
    using JLD2
    include("globals.jl")


    using Distributions
    probType=Union{Uniform{Float64},Beta{Float64}}
    # we need a basic agent object
    mutable struct agent
        agtNum::Int64
        privacy::Float64
        betaObj::Beta{Float64}
        gammaObj::Gamma{Float64}
        expUnif::Float64
        expSubj::Float64
        blissPoint::Float64
        history::Dict{Int64,Float64}
        currEngine::Any
        prevEngine::Any
        
    end
    # for convenience, we need an agent object we can send off to parallel processes
    struct parAgent
        history::Array{Int64}
    end

# preliminary functions
        # we need a function given both a mode and a beta that generates the agent search preferences
        function alphaGen(mode::Float64,beta::Float64)
            alpha::Float64= -mode/(mode-1.0)*beta + (2.0*mode-1)/(mode-1)
            return alpha
        end
        # and a function that generates the agent's search preferences
        function preferenceGen()
            global modeGen
            global betaGen
            mode::Float64=rand(modeGen,1)[1]
            beta::Float64=rand(betaGen,1)[1] + 1.0
            alpha::Float64=alphaGen(mode,beta)
            #println("Debug")
            #println(mode)
            #println(alpha)
            #println(beta)
            return Beta(alpha,beta)
        end
        # we need a function that generates the agents
        # first, we need a function that simulates the search process under an assumed distribution
        function weightTime(prob::probType,agtPref::Beta{Float64})
            global searchResolution
            # generate actual desired result
            result::Float64=rand(agtPref,1)[1]
            U::Uniform{Float64}=Uniform()
            # now prepare the loop
            tick::Int64=0
            cum::Float64=0.0
            while true
                tick=tick+1
                guess::Float64=rand(prob,1)[1]
                if abs(guess-result) <= searchResolution
                    break
                else
                    if guess > result
                        # find out the quantile of the guess for the assumed distribution
                        cum=cdf(prob,guess)
                        guess=quantile(prob,rand(U,1)[1]*(1.0-cum)+cum)
                    else
                        cum=cdf(prob,guess)
                        guess=quantile(prob,rand(U,1)[1]*(cum))
                    end
                end
            end
        return tick
        end 


    function agentGen(agtNum::Int64,privacyBeta::Beta{Float64})
        # generate privacy preference
        #global 
        privacy::Float64=rand(privacyBeta,1)[1]
        myPrefs::Beta{Float64}=preferenceGen()
        # now, calculate the expected wait time 
        uniPref=Uniform()
        selfArray=Float64[]
        unifArray=Float64[]
        for t in 1:10000
            push!(selfArray,weightTime(myPrefs,myPrefs))
            push!(unifArray,weightTime(uniPref,myPrefs))
        end
        # calculate bliss points under either privacy extreme case
        selfExp=mean(selfArray)
        unifExp=mean(unifArray)
        # for a minimally privacy conscious agent, a lower expected search time is better
        # and thus 0 is the bliss point. 
        # for a maximally privacy conscious agent, the expected search time under a uniform model is the bliss point
        # from here, further inefficiency is not preferred
        # we can always allow the scaling factor to be 1 since only the rank ordering matters 
        # we can use the distance between the expectation under the uniform and the expectation
        # under the subjective distribution as an index of how idiosyncratic the agent's interests are 
        # this also implies that for fixed privacy preferences, agents with less idiosyncratic views are 
        # less sensitive to privacy considerations
        # now, the privacy parameter sets a bliss point between 0 and the expectation under uniform sampling
        blissPoint::Float64=privacy*(unifExp)
        # now, fit a gamma distribution with a scale of 1 to this
        gammaK::Float64=blissPoint+1
        agtUtil=Gamma(gammaK,1)
        #push!(agtList,agent(privacy,myPrefs,agtUtil,unifExp,selfExp,blissPoint,Dict{Int64,Int64}()))
        #println(typeof(key))
        return agent(agtNum,privacy,myPrefs,agtUtil,unifExp,selfExp,blissPoint,Dict{Int64,Int64}(),nothing,nothing)

    end   

    # now, we need a utility function for the agent
    function util(agt::agent,arg::Float64)
        return pdf(agt.gammaObj,arg)
    end
end