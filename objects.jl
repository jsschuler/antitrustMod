# we need a basic agent object

struct agent# we need a basic agent object

struct agent
    privacy::Rational{Int64}
    interest1::Rational{Int64}
    interest2::Rational{Int64}

end

# we need an advertizer object

mutable struct advertiser
    profit::Int64
end

# now we need search engines

abstract type searchEngine
end

    privacy::Rational{Int64}
    interest1::Rational{Int64}
    interest2::Rational{Int64}

end

# we need an advertizer object

mutable struct advertiser
    profit::Int64
end

# now we need search engines

abstract type searchEngine
end

# now a macro that creates a search engine struct 

searchEngineList=Array{Symbol}(undef,0)

macro searchGen(learning::Rational{Int64})
    searchIndex::Int64=length(searchEngineList)+1
    searchName="S"*string(searchIndex)
    funcName="S"*string(searchIndex)*"Gen"
    cloneName="C"*string(searchIndex)
    quote
        # generate the struct
        struct $searchName
            efficiency::Float64
            learning::Rational{Int64}
        end 

        struct cloneName
            efficiency::Float64
            learning::Rational{Int64}
        end
        # now create the function that generates the struct 
        function $funcName(efficiency::Float64,learning::Rational{Int64})
            push!(searchEngineList,$searchName(efficiency,learning))
        end

        function clone(searchEngine::$searchName)




    end   