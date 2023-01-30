#####################################################################################################################################################################################
#                               Data Analysis Code for Antitrust Model                                                                                                              #
#                               January 2023                                                                                                                                        #
#                               John S. Schuler                                                                                                                                     #
#                                                                                                                                                                                   #
#                                                                                                                                                                                   #
#####################################################################################################################################################################################

using CSV
using DataFrames
using StatsBase
#using CairoMakie
using Plots
using Distributions
# read in Data 

runs=DataFrame(CSV.File("../Data/modOutput.csv"))
mod1=runs[runs.agtSeed.==1619 .&& runs.runSeed.==4037,:]
mod1noDup=mod1[1:50,:]

# get Google usage Percents
plot(mod1noDup.time,mod1noDup.googPct,title="% of Searches on Google")
xlabel!("Time")
ylabel!("%")
# now get search time percentiles
plot(mod1noDup.time,mod1noDup.g5, label="5%") 
plot!(mod1noDup.time,mod1noDup.q25, label="25%") 
plot!(mod1noDup.time,mod1noDup.q50, label="Med") 
plot!(mod1noDup.time,mod1noDup.q75, label="75%") 
plot!(mod1noDup.time,mod1noDup.q95, label="95%") 

# now we need the distribution of privacy preference
privacyVal=2.0
privacyBeta::Beta{Float64}=Beta(1.0,privacyVal)

plot(0:0.01:1,pdf(privacyBeta,0:0.01:1))