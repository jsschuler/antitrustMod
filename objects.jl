# we need a union type that is either uniform or Beta.
probType=Union{Uniform{Float64},Beta{Float64}}

# we need a basic agent object
struct agent
    privacy::Float64
    betaObj::Beta{Float64}
    gammaObj::Gamma{Float64}
    expUnif::Float64
    expSubj::Float64
    blissPoint::Float64
end
 
# now we need a search engine object
# the search engines are parameterized by a particular results function
# for "Google", it estimates parameters from the agent's search history
# for Duck Duck Go, it generates uniform variates 

abstract type searchEngine
end

mutable struct Google <: searchEngine
    agentHistory::Dict{agent,Array{Float64}}
    revenue::Array{Int64}
end 

mutable struct Google <: searchEngine
    #agentHistory::Dict{agent,Array{Float64}}
    revenue::Array{Int64}
end 

