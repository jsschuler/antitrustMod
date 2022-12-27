# we need a function that generates the privacy utility

function privacyGen()
    global zeroInflation
    global poissonDist

    if rand()[1] > zeroInflation
        privacyParam::Int64=rand(poissonDist,1)[1]

    end



end   


function agentGen()
    global levyDist1
    global levyDist2
    global zeroInflation
    global poissonParameter
    # generate Beta parameters
    interest1::Float64=rand(levyDist1,1)[1]
    interest2::Float64=rand(levyDist2,1)[1]


    
    
    return agent()
end   