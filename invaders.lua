-- Space Invaders for ComputerCraft

-- Screen Setup
local w, h = term.getSize()

-- Game Variables
local playerX = math.floor(w / 2)
local aliens = {}
local score = 0
local bullets = {}
local isGameOver = false
local playerLives = 3
local tickRate = 0.1 -- Time in seconds for each game ticklocal alienMoveInterval = 3 -- Number of ticks before aliens move
local alienMoveInterval = 3 -- Number of ticks before aliens move
local waverMoveInterval = 3 -- Number of ticks before aliens move
local tickCounter = 0 -- Tracks the number of ticks
local tickCounterWaver = 0 -- Tracks the number of ticks
local lastScoreForExtraAlien = 0
local alienAmount = 5
local waversAmount = 3
local wavers = {}

local leaderboard = {}

local function loadLeaderboard()
    if fs.exists("leaderboard.txt") then
        local file = fs.open("leaderboard.txt", "r")
        leaderboard = {}
        local line = file.readLine()
        while line do
            local name, score = string.match(line, "(.+),(%d+)")
            table.insert(leaderboard, { name = name, score = tonumber(score) })
            line = file.readLine()
        end
        file.close()
    end
end

loadLeaderboard()


local explosion = {
    active = false,
    x = 0,
    y = 0,
    frameIndex = 1,
    frames = {"*", "x", "#", "@"},
    maxFrameIndex = 4,
    duration = 4, -- Number of ticks for which explosion is displayed
    tickCount = 0
}
local playerHit = {
    active = false,
    duration = 2, -- Duration of the hit animation in ticks
    tickCount = 0
}
local shockwave = {
    active = false,
    x = 0,
    spread = 0, -- How far the shockwave has spread from the center
    maxSpread = 5, -- Maximum spread of the shockwave
    duration = 5, -- Duration of the shockwave in ticks
    tickCount = 0
}
local gameOverArt = {
    "              GGG   A   M   M EEEEE",
    "             G     A A  MM MM E   ",
    "             G  GG AAAA M M M EEEE",
    "             G   G A  A M   M E   ",
    "              GGG  A  A M   M EEEEE",
    "             ",
    "              OOO  V   V EEEEE RRRR ",
    "             O   O V   V E     R   R",
    "             O   O V   V EEEE  RRRR ",
    "             O   O  V V  E     R R  ",
    "              OOO    V   EEEEE R  RR"
}
local invadersTitleArt = {
    "  ___                 _            ",
    " |_ _|_ ___ ____ _ __| |___ _ _ ___",
    "  | || ' \\ V / _` / _` / -_) '_(_-<",
    " |___|_||_\\_/\\__,_\\__,_\\___|_| /__/",
    "                                  "
}


local startY = math.floor((h) / 2)  -- Vertical centering

local function displayTitle()
    term.clear()
    for i, line in ipairs(invadersTitleArt) do
        local x = math.floor((w - string.len(line)) / 2)  -- Horizontal centering
        term.setCursorPos(x, startY + i)
        print(line)
    end
end

local function promptPlayerName()
    print("\n\n")  -- Extra lines for spacing
    term.write("Enter your name: ")
    local x = math.floor((w - 15) / 2)  -- Adjust '15' based on the prompt length
    return read()
end

displayTitle()
local playerName = promptPlayerName()

