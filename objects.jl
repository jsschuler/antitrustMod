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