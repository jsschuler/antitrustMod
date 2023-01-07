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
# the search engines are parameterized by a forgetfullness parameter
# a perfectly forgetful search engine perturbs agent data to be uniform. 
# a perfectly unforgetful one fits the data as collected and uses it in search

