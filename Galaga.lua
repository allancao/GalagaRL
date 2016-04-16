BULLET_READY = 128
STATES = {}
LEFT_EDGE = 7
RIGHT_EDGE = 183
EPSILON = 0.09
INPUTS = {A=false, up=false, left=false, B=false, select=false, right=false, down=false, start=false}
STATE = nil

--[[ Initialize all possible states and values. Possible states use bullets fired, 
	range 0 - 2, concatenated with current ship position. Gives about 531 possible
	states. Possible actions per state are to move left, move right, stay in 
	current position, or shoot. All values are initialzied to zero. ]]

function initializeStates()
	for i = 0,2 do
		for j = LEFT_EDGE,RIGHT_EDGE do
			STATES[tostring(i) .. tostring(j)] = {
				left = math.random(0, 10), 
				right = math.random(0, 10), 
				shoot = math.random(0, 10)
			}
		end
	end

	STATE = savestate.object(1)
	savestate.save(STATE)

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

	local left = STATES[tostring(state)].left
	local right = STATES[tostring(state)].right
	local shoot = STATES[tostring(state)].shoot

	local tempMax = left
	local tempAction = "left"

	if tempMax < right then 
		tempMax = right 
		tempAction = "right"
	end
	if tempMax < shoot then 
		tempmax = shoot 
		tempAction = "shoot"
	end

	return (getKeyFromValue( STATES[tostring(state)], tempMax)), (tempMax)

end

function possibleMoves( state ) 
    local bullets_shot = tonumber(string.sub(state, 0, 1))
    local position = tonumber(string.sub(state, 2, string.len(state)))
	local tempMoves = {}
	local possibleBullets = {}

	if bullets_shot == 0 then
		table.insert(possibleBullets, 0)
	elseif bullets_shot == 1 then
		table.insert(possibleBullets, 0)
		table.insert(possibleBullets, 1)
	elseif bullets_shot == 2 then
		table.insert(possibleBullets, 1)
		table.insert(possibleBullets, 2)
	end

	--[[ left action ]]
	if not(position == LEFT_EDGE) then
		for k,v in pairs(possibleBullets) do
			table.insert(tempMoves, tostring(v) .. tostring(position - 1))
		end
	end

	--[[ right action ]]
	if not(position == RIGHT_EDGE) then
		for k,v in pairs(possibleBullets) do
			table.insert(tempMoves, tostring(v) .. tostring(position + 1))
		end
	end

	--[[ Shoot action ]]
	if bullets_shot == 0 then
		table.insert(tempMoves, "1" .. tostring(position))
	elseif bullets_shot == 1 then
		table.insert(tempMoves, "1" .. tostring(position))
		table.insert(tempMoves, "2" .. tostring(position))
	end

	return tempMoves
end

--[[ Helper method to find max actions. ]]

function getKeyFromValue( t, val )
	local tempMax = {}
	if t.left == val then table.insert(tempMax, "left") end
	if t.right == val then table.insert(tempMax, "right") end
	if t.shoot == val then table.insert(tempMax, "shoot") end

	local randomNum = math.random(1,table.getn(tempMax))
	return table.remove(tempMax, randomNum)
end

-- Q-Learning Algo
function update( state, reward, discount, lrnRate )

	local currentAction, currentValue = findMaxAction(state)

	local possibleMoves = possibleMoves(state)
	local maxStateValues = {}

	local tempMaxState = ""
	local tempMaxValue = -999999

	for k,v in pairs(possibleMoves) do
		local maxState, maxStateValue = findMaxAction(v)
		if maxStateValue > tempMaxValue then
			tempMaxValue = maxStateValue
			tempMaxState = maxState
		end
	end

	local newValue = currentValue + lrnRate * (reward + (discount * tempMaxValue) - currentValue)  
	updateQValue(state, currentAction, newValue)
	emu.print("STATE: " .. state)
	emu.print(STATES[state])
	emu.print("REWARD: " .. reward)
	emu.print("CURRENTVALUE: " .. currentValue)
	emu.print("NEWVALUE: " .. newValue)

end

function updateQValue( state, action, newValue )

	if action == "left" then STATES[tostring(state)].left = newValue
	elseif action == "right" then STATES[tostring(state)].right = newValue
	elseif action == "shoot" then STATES[tostring(state)].shoot = newValue
	end	
end

function getQValue( state, action )
	if action == "left" then return STATES[tostring(state)].left
	elseif action == "right" then return STATES[tostring(state)].right
	elseif action == "shoot" then return STATES[tostring(state)].shoot
	end		
end

function takeAction( state )
	local random = math.random()
	if random > EPSILON then 
		local maxQ = findMaxAction(state)
		if maxQ == "left" then moveLeft()
		elseif maxQ == "right" then moveRight()
		elseif maxQ == "shoot" then shoot()
		end
	else
		random = math.random()
		if random <= .333 then moveLeft()
		elseif random > .333 and random < .666 then moveRight()
		else shoot()
		end
	end
end 

-- {A=false, up=false, left=false, B=false, select=false, right=false, down=false, start=false}
function moveLeft()
	-- INPUTS = {A=false, up=false, left=true, B=false, select=false, right=false, down=false, start=false}
	-- joypad.set(1, INPUTS)
	local oldPos = memory.readbyte(0x0203)
	memory.writebyte(0x0203, oldPos - 1)
	
end

function moveRight()
	-- INPUTS = {A=false, up=false, left=false, B=false, select=false, right=true, down=false, start=false}
	-- joypad.set(1, INPUTS)
	local oldPos = memory.readbyte(0x0203)
	memory.writebyte(0x0203, oldPos + 1)
end

function shoot()
	INPUTS = {A=true, up=false, left=false, B=false, select=false, right=false, down=false, start=false}
	joypad.set(1, INPUTS)
end

function reset()
	INPUTS = {A=false, up=false, left=false, B=false, select=false, right=false, down=false, start=false}
	joypad.set(1, INPUTS)
end

function calculateScore() 
	local first = tostring(memory.readbyte(0x00E0))
	local second = tostring(memory.readbyte(0x00E1))
	local third = tostring(memory.readbyte(0x00E2))
	local fourth = tostring(memory.readbyte(0x00E3))
	local fifth = tostring(memory.readbyte(0x00E4))
	local sixth = tostring(memory.readbyte(0x00E5))
	local seventh = tostring(memory.readbyte(0x00E6))

	local totalScore = tonumber(first .. second .. third .. fourth .. fifth .. sixth .. seventh)
	return totalScore
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

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

-- [[Main Method]]

initializeStates()
local reward = 0
while true do
	reset()
	emu.print("GETCURRENTSTATE")
	emu.print(getCurrentState())
	local discount = 0.9
	local lrnRate = 0.1

	if memory.readbyte(0x0485) == 2 then 
		-- reward = reward + 5
	else
		-- table.saveTable( STATES , "states_table.txt" )
		file = io.open ("states.txt", "a")
		io.output(file)
		io.write(table.tostring(STATES))
		io.close()
		emu.print(STATES)
		savestate.load(STATE)
	end

	if calculateScore() > reward then reward = calculateScore() - reward end

	update(getCurrentState(), reward, discount, lrnRate)
	takeAction(getCurrentState())

	-- local maxAction, actionValue = findMaxAction(getCurrentState())
	-- emu.print(maxAction)
	emu.frameadvance();
	-- reset()
end


