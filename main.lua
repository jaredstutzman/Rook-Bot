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
-- debug.setmetatable(true, {
--     __len = function(value)
--         return value and 1 or 0
--     end
-- })

-- print(#true)
-- print(#false)
local botV1 = require("botV3")
local botV2 = require("botV2")
local backGroup = display.newGroup()
local setup = true
local isBiding = false
local isLaying = false
local gameIsWon = false
local highestBid = 0
local playerWithNest
local playerStartBid = math.random(4)
local cardPile
local passedPlayers = {}
local playerTurn = 1
local players = {}
local teams = {}
local deck = {}
local nest = {}
local bids = {}
_G.game = {}
_G.game.bids = bids
_G.game.thisRound = 0
_G.game.rounds = {}
-- _G.game.trump
-- create deck
local colors = {"r", "b", "y", "g"}
for c = 1, #colors do
    deck[#deck + 1] = colors[c] .. "5"
    for n = 9, 14 do
        deck[#deck + 1] = colors[c] .. n
    end
    deck[#deck + 1] = colors[c] .. "1"
end
deck[#deck + 1] = "bird"
players[1] = botV1.new(1, 1)
players[2] = botV2.new(2, 2)
players[3] = botV1.new(3, 1)
players[4] = botV2.new(4, 2)
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
    if string.lower(colorAbrev) == "t" then
        if _G.game.trump == nil then
            return false
        end
        colorAbrev = string.sub(_G.game.trump, 1, 1)
    elseif color == "bird" then
        return card == "bird"
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
-- display a card
_G.showCard = function(color, number)
    local card = display.newGroup()
    card.back = display.newRoundedRect(card, 0, 0, 100, 160, 7)
    card.back:setFillColor(1, 1, 1)
    card.back.strokeWidth = 5
    if color then
        card.name = color .. number
    else
        card.name = number
    end
    -- color is nil then it's the bird card and it's black
    local rgbColor = {0.2, 0.6, 0.7}
    if color == "r" then
        rgbColor = {0.8, 0, 0.1}
    elseif color == "b" then
        rgbColor = {0.1, 0.1, 0.1}
    elseif color == "y" then
        rgbColor = {0.9, 0.9, 0.2}
    elseif color == "g" then
        rgbColor = {0.1, 0.7, 0.1}
    end
    card.back:setStrokeColor(unpack(rgbColor))
    if (number == "bird") then
        card.front = display.newImageRect(card, "bird.png", 1169 * 0.05, 1185 * 0.05)
        card.topText = display.newText(card, number, 0, 0, "AmericanTypewriter-Semibold", 10)
        card.topText:setFillColor(unpack(rgbColor))
        card.topText.x = -card.back.width * 0.34
        card.topText.y = -card.back.height * 0.43
        card.bottomText = display.newText(card, number, 0, 0, "AmericanTypewriter-Semibold", 10)
        card.bottomText:setFillColor(unpack(rgbColor))
        card.bottomText.x = card.back.width * 0.34
        card.bottomText.y = card.back.height * 0.43
        card.bottomText.rotation = 180
    else
        card.front = display.newText(card, number, 0, 0, "AmericanTypewriter-Semibold", 60)
        card.front:setFillColor(unpack(rgbColor))
        card.topNumber = display.newText(card, number, 0, 0, "AmericanTypewriter-Semibold", 10)
        card.topNumber:setFillColor(unpack(rgbColor))
        card.topNumber.x = -card.back.width * 0.38
        card.topNumber.y = -card.back.height * 0.43
        card.bottomNumber = display.newText(card, number, 0, 0, "AmericanTypewriter-Semibold", 10)
        card.bottomNumber:setFillColor(unpack(rgbColor))
        card.bottomNumber.x = card.back.width * 0.38
        card.bottomNumber.y = card.back.height * 0.43
        card.bottomNumber.rotation = 180
    end
    return card
end
-- display a hand of cards
_G.showHand = function(playerID, cards)
    local hand = display.newGroup()
    -- how much to spread the cards
    local spreadAngle = 8
    local spread = 12
    local player = players[playerID]
    local theseCards = player.cards
    if cards then
        theseCards = cards
    end
    hand.cards = {}
    for c = 1, #theseCards do
        local thisCard
        if theseCards[c] == "bird" then
            thisCard = _G.showCard(nil, theseCards[c])
        else
            thisCard = _G.showCard(string.sub(theseCards[c], 1, 1), string.sub(theseCards[c], 2, -1))
        end
        thisCard.xScale = 0.8
        thisCard.yScale = 0.8
        thisCard.x = (c - #theseCards / 2 - 0.5) * spread
        thisCard.y = math.abs(c - #theseCards / 2 - 0.5) ^ 1.5 * spread * 0.1
        thisCard.rotation = (c - #theseCards / 2 - 0.5) * spreadAngle
        hand:insert(thisCard)
        hand.cards[#hand.cards + 1] = thisCard
    end
    return hand
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
local countPoints = function(team, lastRound)
    local round = _G.game.rounds
    local subtotal = 0
    local cardValue = function(card)
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
    -- loop through the last 7 rounds, a full hand
    for i = lastRound - 6, lastRound do
        -- if that round was won by a player on this team
        if teams[team][round[i].wonBy] then
            -- loop through all the cards and count the points
            for I = 1, #round[i].turns do
                subtotal = subtotal + cardValue(round[i].turns[I].card)
            end
            -- the last round is worth 20 points
            if i == lastRound then
                subtotal = subtotal + 20
            end
        end
    end
    -- add the points from the nest if they own the nest
    if teams[team][playerWithNest] then
        for i = 1, #nest do
            subtotal = subtotal + cardValue(nest[i])
        end
    end
    return subtotal
end
local numberOfBids = 0
local step = function()
    local thisPlayer = players[playerTurn]
    if setup then
        -- TODO: trump = nil
        setup = false
        isBiding = true
        highestBid = 0
        shuffleCards()
        dealCards()
        for i = 1, 4 do
            players[i].reset()
            players[i].sortHand()
            players[i].showHand()
        end
    elseif isBiding then
        numberOfBids = numberOfBids + 1
        if highestBid == 0 then
            playerStartBid = playerStartBid % 4 + 1
            playerTurn = playerStartBid
            thisPlayer = players[playerTurn]
        end
        if thisPlayer.didPass == false then
            local bid = thisPlayer.bid(bids, highestBid, passedPlayers)
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
        end
        local numberOfPassed = 0
        numberOfPassed = numberOfPassed + (passedPlayers[1] or 0)
        numberOfPassed = numberOfPassed + (passedPlayers[2] or 0)
        numberOfPassed = numberOfPassed + (passedPlayers[3] or 0)
        numberOfPassed = numberOfPassed + (passedPlayers[4] or 0)
        if numberOfPassed == 3 then
            isBiding = false
            isLaying = true
            -- give the player the nest then put there unwanted cards back
            nest = players[playerWithNest].takeNest(nest)
            bids.lastBid = highestBid
            passedPlayers = {}
        end
    elseif isLaying then
        local round = _G.game.rounds[#_G.game.rounds]
        if round == nil or #round.turns == 4 then
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
        local cardPlayed = players[playerTurn].layCard()
        round.turns[#round.turns + 1] = {}
        round.turns[#round.turns].player = playerTurn
        round.turns[#round.turns].card = cardPlayed
        -- show the card layed on the pile
        timer.performWithDelay(100, function()
            if cardPile then
                display.remove(cardPile)
                cardPile = nil
            end
            local pileCards = {}
            for i = 1, #round.turns do
                pileCards[#pileCards + 1] = round.turns[i].card
            end
            cardPile = _G.showHand(1, pileCards)
            backGroup:insert(cardPile)
            cardPile.x = display.contentCenterX
            cardPile.y = display.contentCenterY
        end)
        if #round.turns == 4 then
            round.wonBy = whoWinsTheDraw(round)
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
            timer.performWithDelay(100, function()
                if cardPile then
                    transition.to(cardPile, {
                        x = pilePosition.x,
                        y = pilePosition.y,
                        time = 100
                    })
                end
            end)
        end
        deck[#deck + 1] = cardPlayed
        -- all the cards were layed exept the nest
        if #deck == 28 then
            isLaying = false
        end
    elseif not gameIsWon then
        -- get ready for the next round
        local team = players[playerWithNest].team
        local otherTeam = team - (team * 2 - 3)
        local points = countPoints(team, _G.game.thisRound)
        local wentUp = points >= _G.game.bids.lastBid
        if wentUp then
            teams[team].points = teams[team].points + points
        else
            teams[team].points = teams[team].points - _G.game.bids.lastBid
        end
        teams[otherTeam].points = teams[otherTeam].points + 200 - points
        -- put the nest back in the deck
        for i = 5, 1, -1 do
            deck[#deck + 1] = nest[i]
            table.remove(nest, i)
        end
        setup = true
        -- check if a team won
        if teams[otherTeam].points > 10000 and teams[otherTeam].points > teams[team].points then
            setup = false
            gameIsWon = true
            print("team " .. otherTeam .. " won")
            print("with " .. teams[otherTeam].points .. " points")
            print('vs team ' .. team)
            print("with " .. teams[team].points .. " points")
        end
        -- check if a team won
        if teams[team].points > 10000 and teams[team].points > teams[otherTeam].points then
            setup = false
            gameIsWon = true
            print("team " .. team .. " won")
            print("with " .. teams[team].points .. " points")
            print('vs team ' .. otherTeam)
            print("with " .. teams[otherTeam].points .. " points")
        end
    end
    playerTurn = playerTurn % 4 + 1
end

-- timer.performWithDelay(1, step, -1)
for i = 1, 8000 do
    step()
end

-- TODO: add a manual control for speed, pause, etc.
-- TODO: add a control to turn off visuals

-- TODO: rewrite and clean up
