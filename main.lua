-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Screen drawing

-- Get screen dimensions
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
-- pressing the buttons
local Ntaps = 20 -- how many taps does it take to go left-to-right full screen

local road1 = display.newImage("road.png")
local road2 = display.newImage("road.png")

road1.width, road1.height = screenWidth, screenHeight
road2.width, road2.height = screenWidth, screenHeight

-- Let's add road scroll speed
local scrollSpeed = 5

-- Now let's do the walking feet
-- Load two separate images as textures
feetW = 49
local steps1 = display.newImageRect("steps1.png", feetW, 56)
local steps2 = display.newImageRect("steps2.png", feetW, 56)

-- Initially hide the second image
steps2.isVisible = false

local stepsX, stepsY = display.contentCenterX, screenHeight*0.8

local stepCount = 0
local stepText = display.newText( stepCount,
                                 display.contentCenterX,
                                 20,
                                 native.systemFont, 40 )

local function redrawFeet()
    -- Position them at the same spot
    steps1.x, steps1.y = stepsX, stepsY
    steps2.x, steps2.y = stepsX, stepsY
end

local function scrollRoad(event)
    road1.y = road1.y + scrollSpeed
    road2.y = road2.y + scrollSpeed

    -- Reset images when they move out of view
    if road1.y >= display.contentHeight + road1.height * 0.5 then
        road1.y = road2.y - road2.height
    end
    if road2.y >= display.contentHeight + road2.height * 0.5 then
        road2.y = road1.y - road1.height
    end
end

-- adding the rock / Let's rock!
local rock = display.newImageRect("rock.png", 22, 22)
local rockX, rockY = display.contentCenterX, display.contentCenterY

local function makeSteps()
    redrawFeet()
    steps1.isVisible = not steps1.isVisible
    steps2.isVisible = not steps2.isVisible
    stepCount = stepCount + 1
    stepText.text = stepCount
end

-- add physics
local physics = require( "physics" )
physics.start()
isPhysicsPaused = false

physics.addBody(rock, "dynamic", {radius=11, bounce=1.0})
physics.addBody(steps1, "static")

myTimer = nil
gameOverText =  nil
gameOverOverlay = nil
restartButton = nil
restartButtonText = nil

local function initLevel()
    -- The func that starts the game
    rockX, rockY = display.contentCenterX, display.contentCenterY
    rock.x, rock.y = rockX, rockY

    local sign = math.random(1, 2) == 1 and 1 or -1
    local vx = sign*math.random(10, 50)
    local vy = math.random(-50, 50)

    road1.x, road1.y = display.contentCenterX, display.contentCenterY

    -- Place above road1
    road2.x, road2.y = display.contentCenterX, road1.y - road1.height

    stepCount = 0
    steps1.isVisible = true
    steps2.isVisible = false
    stepsX, stepsY = display.contentCenterX, screenHeight*0.8
    redrawFeet()
    Runtime:addEventListener("enterFrame", scrollRoad)
    -- Switch images every 500ms indefinitely
    myTimer = timer.performWithDelay(500, makeSteps, 0)

    rock:setLinearVelocity(vx,vy)
    if isPhysicsPaused then
        physics.start()
        isPhysicsPaused = false
    end

    if gameOverText then
        display.remove(gameOverText)
    end

    if gameOverOverlay then
        display.remove(gameOverOverlay)
    end

    if restartButton then
        display.remove(restartButton)
    end
    if restartButtonText then
        display.remove(restartButtonText)
    end
end

initLevel()

-- Left / Right controls
local leftButton = display.newImageRect( "moveLeft.png", 50, 50 )
leftButton.x = 25
leftButton.y = stepsY

local rightButton = display.newImageRect( "moveRight.png", 50, 50 )
rightButton.x = screenWidth - 25
rightButton.y = stepsY

local function pushLeft()
  stepsX = math.max(stepsX - screenWidth/Ntaps, feetW/2)
  redrawFeet()
end

local function pushRight()
  stepsX = math.min(stepsX + screenWidth/Ntaps, 320-feetW/2)
  redrawFeet()
end

leftButton:addEventListener("touch", pushLeft)
rightButton:addEventListener("touch", pushRight)

-- Model the collision with the rock

-- Bouncing off the walls
-- Create walls (static objects)
local leftWall = display.newRect(0, screenHeight/2, 10, screenHeight)
local rightWall = display.newRect(screenWidth, screenHeight/2, 10, screenHeight)
local bottomWall = display.newRect(screenWidth/2, screenHeight, screenWidth, 10)
local topWall = display.newRect(screenWidth/2, -50, screenWidth, 10)

physics.addBody(leftWall, "static")
physics.addBody(rightWall, "static")
physics.addBody(bottomWall, "static")
physics.addBody(topWall, "static")

local function restartGame()
    initLevel()
end

local function showGameOver()
    physics.pause()
    isPhysicsPaused = true
    timer.cancel(myTimer)
    gameOverOverlay = display.newRect(display.contentCenterX,
                                display.contentCenterY,
                                display.contentWidth,
                                display.contentHeight)
    gameOverOverlay:setFillColor(0, 0, 0, 0.5)

    gameOverText = display.newText("GAME OVER",
                                        display.contentCenterX,
                                        display.contentCenterY - 50,
                                        native.systemFont, 48)
    gameOverText:setFillColor(1, 0, 0)

    Runtime:removeEventListener("enterFrame", scrollRoad)

    -- Create a restart button
    restartButton = display.newRect(display.contentCenterX, display.contentCenterY + 50, 200, 50)
    restartButton:setFillColor(0, 1, 0)  -- Set button color to green

    -- Create text for the button
    restartButtonText = display.newText("Restart",
        display.contentCenterX,
        display.contentCenterY + 50,
        native.systemFont, 20)

    restartButtonText:setFillColor(0, 0, 0)  -- Set text color to black
    
    -- Add touch event listener to the button
    restartButton:addEventListener("tap", restartGame)
end

-- Function to calculate the reflection vector
local function reflectRock(event)
    if event.phase == "began" then
        if event.object2 == leftWall or event.object2 == rightWall then
            local vx, vy = event.object1:getLinearVelocity()
            event.object1:setLinearVelocity(-vx, vy)
        elseif event.object2 == bottomWall or event.object1 == bottomWall then
          showGameOver()
        elseif event.object2 == topWall or event.object1 == topWall then
            showGameOver()
        end
    end
end

-- Listen for collision events
Runtime:addEventListener("collision", reflectRock)

--
local function onCollision(event)
    if event.phase == "began" then
        local obj1 = event.object1
        local obj2 = event.object2

        -- Identify the rock and sneackers
        local myrock, sneackers
        if obj1 == rock and obj2 == steps1 then
            myrock, sneackers = obj1, obj2
        elseif obj1 == steps1 and obj2 == rock then
            myrock, sneackers = obj2, obj1
        else
            return
        end

        -- Calculate the difference in center positions
        local diffX = myrock.x - sneackers.x
        local diffY = myrock.y - sneackers.y

        -- Normalize the direction vector
        local magnitude = math.sqrt(diffX^2 + diffY^2)
        if magnitude > 0 then
            diffX = diffX / magnitude
            diffY = diffY / magnitude
        end

        -- Apply an impulse in the calculated direction
        local bouncyFactor = 0.1 -- Adjust as needed
        myrock:applyLinearImpulse(diffX * bouncyFactor,
                                  diffY * bouncyFactor,
                                  myrock.x, myrock.y)
    end
end

Runtime:addEventListener("collision", onCollision)

