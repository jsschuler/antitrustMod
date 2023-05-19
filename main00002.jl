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

# include global parameters
include("globals.jl")

# let's test some objects
include("objects3.jl")

# now, all actions work through aliases. 
# if an agent decides to use a VPN, it simply generates a new alias. 
# if an agent requests deletion, it removes records of its alias from the search engine. 
# if an agent requests data sharing, it transfers its alias data to another search engine 


# initialize model
include("initFunctions.jl")

# generate Google
googleGen()
include("searchFunctions.jl")
# generate agents
agtList=agent[]
genAgents()

for tick in 1:modRuns
    # First, have all agents set themselves up. 
    # this function gets rewritten depending on the actions the agents take
    for t in 1:modTime
        # have agents search 
        # randomize agt search amount 
        searchCnt=rand(searchQty,agtCnt)
        # randomize agent ordering
        searchOrder=sample(1:agtCnt,agtCnt,replace=false)
        for i in searchOrder
            # we need an array for how long it took
            searchWait=Int64[]
            println(searchCnt[i])
            searchRes=search(agtList[i],searchCnt[i])
            # now for each agent, we need to know the final target of the search result 
            for res in searchRes
            # update search engine records for the alias with the search target
                update(res[4],agtList[i].mask,agtList[i].currEngine)
                push!(searchWait,res[3])
            end
            
            # now update agent's history
            agtList[i].history[t]=mean(searchWait)
        end
    end
end