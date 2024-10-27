-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
-- Your code here
local minBid = 120

local oppHasTrump = function(obj)
    -- is there any round data
    if _G.game.rounds and #_G.game.rounds > 0 then
        -- loop through all the rounds this hand played
        -- and count the trump
        local firstRound = math.floor(_G.game.thisRound / 7) * 7 + 1
        local trumpCount = 0
        for i = firstRound, _G.game.thisRound do
            for I = 1, #_G.game.rounds[i].turns do
                if _G.cardMatches(_G.game.rounds[i].turns[I].card, "trump") then
                    trumpCount = trumpCount + 1
                end
            end
        end
        -- count trump in your hand
        for c = 1, #obj.cards do
            if _G.cardMatches(obj.cards[c], "trump") then
                trumpCount = trumpCount + 1
            end
        end
        -- count trump in nestReject
        if obj.nestReject then
            for c = 1, #obj.nestReject do
                if _G.cardMatches(obj.nestReject[c], "trump") then
                    trumpCount = trumpCount + 1
                end
            end
        end
        -- check if that was all the trump
        if trumpCount == 9 then
            return true
        end
        -- the opponents did not play trump when it was led
        -- loop through all the rounds trump was led
        local opp1hasTrump = true
        local opp2hasTrump = true
        for i = firstRound, _G.game.thisRound do
            -- check if this round just started
            if #_G.game.rounds[i].turns > 0 then
                -- check if the trump was led
                if _G.cardMatches(_G.game.rounds[i].turns[1].card, "trump") then
                    -- check if the opponents played trump
                    for I = 1, #_G.game.rounds[i].turns do
                        -- this is an oppoennt
                        if not _G.teams[obj.team][_G.game.rounds[i].turns[I].player] then
                            -- chack if they ran out of trump
                            if not _G.cardMatches(_G.game.rounds[i].turns[I].card, "trump") then
                                if _G.game.rounds[i].turns[I].player < 3 then
                                    opp1hasTrump = false
                                else
                                    opp2hasTrump = false
                                end
                            end
                        end
                    end
                end
            end
        end
        if not opp1hasTrump and not opp2hasTrump then
            return true
        end
    else
        return false
    end
end

