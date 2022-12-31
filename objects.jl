# we need a union type that is either uniform or Beta.
probType=Union{Uniform{Float64},Beta{Float64}}

# we need a basic agent object
struct agent
    privacy::Int64
    interest1::Float64
    interest2::Float64
    betaObj::probType
end

struct mask
    agt::agent
    history::Array{Float64}
end


# and we need a simulated agent object for search engines to simulate 
struct simAgent
    privacy::Int64
    interest1::Float64
    interest2::Float64
    betaObj::probType
end 
# now we need search engines

struct simMask
    agt::agent
    history::Array{Float64}
end

abstract type searchEngine
end


# we need an advertizer object

mutable struct advertiser
    profit::Int64
end

# now we need search engines

abstract type searchEngine
end

abstract type cloneEngine
end
# now a macro that creates a search engine struct 

searchEngineList=Array{Symbol}(undef,0)
 
macro searchGen(learning::Float64,efficiency::Float64)
    #searchName="test"
    searchIndex::String=string(sample(1:1000000,1)[1])
    searchName=Symbol("S"*searchIndex)
    funcName=Symbol("S"*searchIndex*"Gen")
    cloneName=Symbol("C"*searchIndex)
    #println(funcName)
    quote
        # generate the struct
        mutable struct $searchName <: searchEngine
            efficiency::Float64
            learning::Float64
            profit::Float64
        end 

        struct $cloneName <: cloneEngine
            efficiency::Float64
            learning::Float64
            profit::Float64
        end
        # now create the function that generates the struct 
        index::Int64=length(searchEngineList)
        push!(searchEngineList,$searchName($efficiency,$learning,0.0))
        



        function clone(searchEngine::$searchName)

            return($cloneName($searchName.efficiency,$searchName.learning))
        end 
    end

    end   