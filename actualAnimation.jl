using StatsBase
# now, we need the actual animation code 
# begin with some paramaters 
# how many agents of each type?
agtTypCnt=[30,15,50,40]
# this yields the number of search engines 
engineCnt=length(agtTypCnt)

# the number of search engines determines everything. 
# now, so long as the number of search engines is > 3, we get 
α=π/length(agtTypCnt)
# from this alpha, we get the width of the box 
width=2*cos(π/2-α)
# this is relative to the normalized inner radius 
# now, we need enough space to fit all agents 
# the largest group of agents will be the limiting factor 
# ideally, each group will be rougly equally long

numSplit=function(num::Int64)
    # if the number if even, just split in half
    if num%2==0
        outPut=Int64.([num/2,num/2])
    else
        outPut=[floor(Int64,num/2)+1,floor(Int64,num/2)]
    end
    return outPut
end

nameSplit=function()

arrangeFunc=function(step::Int64)
    global agtTypCnt
    rankVec=ordinalrank(agtTypCnt)
    workingVec=agtTypCnt
    for t in 1:step
        newVec=[]
        rankVec=ordinalrank(workingVec)
        for j in 1:length(rankVec)
            if rankVec[j]==1
                numSplit(workingVec[j])
            end
        end
    end


end


# now that we have α, we can solve for r1 and r2. 

areaFunc=function(rRatio)
    global α
    length=rRatio-(4*sin(α/2)^2-cos(π/2-α))
    width=2*cos(π/2-α)
    #println(length)
    #println(width)
    return length/width
end

areaSolve=function()
    rng=1:0.01:2
    global area
    allAreas=abs.(areaFunc.(rng).-area)
    allBool=allAreas.==minimum(allAreas)
    for t in 1:length(allAreas)
        if allBool==1
            finT=t
            break
        end
    end

end