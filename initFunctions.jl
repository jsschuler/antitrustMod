using Distributions
probType=Union{Uniform{Float64},Beta{Float64}}


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
function waitTime(prob::probType,agtPref::Beta{Float64})
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


function agentGen(agtNum::Int64)
    # generate privacy preference
    #global 
    global privacyBeta
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
    global engineList
    return agent(agtNum,aliasGen(),privacy,myPrefs,agtUtil,unifExp,selfExp,blissPoint,Dict{Int64,Int64}(),engineList[1],nothing,false)
end   

# now, we need a utility function for the agent
function util(agt::agent,arg::Float64)
    return pdf(agt.gammaObj,arg)
end
# and we need a function that simply evaluates the agent's utility at the expected weight time under uniformity
function util(agt::agent)
    return pdf(agt.gammaObj,agt.waitUnif)
end


# we need a function to generate the agents

function genAgents()
    global agtCnt
    global agtList
    for i in 1:agtCnt
        push!(agtList,agentMod.agentGen(i))
    end
end

