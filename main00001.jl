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
#Random.seed!(1234)
Random.seed!(123)


## global parameters
# what is the probability that a random successful search results in an ad being clicked on?
clickProb::Float64=0.05
# now, we need the parameters for the Exponential distributions generating the two Beta parameters for each agent 
agtCnt=1000
# now, we need to generate the parameters for the agent's interests
# represented by beta distributions. 
# we parameterize the beta distribution by its mode. Given a mode, the two 
# betas are related linearly. The greater the coefficients, the lower the variance. 
# We can generate modes using a beta distribution 
modeGen::Beta{Float64}=Beta(5,5)
# and we generate the betas using an exponential distribution
betaGen::Exponential{Float64}=Exponential(5)
# jointly, these generate agent preferences
# also, agents have a privacy preference from 0 to 1 with a mode at 0. 
# this also comes from a beta random variable
privacyBeta::Beta{Float64}=Beta(1.0,3.0)
# how close does the offered search result have to be before the agent accepts it?
searchResolution::Float64=.05
# we need a Poisson process for how many agents switch 
switchPct::Float64=.1
poissonDist::Poisson{Float64}=Poisson(switchPct*agtCnt)




include("objects.jl")
include("functions.jl")

# test functions
#alphaTest=alphaGen(.4,10.0)
#alphaTest=alphaGen(.2,5.0)
#alphaTest=alphaGen(.9,1.3)

agtList=agent[]

agentGen()

println(util(agtList[1],3.0))
println(util(agtList[1],13.0))
println(util(agtList[1],agtList[1].blissPoint-.05))
println(util(agtList[1],agtList[1].blissPoint))
println(util(agtList[1],agtList[1].blissPoint+0.05))

searchList=searchEngine[]
time=1
googleGen()
#duckGen()
println(typeof(searchList[1]))
println(fieldnames(Google))
searchList[1].revenue[time]=0
for t in 1:1000
    search(agtList[1],searchList[1])
end
println(searchList[1].revenue)

# now it is time to build the main model 

# Step 0: Initialize all agents, Initialize Google and set the tick on which Duck Duck Go will enter 

# now, for each tick 
# some Poisson number of agents try a different search engine if one is available. 
# if they prefer it, they keep using it. 
# we track revenue and agent utility over time