local rtn = {}
rtn.new = function(ID, team)
    local obj = {}
    obj.group = display.newGroup()
    obj.ID = ID
    obj.team = team
    obj.cards = {}
    obj.didPass = false
    obj.handIsSorted = false
    obj.tookNest = false
    -- players in order clockwise from the top left
    obj.group.x = (math.ceil((obj.ID % 4 + 1) / 2) * 2 - 3) * 80 + display.contentCenterX
    obj.group.y = (math.ceil(obj.ID / 2) * 2 - 3) * 100 + display.contentCenterY + 20
    obj.reset = function()
        obj.didPass = false
        obj.handIsSorted = false
        obj.tookNest = false
        obj.nestReject = nil
    end
    obj.sortHand = function(trump)
        local redCards = {
            color = "red"
        }
        local blackCards = {
            color = "black"
        }
        local yellowCards = {
            color = "yellow"
        }
        local greenCards = {
            color = "green"
        }
        local hasBird = false
        for c = #obj.cards, 1, -1 do
            -- deal with bird first
            if obj.cards[c] == "bird" then
                hasBird = true
                table.remove(obj.cards, c)
                -- the card is red
            elseif _G.cardMatches(obj.cards[c], "red") then
                redCards[#redCards + 1] = tonumber(string.sub(obj.cards[c], 2))
                -- the card is black
            elseif _G.cardMatches(obj.cards[c], "black") then
                blackCards[#blackCards + 1] = tonumber(string.sub(obj.cards[c], 2))
                -- the card is yellow
            elseif _G.cardMatches(obj.cards[c], "yellow") then
                yellowCards[#yellowCards + 1] = tonumber(string.sub(obj.cards[c], 2))
                -- the card is green
            elseif _G.cardMatches(obj.cards[c], "green") then
                greenCards[#greenCards + 1] = tonumber(string.sub(obj.cards[c], 2))
            end
        end
        table.sort(redCards)
        table.sort(blackCards)
        table.sort(yellowCards)
        table.sort(greenCards)
        local move1up = function(t)
            if t[1] == 1 then
                table.remove(t, 1)
                t[#t + 1] = 1
            end
        end
        local addPrefix = function(t, prefix)
            for c = 1, #t do
                t[c] = prefix .. t[c]
            end
        end
        move1up(redCards)
        move1up(blackCards)
        move1up(yellowCards)
        move1up(greenCards)
        addPrefix(redCards, "r")
        addPrefix(blackCards, "b")
        addPrefix(yellowCards, "y")
        addPrefix(greenCards, "g")
        local sortedCards = {redCards, blackCards, yellowCards, greenCards}
        -- remove empty colors
        for i = 4, 1, -1 do
            if not (trump and _G.cardMatches(sortedCards[i].color, trump)) then
                if #sortedCards[i] == 0 and not hasBird then
                    table.remove(sortedCards, i)
                end
            end
        end
        table.sort(sortedCards, function(a, b)
            -- trump goes first
            if (trump and _G.cardMatches(a.color, trump)) then
                return false
            end
            if (trump and _G.cardMatches(b.color, trump)) then
                return true
            end
            -- there is no trump so sort by size
            return #a < #b
        end)
        if hasBird then
            local foundCardBiggerThanBird = false
            for c = 1, #sortedCards[#sortedCards] do
                -- the bird should go infront of everything 10 and lower
                if tonumber(string.sub(sortedCards[#sortedCards][c], 2)) > 10 then
                    table.insert(sortedCards[#sortedCards], c, "bird")
                    foundCardBiggerThanBird = true
                    break
                end
                -- the bird should go behind 1
                if tonumber(string.sub(sortedCards[#sortedCards][c], 2)) == 1 then
                    table.insert(sortedCards[#sortedCards], c, "bird")
                    foundCardBiggerThanBird = true
                    break
                end
            end
            -- if all the cards are lower than the bird then add the bird to the end
            if not foundCardBiggerThanBird then
                table.insert(sortedCards[#sortedCards], #sortedCards[#sortedCards] + 1, "bird")
            end
        end
        obj.cards = table.copy(unpack(sortedCards))
    end
    obj.showHand = function()
        if obj.myHand then
            display.remove(obj.myHand)
        end
        obj.myHand = _G.showHand(obj.ID, "faceDown")
        obj.myHand.x = 0
        obj.myHand.y = 0
        obj.group:insert(obj.myHand)
    end
    obj.bid = function(bids, highestBid, passedPlayers, submitBid)
        obj.didPass = false
        local largestSafeBid = minBid
        local idealBid = largestSafeBid
        local cardPower = 0
        local cardWorth = 0
        for c = 1, #obj.cards do
            if obj.cards[c] == "bird" then
                cardPower = cardPower + 2.5
                cardWorth = cardWorth + 18
            elseif string.sub(obj.cards[c], 2) == "1" then
                cardPower = cardPower + 15
                cardWorth = cardWorth + 25
            elseif string.sub(obj.cards[c], 2) == "14" then
                cardWorth = cardWorth + 13
            elseif string.sub(obj.cards[c], 2) == "5" then
                cardPower = cardPower + 0
            else
                cardWorth = cardWorth + tonumber(string.sub(obj.cards[c], 2))
                cardPower = cardPower + tonumber(string.sub(obj.cards[c], 2)) - 8
            end
        end
        -- many cards of one color is good as long as some of those cards are good else it's bad
        local colorValue = 0
        local redCount = {}
        local blackCount = {}
        local yellowCount = {}
        local greenCount = {}
        for c = 1, #obj.cards do
            -- deal with colors
            if obj.cards[c] == "bird" then
                break
            end
            if _G.cardMatches(obj.cards[c], "red") then
                redCount[#redCount + 1] = obj.cards[c]
            end
            if _G.cardMatches(obj.cards[c], "black") then
                blackCount[#blackCount + 1] = obj.cards[c]
            end
            if _G.cardMatches(obj.cards[c], "yellow") then
                yellowCount[#yellowCount + 1] = obj.cards[c]
            end
            if _G.cardMatches(obj.cards[c], "green") then
                greenCount[#greenCount + 1] = obj.cards[c]
            end
        end
        local highCardPoints = {
            ["1"] = 50,
            ["14"] = 30,
            ["13"] = 25,
            ["12"] = 20,
            ["11"] = 18
        }
        local redPoints = 0
        local blackPoints = 0
        local yellowPoints = 0
        local greenPoints = 0
        for c = 1, #redCount do
            if highCardPoints[string.sub(redCount[c], 2)] then
                redPoints = redPoints + highCardPoints[string.sub(redCount[c], 2)]
            else
                redPoints = redPoints + tonumber(string.sub(redCount[c], 2))
            end
        end
        for c = 1, #blackCount do
            if highCardPoints[string.sub(blackCount[c], 2)] then
                blackPoints = blackPoints + highCardPoints[string.sub(blackCount[c], 2)]
            else
                blackPoints = blackPoints + tonumber(string.sub(blackCount[c], 2))
            end
        end
        for c = 1, #yellowCount do
            if highCardPoints[string.sub(yellowCount[c], 2)] then
                yellowPoints = yellowPoints + highCardPoints[string.sub(yellowCount[c], 2)]
            else
                yellowPoints = yellowPoints + tonumber(string.sub(yellowCount[c], 2))
            end
        end
        for c = 1, #greenCount do
            if highCardPoints[string.sub(greenCount[c], 2)] then
                greenPoints = greenPoints + highCardPoints[string.sub(greenCount[c], 2)]
            else
                greenPoints = greenPoints + tonumber(string.sub(greenCount[c], 2))
            end
        end
        local redIsGood = false
        local blackIsGood = false
        local yellowIsGood = false
        local greenIsGood = false
        if redPoints > 80 then
            redIsGood = true
        end
        if blackPoints > 80 then
            blackIsGood = true
        end
        if yellowPoints > 80 then
            yellowIsGood = true
        end
        if greenPoints > 80 then
            greenIsGood = true
        end
        if redIsGood then
            colorValue = colorValue + (#redCount) ^ 2
        else
            colorValue = colorValue - #redCount
        end
        if blackIsGood then
            colorValue = colorValue + (#blackCount) ^ 2
        else
            colorValue = colorValue - #blackCount
        end
        if yellowIsGood then
            colorValue = colorValue + (#yellowCount) ^ 2
        else
            colorValue = colorValue - #yellowCount
        end
        if greenIsGood then
            colorValue = colorValue + (#greenCount) ^ 2
        else
            colorValue = colorValue - #greenCount
        end
        -- add up how valuable your colors are for trump
        largestSafeBid = math.floor((largestSafeBid + colorValue * 1.5) / 5 + 0.5) * 5
        -- add up how high your cards are numbered
        largestSafeBid = math.floor((largestSafeBid + cardPower * 0.1) / 5 + 0.5) * 5
        -- add up how much your cards are worth on average
        largestSafeBid = math.floor((largestSafeBid + cardWorth * 0.3) / 5 + 0.5) * 5
        -- don't bid over 200
        largestSafeBid = math.min(largestSafeBid, 200)
        idealBid = largestSafeBid
        if largestSafeBid <= highestBid then
            idealBid = "pass"
        else
            -- don't out bid your teammate if your opponents passed
            -- unless you have way better cards
            -- 
            -- check if both your opponents passed
            local opponent1ID = (obj.ID + 1) % 4
            local opponent2ID = (obj.ID + 3) % 4
            if passedPlayers[(obj.ID + 1) % 4] and passedPlayers[(obj.ID + 3) % 4] then
                -- check if you can afford to out bid
                if largestSafeBid >= highestBid + 15 then
                    idealBid = highestBid + 5
                else
                    idealBid = "pass"
                end
            end
        end
        if idealBid == "pass" then
            obj.didPass = true
        end
        display.remove(obj.myBidDisplay)
        obj.myBidDisplay = _G.showBid(idealBid)
        obj.myBidDisplay.x = -50
        obj.myBidDisplay.y = -10
        obj.group:insert(obj.myBidDisplay)
        submitBid(idealBid)
    end
    obj.chooseTrump = function()
        local redCards = {}
        local blackCards = {}
        local yellowCards = {}
        local greenCards = {}
        obj.cardDetails = {
            redCards = redCards,
            blackCards = blackCards,
            yellowCards = yellowCards,
            greenCards = greenCards
        }
        redCards.height = 0
        blackCards.height = 0
        yellowCards.height = 0
        greenCards.height = 0
        redCards.color = "red"
        blackCards.color = "black"
        yellowCards.color = "yellow"
        greenCards.color = "green"
        local redHighCards = {}
        local blackHighCards = {}
        local yellowHighCards = {}
        local greenHighCards = {}
        local hasRedOne = 0
        local hasBlackOne = 0
        local hasYellowOne = 0
        local hasGreenOne = 0
        local hasRed14 = 0
        local hasBlack14 = 0
        local hasYellow14 = 0
        local hasGreen14 = 0
        local birdPoints = 0
        local isHigh = function(card, group)
            local isOne = 0
            local is14 = 0
            if (tonumber(string.sub(obj.cards[card], 2)) > 10) then
                group[#group + 1] = card
            end
            if (tonumber(string.sub(obj.cards[card], 2)) == 14) then
                is14 = 1
            end
            if (tonumber(string.sub(obj.cards[card], 2)) == 1) then
                group[#group + 1] = card
                isOne = 1
            end
            return isOne, is14
        end
        for c = 1, #obj.cards do
            if obj.cards[c] == "bird" then
                birdPoints = 11
            elseif _G.cardMatches(obj.cards[c], "red") then
                redCards[#redCards + 1] = c
                redCards.height = redCards.height + tonumber(string.sub(obj.cards[c], 2))
                local hasOne, has14 = isHigh(c, redHighCards)
                hasRedOne = hasRedOne + hasOne
                hasRed14 = hasRed14 + has14
            elseif _G.cardMatches(obj.cards[c], "black") then
                blackCards[#blackCards + 1] = c
                blackCards.height = blackCards.height + tonumber(string.sub(obj.cards[c], 2))
                local hasOne, has14 = isHigh(c, blackHighCards)
                hasBlackOne = hasBlackOne + hasOne
                hasBlack14 = hasBlack14 + has14
            elseif _G.cardMatches(obj.cards[c], "yellow") then
                yellowCards[#yellowCards + 1] = c
                yellowCards.height = yellowCards.height + tonumber(string.sub(obj.cards[c], 2))
                local hasOne, has14 = isHigh(c, yellowHighCards)
                hasYellowOne = hasYellowOne + hasOne
                hasYellow14 = hasYellow14 + has14
            elseif _G.cardMatches(obj.cards[c], "green") then
                greenCards[#greenCards + 1] = c
                greenCards.height = greenCards.height + tonumber(string.sub(obj.cards[c], 2))
                local hasOne, has14 = isHigh(c, greenHighCards)
                hasGreenOne = hasGreenOne + hasOne
                hasGreen14 = hasGreen14 + has14
            end
        end
        local redPoints = (#redCards * 11) + (#redHighCards * 10) + (hasRedOne * 20) + birdPoints
        local blackPoints = (#blackCards * 11) + (#blackHighCards * 10) + (hasBlackOne * 20) + birdPoints
        local yellowPoints = (#yellowCards * 11) + (#yellowHighCards * 10) + (hasYellowOne * 20) + birdPoints
        local greenPoints = (#greenCards * 11) + (#greenHighCards * 10) + (hasGreenOne * 20) + birdPoints
        -- 14s are worth more if there is a 1
        if hasRed14 == 1 and hasRedOne == 1 then
            redPoints = redPoints + 11
        end
        if hasBlack14 == 1 and hasBlackOne == 1 then
            blackPoints = blackPoints + 11
        end
        if hasYellow14 == 1 and hasYellowOne == 1 then
            yellowPoints = yellowPoints + 11
        end
        if hasGreen14 == 1 and hasGreenOne == 1 then
            greenPoints = greenPoints + 11
        end
        redCards.points = redPoints
        blackCards.points = blackPoints
        yellowCards.points = yellowPoints
        greenCards.points = greenPoints
        -- pick the scoring color for trump
        local scores = {redCards, blackCards, yellowCards, greenCards}
        table.sort(scores, function(a, b)
            if a.points == b.points then
                return a.height < b.height
            end
            return a.points < b.points
        end)
        local trump = scores[4].color
        return trump
    end
    obj.sortOutNest = function(trump)
        -- now put five cards back in the nest
        -- the most important rules are in this order
        -- put exactly 5 cards back
        -- don't put trump back
        -- don't put the highest cards back
        -- try to eliminate entire colors
        -- if you keep one card of a color don't keep points
        local newNest = {}
        local posibleEliminies = {}
        local keepingColors = {}
        keepingColors[1] = trump
        for c = 1, #obj.cards do
            -- not trump
            if not _G.cardMatches(obj.cards[c], trump) then
                posibleEliminies[#posibleEliminies + 1] = c
            end
        end
        if #posibleEliminies < 5 then
            for c = #posibleEliminies, 1, -1 do
                newNest[#newNest + 1] = obj.cards[posibleEliminies[c]]
                table.remove(obj.cards, posibleEliminies[c])
            end
            for c = 1, 5 - #posibleEliminies do
                newNest[#newNest + 1] = obj.cards[c]
                table.remove(obj.cards, c)
            end
            return newNest
        end
        -- if 5 cards are eliminated then we're done
        if #posibleEliminies == 5 then
            for c = #posibleEliminies, 1, -1 do
                newNest[#newNest + 1] = obj.cards[posibleEliminies[c]]
                table.remove(obj.cards, posibleEliminies[c])
            end
            return newNest
        end
        local highCards = {}
        highCards.r = {}
        highCards.b = {}
        highCards.y = {}
        highCards.g = {}
        local highCardLookUp = {}
        -- how many non high cards are there
        for c = #posibleEliminies, 1, -1 do
            -- check each color
            local color = highCards[string.sub(obj.cards[posibleEliminies[c]], 1, 1)]
            local isHigh = false
            if tonumber(string.sub(obj.cards[posibleEliminies[c]], 2)) == 1 then
                isHigh = true
                -- if we have enough high cards of that color to make this card high
            elseif #color > 14 - tonumber(string.sub(obj.cards[posibleEliminies[c]], 2)) then
                isHigh = true
            end
            if isHigh then
                color[#color + 1] = posibleEliminies[c]
                highCardLookUp[c] = true
            end
        end
        local sorted = false
        local numberEliminies = #posibleEliminies
        for k, v in pairs(highCardLookUp) do
            posibleEliminies[k] = false
            numberEliminies = numberEliminies - 1
            if numberEliminies == 5 then
                sorted = true
                break
            end
        end
        if sorted then
            for c = #posibleEliminies, 1, -1 do
                if posibleEliminies[c] ~= false then
                    newNest[#newNest + 1] = obj.cards[posibleEliminies[c]]
                    table.remove(obj.cards, posibleEliminies[c])
                end
            end
            return newNest
        end
        for c = #posibleEliminies, 1, -1 do
            if posibleEliminies[c] == false then
                table.remove(posibleEliminies, c)
            end
        end
        local countColor = {
            r = {},
            b = {},
            y = {},
            g = {}
        }
        -- prioritize all the posibleEliminies to get rid of some first
        for c = 1, #posibleEliminies do
            local card = obj.cards[posibleEliminies[c]]
            local color = string.sub(card, 1, 1)
            countColor[color][#countColor[color] + 1] = c
            local priority = 10
            if string.sub(card, 2) == "5" or string.sub(card, 2) == "10" or string.sub(card, 2) == "14" then
                priority = 4
            end
            posibleEliminies[c] = {
                ID = posibleEliminies[c],
                priority = priority
            }
        end
        local cardCounts = {
            r = {},
            b = {},
            y = {},
            g = {}
        }
        for k, v in pairs(cardCounts) do
            for c = 1, #obj.cards do
                if _G.cardMatches(obj.cards[c], k) then
                    v[#v + 1] = obj.cards[c]
                end
            end
        end
        -- if there is only one card and it is a pointer don't keep it
        for k, v in pairs(countColor) do
            if v[1] then
                if #cardCounts[k] == 1 then
                    -- then it is points
                    if posibleEliminies[v[1]].priority == 4 then
                        posibleEliminies[v[1]].priority = 1
                    else
                        posibleEliminies[v[1]].priority = 3
                    end
                elseif #cardCounts[k] == 2 then
                    for c = 1, #v do
                        if posibleEliminies[v[c]].priority == 4 then
                            posibleEliminies[v[c]].priority = 2
                        else
                            posibleEliminies[v[c]].priority = 3.5
                        end
                    end
                elseif #cardCounts[k] == 3 then
                    for c = 1, #v do
                        if posibleEliminies[v[c]].priority == 4 then
                            posibleEliminies[v[c]].priority = 3
                        else
                            posibleEliminies[v[c]].priority = 4
                        end
                    end
                end
            end
        end
        -- simply finish for now 
        local priorities = posibleEliminies
        table.sort(priorities, function(a, b)
            return a.priority < b.priority
        end)
        local numberOfCards = #obj.cards
        for c = 1, 5, 1 do
            newNest[#newNest + 1] = obj.cards[priorities[c].ID]
            obj.cards[priorities[c].ID] = false
            numberOfCards = numberOfCards - 1
            if numberOfCards == 7 then
                break
            end
        end
        for c = #obj.cards, 1, -1 do
            if obj.cards[c] == false then
                table.remove(obj.cards, c)
            end
        end
        return newNest
    end
    obj.takeNest = function(nest, putBack)
        obj.cards = table.copy(nest, obj.cards)
        obj.tookNest = true
        obj.sortHand()
        obj.showHand()
        local trump = obj.chooseTrump()
        _G.game.trump = trump
        obj.sortHand(trump)
        obj.showHand()
        local nestReject = obj.sortOutNest(trump)
        obj.nestReject = nestReject
        if obj.myHand then
            display.remove(obj.myHand)
        end
        obj.sortHand(trump)
        obj.showHand()
        putBack(nestReject)
    end
    obj.layCard = function(submitCard)
        -- sort hand with trump last
        obj.sortHand(_G.game.trump)
        local cardID = 1
        -- play the color thats led
        -- unless you are first
        local turns = _G.game.rounds[_G.game.thisRound].turns
        if turns and #turns > 0 then
            local cardLed = turns[1].card
            for c = 1, #obj.cards do
                -- it's the same color
                if _G.cardMatches(obj.cards[c], cardLed) then
                    cardID = c
                    break
                end
            end
        else
            -- if you have the nest
            if obj.tookNest then
                cardID = #obj.cards
                -- stop laying trump if your opponents are out of trump
                local oppOutOfTrump = oppHasTrump(obj)
                -- if you have trump
                if _G.cardMatches(obj.cards[#obj.cards], "trump") then
                    if oppOutOfTrump then
                        for c = #obj.cards, 1, -1 do
                            -- lay the highest non trump
                            if not _G.cardMatches(obj.cards[c], "trump") then
                                cardID = c
                                break
                            end
                        end
                    end
                end
            end
        end
        -- lay card
        local card = obj.cards[cardID]
        local cardObj = obj.myHand.cards[cardID]
        local cardLocationX, cardLocationY = cardObj:localToContent(0, 0)
        display.currentStage:insert(cardObj)
        cardObj.x = cardLocationX
        cardObj.y = cardLocationY
        transition.to(cardObj, {
            x = display.contentCenterX,
            y = display.contentCenterY,
            time = 100,
            onComplete = function()
                display.remove(cardObj)
            end
        })
        table.remove(obj.cards, cardID)
        table.remove(obj.myHand.cards, cardID)
        obj.showHand()
        submitCard(card)
    end
    return obj
end
return rtn
