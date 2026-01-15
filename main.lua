-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
-- Your code here
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    package.loaded["lldebugger"] = assert(loadfile(os.getenv("LOCAL_LUA_DEBUGGER_FILEPATH")))()
    require("lldebugger").start()
end
local isPixelArt = false
if isPixelArt then
    display.setDefault("magTextureFilter", "nearest")
    display.setDefault("minTextureFilter", "nearest")
else
    display.setDefault("magTextureFilter", "linear")
    display.setDefault("minTextureFilter", "linear")
end
-- debug.setmetatable(true, {
--     __len = function(value)
--         return value and 1 or 0
--     end
-- })

-- print(#true)
-- print(#false)
local botV1 = require("botV3")
local botV2 = require("botV4")
local playerV1 = require("player")
local backGroup = display.newGroup()
local cardGroup = display.newGroup()
local frontGroup = display.newGroup()
local setup = true
local isBiding = false
local isLaying = false
local gameIsWon = false
local highestBid = 0
local playerWithNest
local playerStartBid = math.random(4)
local waitingOnPlayer = false
local slowForPlayer = false
local cardPile
local passedPlayers = {}
local playerTurn = math.random(4)
local teams = {}
local deck = {}
local nest = {}
local bids = {}
_G.game = {}
_G.game.bids = bids
_G.game.thisRound = 0
_G.game.rounds = {}
_G.oldGames = {}
-- game mode is ether "play" or "test"
_G.gameMode = "play"
_G.overClocking = 1
_G.paused = false
-- true shows cards
_G.showVisuals = false or _G.gameMode == "play"
_G.animationTime = 100
-- trump can be "red", "black", "yellow", "green"
-- _G.game.trump
-- create deck
local colors = { "r", "b", "y", "g" }
local createDeck = function()
    deck = {}
    for c = 1, #colors do
        deck[#deck + 1] = colors[c] .. "5"
        for n = 9, 14 do
            deck[#deck + 1] = colors[c] .. n
        end
        deck[#deck + 1] = colors[c] .. "1"
    end
    deck[#deck + 1] = "bird"
end
createDeck()
local players
local createPlayers = function()
    players = {}
    players[1] = botV2.new(1, 1)
    players[2] = botV1.new(2, 2)
    players[3] = botV2.new(3, 1)
    if _G.gameMode == "play" then
        players[4] = playerV1.new(4, 2)
    else
        players[4] = botV1.new(4, 2)
    end
    cardGroup:insert(players[1].group)
    cardGroup:insert(players[2].group)
    cardGroup:insert(players[3].group)
    cardGroup:insert(players[4].group)
    teams[1] = {
        [1] = players[1],
        [3] = players[3],
        points = 0
    }
    teams[2] = {
        [2] = players[2],
        [4] = players[4],
        points = 0
    }
end
createPlayers()
local scoreboard1
local scoreboard2
local sideMenu
local resumeGame
local nestDisplay
local readyToChangeGamgeMode = false
local restartGame = function()
    _G.oldGames[#_G.oldGames + 1] = _G.game
    _G.game = {}
    bids = {}
    _G.game.bids = bids
    _G.game.thisRound = 0
    _G.game.rounds = {}
    teams[1].points = 0
    teams[2].points = 0
    timer.cancel("card")
    transition.cancel("card")
    display.remove(cardPile)
    display.remove(nestDisplay)
    -- the rest of it gets done by setup
    setup = true
    gameIsWon = false
    playerWithNest = nil
    playerStartBid = math.random(4)
    waitingOnPlayer = false
    slowForPlayer = false
    createDeck()
    -- reset the score boards
    scoreboard1.bid.text = scoreboard1.bid.defaultText
    scoreboard2.bid.text = scoreboard2.bid.defaultText
    scoreboard1.score.text = tostring(teams[1].points)
    scoreboard2.score.text = tostring(teams[2].points)
    resumeGame()
end
local changeMode = function()
    -- check what game mode is and change it
    readyToChangeGamgeMode = false
    if _G.gameMode == "play" then
        _G.gameMode = "test"
        _G.showVisuals = _G.showVisuals or _G.gameMode == "play"
        display.remove(nestDisplay)
        for i = 1, 4 do
            players[i].delete()
            players[i] = nil
        end
        createPlayers()
        restartGame()
    else
        _G.gameMode = "play"
        _G.showVisuals = _G.showVisuals or _G.gameMode == "play"
        display.remove(nestDisplay)
        for i = 1, 4 do
            players[i].delete()
            players[i] = nil
        end
        createPlayers()
        restartGame()
    end
end
-- pause function
local pauseGame = function()
    _G.paused = true
    -- pause all timers and transitions
    timer.pauseAll()
    transition.pauseAll()
    timer.resume("UI")
    transition.resume("UI")
    -- display UI
    local pauseIcon = display.newImageRect(frontGroup, "pause_button.png", 15, 15)
    pauseIcon.x = display.contentCenterX
    pauseIcon.y = display.contentCenterY
    transition.to(pauseIcon, {
        tag = "UI",
        alpha = 0.1,
        xScale = 10,
        yScale = 10,
        time = 800,
        transition = easing.outCubic,
        onComplete = function()
            display.remove(pauseIcon)
        end
    })
    sideMenu = display.newGroup()
    frontGroup:insert(sideMenu)
    sideMenu.back = display.newRect(0, 0, 100, display.actualContentHeight)
    sideMenu.back:setFillColor(0.7, 0.7, 0.7)
    sideMenu:insert(sideMenu.back)
    sideMenu.resumeButton = display.newImageRect(sideMenu, "play_button.png", 50, 50)
    sideMenu.resumeButton.y = -sideMenu.back.height / 2 + 50
    sideMenu.restartButton = display.newImageRect(sideMenu, "restart_button.png", 50, 50)
    sideMenu.restartButton.y = -sideMenu.back.height / 2 + 150
    sideMenu.modeButton = display.newGroup()
    sideMenu.modeButton.back = display.newRoundedRect(0, 0, 80, 30, 6)
    sideMenu.modeButton.back:setFillColor(0.2, 0.2, 0.2)
    sideMenu.modeButton:insert(sideMenu.modeButton.back)
    sideMenu.modeButton.text = display.newText({
        text = "Play",
        x = 0,
        y = 0,
        font = native.systemFontBold,
        fontSize = 19
    })
    sideMenu.modeButton.text.playText = "play"
    sideMenu.modeButton.text.testText = "test"
    if _G.gameMode == "play" then
        sideMenu.modeButton.text.text = sideMenu.modeButton.text.playText
    else
        sideMenu.modeButton.text.text = sideMenu.modeButton.text.testText
    end
    sideMenu.modeButton.text:setFillColor(0.3, 0.8, 0.2)
    sideMenu.modeButton:insert(sideMenu.modeButton.text)
    sideMenu.modeButton.description = display.newText({
        text = "Game mode",
        x = 0,
        y = 0,
        font = native.systemFontBold,
        fontSize = 12
    })
    sideMenu.modeButton.description.y = -25
    sideMenu.modeButton.description:setFillColor(0.2, 0.2, 0.2)
    sideMenu.modeButton:insert(sideMenu.modeButton.description)
    sideMenu.modeButton.y = -sideMenu.back.height / 2 - 50
    sideMenu.modeButton.back:addEventListener("touch", function(event)
        if event.phase == "ended" then
            -- "test" text changes to "play" and vice versa
            sideMenu.modeButton.text.text = sideMenu.modeButton.text.text == "play" and "test" or "play"
            readyToChangeGamgeMode = true
            -- if button does not match current game mode then change
            if sideMenu.modeButton.text.text == _G.gameMode then
                readyToChangeGamgeMode = false
            end
        end
        return true
    end)
    -- position the mode button
    sideMenu.modeButton.y = -sideMenu.back.height / 2 + 250
    sideMenu:insert(sideMenu.modeButton)
    -- position side menu
    sideMenu.x = display.contentCenterX + display.actualContentWidth / 2 - sideMenu.width / 2
    sideMenu.y = display.contentCenterY
    sideMenu.resumeButton:addEventListener("touch", function(event)
        if event.phase == "ended" then
            resumeGame()
        end
        return true
    end)
    sideMenu.restartButton:addEventListener("touch", function(event)
        if event.phase == "ended" then
            restartGame()
        end
        return true
    end)
end
-- resume function
resumeGame = function()
    -- if game mode was change let it change and restart in stead
    if readyToChangeGamgeMode then
        changeMode()
        return
    end
    _G.paused = false
    -- resume all timers and transitions
    timer.resumeAll()
    transition.resumeAll()
    local playIcon = display.newImageRect(frontGroup, "play_button.png", 15, 15)
    playIcon.x = display.contentCenterX
    playIcon.y = display.contentCenterY
    transition.to(playIcon, {
        tag = "UI",
        alpha = 0.1,
        xScale = 10,
        yScale = 10,
        time = 800,
        transition = easing.outCubic,
        onComplete = function()
            display.remove(playIcon)
        end
    })
    display.remove(sideMenu)
end
-- background
local background = display.newRect(0, 0, display.actualContentWidth, display.actualContentHeight)
background.x = display.contentCenterX
background.y = display.contentCenterY
background:setFillColor(0)
backGroup:insert(background)
-- pause the game
background:addEventListener("touch", function(event)
    if event.phase == "ended" then
        -- pause by touching the background
        -- if _G.paused then
        --     resumeGame()
        -- else
        --     pauseGame()
        -- end
    end
end)
-- pause button
local pauseButton = display.newImageRect(frontGroup, "pause_button.png", 50, 50)
pauseButton.x = display.contentCenterX + display.actualContentWidth / 2 - 50
pauseButton.y = display.contentCenterY - display.actualContentHeight / 2 + 50
frontGroup:insert(pauseButton)
pauseButton:addEventListener("touch", function(event)
    if event.phase == "ended" then
        pauseGame()
    end
    return true
end)
-- setup the scoreboard
scoreboard1 = display.newGroup()
scoreboard1.back = display.newRect(0, 0, 80, 80)
scoreboard1.back:setFillColor(0.2, 0.2, 0.2)
scoreboard1:insert(scoreboard1.back)
scoreboard1.title = display.newText({
    text = "TEAM 1",
    color = { 0, 0, 0 },
    font = native.systemFontBold,
    fontSize = 15
})
scoreboard1.title.x = 0
scoreboard1.title.y = -30
scoreboard1:insert(scoreboard1.title)
scoreboard1.score = display.newText({
    text = "0",
    color = { 0, 0, 0 },
    font = native.systemFontBold,
    fontSize = 25
})
scoreboard1.score.x = 0
scoreboard1.score.y = 0
scoreboard1:insert(scoreboard1.score)
scoreboard1.bid = display.newText({
    text = "bid: N/A",
    color = { 0, 0, 0 },
    font = native.systemFontBold,
    fontSize = 17
})
scoreboard1.bid.baseText = "bid: "
scoreboard1.bid.defaultText = "bid: N/A"
scoreboard1.bid.x = 0
scoreboard1.bid.y = 30
scoreboard1:insert(scoreboard1.bid)
scoreboard1.x = display.contentCenterX + display.actualContentWidth / 2 - scoreboard1.back.width / 2
scoreboard1.y = display.contentCenterY + display.actualContentHeight / 2 - scoreboard1.back.height / 2
backGroup:insert(scoreboard1)
scoreboard2 = display.newGroup()
scoreboard2.back = display.newRect(0, 0, 80, 80)
scoreboard2.back:setFillColor(0.2, 0.2, 0.2)
scoreboard2:insert(scoreboard2.back)
scoreboard2.title = display.newText({
    text = "TEAM 2",
    color = { 0, 0, 0 },
    font = native.systemFontBold,
    fontSize = 15
})
scoreboard2.title.x = 0
scoreboard2.title.y = -30
scoreboard2:insert(scoreboard2.title)
scoreboard2.score = display.newText({
    text = "0",
    color = { 0, 0, 0 },
    font = native.systemFontBold,
    fontSize = 25
})
scoreboard2.score.x = 0
scoreboard2.score.y = 0
scoreboard2:insert(scoreboard2.score)
scoreboard2.bid = display.newText({
    text = "bid: N/A",
    color = { 0, 0, 0 },
    font = native.systemFontBold,
    fontSize = 17
})
scoreboard2.bid.baseText = "bid: "
scoreboard2.bid.defaultText = "bid: N/A"
scoreboard2.bid.x = 0
scoreboard2.bid.y = 30
scoreboard2:insert(scoreboard2.bid)
scoreboard2.x = display.contentCenterX - display.actualContentWidth / 2 + scoreboard2.back.width / 2
scoreboard2.y = display.contentCenterY + display.actualContentHeight / 2 - scoreboard2.back.height / 2
backGroup:insert(scoreboard2)
_G.teams = teams
-- check if a team is out of trump
_G.doesHaveThisColor = function(team, color)
    local colorFound = false
    for k, v in ipairs(teams[team]) do
        for i = 1, #v.cards do
            if v.cards[i] == "bird" then
                if color == string.sub(_G.game.trump, 1, 1) then
                    return true
                end
            else
                if string.sub(v.cards[i], 1, 1) == color then
                    return true
                end
            end
        end
    end
    return false
end
-- check if card matches the color
_G.cardMatches = function(card, color)
    local cardAbrev = string.sub(card, 1, 1)
    local colorAbrev = string.sub(color, 1, 1)
    -- is color trump ?
    if string.lower(colorAbrev) == "t" or color == "bird" then
        if _G.game.trump == nil then
            return false
        end
        colorAbrev = string.sub(_G.game.trump, 1, 1)
    end
    -- the bird only matches trump
    if card == "bird" then
        if _G.game.trump then
            if colorAbrev == string.sub(_G.game.trump, 1, 1) then
                return true
            end
        else
            return false
        end
    else
        -- any normal card has to match the color
        if cardAbrev == colorAbrev then
            return true
        end
    end
    return false
end
-- turn the back side of the card up
_G.flipCard = function(card, flipSpeed)
    local flipTime = _G.animationTime * 0.8
    if flipSpeed == "slow" then
        flipTime = _G.animationTime * 2
    end
    if card.isFlipped then
        card.isFlipped = false
        -- show the front of the card when it's flipping over
        local showFront = function()
            card.backSide.isVisible = false
            card.frontSide.isVisible = true
        end
        timer.performWithDelay(flipTime * 0.5, showFront, "card")
        transition.to(card, {
            tag = "card",
            xScale = 1,
            time = flipTime * 1
        })
    else
        card.isFlipped = true
        -- show the back of the card when it's flipping over
        local showBack = function()
            card.backSide.isVisible = true
            card.frontSide.isVisible = false
        end
        timer.performWithDelay(flipTime * 0.5, showBack, "card")
        transition.to(card, {
            tag = "card",
            xScale = -1,
            time = flipTime * 1
        })
    end
end
-- display a card
_G.showCard = function(color, number, direction)
    local card = display.newGroup()
    card.frontSide = display.newGroup()
    card.back = display.newRoundedRect(card.frontSide, 0, 0, 56, 89.6, 5)
    card.back:setFillColor(1, 1, 1)
    card.back.strokeWidth = card.back.width * 0.04
    if color then
        card.name = color .. number
    else
        card.name = number
    end
    -- color is nil then it's the bird card and it's black
    local rgbColor = { 0.2, 0.6, 0.7 }
    if color == "r" then
        rgbColor = { 0.8, 0, 0.1 }
    elseif color == "b" then
        rgbColor = { 0.1, 0.1, 0.1 }
    elseif color == "y" then
        rgbColor = { 0.9, 0.9, 0.2 }
    elseif color == "g" then
        rgbColor = { 0.1, 0.7, 0.1 }
    end
    card.back:setStrokeColor(unpack(rgbColor))
    if (number == "bird") then
        card.front = display.newImageRect(card.frontSide, "bird.png", card.back.width * 0.73, card.back.width * 0.73)
        card.topText = display.newText(card.frontSide, number, 0, 0, "AmericanTypewriter-Semibold", card.back.width * 0.1)
        card.topText:setFillColor(unpack(rgbColor))
        card.topText.x = -card.back.width * 0.34
        card.topText.y = -card.back.height * 0.43
        card.bottomText = display.newText(card.frontSide, number, 0, 0, "AmericanTypewriter-Semibold",
            card.back.width * 0.1)
        card.bottomText:setFillColor(unpack(rgbColor))
        card.bottomText.x = card.back.width * 0.34
        card.bottomText.y = card.back.height * 0.43
        card.bottomText.rotation = 180
    else
        card.front = display.newText(card.frontSide, number, 0, 0, "AmericanTypewriter-Semibold", 42)
        card.front:setFillColor(unpack(rgbColor))
        card.topNumber = display.newText(card.frontSide, number, 0, 0, "AmericanTypewriter-Semibold", card.back.width *
            0.1)
        card.topNumber:setFillColor(unpack(rgbColor))
        card.topNumber.x = -card.back.width * 0.38
        card.topNumber.y = -card.back.height * 0.43
        card.bottomNumber = display.newText(card.frontSide, number, 0, 0, "AmericanTypewriter-Semibold",
            card.back.width * 0.1)
        card.bottomNumber:setFillColor(unpack(rgbColor))
        card.bottomNumber.x = card.back.width * 0.38
        card.bottomNumber.y = card.back.height * 0.43
        card.bottomNumber.rotation = 180
    end
    -- add the back side of the card
    card.backSide = display.newImageRect(card, "card.png", card.back.width, card.back.height)
    card:insert(card.frontSide)
    card:insert(card.backSide)
    if direction == "faceUp" then
        card.frontSide.isVisible = true
        card.backSide.isVisible = false
        card.isFlipped = false
    elseif direction == "faceDown" then
        card.frontSide.isVisible = false
        card.backSide.isVisible = true
        card.isFlipped = true
    else
        -- give a warning if the direction is wrong
        print("WARNING: card direction must be \"faceUp\" or \"faceDown\"!")
    end
    return card
end
-- display a hand of cards
-- direction is "faceUp" or "faceDown". cards is optional and will override playerID
_G.showHand = function(playerID, direction, cards)
    local hand = display.newGroup()
    -- how much to spread the cards
    local spreadAngle = 8
    local spread = 10
    local player = players[playerID]
    local theseCards = player.cards
    if cards then
        theseCards = cards
    end
    hand.cards = {}
    for c = 1, #theseCards do
        local thisCard
        if theseCards[c] == "bird" then
            thisCard = _G.showCard(nil, theseCards[c], direction)
        else
            thisCard = _G.showCard(string.sub(theseCards[c], 1, 1), string.sub(theseCards[c], 2, -1), direction)
        end
        thisCard.x = (c - #theseCards / 2 - 0.5) * spread
        thisCard.y = math.abs(c - #theseCards / 2 - 0.5) ^ 1.5 * spread * 0.1
        thisCard.homeX = thisCard.x
        thisCard.homeY = thisCard.y
        thisCard.homeRotation = thisCard.rotation
        thisCard.rotation = (c - #theseCards / 2 - 0.5) * spreadAngle
        local raisedDistance = 40
        thisCard.rasedX = thisCard.x + math.sin(math.rad(thisCard.rotation)) * raisedDistance
        thisCard.rasedY = thisCard.y - math.cos(math.rad(thisCard.rotation)) * raisedDistance
        thisCard.isRaised = false
        hand:insert(thisCard)
        thisCard.raise = function(self)
            self.isRaised = true
            self.x = self.homeX
            self.y = self.homeY
            transition.cancel(self)
            transition.to(self, {
                tag = "card",
                time = _G.animationTime * 1,
                x = self.rasedX,
                y = self.rasedY
            })
        end
        thisCard.lower = function(self)
            self.isRaised = false
            self.x = self.rasedX
            self.y = self.rasedY
            transition.cancel(self)
            transition.to(self, {
                tag = "card",
                time = _G.animationTime * 1,
                x = self.homeX,
                y = self.homeY
            })
        end
        thisCard:addEventListener("touch", function(event)
            if hand.touchEvent then
                hand.touchEvent(event, thisCard)
            end
            return true
        end)
        thisCard.value = theseCards[c]
        thisCard.ID = c
        hand.cards[#hand.cards + 1] = thisCard
    end
    return hand
end
-- show what was bid
_G.showBid = function(bid)
    local bidGroup = display.newGroup()

    bidGroup.Back = display.newRoundedRect(0, 0, 54, 33.5, 5)
    bidGroup.Back.strokeWidth = 3
    bidGroup.Back:setStrokeColor(0, 0, 0)
    bidGroup:insert(bidGroup.Back)
    bidGroup.bidText = display.newText({
        text = bid,
        x = 0,
        y = 0,
        font = native.systemFontBold,
        fontSize = 25
    })
    bidGroup.bidText:setFillColor(0, 0, 0)
    bidGroup:insert(bidGroup.bidText)
    bidGroup.setText = function(self, newBid)
        self.bidText.text = newBid
    end
    return bidGroup
end
-- show the next (face down)
nestDisplay = display.newGroup()
nestDisplay.homeX = display.contentCenterX
nestDisplay.homeY = display.contentCenterY
-- direction is "faceUp" or "faceDown". playerWithShowNest is optional and will put the nest on the player
local showNest = function(direction, playerWithShowNest)
    if showVisuals then
        display.remove(nestDisplay)
        -- just put player 1. it doesn't matter
        nestDisplay = _G.showHand(1, direction, nest)
        nestDisplay.homeX = display.contentCenterX
        nestDisplay.homeY = display.contentCenterY
        cardGroup:insert(nestDisplay)
        nestDisplay.x = nestDisplay.homeX
        nestDisplay.y = nestDisplay.homeY
        if playerWithShowNest then
            -- put the nest on the player
            nestDisplay.x = players[playerWithShowNest].group.x
            nestDisplay.y = players[playerWithShowNest].group.y
        end
    end
end
-- display what color trump is
local trumpDisplay = display.newGroup()
trumpDisplay.back = display.newRect(0, 0, 80, 80)
trumpDisplay.back:setFillColor(0.2, 0.2, 0.2)
trumpDisplay.back.strokeWidth = 3
trumpDisplay.back:setStrokeColor(1, 1, 1)
trumpDisplay.defaultColor = { 0.2, 0.2, 0.2 }
trumpDisplay.redColor = { 0.9, 0.2, 0.2 }
trumpDisplay.blackColor = { 0, 0, 0 }
trumpDisplay.greenColor = { 0.1, 0.8, 0.1 }
trumpDisplay.yellowColor = { 0.8, 0.8, 0.1 }
trumpDisplay:insert(trumpDisplay.back)
trumpDisplay.title = display.newText({
    text = "TRUMP",
    color = { 0, 0, 0 },
    font = native.systemFontBold,
    fontSize = 15
})
trumpDisplay.title.x = 0
trumpDisplay.title.y = -30
trumpDisplay:insert(trumpDisplay.title)
trumpDisplay.color = display.newText({
    text = "N/A",
    color = { 0, 0, 0 },
    font = native.systemFontBold,
    fontSize = 15
})
trumpDisplay.color.defaultText = "N/A"
trumpDisplay.color.x = 0
trumpDisplay.color.y = 0
trumpDisplay:insert(trumpDisplay.color)
trumpDisplay.x = display.contentCenterX - display.actualContentWidth / 2 + trumpDisplay.width / 2
trumpDisplay.y = display.contentCenterY
backGroup:insert(trumpDisplay)
trumpDisplay.show = function(self, newColor)
    self.color.text = newColor
end

local testingData = display.newGroup()
testingData.back = display.newRect(0, 0, 100, 80)
testingData.back:setFillColor(0.2, 0.2, 0.2)
testingData:insert(testingData.back)
testingData.FPS = display.newText({
    text = "",
    color = { 0, 0, 0 },
    font = native.systemFontBold,
    fontSize = 15
})
testingData.FPS.baseText = "FPS: "
testingData.FPS.text = testingData.FPS.baseText
testingData:insert(testingData.FPS)
testingData.x = display.contentCenterX - display.actualContentWidth / 2 + testingData.width / 2
testingData.y = display.contentCenterY - display.actualContentHeight / 2 + testingData.height / 2
if _G.gameMode ~= "test" then
    testingData.isVisible = false
end

_G.showTrump = function()
    if _G.game.trump then
        trumpDisplay.color.text = _G.game.trump
        trumpDisplay.back:setFillColor(unpack(trumpDisplay[_G.game.trump .. "Color"]))
    else
        trumpDisplay.back:setFillColor(unpack(trumpDisplay.defaultColor))
        trumpDisplay.color.text = trumpDisplay.color.defaultText
    end
end
-- shuffle cards
local shuffleCards = function()
    local shuffledCards = {}
    for i = 1, #deck do
        local index = math.random(1, #deck)
        shuffledCards[i] = deck[index]
        table.remove(deck, index)
    end
    deck = shuffledCards
end
-- deal cards
local dealCards = function()
    for p = 1, 4 do
        for c = 1, 7 do
            players[p].cards[#players[p].cards + 1] = deck[#deck]
            table.remove(deck, #deck)
        end
    end
    -- nest maybe wasn't emptied if the game was restarted
    nest = {}
    for c = 1, 5 do
        nest[#nest + 1] = deck[#deck]
        table.remove(deck, #deck)
    end
end
local whoWinsTheDraw = function(round)
    local bestCard = round.turns[1].card
    local winingPlayer = round.turns[1].player
    local bestValue = string.sub(round.turns[1].card, 2)
    local leadColor = string.sub(bestCard, 1, 1)
    -- change bestValue to a number
    if bestCard == "bird" then
        leadColor = string.sub(_G.game.trump, 1, 1)
        bestValue = 10.5
    else
        bestValue = tonumber(bestValue)
    end
    local trumptIn = false
    for i = 2, #round.turns do
        local cardValue = string.sub(round.turns[i].card, 2)
        -- change bestValue to a number
        if round.turns[i].card == "bird" then
            cardValue = 10.5
        else
            cardValue = tonumber(cardValue)
        end
        -- played the color thats lead
        if not trumptIn then
            if string.sub(round.turns[i].card, 1, 1) == leadColor or
                (round.turns[i].card == "bird" and leadColor == string.sub(_G.game.trump, 1, 1)) then
                -- 1 is high
                if (cardValue > bestValue and bestValue ~= 1) or cardValue == 1 then
                    bestCard = round.turns[i].card
                    winingPlayer = round.turns[i].player
                    bestValue = cardValue
                end
            end
        end
        -- trumpt in
        -- trump is not lead
        if leadColor ~= string.sub(_G.game.trump, 1, 1) then
            -- this is trump
            if string.sub(round.turns[i].card, 1, 1) == string.sub(_G.game.trump, 1, 1) or round.turns[i].card == "bird" then
                if not trumptIn then
                    bestCard = round.turns[i].card
                    winingPlayer = round.turns[i].player
                    bestValue = cardValue
                    -- 1 is high
                elseif (cardValue > bestValue and bestValue ~= 1) or cardValue == 1 then
                    bestCard = round.turns[i].card
                    winingPlayer = round.turns[i].player
                    bestValue = cardValue
                end
                trumptIn = true
            end
        end
    end
    return winingPlayer
end
_G.countPointsPerCard = function(card)
    if string.sub(card, 2) == "5" then
        return 5
    elseif string.sub(card, 2) == "10" or string.sub(card, 2) == "14" then
        return 10
    elseif string.sub(card, 2) == "1" then
        return 15
    elseif card == "bird" then
        return 20
    end
    return 0
end
_G.countPointsPerRound = function(roundNumber)
    local round = _G.game.rounds[roundNumber]
    local subtotal = 0
    -- loop through all the cards and count the points
    for i = 1, #round.turns do
        subtotal = subtotal + _G.countPointsPerCard(round.turns[i].card)
    end
    -- the last round is worth 20 points
    if roundNumber % 7 == 0 then
        subtotal = subtotal + 20
    end
    return subtotal
end
_G.countPoints = function(teamNumber, lastRound)
    local round = _G.game.rounds
    local subtotal = 0
    -- loop through all the draws this round
    local firstRound = lastRound - (lastRound - 1) % 7
    for i = firstRound, lastRound do
        -- if that round was won by a player on this team
        if teams[teamNumber][round[i].wonBy] then
            subtotal = subtotal + _G.countPointsPerRound(i)
        end
    end
    -- add the points from the nest if they own the nest
    if teams[teamNumber][playerWithNest] then
        for i = 1, #nest do
            subtotal = subtotal + _G.countPointsPerCard(nest[i])
        end
    end
    return subtotal
end
local step = function()
    playerTurn = playerTurn % 4 + 1
    local thisPlayer = players[playerTurn]
    if setup then
        -- TODO: trump = nil
        setup = false
        isBiding = true
        highestBid = 0
        _G.game.trump = nil
        _G.showTrump()
        -- reset all players also makes sure they have no cards
        for i = 1, 4 do
            players[i].resetRound()
        end
        -- gives each player 7 cards
        shuffleCards()
        dealCards()
        -- show nest
        showNest("faceDown")
        -- sort and show each players hand
        for i = 1, 4 do
            players[i].sortHand()
            players[i].showHand()
        end
    elseif isBiding then
        if highestBid == 0 then
            playerStartBid = playerStartBid % 4 + 1
            playerTurn = playerStartBid
            thisPlayer = players[playerTurn]
        end
        local bidSubmit = function(bid)
            waitingOnPlayer = false
            bids[#bids + 1] = {
                player = playerTurn,
                bid = bid
            }
            if bid ~= "pass" then
                highestBid = bid
                playerWithNest = playerTurn
            else
                passedPlayers[playerTurn] = 1
            end
            local numberOfPassed = 0
            numberOfPassed = numberOfPassed + (passedPlayers[1] or 0)
            numberOfPassed = numberOfPassed + (passedPlayers[2] or 0)
            numberOfPassed = numberOfPassed + (passedPlayers[3] or 0)
            numberOfPassed = numberOfPassed + (passedPlayers[4] or 0)
            if numberOfPassed == 3 then
                isBiding = false
                isLaying = true
                -- put cards back
                local returnCards = function(_cards)
                    -- if showing visuals then pause to animation the nest
                    -- then unpause
                    local pilePosition = {
                        x = display.contentCenterX - display.actualContentWidth / 2,
                        y = display.contentCenterY + display.actualContentHeight / 2
                    }
                    if teams[1][playerWithNest] then
                        pilePosition = {
                            x = display.contentCenterX + display.actualContentWidth / 2,
                            y = display.contentCenterY + display.actualContentHeight / 2
                        }
                    end
                    nest = _cards
                    if showVisuals then
                        showNest("faceDown", playerWithNest)
                        transition.to(nestDisplay, {
                            tag = "card",
                            time = _G.animationTime * 1,
                            x = pilePosition.x,
                            y = pilePosition.y,
                            onComplete = function()
                                waitingOnPlayer = false
                                display.remove(nestDisplay)
                            end
                        })
                    else
                        waitingOnPlayer = false
                    end
                end
                -- give the player the nest then put there unwanted cards back
                waitingOnPlayer = true
                if showVisuals then
                    transition.to(nestDisplay, {
                        tag = "card",
                        time = _G.animationTime * 1,
                        x = players[playerWithNest].group.x,
                        y = players[playerWithNest].group.y,
                        onComplete = function()
                            display.remove(nestDisplay)
                            players[playerWithNest].takeNest(nest, returnCards)
                        end
                    })
                else
                    players[playerWithNest].takeNest(nest, returnCards)
                end
                bids.lastBid = highestBid
                passedPlayers = {}
                -- put the bid on the board
                if players[playerWithNest].team == 1 then
                    scoreboard1.bid.text = scoreboard1.bid.baseText .. tostring(highestBid)
                    scoreboard2.bid.text = scoreboard2.bid.defaultText
                else
                    scoreboard2.bid.text = scoreboard2.bid.baseText .. tostring(highestBid)
                    scoreboard1.bid.text = scoreboard1.bid.defaultText
                end
            end
        end
        if thisPlayer.didPass == false then
            waitingOnPlayer = true
            thisPlayer.bid(bids, highestBid, passedPlayers, bidSubmit)
        end
    elseif isLaying then
        local round = _G.game.rounds[#_G.game.rounds]
        if round == nil or #round.turns == 4 then
            -- stop showing the bids
            for i = 1, #players do
                display.remove(players[i].myBidDisplay)
            end
            -- the first time the player with the nest leads
            playerTurn = playerWithNest
            -- at the end of the round the player that won will start the next round
            -- unless it was the last round of the hand
            if round and round.wonBy and #_G.game.rounds % 7 ~= 0 then
                playerTurn = round.wonBy
            end
            _G.game.rounds[#_G.game.rounds + 1] = {}
            round = _G.game.rounds[#_G.game.rounds]
            display.remove(cardPile)
            cardPile = nil
            _G.game.thisRound = _G.game.thisRound + 1
        end
        if round.turns == nil then
            round.turns = {}
        end
        -- waiting on the player to lay
        local submitCard = function(cardPlayed)
            round.turns[#round.turns + 1] = {}
            round.turns[#round.turns].player = playerTurn
            round.turns[#round.turns].card = cardPlayed
            if #round.turns == 4 then
                round.wonBy = whoWinsTheDraw(round)
            end
            deck[#deck + 1] = cardPlayed
            -- all the cards were layed exept the nest
            if #deck == 28 then
                isLaying = false
            end
            -- show the card layed on the pile
            if _G.showVisuals then
                local pilePosition = {
                    x = display.contentCenterX - display.actualContentWidth / 2,
                    y = display.contentCenterY + display.actualContentHeight / 2
                }
                if teams[1][round.wonBy] then
                    pilePosition = {
                        x = display.contentCenterX + display.actualContentWidth / 2,
                        y = display.contentCenterY + display.actualContentHeight / 2
                    }
                end
                local shouldRemovePile = false
                -- check now because it might change at the end of the timer
                if #round.turns == 4 then
                    shouldRemovePile = true
                end
                local discardPile = function()
                    if cardPile then
                        -- move the pile
                        transition.to(cardPile, {
                            tag = "card",
                            x = pilePosition.x,
                            y = pilePosition.y,
                            time = _G.animationTime * 4,
                            onComplete = function()
                                display.remove(cardPile)
                                cardPile = nil
                                waitingOnPlayer = false
                            end
                        })
                        for c = 1, #cardPile.cards do
                            _G.flipCard(cardPile.cards[c], "slow")
                        end
                    end
                end
                local showCardOnPile = function()
                    if cardPile then
                        display.remove(cardPile)
                        cardPile = nil
                    end
                    local pileCards = {}
                    for i = 1, #round.turns do
                        pileCards[#pileCards + 1] = round.turns[i].card
                    end
                    cardPile = _G.showHand(1, "faceUp", pileCards)
                    cardGroup:insert(cardPile)
                    cardPile.x = display.contentCenterX
                    cardPile.y = display.contentCenterY
                    if shouldRemovePile then
                        if _G.gameMode == "play" then
                            timer.performWithDelay(_G.animationTime * 10, discardPile, "card")
                        else
                            discardPile()
                        end
                    else
                        waitingOnPlayer = false
                    end
                end
                timer.performWithDelay(_G.animationTime * 1, showCardOnPile, "card")
            end
        end
        waitingOnPlayer = true
        players[playerTurn].layCard(playerWithNest, submitCard)
    elseif not gameIsWon then
        -- get ready for the next round
        local team = players[playerWithNest].team
        local otherTeam = team - (team * 2 - 3)
        local points = _G.countPoints(team, _G.game.thisRound)
        local wentUp = points >= _G.game.bids.lastBid
        if wentUp then
            teams[team].points = teams[team].points + points
        else
            teams[team].points = teams[team].points - _G.game.bids.lastBid
        end
        teams[otherTeam].points = teams[otherTeam].points + 200 - points
        -- show the score on the scoreboard
        scoreboard1.score.text = tostring(teams[1].points)
        scoreboard2.score.text = tostring(teams[2].points)
        -- put the nest back in the deck
        for i = 5, 1, -1 do
            deck[#deck + 1] = nest[i]
            table.remove(nest, i)
        end
        setup = true
        -- check if a team won
        if teams[otherTeam].points > 1000 and teams[otherTeam].points > teams[team].points then
            setup = false
            gameIsWon = true
            print("team " .. otherTeam .. " won")
            print("with " .. teams[otherTeam].points .. " points")
            print('vs team ' .. team)
            print("with " .. teams[team].points .. " points")
        end
        -- check if a team won
        if teams[team].points > 1000 and teams[team].points > teams[otherTeam].points then
            setup = false
            gameIsWon = true
            print("team " .. team .. " won")
            print("with " .. teams[team].points .. " points")
            print('vs team ' .. otherTeam)
            print("with " .. teams[otherTeam].points .. " points")
        end
    end
end

local time = 0
local normalTurnTime = 0
local waitTime = 0
local lastFrameTime = system.getTimer()
local averageFPS = 0
local frameTimes = {}
local update = function()
    for i = 1, _G.overClocking do
        time = time + 1
        frameTimes[#frameTimes + 1] = system.getTimer() - lastFrameTime
        lastFrameTime = system.getTimer()
        if #frameTimes > 100 then
            table.remove(frameTimes, 1)
        end
        local fpsTimer = 0
        for i = 1, #frameTimes do
            fpsTimer = fpsTimer + frameTimes[i]
        end
        averageFPS = 1000 / (fpsTimer / #frameTimes)
        if time % 6 == 0 then
            testingData.FPS.text = testingData.FPS.baseText .. math.floor(averageFPS + 0.5)
        end
        if not waitingOnPlayer and not _G.paused then
            normalTurnTime = normalTurnTime + 1
            waitTime = 30
            if not _G.showVisuals then
                waitTime = 1
            end
            if slowForPlayer then
                waitTime = 120
            end
            if normalTurnTime % waitTime == 0 then
                normalTurnTime = 0
                slowForPlayer = false
                step()
            end
        end
    end
end

Runtime:addEventListener("enterFrame", update)


-- TODO: rewrite and clean up

-- TODO: work on improvments "lessOptimalLay"
