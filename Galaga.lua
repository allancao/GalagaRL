BULLET_READY = 0
STATES = {}
LEFT_EDGE = 7
RIGHT_EDGE = 183 


--[[ Initialize all possible states and values. Possible states use bullets fired, 
	range 0 - 2, concatenated with current ship position. Gives about 531 possible
	states. Possible actions per state are to move left, move right, stay in 
	current position, or shoot. All values are initialzied to zero. ]]

function initializeStates()
	for i = 0,2 do
		for j = LEFT_EDGE,RIGHT_EDGE do
			STATES[i .. j] = {left = 0, right = 0, stay = 0, shoot = 0}
		end
	end
end

--[[ Grabs current bullet and position. Position ranges from LEFT_EDGE to RIGHT_EDGE. 
	Bullet flags are from 120 to 0. Only two bullets can coexist at any point in time.
	BULLET_READY signifies that the bullet has left the map, and is ready to re-enter 
	map through the shoot functionality. ]]

function getCurrentState() 

	local currentPosition = memory.readbyte(0x0203)
	local bulletFlag1 = memory.readbyte(0x02E0)
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

--[[ Given a state, used to find the action with highest value for Q-learning. ]]

function findMaxAction( state ) 

	local left = STATES[state].left
	local right = STATES[state].right
	local stay = STATES[state].stay
	local shoot = STATES[state].shoot

	local tempMax = left

	if tempMax < right then tempMax = right end
	if tempMax < stay then tempMax = stay end
	if tempMax < shoot then tempmax = shoot end

	return getKeyFromValue( STATES[state], tempMax)

end

--[[ Helper method to find max actions. ]]

function getKeyFromValue( t, val )
	local tempMax = {}
	for k,v in pairs(t) do
		if v == val then table.insert(tempMax,k) end
	end

	if table.getn(tempMax) > 1 then
		local randomNum = math.random(0,table.getn(tempmax)+1)
		return table.remove(tempMax, randomNum)
	end
	return nil
end

function chooseAction( state )
	local maxQ = findMaxAction(state)
	return maxQ
end 

function moveLeft( pos )
	if not(pos == LEFT_EDGE) then pos = pos - 1 end
end

function moveRight( pos )
	if not(pos == RIGHT_EDGE) then pos = pos + 1 end
end


--[[ Fancy print method, for extracting sublist elements. ]]

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

while true do
	emu.print(getCurrentState())
	emu.frameadvance();
end