local function getDifficultyName(score)
    local difficultyNames = {
        { threshold = 100, name = "Easy Peasy" },
        { threshold = 200, name = "Getting Started" },
        { threshold = 300, name = "Space Cadet" },
        { threshold = 400, name = "Starry Novice" },
        { threshold = 500, name = "Cosmic Rookie" },
        { threshold = 600, name = "Interstellar Learner" },
        { threshold = 700, name = "Galaxy Pupil" },
        { threshold = 800, name = "Shooting Star" },
        { threshold = 900, name = "Comet Tail" },
        { threshold = 1000, name = "Moon Walker" },
        { threshold = 1100, name = "Planetary Defender" },
        { threshold = 1200, name = "Asteroid Dodger" },
        { threshold = 1300, name = "Nebula Navigator" },
        { threshold = 1400, name = "Space Voyager" },
        { threshold = 1500, name = "Orbit Jumper" },
        { threshold = 1600, name = "Star Surfer" },
        { threshold = 1700, name = "Cosmic Crusader" },
        { threshold = 1800, name = "Galaxy Guardian" },
        { threshold = 1900, name = "Stellar Warrior" },
        { threshold = 2000, name = "Meteor Master" },
        { threshold = 2100, name = "Interstellar Ace" },
        { threshold = 2200, name = "Supernova Survivor" },
        { threshold = 2300, name = "Black Hole Bypass" },
        { threshold = 2400, name = "Universe Undefeated" },
        { threshold = 2500, name = "Celestial Champion" },
        { threshold = 2600, name = "Quantum Queller" },
        { threshold = 2700, name = "Galactic Guru" },
        { threshold = 2800, name = "Starlight Strategist" },
        { threshold = 2900, name = "Master Space Commander" }
        -- You can continue adding more thresholds and names as needed
    }

    local currentDifficulty = "Newbie Explorer" -- Default difficulty name
    for _, difficulty in ipairs(difficultyNames) do
        if score < difficulty.threshold then
            break
        end
        currentDifficulty = difficulty.name
    end
    return currentDifficulty
end


-- Initialize Aliens
local function initAliens()
    for i = 1, 5 do
        local x = math.random(1, w) -- Random x position
        table.insert(aliens, { x = x, y = 3 })
    end
end

local function initWavers()
    for i = 1, 3 do  -- You can adjust the number of initial Wavers
        table.insert(wavers, { x = math.random(1, w), y = 2, dx = 1 })
    end
end

-- Updated Draw Function
local function draw()
    term.clear()
	
    if explosion.active then
        term.setTextColor(colors.orange)
        term.setCursorPos(explosion.x, explosion.y)
        write(explosion.frames[explosion.frameIndex])
    end


    -- Draw player's ship
    if not playerHit.active then
        term.setTextColor(colors.green)
        term.setCursorPos(playerX, h)
        write("A")
    end

    -- Draw Shockwave
    if shockwave.active then
        term.setTextColor(colors.orange)
        for i = -shockwave.spread, shockwave.spread do
            if playerX + i > 0 and playerX + i <= w then
                term.setCursorPos(playerX + i, h)
                write("-") -- Shockwave symbol
            end
        end
    end
	
	-- Draw Wavers in a different color
	term.setTextColor(colors.orange)
	for _, waver in pairs(wavers) do
		term.setCursorPos(waver.x, waver.y)
		write("W")  -- Or any symbol you prefer for Wavers
	end

    -- Draw aliens in red
    term.setTextColor(colors.red)
    for _, alien in pairs(aliens) do
        term.setCursorPos(alien.x, alien.y)
        write("V")
    end

    -- Draw bullets in yellow
    term.setTextColor(colors.yellow)
    for _, bullet in pairs(bullets) do
        term.setCursorPos(bullet.x, bullet.y)
        write("|")
    end

    -- Reset text color to white
    term.setTextColor(colors.white)

    -- Draw score, lives, and difficulty
    term.setCursorPos(1, 1)
    local difficultyName = getDifficultyName(score)
    write("Score: " .. score .. "  Lives: ")

	for i = 1, playerLives do
		term.setTextColor(colors.green)
		write("A ")
	end
	
	-- draw current game difficulty
    term.setTextColor(colors.white)
    term.setCursorPos(1, 2)
    write("  Difficulty: " .. difficultyName)
	
	term.setTextColor(colors.white) -- Resetting text color

end


-- Function to Shoot Bullets
local function shoot()
    table.insert(bullets, { x = playerX, y = h - 1 })
end

