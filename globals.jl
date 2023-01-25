## global parameters
# what is the probability that a random successful search results in an ad being clicked on?
clickProb::Float64=0.5
# now, we need the parameters for the Exponential distributions generating the two Beta parameters for each agent 
agtCnt=1000
# how many times to run the model?
modRuns=1
# how many ticks for each model run?
modTime::Int64=2
# when does DuckDuckGo enter?
duckTime::Int64=10

# now set the agent generation  key 
agtSeed::Int64=rand(DiscreteUniform(1,10000),1)[1]
Random.seed!(agtSeed)
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
# how many agents care a lot about privacy?
# higher value means fewer care 
privacyVal::Float64=rand(Uniform(1.1,50),1)[1]
privacyBeta::Beta{Float64}=Beta(1.0,privacyVal)
# how close does the offered search result have to be before the agent accepts it?
searchResolution::Float64=.05
# we need a Poisson process for how many agents switch 
switchPct::Float64=.1
poissonDist::Poisson{Float64}=Poisson(switchPct*agtCnt)
# and a probability distribution for how much agents search 
searchCountDist::NegativeBinomial{Float64}=NegativeBinomial(1.0,.1)
