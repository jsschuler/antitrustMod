#################################################################################################################################################
#                          Program to Generate Control Parameters                                                                               #
#                          Antitrust Model V 1                                                                                                  #
#                          John S. Schuler                                                                                                      #
#                          January 2020                                                                                                         #
#                                                                                                                                               #
#                                                                                                                                               #
#                                                                                                                                               #
#                                                                                                                                               #
#################################################################################################################################################
using DataFrames
using JLD2
using Distributions
# how many control files to generate? (Usually one per processor)
ctrlFiles=16
# how many times to run the model per file?
runTime=100
# what tick does DuckDuckGo enter?
duckTick=20
# now, for the privacy preference, the second Beta parameter controls how many agents care about privacy
# in every case, the modal agent doesn't care at all
# thus, we let it range uniformly between 1.1 and 10 
loVarb=1.1
hiVarb=10 
# how close does the offered search result have to be before the agent accepts it?
searchResolution::Float64=.05
# how many agents?
agtCnt=1000
# we need a Poisson process for how many agents switch 
switchPct::Float64=.1
poissonDist::Poisson{Float64}=Poisson(switchPct*agtCnt)
# and a probability distribution for how much agents search 
searchCountDist::NegativeBinomial{Float64}=NegativeBinomial(1.0,.1)

# for each file, pick an initial agent seed 
seedVarb=DiscreteUniform(1,10000)
agtSeeds=rand(seedVarb,16,replace=false)

for seed in agtSeeds
    seedVec=repeat(seed,runTime)
runVec=repeat()
end
