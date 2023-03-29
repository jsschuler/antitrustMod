#using Luxor
using Javis
using Random
using StatsBase
# initial parameters, agent count 
agtCnt=1000
# search Cnt 
searchCnt=4
# agent preference 
# for now, set random agent preferences 
agtPref=sample(1:searchCnt,agtCnt,replace=true)
# now, how big should each receptacle be?
target=floor(Int64,sqrt(agtCnt))
# now, find the first perfect square greater than this number
i=1
while true
    i=i+1
    if i^2 >= target
        target=i^2
        break
    end
end
agtTyps=sort(agtPref)
# now, we need a target by target array
typeArray=zeros(Int64,(target,target))
k=0
for i in 1:target
    for j in 1:target
        k=k+1
        if k <= length(agtTyps)
            typeArray[i,j]=agtTyps[k]
        end
    end
end

# now try to draw this 
Drawing(1000, 1000)       



function drawmatrix(A::Matrix)
    cellsize=size(A)
table = Table(size(A)..., cellsize...)
used = Set()
for i in CartesianIndices(A)
    r, c = Tuple(i)
    if A[r, c] ∈ used
        sethue("orange")
    else
        sethue("purple")
        push!(used, A[r, c])
    end
    #text(string(A[r, c]), table[r, c],
    #    halign=:center,
    #    valign=:middle)
    circle(O, 20, :fill)
    sethue("white")
    box(table, r, c, action = :stroke)
end
end

A = rand(1:99, 5, 8)

@drawsvg begin

Drawing(1000, 1000)           
background("black")
fontsize(100)
setline(0.5)
sethue("white")
drawmatrix(typeArray, cellsize = 10 .* size(typeArray))
finish()
preview()

end