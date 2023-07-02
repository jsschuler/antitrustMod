
Random.seed!(seed2)


# we need an array to store the already generated structs to avoid redefining them 
structTuples=Set([])
# order of introdudction, 
# Duck Duck Go must be introduced before data sharing 

modRuns=100
tickIntros=rand(DiscreteUniform(1,100),length(order))
if 1 in order
    duckTick=tickIntros[order.==1][1]
else 
    duckTick=-10
end
if 2 in order
    vpnTick=tickIntros[order.==2][1]
else
    vpnTick=-10
end
if 3 in order
    deletionTick=tickIntros[order.==3][1]
else
    deletionTick=-10
end
if 4 in order
    sharingTick=tickIntros[order.==4][1]
else
    sharingTick=-10
end
#tick=0
for ticker in 1:modRuns
    # principle 1: agents search no matter what 
    global tick
    tick=tick + 1
    # Step 0: new laws or search engines are introduced.
    # first, introduce any new laws or search engines 
    if tick==duckTick
        #println("DuckDuckGo In")
        duckGen()
        @actionGen()
    end
    #println("Tick")
    #println(tick)
    # now introduce new laws if applicable 
    if tick==vpnTick
        #println("VPN In")
        vpnGen(tick)
        @actionGen()
    end
    #println("Tick")
    #println(tick)
    if tick==deletionTick
        #println("Deletion In")
        deletionGen(tick)
        @actionGen()
    end
    #println("Tick")
    #println(tick)
    if tick==sharingTick
        #println("Sharing In")
        sharingGen(tick)
        @actionGen()
    end
    #println("Action List")
    #println(length(actionList))

    
end