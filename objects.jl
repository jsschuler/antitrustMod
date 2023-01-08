# we need a union type that is either uniform or Beta.

#@everywhere begin
#    probType=Union{Uniform{Float64},Beta{Float64}}
#end


# now we need a search engine object
# the search engines are parameterized by a particular results function
# for "Google", it estimates parameters from the agent's search history
# for Duck Duck Go, it generates uniform variates 

abstract type searchEngine
end

mutable struct Google <: searchEngine
    agentHistory::Dict{agtModule.agent,Array{Float64}}
    revenue::Dict{Int64,Int64}
end 

mutable struct DuckDuckGo <: searchEngine
    #agentHistory::Dict{agent,Array{Float64}}
    revenue::Dict{Int64,Int64}
end 

