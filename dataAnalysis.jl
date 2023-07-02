using DataFrames
using CSV
using DataFramesMeta


files = readdir("../antiTrustData/")
dfList=DataFrame[]
for fi in files
    push!(dfList,CSV.read("../antiTrustData/"*fi, DataFrame,header=false))
end

df=CSV.read("../antiTrustData/output2023-07-01T20:40:09.787-6876-8278-8584.csv",DataFrame,header=false,delim=',')
df=df[1:4,:]
rename!(df,[:key,:tick,:agt,:engine])