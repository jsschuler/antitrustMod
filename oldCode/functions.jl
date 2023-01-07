

# we need a function that generates the privacy utility
 
function privacyGen()
    global zeroInflation
    global poissonDist
    privacyParam::Int64=0 

    if rand()[1] > zeroInflation
        privacyParam=rand(poissonDist,1)[1]
    end
    return privacyParam
end   
# we need a function that generates the agents

function agentGen()
    global expDist1
    global expDist2
    global zeroInflation
    global poissonParameter
    # generate Beta parameters
    interest1::Float64=rand(expDist1,1)[1]+1.0
    interest2::Float64=rand(expDist2,1)[1]+1.0
    privacy::Int64=privacyGen()
    push!(agtList,agent(privacy,interest1,interest2,Beta(interest1,interest2)))
end   

# and their masks

function maskGen(agt::agent)
    return mask(agt,Float64[])
end 

# we need a function where the agent reveals its preferences

function preference(agt::agent)
    return rand(agt.betaObj,1)[1]
end

# we also need the functions where by advertisers search for agents
# for the agent search, the advertiser has to solve the inverse problem 
# the advertiser assumes the final search value is the mode. 
# the advertiser then searches for a given number of agents
# with modes close to the final search mode. 
# if the agent is in this group, we consider it a privacy event 

function maskID(mask::mask)
        global lambda1
        global lambda2
    if length(mask.history) > 1
        println(mask.history)
        xBar::Float64=mean(mask.history)
        sigmaSqHat::Float64=var(mask.history)
        println(xBar)
        println(sigmaSqHat)
        # now calculate parameters 
        if sigmaSqHat < xBar*(1-xBar)
            aHat::Float64=xBar*((xBar*(1.0-xBar))/(sigmaSqHat)-1.0)
            bHat::Float64=(1.0-xBar)*((xBar*(1.0-xBar))/(sigmaSqHat)-1.0)
            println(aHat)
            println(bHat)
            params=Float64[aHat,bHat]
        else
            params=Float64[lambda1+1.0,lambda2+1.0]

        end
    else
        params=Float64[lambda1+1.0,lambda2+1.0]
    end
    return params

end

function identify(engine::searchEngine,mask::mask)
    global agtList 
    global paramTolerance
    global identifyDepth
    # first, randomly sort the agents
    orders=sample(1:length(agtList),length(agtList),replace=false)
    j::Int64=0
    success::Bool=false
    # get best guess parameters of the masks
    params=maskID(mask)
    # now, search for an agent with parameters within a threshold of these. 
    result::Bool=false
    for agt in agtList
        if abs(params[1]-agt.interest1) <= paramTolerance && abs(params[2]-agt.interest2) <= paramTolerance 
            if mask.agt==agt
                result=true
            end
            break
        end
    end
    println(result)
return result
end

function maskInference(mask::mask)
    if length(mask.history) > 30
        #println("History Report")
        #println(mask.history)
        xBar::Float64=mean(mask.history)
        sigmaSqHat::Float64=var(mask.history)
        #println(xBar)
        #println(sigmaSqHat)
        # now calculate parameters 
        if sigmaSqHat < xBar*(1-xBar)
            aHat::Float64=xBar*((xBar*(1.0-xBar))/(sigmaSqHat)-1.0)
            bHat::Float64=(1.0-xBar)*((xBar*(1.0-xBar))/(sigmaSqHat)-1.0)
            #println("Estimated Parameters")
            #println(aHat)
            #println(bHat)
            # what are the true parameters
            #println("True Parameters")
            #println(mask.agt.interest1)
            #println(mask.agt.interest2)
            betaOut=Beta(aHat,bHat)
        else
            betaOut=Uniform()

        end
    else
        betaOut=Uniform()
    end
    return betaOut

end


# now we need a search function 
function search(mask::mask,engine::searchEngine)
    global searchGrain
    global clickProb
    # search engine will run inference on mask
    searchSampler::probType=maskInference(mask)
    #println("Debug")
    #println(typeof(searchSampler))
    # have agent reveal the agent's preference
    pref::Float64=preference(mask.agt)
    #println(pref)
    t::Int64=0
    choicesAgent=rand(searchSampler,1000000)
    #print(choicesAgent)

    while true
        t=t+1
        choice=choicesAgent[1]
        #println("Step")
        #println(choice)
        #println(pref)
        #println(maximum(choicesAgent))
        #println(minimum(choicesAgent))
        # now, did the search engine hit the target?
        if abs(pref-choice) <= searchGrain
            # now, the search engine records history
            push!(mask.history,choice)
            # Did the agent click an ad?
            if rand(standardSearch,1)[1] < clickProb
                engine.profit=engine.profit+1.0
            end
            break
        else
            higher=pref > choice
            #println(higher)
            if higher
                filter!(x-> x > choice,choicesAgent)
            else
                filter!(x-> x < choice,choicesAgent)                
            end
            #println(length(choicesAgent))

        end

    end
    return t
end   