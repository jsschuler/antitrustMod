###########################################################################################################
#            Antitrust Model Main Code                                                                    #
#            January 2022                                                                                 #
#            John S. Schuler                                                                              #
#                                                                                                         #
#                                                                                                         #
###########################################################################################################

# first, this code must be comprehensive, meaning, it can handle the parameter sweep itself. 
# All data can be saved in Julia file structures. 
 

# for now, define the parameters

# each agent has two interest parameters which are the parameters for a beta random variable. 
# each agent also has a privacy parameter from 0 to 1. 


# now, the agent's utility is how long it has to wait to find what it searches for. 
# as some agents use the internet more than others, the activation scheme is usually Poisson. 

using Random
using StatsBase
using Distributions
using Plots
## global parameters
activation::String="Poisson"
# what is the probability that a random successful search results in an ad being clicked on?
clickProb::Float64=0.001
# now, we need the parameters for the Exponential distributions generating the two Beta parameters for each agent 
agtCnt=10000
lambda1::Float64=4.0
lambda2::Float64=5.0
expDist1=Exponential(lambda1)
expDist2=Exponential(lambda2)
# What is the search granularity (the margin of error within the search is considered to hit the target)
searchGrain::Float64=.01
# what is the agent simulation depth? (the number of simulations agents run)
agentSimDepth::Int64=1000
# what is the search engine search depth?
searchSimDepth::Int64=1000
# How many search rounds do the agents engage in?
searchRounds::Int64=1000

# also, we need the privacy parameters 
# we use a zero-inflated Poisson for the privacy parameter. 
# since the agent's utility is measured in how many attempts it takes to get its desired result.
zeroInflation::Float64=.7
poissonParameter::Float64=5.0
poissonDist=Poisson(poissonParameter)
# Also, what do the search engines use as the standard sampler?
standardSearch::Uniform{Float64}=Uniform()
# finally, what is the parameter tolerance?
paramTolerance::Float64=.01
# and how deep does the search engine search to identify agents?
identifyDepth::Int64=1000

include("objects.jl")
include("functions.jl")
# generate searching agents 
agtList=agent[]
for i in 1:agtCnt
    agentGen()
end   
# now generate masks for each agent
maskList=mask[]
for agt in agtList
    push!(maskList,maskGen(agt))
end

searchEngineList=searchEngine[]
@searchGen(.5,4.5)