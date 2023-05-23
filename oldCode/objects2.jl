# as a preliminary, define agents 
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
    optOut::Bool
    
end

# we also need an internet alias as agents can develop different ones 

mutable struct alias
    agt::agent
end


# now we need a macro to generate additional search engines 
# this macro will need to be overwritten as various laws pass





# The core abstraction is that agents undertake actions. 
# actions are either associated with the use of a search engine or else the use of a law. 
# all actions have an associated agent, a "source", and a "target"
# if the action is just a switching action, the source and target are the same. 
# the same is true for the vpn action. 
# for the laws, sometimes the source and target will be different. This is true for data sharing. 

# top of the action hierarchy 
abstract type action end

actionList=action[]

# thus we define a function of the form:
    # act(type::action,agt::agent)
    # Deciding to use a search engine is an act. 
    # with each search engine corresponding to its own act
    # deciding to use a VPN is an act 
    # deciding to share data is also an act 
    # as is requesting data deletion
    # thus, there is an act for each pair of search engines as far as sharing data between them.
    # agents themselves keep their history





    # now define functions to generate the hard coded search engines
engineList=searchEngine[]

# and generate the acts related to google

struct switchGoogle <: action 
    available::Int64
end

function googleActionGen()
    global actionList
    global tick
    push!(actionList,switchGoogle(tick))
end

function googleGen()
    global engineList
    push!(engineList,google(Dict{alias,Array{Float64}}(),Dict{Int64,Int64}()))
    googleActionGen()
return nothing
end

# now, we need an array to hold quoted code 
quoteList=[]


function act(move::switchGoogle,agt::agent)
    agt.prevEngine=agt.currEngine
    searchObj::searchEngine=engineList[1]
    for engine in engineList
        if typeof(engine)=="Google"
            searchObj=engine
        end
    end
    agt.currEngine=searchObj
end

function reverse(move::switchGoogle,agt::agent)
    agt.currEngine=agt.prevEngine
    agt.prevEngine=nothing
end

struct switchDuck <: action
    available::Int64
end

function duckActionGen()
    global actionList
    global tick
    push!(actionList,switchDuck(tick))
end


function duckGen()
    global engineList
    push!(engineList,duckDuckGo(Dict{Int64,Int64}()))
    duckActionGen()
    return nothing
end

function act(move::switchDuck,agt::agent)
    agt.prevEngine=agt.currEngine
    searchObj::searchEngine=engineList[1]
    for engine in engineList
        if typeof(engine)=="DuckDuckGo"
            searchObj=engine
        end
    end
    agt.currEngine=searchObj
end

function reverse(move::switchDuck,agt::agent)
    agt.currEngine=agt.prevEngine
    agt.prevEngine=nothing
end

# now, we need data deletion acts 

abstract type deletion <: act
end

struct googleDelete <: deletion
end

struct duckDelete <: deletion
end


# now we need a macro that generates all delete rules 
# and also regenerate the search engine generation function
# adding a deletion action
