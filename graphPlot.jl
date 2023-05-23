using GraphPlot
using Compose
using Colors
# color parameters 
googleColorFull=RGBA(.215,.710,.395,1)
duckColorFull=RGBA(.871,.345,.200,1)
googleColorHalf=RGBA(.215,.710,.395,1)
duckColorHalf=RGBA(.871,.345,.200,1)

fullBlack=RGBA(0,0,0,1)


# select random colors to test 

# first, we need to decide on some iconography. 

# an agent using a vpn is transparent 

# agents adopt the color of their search engine
# We use Google Green and Duck Duck Go orange

# An agent requesting data deletion gets a black circle around it

# an agent requesting a data sharing rule gets a maroon circle around it

# now, define some functions on the agent 

# a few dictionaries 
searchColorDict=Dict{searchEngine,RGBA}



function agentBaseColor(agt::agent)
    opacity::Float64=1.0
    if agt.mask.optOut
        opacity=.5
    end
    
    searchEngine=typeof(agt.currEngine)
    if searchEngine==google
        colorOut=RGBA(.215,.710,.395,opacity)
    else
        colorOut=RGBA(.871,.345,.200,opacity)
    end
    return colorOut
end

function agentOutlineColor(agt::agent)
    if !isnothing(agt.lastAct)
        if typeof(agt.lastAct.law)==Nothing
            lineColor=RGBA(0,0,0,1)
        elseif typeof(agt.lastAct.law)==deletion 
            lineColor=RGBA(0,0,0,1)
        elseif typeof(agt.lastAct.law)==sharing
            lineColor=RGBA(.562,.0,.284,1)
        end
    else 
        lineColor=RGBA(0,0,0,1)
    end
    return lineColor
end


function agentOutlineWidth(agt::agent)
    if !isnothing(agt.lastAct)
        if typeof(agt.lastAct.law)==Nothing
            lineWidth=0.0
        elseif typeof(agt.lastAct.law)==deletion 
            lineWidth=.1
        elseif typeof(agt.lastAct.law)==sharing
            lineWidth=.1
        end
    else 
        lineWidth=0.0
    end
    return lineWidth
end

agtPlot = gplot(agtGraph, nodefillc="white")

layout=(args...)->spring_layout(args...; C=30)

draw(SVG("graph.svg", 16cm, 16cm), gplot(agtGraph,layout=layout,
                                                   nodefillc=agentBaseColor.(agtList),
                                                   nodestrokec=agentOutlineColor.(agtList),
                                                   nodestrokelw=agentOutlineWidth.(agtList)))

# now we need a function that outputs the SVG 

function svgGen(tick::Int64)
    global agtList
    draw(SVG("graphPlots/graph"*string(tick)*".svg", 16cm, 16cm), gplot(agtGraph,layout=layout,
                                                   nodefillc=agentBaseColor.(agtList),
                                                   nodestrokec=agentOutlineColor.(agtList),
                                                   nodestrokelw=agentOutlineWidth.(agtList)))
end