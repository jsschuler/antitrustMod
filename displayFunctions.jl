function schedulePrint(argDict)
    for k in keys(argDict)
        println(k.agtNum)
        println(argDict[k])
    end
end
    
function agtNumber(agt::agent)
    return agt.agtNum
end

function actTarget(action)
    println("Target")
    println(typeof(action.engine))
end