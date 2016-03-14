while true do
	emu.frameadvance();
	if gameinfo.getromname() == "Galaga" then
		buttons = {
			"Left",
			"Right",
			"Fire"
		}

		i = 7

	emu.frameadvance();
end

BULLET_READY = 0
STATES = {}

function initializeStates()
	for i = 0,2 do
		for j = 7,183 do
			STATES[i .. j] = {left = 0, right = 0, stay = 0, shoot = 0}
		end
	end
end

function getCurrentState() 

	local currentPosition = memory.readbyte(0x0203)
	local bulletFlag1 = memory.readbyte(0x02E1)
	local bulletFlag2 = memory.readbyte(0x02E8)

	if bulletFlag1 == BULLET_READY and bulletFlag2 == BULLET_READY then
		bulletState = 0
	elseif bulletFlag1 == BULLET_READY or bulletFlag2 == BULLET_READY then
		bulletState = 1
	else
		bulletState = 2
	end

	return (bulletState .. currentPosition)

end

function findMaxAction( state ) 

	local left = STATES[state].left
	local right = STATES[state].right
	local stay = STATES[state].stay
	local shoot = STATES[state].shoot

	local tempMax = left

	if tempMax < right tempMax = right end
	if tempMax < stay tempMax = stay end
	if tempMax < shoot tempmax = shoot end

	return getKeyFromValue( STATES[state], tempMax)

end

function getKeyFromValue( t, val )
	local tempMax = {}
	for k,v in pairs(t) do
		if v == val then table.insert(tempMax,k) end
	end
	if table.getn(tempMax) > 1 then
		local randomNum = math.random(0,table.getn(tempmax)+1)
		return table.remove(tempMax, randomNum)
	return nil
end

function chooseAction( state )
	local maxQ = findMaxAction(state)
	return 

function moveLeft( pos )
	if pos != 7 then pos = pos - 1 end
end

function moveRight( pos )
	if pos != 183 then pos = pos + 1 end
end

function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end