-- Function to Update Bullets and Check for Collisions
local function updateBullets()
    local newBullets = {}
    for _, bullet in pairs(bullets) do
        local nextBulletY = bullet.y - 1
        local hit = false
        for i = #aliens, 1, -1 do
            local alien = aliens[i]
            local nextAlienY = alien.y + 1
            if bullet.x == alien.x and (nextBulletY == alien.y or nextBulletY == alien.y-1 or bullet.y == nextAlienY) then
				explosion.active = true
				explosion.x = alien.x
				explosion.y = alien.y
				explosion.frameIndex = 1
				explosion.tickCount = 0
                table.remove(aliens, i)
                score = score + 10
                hit = true
                break
            end
        end
        for i = #wavers, 1, -1 do
            local waver = wavers[i]
            local nextAlienY = waver.y + 1
            if bullet.x == waver.x and (nextBulletY == waver.y or nextBulletY == waver.y-1 or bullet.y == nextAlienY) then
				explosion.active = true
				explosion.x = waver.x
				explosion.y = waver.y
				explosion.frameIndex = 1
				explosion.tickCount = 0
                table.remove(wavers, i)
                score = score + 10
                hit = true
                break
            end
        end
        if not hit and nextBulletY > 0 then
            bullet.y = nextBulletY
            table.insert(newBullets, bullet)
        end
    end
    bullets = newBullets
end

local playerHit = {
    active = false,
    duration = 2, -- Duration of the hit animation in ticks
    tickCount = 0
}

-- Player Control
local function movePlayer(direction)
    if direction == "left" and playerX > 1 then
        playerX = playerX - 1
    elseif direction == "right" and playerX < w then
        playerX = playerX + 1
    end
end

-- Function to Move Aliens Down
local function updateAliens()
    -- Only move aliens after a certain number of ticks
    if tickCounter >= alienMoveInterval then
        for _, alien in pairs(aliens) do
            alien.y = alien.y + 1
            if alien.y > h then
                alien.y = 3 -- Reset alien position if it reaches the bottom
                alien.x = math.random(1, w) -- Reset alien position if it reaches the bottom
            end
        end
        tickCounter = 0 -- Reset counter after moving aliens
    else
        tickCounter = tickCounter + 1 -- Increment counter
    end
end

-- Function to Move Wavers Down
local function updateWavers()
    -- Only move aliens after a certain number of ticks
    if tickCounterWaver >= waverMoveInterval then
        for _, waver in pairs(wavers) do
		
			local move = math.random(1, 3)  -- Randomly choose between 1, 2, or 3

			if move == 1 then
				-- Move left
				waver.x = math.max(1, waver.x - 1)
			elseif move == 2 then
				-- Move right
				waver.x = math.min(w, waver.x + 1)
			end
			-- If move is 3, Waver continues forward without changing x position


			-- Keep Wavers within screen bounds
			if waver.x <= 1 then
				waver.x = 2
				waver.dx = 1
			elseif waver.x >= w then
				waver.x = w - 1
				waver.dx = -1
			end
			
            waver.y = waver.y + 1
			
            if waver.y > h then
                waver.y = 3 -- Reset alien position if it reaches the bottom
                waver.x = math.random(1, w) -- Reset alien position if it reaches the bottom
            end
        end
        tickCounterWaver = 0 -- Reset counter after moving aliens
    else
        tickCounterWaver = tickCounterWaver + 1 -- Increment counter
    end
end

-- Function to Check and Update Alien Count
local function checkAndUpdateAliens()
    if score >= lastScoreForExtraAlien + 100 then
        lastScoreForExtraAlien = score
		alienAmount = alienAmount + 1
		waversAmount = waversAmount + 0.25
        local x = math.random(1, w) -- Random x position for new alien
        table.insert(aliens, { x = x, y = 1 })
    end
end

-- Function to Spawn a New Alien at a Random Position
local function spawnAlien()
    local x = math.random(1, w) -- Random x position along the top
    table.insert(aliens, { x = x, y = 1 })
end
-- Function to Spawn a New Waver at a Random Position
local function spawnWaver()
    local x = math.random(1, w) -- Random x position along the top
    table.insert(wavers, { x = x, y = 1 })
end

