using StatsBase
# now, we need the actual animation code 
# begin with some paramaters 
# how many agents of each type?
agtTypCnt=[30,15,50,40]
labelVec=Array(1:length(agtTypCnt))
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

numSplit=function(arr::Array{Int64},idx::Int64,k::Int64)
    
    if idx==1
        retArr=cat(repeat([arr[idx]],k),arr[(idx+1):length(arr)],dims=1)
    elseif idx==length(arr)
        retArr=cat(arr[1:(length(arr)-1)],repeat([arr[idx]],k),dims=1)
    else
        retArr=cat(arr[1:(idx-1)],repeat([arr[idx]],k),arr[(idx+1):length(arr)],dims=1)
    end 
end

nameSplit=function(arr::Array{Int64},label::Int64,k::Int64)
    idx=0
    for lb in arr
        println(lb)
        println(lb==label)
        if lb==label
            idx=lb
            break
        end
    end
    
    if idx==1
        retArr=cat(repeat([arr[idx]],k),arr[(idx+1):length(arr)],dims=1)
    elseif idx==length(arr)
        retArr=cat(arr[1:(length(arr)-1)],repeat([arr[idx]],k),dims=1)
    else
        retArr=cat(arr[1:(idx-1)],repeat([arr[idx]],k),arr[(idx+1):length(arr)],dims=1)
    end
end


applyFunc=(f,g) -> x -> g(f(x))

nestFunc=function(f...)
    holdF=applyFunc(f[1],f[2])
    for i in 3:length(f)
        holdF=applyFunc(holdF,f[i])
    end
    return holdF
end


splitFunc=function(depth::Int64)
    global agtTypCnt
    funcList=[]
    for i in 2:depth 
        for j in 1:length(agtTypCnt)
            push!(funcList,x -> numSplit(x,j,i))
        end
    end
end

# now we need a function that calculates the area required given the vector 

areaFunc=function(arr::Array{Int64})
    # we need an open area between each rank thus, our width is 2k-1
    # our height is the max length 
    area=(2*length(arr)-1)*maximum(arr)
    return area
end

# now test functions
f1=x-> x+1
f2=  x -> x+2 
f3= x -> x -3
f4= x -> x^2

# Step 1: We can store each option as a function



arrangeFunc=function(step::Int64)
    global agtTypCnt
    rankVec=ordinalrank(agtTypCnt)
    


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