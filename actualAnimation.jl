using StatsBase
using Javis
# now, we need the actual animation code 
# begin with some paramaters 
# how many agents of each type?
agtTypCnt=[30,15,50,40,15,7,100]
labelVec=Array(1:length(agtTypCnt))
# this yields the number of search engines 
engineCnt=length(agtTypCnt)

# the number of search engines determines everything. 
# now, so long as the number of search engines is > 3, we get 
searchAngle=2*π/length(agtTypCnt)
α=searchAngle/2
# from this alpha, we get the width of the box 
width=2*cos(π/2-α)
# this is relative to the normalized inner radius 
# now, we need enough space to fit all agents 
# the largest group of agents will be the limiting factor 
# ideally, each group will be rougly equally long


# now we need a function that calculates the area required given the vector 

function areaFunc(arr::Array{Int64})
    # we need an open area between each rank thus, our width is 2k-1
    # our height is the max length 
    area=(2*length(arr)-1)*maximum(arr)
    return area
end

# now test functions

# Step 1: We can store each option as a function

# what we need is an array of matrices
function matrixRow(label,i,j)
    # does the length of the array evenly divide by j?
    arr=repeat([label],i)
    remainder=mod(length(arr),j)
    # recall we need buffers of 0's in between
    if remainder > 0
        long=numerator((length(arr)+j-remainder)//j)
        fullArray=cat(arr,repeat([0],(j-remainder)),dims=1)
    else
        long=numerator(length(arr)//j)
        fullArray=arr
    end
    newMat=transpose(reshape(fullArray,(j,long)))
    # now pad with 0's in between
    #outMat=reshape(vcat(newMat,zeros(Int64,size(newMat))),long,2*j)[:,1:size(newMat)[2]]
    return newMat
end




function zeroPad(matr,n)
    newRows=n-size(matr)[1]
    #println(newRows)
    #println(size(matr)[2])
    return vcat(matr,zeros(Int64,(newRows,size(matr)[2])))

end

function matrixArrange(mats)
    long=[]
    for m in mats
        push!(long,size(m)[1])
    end
    maxRow=maximum(long)
    #println(maxRow)
    padArray=[]
    for m in mats
        if size(m)[1] < maxRow
            push!(padArray,zeroPad(m,maxRow))
        else
            push!(padArray,m)
        end
    end
    allTogether=hcat(padArray...)
    # now add the zero rows in between
    zPadArray=[]
    for i in 1:(size(allTogether)[2]-1)
        push!(zPadArray,hcat(allTogether[:,i],zeros(Int64,(maxRow,1))))
    end
    push!(zPadArray,allTogether[:,size(allTogether)[2]])
    finMat=hcat(zPadArray...)
    # now add some final zero-padding
    finMat=vcat(zeros(Int64,1,size(finMat)[2]),finMat,zeros(Int64,1,size(finMat)[2]))
    finMat=hcat(zeros(Int64,size(finMat)[1],1),finMat,zeros(Int64,size(finMat)[1],1))
    return finMat
end


function arrangeFunc()
    global agtTypCnt
    # we need a base dictionary 
    initDict=Dict()
    splitDict=Dict()
    currDict=Dict()
    for i in 1:length(agtTypCnt)
        initDict[i]=agtTypCnt[i]
        splitDict[i]=1
        currDict[i]=agtTypCnt[i]
    end

    # We need an array of dictionaries
    dictArray=[]
    dimArray=[]
    MatArray=[]
    t=0
    halt=false
    while !halt 
    #for t in 1:1000
        t=t+1
        # find the largest rank
        largest=0
        maxIndex=0
        for j in 1:length(agtTypCnt)
            if currDict[j] > largest
                largest=currDict[j]
                maxIndex=j
            end
        end
        # now, split this once more than it has been split before 
        splitDict[maxIndex]=splitDict[maxIndex]+1
        currDict[maxIndex]=numerator((initDict[maxIndex]+splitDict[maxIndex]-mod(initDict[maxIndex],splitDict[maxIndex]))//splitDict[maxIndex])
        # generate matrices 
        matrixTuple=[]
        for i in 1:length(agtTypCnt)
            push!(matrixTuple,matrixRow(i,initDict[i],splitDict[i]))
        end
        finMat=matrixArrange(matrixTuple)
        push!(MatArray,finMat)
        #println(finMat)
        #println(size(finMat))
        #println(currDict)
        if size(finMat)[1]==3
            halt=true
        end
        
    end
    return MatArray
end


# we need a function that calculates the length / width of these matrices
function matRatio(matrix)
    return size(matrix)[1]/size(matrix)[2]
end

# now that we have α, we can solve for r1 and r2. 

function areaFunc(rRatio)
    global α
    # we need to calculate the ratio of the rectangle
    # step 1: get the base
    b1=cos((π/2)-α)
    base=2*b1
    # get other side of the right triangle 
    a1=sin((π/2)-α)
    # now get the chord formed by the isosceles triangle 
    chord=sqrt(1+1-2*cos(α))
    # now get the region between the upper rectangle and the lower triangles 
    region=sqrt(chord^2-(cos((π/2)-α)^2))
    # now get the major size of the whole triangle 
    major=sqrt(rRatio^2-cos((π/2)-α)^2)
    # get the remainder
    target=major-region-a1
    #target=major-a1
    finRatio=target/base
    return finRatio
end

function areaSolve(steps::Int64)
    steps=steps-1
    rng=steps//steps:1//steps:(2*steps)//steps
    allAreas=areaFunc.(Float64.(sqrt(2).*rng))
    return allAreas
end

# now we need a function that takes the minimum
function optimizeShape()
    possibilities=arrangeFunc()
    areaRatio=areaSolve(length(possibilities))
    delta=abs.(areaRatio.-matRatio.(possibilities))
    minDex=(1:length(delta))[delta.==minimum(delta)][1]
    println(minimum(delta))
    # now get final matrix format
    finForm=possibilities[minDex]
    steps=length(possibilities)-1
    rng=sqrt(2).* Array(steps//steps:1//steps:(2*steps)//steps)
    bestRatio=Float64(rng[minDex])
    # now return both the matrix and the ratio 
    bestForm=possibilities[minDex]
    return (bestRatio,bestForm)
end

params=optimizeShape()

rRatio=params[1]
format=params[2]


# now, we want the wider circle to take up 95% of the frame thus, 
rSmall=.95*.5*resolution/rRatio
rLarge=.95*.5*resolution
# now calculate some points 

# set orientation parameter for Google 
# for now, let it be straight up, thus beta=pi/2
orient=π/2
innerPoint=Point(0,rSmall)


# we need another version of this function for plotting

function areaFunc(rSmall,rLarge)
    rRatio=rLarge/rSmall
    global α
    # we need to calculate the ratio of the rectangle
    # step 1: get the base
    b1=cos((π/2)-α)
    base=2*b1
    # get other side of the right triangle 
    a1=sin((π/2)-α)
    # now get the chord formed by the isosceles triangle 
    chord=sqrt(1+1-2*cos(α))
    # now get the region between the upper rectangle and the lower triangles 
    region=sqrt(chord^2-(cos((π/2)-α)^2))
    # now get the major size of the whole triangle 
    major=sqrt(rRatio^2-cos((π/2)-α)^2)
    # get the remainder
    target=major-a1-region
    finRatio=target/base
    return [b1,a1,chord,region,target]
end


# begin with Luxor 
# we want a function that generates agent colors based on 
function colorFunc(num::Int64)
    if num==1
        return "blue"
    elseif num==2
        return "green"
    elseif num==3
        return "red"
    else
        return "yellow"
    end
end


@drawsvg begin
    #Drawing(400, 400)
    background("black")
    #sethue("white")
    sethue(convert(RGB,HSL(50,.5,.5)))
    
    # now draw the inner circle 
    
    p1=Point(rSmall,0)
    p2=Point(rLarge,0)
    circle(O, rSmall, :stroke)
    circle(O, rLarge, :stroke)

    # now, we need a point indicating orientation
    orient=Point(0,rSmall)
    line(O,-orient)
    ref=Point(rSmall,0)
    ref2=Point(-rSmall,0)
    line(O,ref)
    line(O,ref2)

    # now we need the boundaries of the first receptacle
    lower11=Point(rSmall*cos(α),-rSmall*sin(α))
    lower01=Point(-rSmall*cos(α),-rSmall*sin(α))
    line(O,lower11)
    line(O,lower01)

    vParams=areaFunc(rSmall,rLarge)
    b1=rSmall*vParams[1]
    a1=rSmall*vParams[2]
    chord=rSmall*vParams[3]
    region=rSmall*vParams[4]
    target=rSmall*vParams[5]
    # now, we need the upper boundaries
    #box11=lower11+Point(0,-region)
    #line(lower11,box11)
    #box01=lower01+Point(0,-region)
    #line(lower01,box01)
    #line(box01,box11)

    #box02=box01+Point(0,-target)
    #box12=box11+Point(0,-target)

    #line(box01,box02)
    #line(box11,box12)
    #line(box02,box12)
    closepath()
    
    strokepath()
end
    # now place holders for the agents 
    agentPlace=params[2]
    dims=size(agentPlace)
    yRange=abs(box01[2]-box02[2])
    xRange=abs(box02[1]-box12[1])
    #curve(Point(150, 150), Point(0, 100), Point(-200, -200))
    xBoxLim=xRange/dims[2]
    yBoxLim=yRange/dims[1]
    xLims=box02[1]:xBoxLim:box12[1]
    yLims=box02[2]:yBoxLim:box01[2]
    xBoxHalf=xBoxLim/2
    yBoxHalf=yBoxLim/2
    # now generate centers
    centerVec=[]
    colorVec=[]
    for i in 1:(length(xLims)-1)
        for j in 1:(length(yLims)-1)
            if agentPlace[j,i] > 0
                push!(centerVec,Point(xLims[i]+xBoxHalf,yLims[j]-yBoxHalf))
                push!(colorVec, colorFunc(agentPlace[j,i]))
            end
        end

    end
    
    circR=.6*xBoxHalf
    sethue("red")
    for p in 1:length(centerVec)
        sethue(colorVec[p])
        circle(centerVec[p], circR, :fill)
    end
    sethue("white")
    line(box01,box02)
    line(box11,box12)
    line(box02,box12)
    line(lower01,box01)
    line(lower11,box11)



    closepath()
    
    strokepath()

    rotate(-2*α)

    orient=Point(0,rSmall)
    line(O,-orient)
    ref=Point(rSmall,0)
    ref2=Point(-rSmall,0)
    line(O,ref)
    line(O,ref2)
    # now we need the boundaries of the first receptacle
    lower11=Point(rSmall*cos(α),-rSmall*sin(α))
    lower01=Point(-rSmall*cos(α),-rSmall*sin(α))
    line(O,lower11)
    line(O,lower01)

    vParams=areaFunc(rSmall,rLarge)
    b1=rSmall*vParams[1]
    a1=rSmall*vParams[2]
    chord=rSmall*vParams[3]
    region=rSmall*vParams[4]
    target=rSmall*vParams[5]
    # now, we need the upper boundaries
    box11=lower11+Point(0,-region)
    line(lower11,box11)
    box01=lower01+Point(0,-region)
    line(lower01,box01)
    line(box01,box11)

    box02=box01+Point(0,-target)
    box12=box11+Point(0,-target)

    line(box01,box02)
    line(box11,box12)
    line(box02,box12)

    # now place holders for the agents 
    agentPlace=params[2]
    dims=size(agentPlace)
    yRange=abs(box01[2]-box02[2])
    xRange=abs(box02[1]-box12[1])
    #curve(Point(150, 150), Point(0, 100), Point(-200, -200))
    xBoxLim=xRange/dims[2]
    yBoxLim=yRange/dims[1]
    xLims=box02[1]:xBoxLim:box12[1]
    yLims=box02[2]:yBoxLim:box01[2]
    xBoxHalf=xBoxLim/2
    yBoxHalf=yBoxLim/2
    # now generate centers
    centerVec=[]
    for i in 1:(length(xLims)-1)
        for j in 1:(length(yLims)-1)
            if agentPlace[j,i] > 0
                push!(centerVec,Point(xLims[i]+xBoxHalf,yLims[j]-yBoxHalf))
            end
        end

    end
    circR=.6*xBoxHalf
    sethue("red")
    for p in centerVec
        circle(p, circR, :fill)
    end
    sethue("white")
    line(box01,box02)
    line(box11,box12)
    line(box02,box12)
    line(lower01,box01)
    line(lower11,box11)

    closepath()
    
    strokepath()

    rotate(-2*α)

    orient=Point(0,rSmall)
    line(O,-orient)
    ref=Point(rSmall,0)
    ref2=Point(-rSmall,0)
    line(O,ref)
    line(O,ref2)
    # now we need the boundaries of the first receptacle
    lower11=Point(rSmall*cos(α),-rSmall*sin(α))
    lower01=Point(-rSmall*cos(α),-rSmall*sin(α))
    line(O,lower11)
    line(O,lower01)

    vParams=areaFunc(rSmall,rLarge)
    b1=rSmall*vParams[1]
    a1=rSmall*vParams[2]
    chord=rSmall*vParams[3]
    region=rSmall*vParams[4]
    target=rSmall*vParams[5]
    # now, we need the upper boundaries
    box11=lower11+Point(0,-region)
    line(lower11,box11)
    box01=lower01+Point(0,-region)
    line(lower01,box01)
    line(box01,box11)

    box02=box01+Point(0,-target)
    box12=box11+Point(0,-target)

    line(box01,box02)
    line(box11,box12)
    line(box02,box12)

    # now place holders for the agents 
    agentPlace=params[2]
    dims=size(agentPlace)
    yRange=abs(box01[2]-box02[2])
    xRange=abs(box02[1]-box12[1])
    #curve(Point(150, 150), Point(0, 100), Point(-200, -200))
    xBoxLim=xRange/dims[2]
    yBoxLim=yRange/dims[1]
    xLims=box02[1]:xBoxLim:box12[1]
    yLims=box02[2]:yBoxLim:box01[2]
    xBoxHalf=xBoxLim/2
    yBoxHalf=yBoxLim/2
    # now generate centers
    centerVec=[]
    for i in 1:(length(xLims)-1)
        for j in 1:(length(yLims)-1)
            if agentPlace[j,i] > 0
                push!(centerVec,Point(xLims[i]+xBoxHalf,yLims[j]-yBoxHalf))
            end
        end

    end
    circR=.6*xBoxHalf
    sethue("red")
    for p in centerVec
        circle(p, circR, :fill)
    end
    sethue("white")
    line(box01,box02)
    line(box11,box12)
    line(box02,box12)
    line(lower01,box01)
    line(lower11,box11)

    closepath()
    
    strokepath()

    rotate(-2*α)

    orient=Point(0,rSmall)
    line(O,-orient)
    ref=Point(rSmall,0)
    ref2=Point(-rSmall,0)
    line(O,ref)
    line(O,ref2)
    # now we need the boundaries of the first receptacle
    lower11=Point(rSmall*cos(α),-rSmall*sin(α))
    lower01=Point(-rSmall*cos(α),-rSmall*sin(α))
    line(O,lower11)
    line(O,lower01)

    vParams=areaFunc(rSmall,rLarge)
    b1=rSmall*vParams[1]
    a1=rSmall*vParams[2]
    chord=rSmall*vParams[3]
    region=rSmall*vParams[4]
    target=rSmall*vParams[5]
    # now, we need the upper boundaries
    box11=lower11+Point(0,-region)
    line(lower11,box11)
    box01=lower01+Point(0,-region)
    line(lower01,box01)
    line(box01,box11)

    box02=box01+Point(0,-target)
    box12=box11+Point(0,-target)

    line(box01,box02)
    line(box11,box12)
    line(box02,box12)

    # now place holders for the agents 
    agentPlace=params[2]
    dims=size(agentPlace)
    yRange=abs(box01[2]-box02[2])
    xRange=abs(box02[1]-box12[1])
    #curve(Point(150, 150), Point(0, 100), Point(-200, -200))
    xBoxLim=xRange/dims[2]
    yBoxLim=yRange/dims[1]
    xLims=box02[1]:xBoxLim:box12[1]
    yLims=box02[2]:yBoxLim:box01[2]
    xBoxHalf=xBoxLim/2
    yBoxHalf=yBoxLim/2
    # now generate centers
    centerVec=[]
    for i in 1:(length(xLims)-1)
        for j in 1:(length(yLims)-1)
            if agentPlace[j,i] > 0
                push!(centerVec,Point(xLims[i]+xBoxHalf,yLims[j]-yBoxHalf))
            end
        end

    end
    circR=.6*xBoxHalf
    sethue("red")
    for p in centerVec
        circle(p, circR, :fill)
    end
    sethue("white")
    line(box01,box02)
    line(box11,box12)
    line(box02,box12)
    line(lower01,box01)
    line(lower11,box11)

    closepath()
    
    strokepath()
end




Background(1:frames, ground)

# guide points
#p1 = Object(1:frames, JCircle(O, 5, color = "blue", action = :fill), Point(0,-rSmall))
#p2 = Object(1:frames, JCircle(O, 5, color = "blue", action = :fill), Point(rSmall,0))
#p3= Object(1:frames, JCircle(O, 5, color = "blue", action = :fill), Point(rSmall,-rSmall))
#@drawsvg begin

#earth_orbit = Object(@JShape begin
#    sethue(color)
#    setdash(edge)
#    circle(O, rLarge, action)
#end color = "white" action = :stroke edge = "solid")

#venus_orbit = Object(@JShape begin
#    sethue(color)
#    setdash(edge)
#    circle(O, rSmall, action)
#end color = "white" action = :stroke edge = "solid")




function ground(args...)
    background("black")
    sethue("white")
end
resolution=500
myvideo = Video(resolution, resolution)
# now, we want the wider circle to take up 95% of the frame thus, 
rSmall=.95*.5*resolution/rRatio
rLarge=.95*.5*resolution
# now calculate some points 

# set orientation parameter for Google 
# for now, let it be straight up, thus beta=pi/2
orient=π/2
innerPoint=Point(0,rSmall)

@drawsvg begin
    #Drawing(400, 400)
    background("black")
    sethue("white")
    
    
    # now draw the inner circle 
    
    p1=Point(rSmall,0)
    p2=Point(rLarge,0)
    circle(O, rSmall, :stroke)
    circle(O, rLarge, :stroke)
    # now, we need a point indicating orientation
    orient=Point(0,rSmall)
    line(O,-orient)
    ref=Point(rSmall,0)
    ref2=Point(-rSmall,0)
    line(O,ref)
    line(O,ref2)
    # now we need the boundaries of the first receptacle
    lower11=Point(rSmall*cos(α),-rSmall*sin(α))
    lower01=Point(-rSmall*cos(α),-rSmall*sin(α))
    line(O,lower11)
    line(O,lower01)

    vParams=areaFunc(rSmall,rLarge)
    b1=rSmall*vParams[1]
    a1=rSmall*vParams[2]
    chord=rSmall*vParams[3]
    region=rSmall*vParams[4]
    target=rSmall*vParams[5]
    # now, we need the upper boundaries
    box11=lower11+Point(0,-region)
    line(lower11,box11)
    box01=lower01+Point(0,-region)
    line(lower01,box01)
    line(box01,box11)

    box02=box01+Point(0,-target)
    box12=box11+Point(0,-target)

    line(box01,box02)
    line(box11,box12)
    line(box02,box12)

    # now place holders for the agents 
    agentPlace=params[2]
    dims=size(agentPlace)
    yRange=abs(box01[2]-box02[2])
    xRange=abs(box02[1]-box12[1])
    #curve(Point(150, 150), Point(0, 100), Point(-200, -200))
    xBoxLim=xRange/dims[2]
    yBoxLim=yRange/dims[1]
    xLims=box02[1]:xBoxLim:box12[1]
    yLims=box02[2]:yBoxLim:box01[2]
    xBoxHalf=xBoxLim/2
    yBoxHalf=yBoxLim/2
    # now generate centers
    centerVec=[]
    colorVec=[]
    for i in 1:(length(xLims)-1)
        for j in 1:(length(yLims)-1)
            if agentPlace[j,i] > 0
                push!(centerVec,Point(xLims[i]+xBoxHalf,yLims[j]-yBoxHalf))
                push!(colorVec, colorFunc(agentPlace[j,i]))
            end
        end

    end
    circR=.6*xBoxHalf
    sethue("red")
    for p in 1:length(centerVec)
        sethue(colorVec[p])
        circle(centerVec[p], circR, :fill)
    end
    sethue("white")
    line(box01,box02)
    line(box11,box12)
    line(box02,box12)
    line(lower01,box01)
    line(lower11,box11)



    closepath()
    
    strokepath()

    rotate(-2*α)

    orient=Point(0,rSmall)
    line(O,-orient)
    ref=Point(rSmall,0)
    ref2=Point(-rSmall,0)
    line(O,ref)
    line(O,ref2)
    # now we need the boundaries of the first receptacle
    lower11=Point(rSmall*cos(α),-rSmall*sin(α))
    lower01=Point(-rSmall*cos(α),-rSmall*sin(α))
    line(O,lower11)
    line(O,lower01)

    vParams=areaFunc(rSmall,rLarge)
    b1=rSmall*vParams[1]
    a1=rSmall*vParams[2]
    chord=rSmall*vParams[3]
    region=rSmall*vParams[4]
    target=rSmall*vParams[5]
    # now, we need the upper boundaries
    box11=lower11+Point(0,-region)
    line(lower11,box11)
    box01=lower01+Point(0,-region)
    line(lower01,box01)
    line(box01,box11)

    box02=box01+Point(0,-target)
    box12=box11+Point(0,-target)

    line(box01,box02)
    line(box11,box12)
    line(box02,box12)

    # now place holders for the agents 
    agentPlace=params[2]
    dims=size(agentPlace)
    yRange=abs(box01[2]-box02[2])
    xRange=abs(box02[1]-box12[1])
    #curve(Point(150, 150), Point(0, 100), Point(-200, -200))
    xBoxLim=xRange/dims[2]
    yBoxLim=yRange/dims[1]
    xLims=box02[1]:xBoxLim:box12[1]
    yLims=box02[2]:yBoxLim:box01[2]
    xBoxHalf=xBoxLim/2
    yBoxHalf=yBoxLim/2
    # now generate centers
    centerVec=[]
    for i in 1:(length(xLims)-1)
        for j in 1:(length(yLims)-1)
            if agentPlace[j,i] > 0
                push!(centerVec,Point(xLims[i]+xBoxHalf,yLims[j]-yBoxHalf))
            end
        end

    end
    circR=.6*xBoxHalf
    sethue("red")
    for p in centerVec
        circle(p, circR, :fill)
    end
    sethue("white")
    line(box01,box02)
    line(box11,box12)
    line(box02,box12)
    line(lower01,box01)
    line(lower11,box11)

    closepath()
    
    strokepath()

    rotate(-2*α)

    orient=Point(0,rSmall)
    line(O,-orient)
    ref=Point(rSmall,0)
    ref2=Point(-rSmall,0)
    line(O,ref)
    line(O,ref2)
    # now we need the boundaries of the first receptacle
    lower11=Point(rSmall*cos(α),-rSmall*sin(α))
    lower01=Point(-rSmall*cos(α),-rSmall*sin(α))
    line(O,lower11)
    line(O,lower01)

    vParams=areaFunc(rSmall,rLarge)
    b1=rSmall*vParams[1]
    a1=rSmall*vParams[2]
    chord=rSmall*vParams[3]
    region=rSmall*vParams[4]
    target=rSmall*vParams[5]
    # now, we need the upper boundaries
    box11=lower11+Point(0,-region)
    line(lower11,box11)
    box01=lower01+Point(0,-region)
    line(lower01,box01)
    line(box01,box11)

    box02=box01+Point(0,-target)
    box12=box11+Point(0,-target)

    line(box01,box02)
    line(box11,box12)
    line(box02,box12)

    # now place holders for the agents 
    agentPlace=params[2]
    dims=size(agentPlace)
    yRange=abs(box01[2]-box02[2])
    xRange=abs(box02[1]-box12[1])
    #curve(Point(150, 150), Point(0, 100), Point(-200, -200))
    xBoxLim=xRange/dims[2]
    yBoxLim=yRange/dims[1]
    xLims=box02[1]:xBoxLim:box12[1]
    yLims=box02[2]:yBoxLim:box01[2]
    xBoxHalf=xBoxLim/2
    yBoxHalf=yBoxLim/2
    # now generate centers
    centerVec=[]
    for i in 1:(length(xLims)-1)
        for j in 1:(length(yLims)-1)
            if agentPlace[j,i] > 0
                push!(centerVec,Point(xLims[i]+xBoxHalf,yLims[j]-yBoxHalf))
            end
        end

    end
    circR=.6*xBoxHalf
    sethue("red")
    for p in centerVec
        circle(p, circR, :fill)
    end
    sethue("white")
    line(box01,box02)
    line(box11,box12)
    line(box02,box12)
    line(lower01,box01)
    line(lower11,box11)

    closepath()
    
    strokepath()

    rotate(-2*α)

    orient=Point(0,rSmall)
    line(O,-orient)
    ref=Point(rSmall,0)
    ref2=Point(-rSmall,0)
    line(O,ref)
    line(O,ref2)
    # now we need the boundaries of the first receptacle
    lower11=Point(rSmall*cos(α),-rSmall*sin(α))
    lower01=Point(-rSmall*cos(α),-rSmall*sin(α))
    line(O,lower11)
    line(O,lower01)

    vParams=areaFunc(rSmall,rLarge)
    b1=rSmall*vParams[1]
    a1=rSmall*vParams[2]
    chord=rSmall*vParams[3]
    region=rSmall*vParams[4]
    target=rSmall*vParams[5]
    # now, we need the upper boundaries
    box11=lower11+Point(0,-region)
    line(lower11,box11)
    box01=lower01+Point(0,-region)
    line(lower01,box01)
    line(box01,box11)

    box02=box01+Point(0,-target)
    box12=box11+Point(0,-target)

    line(box01,box02)
    line(box11,box12)
    line(box02,box12)

    # now place holders for the agents 
    agentPlace=params[2]
    dims=size(agentPlace)
    yRange=abs(box01[2]-box02[2])
    xRange=abs(box02[1]-box12[1])
    #curve(Point(150, 150), Point(0, 100), Point(-200, -200))
    xBoxLim=xRange/dims[2]
    yBoxLim=yRange/dims[1]
    xLims=box02[1]:xBoxLim:box12[1]
    yLims=box02[2]:yBoxLim:box01[2]
    xBoxHalf=xBoxLim/2
    yBoxHalf=yBoxLim/2
    # now generate centers
    centerVec=[]
    for i in 1:(length(xLims)-1)
        for j in 1:(length(yLims)-1)
            if agentPlace[j,i] > 0
                push!(centerVec,Point(xLims[i]+xBoxHalf,yLims[j]-yBoxHalf))
            end
        end

    end
    circR=.6*xBoxHalf
    sethue("red")
    for p in centerVec
        circle(p, circR, :fill)
    end
    sethue("white")
    line(box01,box02)
    line(box11,box12)
    line(box02,box12)
    line(lower01,box01)
    line(lower11,box11)

    closepath()
    
    strokepath()
    end

    #render(myvideo; pathname = "cosmic_dance.gif")


