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


function agentGen()
    global levyDist1
    global levyDist2
    global zeroInflation
    global poissonParameter
    # generate Beta parameters
    interest1::Float64=rand(levyDist1,1)[1]
    interest2::Float64=rand(levyDist2,1)[1]
    privacy::Int64=privacyGen()
    push!(agtList,agent(privacy,interest1,interest2))
end   

# we need a function where the agent reveals its preferences

function preference(agt::Agent)
    return rand(agt.betaObj,1)[1]
end

# we also need the functions where by advertisers search for agents
# for the agent search, the advertiser has to solve the inverse problem 
# the advertiser assumes the final search value is the mode. 
# the advertiser then searches for a given number of agents
# with modes close to the final search mode. 
# if the agent is in this group, we consider it a privacy event 

function identify(engine::searchEngine,agt:agent,mode::Float64)
    global agtList 
    global modeTolerance

end

# now we need a search function 
function search(agt::Agent,engine::searchEngine)
    global searchGrain
    global clickProb
    # have agent reveal the agent's preference
    pref::Float64=preference(agt)
    t::Int64=0
    choicesUniform=rand(standardSearch,1000000)
    choicesAgent=rand(agt.betaObj,1000000)
    while true
        t=t+1
        # decide whether to draw from the agent's distribution or the standard one
        mixture::Float64=rand(standardSearch,1)[1]
        if mixture > (1-engine.efficiency)
            # draw from uniform
            choice=choicesUniform[1]            
        else
            choice=choicesAgent[1]
        end 
        # now, did the search engine hit the target?
        if abs(pref-choice) <= searchGrain

            # Did the agent click an ad?
            if rand(standardSearch,1)[1] < clickProb


        else
            higher=pref > choice
            if higher
                filter!(x-> x > choice,choicesUniform)
                filter!(x-> x > choice,choicesAgent)
            else
                filter(x-> x < choice,choicesUniform)
                filter(x-> x < choice,choicesAgent)                
            end

        end

    end


end   