-- Function to Check for Player-Alien Collision
local function checkPlayerCollision()
    for i = #aliens, 1, -1 do
        local alien = aliens[i]
        if alien.x == playerX and alien.y == h then
			-- When the player is hit
			shockwave.active = true
			shockwave.x = playerX
			shockwave.tickCount = 0
			shockwave.spread = 0
			-- Player hit logic...

            playerLives = playerLives - 1
            table.remove(aliens, i) -- Remove the colliding alien
            if playerLives <= 0 then
                isGameOver = true
                return
            end
        end
    end
    for i = #wavers, 1, -1 do
        local waver = wavers[i]
        if waver.x == playerX and waver.y == h then
			-- When the player is hit
			shockwave.active = true
			shockwave.x = playerX
			shockwave.tickCount = 0
			shockwave.spread = 0
			-- Player hit logic...

            playerLives = playerLives - 1
            table.remove(wavers, i) -- Remove the colliding waver
            if playerLives <= 0 then
                isGameOver = true
                return
            end
        end
    end
end

-- Game Initialization
initAliens()
draw()

-- Main Game Loop
local timerId = os.startTimer(tickRate)
while not isGameOver do
    -- Handle events (key and timer)
    local event, id = os.pullEvent()

    if event == "timer" and id == timerId then
        -- Game tick update
        updateBullets()
        updateAliens()
		if score >= 200 then
			updateWavers()
		end
		checkAndUpdateAliens()

        -- Check for player-alien collision
        checkPlayerCollision()

        -- -- Check if new aliens should be spawned
        if #aliens < alienAmount then
            spawnAlien()
        end
		if score >= 200 and #wavers == 0 then
			initWavers()
		end
		if score >= 200 then
			if #wavers < waversAmount then
				spawnWaver()
			end
		end
			
		if playerHit.active then
			playerHit.tickCount = playerHit.tickCount + 1
			if playerHit.tickCount >= playerHit.duration then
				playerHit.active = false
				playerHit.tickCount = 0
			end
		end
			
		-- Update Shockwave State
		if shockwave.active then
			shockwave.tickCount = shockwave.tickCount + 1
			shockwave.spread = shockwave.spread + 1

			if shockwave.tickCount >= shockwave.duration then
				shockwave.active = false
				shockwave.tickCount = 0
				shockwave.spread = 0
				playerX = math.floor(w / 2) -- Move player back to center after shockwave
			end
		end
		
		-- Update Explosion
		if explosion.active then
			explosion.tickCount = explosion.tickCount + 1
			if explosion.tickCount >= explosion.duration then
				explosion.active = false
				explosion.tickCount = 0
			else
				explosion.frameIndex = (explosion.frameIndex % explosion.maxFrameIndex) + 1
			end
		end

        -- Redraw and reset timer
        draw()
        timerId = os.startTimer(tickRate)

    elseif event == "key" then
        -- Handle key input
        if id == keys.a then
            movePlayer("left")
        elseif id == keys.d then
            movePlayer("right")
        elseif id == keys.space then
            shoot()
        end
    end

    -- Additional game logic (e.g., game over conditions)
end

if isGameOver then
    table.insert(leaderboard, { name = playerName, score = score })
    table.sort(leaderboard, function(a, b) return a.score > b.score end)
    -- Save leaderboard
    local function saveLeaderboard()
        local file = fs.open("leaderboard.txt", "w")
        for _, entry in ipairs(leaderboard) do
            file.writeLine(entry.name .. "," .. tostring(entry.score))
        end
        file.close()
    end
    saveLeaderboard()
end

-- Game Over Message
term.clear()

local function showGameOverScreen()
    term.clear()
    term.setCursorPos(1, math.floor((h - #gameOverArt) / 2))
    for _, line in ipairs(gameOverArt) do
        print(line)
    end
end

showGameOverScreen()
-- ... (after showing game over screen)

local function displayLeaderboard()
    print("Leaderboard:")
    for i, entry in ipairs(leaderboard) do
        print(i .. ". " .. entry.name .. " - " .. entry.score)
    end
end

displayLeaderboard()
