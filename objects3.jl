# the core challenge is to control the model behavior using structs 
# we have a few structs
# simplest is the agent struct which is alone
# search engines are either hard search engines like Google and Duck Duck Go 
# they are hard coded structs 
# or else they are soft engines which are generated by 
# a function with parameters 

# also, there are structs for laws. 
# we have the data deletion law 
# and the data sharing law 

# finally, and most complex are the action laws. 
# to keep the main model code as simple as possible, 
# there is an action space. 
# an agent acts using the syntax change(move::action,agt::agent)
# thus, there is an action struct for every combination of law and target search engine 
# there is also an action for each search engine, this means switching.
# as agents have memory, there is also a corresponding reverse function with similar syntax 

# every time a new search engine or law is introduced, the action space must be regenerated 
# to account for all combinations

# as a preliminary, define agents 
using Distributions
probType=Union{Uniform{Float64},Beta{Float64}}
# we need an internet alias as agents can develop different ones 

mutable struct alias
    optOut::Bool
end
allAlias=alias[]

function aliasGen(optOut::Bool)
    global allAlias
    newAlias=alias(optOut)
    push!(allAlias)
    return newAlias
end
# we need a basic agent object
mutable struct agent
    agtNum::Int64
    mask::alias
    privacy::Float64
    betaObj::Beta{Float64}
    gammaObj::Gamma{Float64}
    expUnif::Float64
    expSubj::Float64
    blissPoint::Float64
    history::Dict{Int64,Float64}
    currEngine::Any
    prevEngine::Any
    lastAct::Any
end



# we need a preliminary set of search objects 

abstract type searchEngine end
# we keep a list of all search engines 
engineList=searchEngine[]

# we now need to subtypes for search engines. 
# hard coded search engines (Google and Duck Duck Go)
# search engines indicated with a privacy parameter
# this parameter how much user data the search engine retains 
# this ranges from 0 (all user date to retained) to 1 (none retained)
# we turn this into 1/(p^k) where k is a constant and p is the privacy parameter

abstract type hardEngine <: searchEngine end
abstract type paramEngine <: searchEngine end

# now hard code the Google search engine 

mutable struct google <: hardEngine
    aliasData::Dict{alias,Array{Float64}}
    usageCount::Dict{Int64,Int64}
    aliasHld::Dict{alias,Array{Float64}}
end
# and the Duck Duck Go Engine
mutable struct duckDuckGo <: hardEngine
    aliasData::Dict{alias,Array{Float64}}
    usageCount::Dict{Int64,Int64}
    aliasHld::Dict{alias,Array{Float64}}
end

# also, we need the law structs 

abstract type law end
# we keep a list of all laws
lawList=law[] 

# we need functions to generate search engines and laws 
# and separate functions to generate the space of all actions 

# first the function to generate Google 
function googleGen()
    global engineList
    push!(engineList,google(Dict{alias,Array{Float64}}(),Dict{Int64,Int64}(),Dict{alias,Array{Float64}}()))
end

# now, the function to generate Duck Duck Go 

function duckGen()
    global engineList
    push!(engineList,duckDuckGo(Dict{alias,Array{Float64}}(),Dict{Int64,Int64}(),Dict{alias,Array{Float64}}()))
end

# finally, a function to generate other search engines
# this is more complex because each gets its own type
# for simplicity, we have a base function that generates the search engine. 
# other functions will call this and also specify the particular behavior 

function otherGen(name)
    symName=Symbol(name)
    quote
        mutable struct $symName <: paramEngine
            aliasData::Dict{alias,Array{Float64}}
            usageCount::Dict{Int64,Int64}
        end
        push!(engineList,$symName(Dict{alias,Array{Float64}}(),Dict{Int64,Int64}()),Dict{Int64,Int64}())
    end
end



# this must be called through an eval / Meta parse statement  

# now the functions to generate laws.
# we keep track of when they are passed
# for convenience, vpn access is also represented as a law
struct vpn <: law
    available::Int64
