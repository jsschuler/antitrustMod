###########################################################################################################
#            Antitrust Model Main Code                                                                    #
#            April 2022                                                                                   #
#            John S. Schuler                                                                              #
#            OECD Version                                                                                 #
#                                                                                                         #
###########################################################################################################

### Model Description ####

# Agents have preferences for privacy meaning their bliss point is somewhere between the 
# expected wait time for a result given perfect information and the expected wait time for 
# a result given uniform information.

# agents also have a parameter  determining how often they "Act" (try a new search engine)
# The possible actions depend on the environment 
    # if a data sharing law is available, agents can copy their data across search engines 
    # if a data deletion rule is available, agents may delete their data 
    # agents can switch across any available search engines 

# agents are connected by a network. When an agent undertakes an action, adjacent agents in the network also try the action 
# and maintain it if they prefer it. 
using Distributions
using InteractiveUtils
using Graphs
# let's test some objects
include("objects3.jl")
# include global parameters
include("globals.jl")



#a1=agent(1,.5,Beta(.3,.5),Gamma(4,5),.2,.2,.6,Dict{Int64,Float64}(),nothing,nothing)

#alias1=alias(a1)

# now test Google and Duck Duck Go
#googleGen()
#duckGen()
# now test the other search engine generator
#eval(otherGen("newSearch"))
#engineList
#println(engineList)
#deletionGen(10)
#println(lawList)
#sharingGen(15)
#println(lawList)
#for l in lawList
#    println(supertype(typeof(l)))
#    println(subtypes(supertype(typeof(l))))
#end
#println(subtypes(law))

#allActions=actionCombine()
#println(allActions)
#@actionGen()

# initialize model
include("initFunctions.jl")

# generate Google
googleGen()

# generate agents
agtList=agentMod.agent[]
genAgents()

for tick in 1:modRuns
    # First, have all agents set themselves up. 
    # this function gets rewritten depending on the actions the agents take

    for t in 1:modTime
        # have agents search 

    end
end