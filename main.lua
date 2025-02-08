-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here

local road1 = display.newImageRect("road.png", 320, 480)
local road2 = display.newImageRect("road.png", 320, 480)

road1.x, road1.y = display.contentCenterX, display.contentCenterY

-- Place above road1
road2.x, road2.y = display.contentCenterX, road1.y - road1.height

-- Let's add scroll speed
local scrollSpeed = 5

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

Runtime:addEventListener("enterFrame", scrollRoad)

-- Now let's do the walking feet
-- Load two separate images as textures
local steps1 = display.newImageRect("steps1.png", 49, 56)
local steps2 = display.newImageRect("steps2.png", 49, 56)

-- Initially hide the second image
steps2.isVisible = false

local stepsX, stepsY = display.contentCenterX, 420

-- Function to alternate visibility
--

-- Step counter
local stepCount = 0
local stepText = display.newText( stepCount,
                                 display.contentCenterX,
                                 20,
                                 native.systemFont, 40 )
local function makeSteps()
    -- Position them at the same spot
    steps1.x, steps1.y = stepsX, stepsY
    steps2.x, steps2.y = stepsX, stepsY

    steps1.isVisible = not steps1.isVisible
    steps2.isVisible = not steps2.isVisible
    stepCount = stepCount + 1
    stepText.text = stepCount
end

-- Switch images every 500ms indefinitely
local myTimer = timer.performWithDelay(500, makeSteps, 0)

-- Left / Right controls
local leftButton = display.newImageRect( "moveLeft.png", 50, 50 )
leftButton.x = 25
leftButton.y = stepsY

local rightButton = display.newImageRect( "moveRight.png", 50, 50 )
rightButton.x = 320 - 25
rightButton.y = stepsY

-- pressing the buttons
local function pushLeft()
  stepsX = math.max(stepsX - 10, 75)
end

local function pushRight()
  stepsX = math.min(stepsX + 10, 320-75)
end

leftButton:addEventListener("tap", pushLeft)
rightButton:addEventListener("tap", pushRight)

-- adding the rock / Let's rock!
local rock = display.newImageRect("rock.png", 22, 22)
local rockX, rockY = display.contentCenterX, display.contentCenterY

rock.x, rock.y = rockX, rockY

-- add physics
local physics = require( "physics" )
physics.start()

physics.addBody(rock, "dynamic", {radius=11, bounce=1.0})

physics.addBody(steps1, "static")

-- Model the collision with the rock

-- Bouncing off the walls
-- Create walls (static objects)
local leftWall = display.newRect(0, 240, 10, 480)
local rightWall = display.newRect(320, 240, 10, 480)
local bottomWall = display.newRect(160, 480, 320, 10)

physics.addBody(leftWall, "static")
physics.addBody(rightWall, "static")
physics.addBody(bottomWall, "static")

local function showGameOver()
    physics.pause()
    timer.cancel(myTimer)
    local overlay = display.newRect(display.contentCenterX,
                                display.contentCenterY,
                                display.contentWidth,
                                display.contentHeight)
    overlay:setFillColor(0, 0, 0, 0.5)

    local gameOverText = display.newText("GAME OVER",
                                        display.contentCenterX,
                                        display.contentCenterY - 50,
                                        native.systemFont, 48)
    gameOverText:setFillColor(1, 0, 0)

    Runtime:removeEventListener("enterFrame", scrollRoad)
end

-- Function to calculate the reflection vector
local function reflectRock(event)
    if event.phase == "began" then
        if event.object2 == leftWall or event.object2 == rightWall then
            local vx, vy = event.object1:getLinearVelocity()
            event.object1:setLinearVelocity(-vx, vy)
        elseif event.object2 == bottomWall or event.object1 == bottomWall then
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