end

function vpnGen(t)
    global lawList
    push!(lawList,vpn(t))
end

struct deletion <: law
    available::Int64
end

function deletionGen(t)
    global lawList
    push!(lawList,deletion(t))
end

struct sharing <: law
    available::Int64
end

function sharingGen(t)
    global lawList
    push!(lawList,sharing(t))
end

# finally, actions 

abstract type action end

actionList=action[]

# now the function that generates actions
# first, we generate all combinations of actions


# we need a quote func

function actQuoteFunc(law,engine,idx)
    # how many actions are there already?
    actNm=Symbol("action"*string(idx))
    engineNm=Symbol(string(engine))
    #println("Macro")
    #println(engineNm)
    if isnothing(law)
        quote
            struct $actNm <: action
                law::Nothing
                engine::$engineNm
                
            end
            # find the relevant search engine 
            myEngine=filter(x-> typeof(x)==$engineNm,engineList)[1]
            push!(actionList,$actNm(nothing,myEngine))

            # we need the before act where the agent switches search engines
            function beforeAct(agt::agent,action::$actNm)
                agt.prevEngine=agt.currEngine
                agt.currEngine==action.engine
                agt.lastAct=action
            end
            # In the after act, the agent makes the change permanent if it prefers it
            function afterAct(agt::agent,result::Bool,action::$actNm)
                if !result
                    agt.currEngine=agt.prevEngine
                    agt.prevEngine=nothing
                else
                    agt.lastAct=nothing
                end
            end


        end
        
    elseif typeof(law)==deletion
        actNm=Symbol("action"*string(idx))
        engineNm=Symbol(string(engine))
        quote
            struct $actNm <: action
                law::$lawNm
                engine::$engineNm
            end

            function beforeAct(agt:agent,action::$actionNm)
                action.engine.aliasHld[agt.mask]=action.engine.aliasData[agt.mask]
                action.engine.aliasData[agt.mask]=[]
                agt.lastAct=action
            end

            function afterAct(agt::agent,result::Bool,action::$actionNm)
                if result
                    action.engine.aliasHld[agt.mask]=[]
                    act.lastAct=nothing
                else
                    action.engine.aliasData[agt.mask]=action.engine.aliasHld[agt.mask]
                    action.engine.aliasHld[agt.mask]=[]
                end
            end

        end
    elseif typeof(law)==sharing
        actNm=Symbol("action"*string(idx))
        engineNm=Symbol(string(engine))
        quote
            struct $actNm <: action
                law::$lawNm
                engine::$engineNm
            end

            function beforeAct(agt::agent,action::$actionNm)
                # share data from the agent's current search engine to its target search engine. 
                action.engine.aliasData[agt.mask]=agt.currEngine.aliasData[agt.mask]
                agt.prevEngine=agt.currEngine
                agt.currEngine=action.engine
                agt.lastAct=action
            end

            function afterAct(agt::agent,result::Bool,action::$actionNm)
                if !result
                    agt.currEngine=agt.prevEngine
                    agt.prevEngine=nothing
                else
                    agt.lastAct=nothing
                end
            end

        end
    else



    end
    #println(actCnt)
end

# we need a function that returns an array of terminal types

function baseTypes(typ)
    

end


function actionCombine()
    global actionList
    #actionList=action[]
    # get the list of all current laws
    allLaws=vcat([nothing],subtypes(law))
    allEngines=vcat(subtypes(hardEngine),subtypes(paramEngine))
    # now, an array of quotes
    qArray=[]
    actionTicker=0
    for l in allLaws
        for e in allEngines
            actionTicker=actionTicker+1
            push!(qArray,actQuoteFunc(l,e,actionTicker))
        end
    end
    return qArray
end
# now a macro that generates the objects
macro actionGen()
    quote
        qList=actionCombine()
        for q in qList
            eval(q)
        end
    end
end
