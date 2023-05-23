
# now, we need to generate the functions that allow actions 

# first, a function that generates the code for the actions 
# let's write a few functions that generate quotes based on the law

function switchLaw(act)
    actType=string(typeof(act))
    engineObj=string(typeof(act.target))
    # find the engine object 
    targetEngine=filter(x -> typeof(x)==typeof(act.target),engineList)[1]
    quote 
        function act(move::$(esc(actType)),alias::alias)
            alias.agt.prevEngine=agt.currEngine
            alias.agt.currEngine=targetEngine
        end
    end
end

# this function generates a quoted function for a deletion law
function deleteLaw(act)
    actType=string(typeof(act))
    engineObj=string(typeof(act.target))
    # find the engine object 
    targetEngine=filter(x -> typeof(x)==typeof(act.target),engineList)[1]
    quote
        function act(move::$(esc(actType)),alias::alias)
            move.target.aliasData[alias.agt]=[]
        end
    end
end
# this function generates a quoted function for a data sharing law 
# 
function sharingLaw(act)
    actType=string(typeof(act))
    engineObj=string(typeof(act.target))
    targetEngine=filter(x -> typeof(x)==typeof(act.target),engineList)[1]
    quote
        function act(move::$(esc(actType)),alias::alias)
            move.target.aliasData[alias]=alias.agt.currEngine.aliasData[alias]
        end
    end
end

function actQuoteGen()
    # get a list of all search engines 
    global actionList
    qArray=[]
    for act in actionList
        if act.law===nothing
            # we need switching instructions
            push!(qArray,switchLaw(act))
        elseif typeof(act.law)==deletion
            push!(qArray,deleteLaw(act))
        else
            push!(qArray,sharingLaw(act))
        end
    end
    return qArray
end

# now generate these functions

function actFuncGen()
    actQuotes=actQuoteGen()
    for q in actQuotes
        eval(q)
    end
end