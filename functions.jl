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


# now we need a search function 
function search(agt::Agent,engine::searchEngine)

end   