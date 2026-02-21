local widget = require("widget")

local minBid = 120
local rtn = {}

rtn.new = function(ID, team)
    local obj = {}
    obj.group = display.newGroup()
    obj.ID = ID
    obj.isRealPlayer = true
    obj.team = team
    obj.cards = {}
    obj.didPass = false
    obj.handIsSorted = false
    obj.tookNest = false
    obj.objects = {}
    -- players in order clockwise from the top left
    obj.group.x = (math.ceil((obj.ID % 4 + 1) / 2) * 2 - 3) * 80 + display.contentCenterX
    obj.group.y = (math.ceil(obj.ID / 2) * 2 - 3) * 100 + display.contentCenterY + 20
    local function onGlobalTouch(event)
            -- Track swipe direction
            obj.swipeUp = obj.swipeUp or false
            obj._lastTouchY = obj._lastTouchY or nil
            obj._lastTouchX = obj._lastTouchX or nil
        if obj.submitCardHere then
            -- handle the lay event for the card held
            if obj.myHand and obj.myHand.holdingCard then
                obj.myHand.holdingCard:dispatchEvent({
                    name = "layingCard",
                    phase = event.phase,
                    x = event.x,
                    y = event.y
                })
            end
            -- if the touch is on the player's hand and there is a card in focus then dispatch a hold event to that card
            if obj.myHand and obj.myHand.cardInFocus then
                -- dispatch a hold event
                -- a hold is a touch above the hand center line
                local _, handCenterY = obj.myHand:localToContent(0, 0)
                if event.y < handCenterY-40 or obj.myHand.holdingCard then
                    -- holding the card
                    if event.phase == "moved" then
                        obj.myHand.cardInFocus:dispatchEvent({
                            name = "holdCard",
                            phase = event.phase,
                            x = event.x,
                            y = event.y
                        })
                    end
                end
            end
            -- if the touch ends or is cancelled then dispatch a release event
            if obj.myHand and obj.myHand.cardInFocus then
                if event.phase == "ended" or event.phase == "cancelled" then
                    obj.myHand.cardInFocus:dispatchEvent({
                        name = "releaseCard",
                        phase = event.phase,
                        x = event.x,
                        y = event.y
                    })
                end
            end
        end
        -- Update swipeUp on every movement
        if event.phase == "moved" then
            if obj._lastTouchY ~= nil and obj._lastTouchX ~= nil then
                local dy = event.y - obj._lastTouchY
                local dx = event.x - obj._lastTouchX
                -- mostly upward if dy is negative and abs(dy) > abs(dx)
                if (math.abs(dy) > math.abs(dx) and dy < 0) or (dx == 0 and dy == 0) then
                    obj.swipeUp = true
                else
                    obj.swipeUp = false
                end
            end
            obj._lastTouchY = event.y
            obj._lastTouchX = event.x
        elseif event.phase == "began" then
            obj._lastTouchY = event.y
            obj._lastTouchX = event.x
            obj.swipeUp = false
        elseif event.phase == "ended" or event.phase == "cancelled" then
            obj._lastTouchY = nil
            obj._lastTouchX = nil
            obj.swipeUp = false
        end
    end

    _G.screenCover:addEventListener("touch", onGlobalTouch)
    obj.resetRound = function()
        obj.didPass = false
        obj.handIsSorted = false
        obj.tookNest = false
        obj.nestReject = nil
        obj.cards = {}
        for i = #obj.objects, 1, -1 do
            display.remove(obj.objects[i])
            table.remove(obj.objects, i)
        end
        display.remove(obj.myBidDisplay)
        obj.showHand()
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
        local sortedCards = { redCards, blackCards, yellowCards, greenCards }
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
        obj.myHand = _G.showHand(obj.ID, "faceUp")
        obj.myHand.x = 0
        obj.myHand.y = 0
        obj.group:insert(1, obj.myHand)
        obj.myHand.holdGroup = display.newGroup()
        _G.frontGroup:insert(obj.myHand.holdGroup)
        -- touch event to handle several actions
        -- dragging across the hand will lift cards as you pass over them
        -- swiping them up will lay them if allowed
        -- or select cards for nest rejection if taking the nest
        obj.myHand.cardInFocus = nil
        obj.myHand.holdingCard = nil
        for c = 1, #obj.myHand.cards do
            local thisCard = obj.myHand.cards[c]
            thisCard:addEventListener("touch", function(event)
                if obj.submitCardHere and not obj.swipeUp then
                    -- first lower the previous card in focus
                    if obj.myHand.holdingCard then
                        return false
                    end
                    if obj.myHand.cardInFocus and obj.myHand.cardInFocus ~= thisCard then
                        obj.myHand.cardInFocus:lower()
                        obj.myHand.cardInFocus = nil
                    end
                    if event.phase == "moved" or event.phase == "began" then
                        if obj.myHand.cardInFocus ~= thisCard then
                            obj.myHand.cardInFocus = thisCard
                            thisCard:raise()
                        end
                        obj.myHand.lastTouchX = event.x
                        obj.myHand.lastTouchY = event.y
                    end
                    return true
                end
            end)
            -- listen for holdCard events
            thisCard:addEventListener("holdCard", function(event)
                -- local cardLocationX, cardLocationY = thisCard:localToContent(0, 0)
                -- thisCard.x = cardLocationX
                -- thisCard.y = cardLocationY
                thisCard.holdX, thisCard.holdY  = -20, - 50
                obj.myHand.holdGroup.x = event.x
                obj.myHand.holdGroup.y = event.y
                -- print("cart.x, thisCard.y", thisCard.x, thisCard.y)
                -- print("event.x, event.y", event.x, event.y)
                if not thisCard.isHeld then
                    thisCard.isHeld = true
                    -- transilate card to holdGroup coordinates
                    local cardLocationX, cardLocationY = thisCard:localToContent(0, 0)
                    local groupLocationX, groupLocationY = obj.myHand.holdGroup:localToContent(0, 0)

                    obj.myHand.holdingCard = thisCard
                    obj.myHand.holdGroup:insert(thisCard)

                    thisCard.x = cardLocationX - groupLocationX
                    thisCard.y = cardLocationY - groupLocationY
                    thisCard.xScale = 1
                    thisCard.yScale = 1

                    -- first cancel any existing transitions on the card
                    transition.cancel(thisCard)

                    transition.to(thisCard, {
                        x = thisCard.holdX,
                        y = thisCard.holdY,
                        time = _G.animationTime,
                    })
                end
            end)
            thisCard:addEventListener("releaseCard", function(event)
                if thisCard.isHeld then
                    thisCard.isHeld = false
                    thisCard.isLaying = false
                    obj.myHand.cardInFocus = nil
                    obj.myHand.holdingCard = nil
                    -- return the card to the hand group
                    local cardLocationX, cardLocationY = thisCard:localToContent(0, 0)
                    local handLocationX, handLocationY = obj.myHand:localToContent(0, 0)

                    obj.myHand:insert(thisCard.ID,thisCard)

                    thisCard.x = cardLocationX - handLocationX
                    thisCard.y = cardLocationY - handLocationY
                    thisCard.xScale = 1
                    thisCard.yScale = 1
                    rotation = thisCard.homeRotation

                    -- first cancel any existing transitions on the card
                    transition.cancel(thisCard)

                    transition.to(thisCard, {
                        x = thisCard.homeX,
                        y = thisCard.homeY,
                        time = _G.animationTime,
                    })
                else
                    -- just push the card back down to the hand
                    if obj.myHand.cardInFocus == thisCard then
                        thisCard:lower()
                        obj.myHand.cardInFocus = nil
                    end
                end
            end)
            thisCard:addEventListener("layingCard", function(event)
                -- this event is dispatched when the card is ready to be laid
                -- the card should grow slightly when close to the center
                -- then lay the card if the touch ends while close to the center
                local pilePosition = _G.centerPilePosition
                local distanceToPile = math.sqrt((event.x - pilePosition.x) ^ 2 + (event.y - pilePosition.y) ^ 2)
                local layDistance = 50
                
                if event.phase == "moved" then
                    if distanceToPile < layDistance then
                        if not thisCard.isLaying then
                            thisCard.isLaying = true
                            transition.to(thisCard, {
                                xScale = 1.2,
                                yScale = 1.2,
                                time = _G.animationTime
                            })
                        end
                    elseif distanceToPile >= layDistance then
                        if thisCard.isLaying then
                            thisCard.isLaying = false
                            transition.to(thisCard, {
                                xScale = 1,
                                yScale = 1,
                                time = _G.animationTime
                            })
                        end
                    end
                elseif event.phase == "ended" or event.phase == "cancelled" then
                    -- dispatch a lay event to the player to handle the game logic of laying the card
                    thisCard.xScale = 1
                    thisCard.yScale = 1
                    if thisCard.isLaying then
                        if obj.submitCardHere then
                            obj.submitCardHere(thisCard)
                        end
                    end
                end
            end)
        end
    end
    obj.bid = function(bids, highestBid, passedPlayers, submitBid)
        local sartingBid = highestBid + 5
        local canPass = true
        if highestBid == 0 then
            sartingBid = minBid
            canPass = false
        end
        local myBid = sartingBid

        -- display bid
        display.remove(obj.myBidDisplay)
        obj.myBidDisplay = _G.showBid(sartingBid)
        obj.myBidDisplay.x = -20
        obj.myBidDisplay.y = 0
        obj.group:insert(obj.myBidDisplay)

        -- display bid choices
        local currentNumber = sartingBid

        -- Handle stepper events
        local function onStepperPress(event)
            if ("increment" == event.phase) then
                currentNumber = sartingBid + event.value * 5 - 5
            elseif ("decrement" == event.phase) then
                currentNumber = sartingBid + event.value * 5 - 5
            end
            myBid = currentNumber
            if event.value == 0 then
                myBid = "pass"
            end
            obj.myBidDisplay:setText(tostring(myBid))
        end

        -- Create the widget
        local lowestStep = 1
        if canPass then
            lowestStep = 0
        end
        local newStepper = widget.newStepper({
            minimumValue = lowestStep,
            maximumValue = (200 - sartingBid) / 5 + 1,
            onPress = onStepperPress,
            initialValue = 1
        })
        newStepper.xScale = 0.7
        newStepper.yScale = 0.8
        newStepper.x = -20
        newStepper.y = 30
        obj.group:insert(newStepper)
        obj.objects[#obj.objects + 1] = newStepper

        local submitButton = display.newGroup()
        submitButton.back = display.newRoundedRect(0, 0, 45, 30, 6)
        submitButton.text = display.newText({
            text = "Submit",
            x = 0,
            y = 0,
            font = native.systemFontBold,
            fontSize = 19
        })
        submitButton.back.strokeWidth = 3
        submitButton.back:setStrokeColor(0, 0, 0)
        submitButton.back:setFillColor(0.8, 0.8, 0.8)
        submitButton.text:setFillColor(0.3, 0.8, 0.2)
        submitButton:insert(submitButton.back)
        submitButton:insert(submitButton.text)
        submitButton.x = 50
        submitButton.y = 0
        obj.group:insert(submitButton)
        obj.objects[#obj.objects + 1] = submitButton

        submitButton:addEventListener("tap", function()
            submitBid(myBid)
            display.remove(newStepper)
            display.remove(submitButton)
            return true
        end)
    end
    obj.takeNest = function(nest, putBack)
        obj.cards = table.copy(nest, obj.cards)
        obj.tookNest = true
        obj.sortHand()
        obj.showHand()
        local nestReject = {}
        -- each card has a touch event
        obj.myHand.touchEvent = function(event, _card)
            if event.phase == "ended" then
                if _card.isRaised then
                    _card:lower()
                    -- find the index of the card
                    -- and remove it
                    for i = 1, #nestReject do
                        if nestReject[i] == _card.value then
                            table.remove(nestReject, i)
                            break
                        end
                    end
                else
                    _card:raise()
                    nestReject[#nestReject + 1] = _card.value
                end
            end
            return true
        end

        local colorList = { "red", "yellow", "black", "green" }
        local columnData = { {
            align = "left",
            width = 40,
            labelPadding = 5,
            startIndex = 4,
            labels = colorList
        } }

        -- Create the widget
        local pickerWheel = widget.newPickerWheel({
            columns = columnData,
            style = "resizable",
            width = 50,
            rowHeight = 25,
            fontSize = 14
        })
        pickerWheel.x = 125
        pickerWheel.y = 0
        obj.group:insert(pickerWheel)
        obj.objects[#obj.objects + 1] = pickerWheel
        -- Select the third row in the first column
        -- pickerWheel:selectValue( 1, 3 )

        local submitButton = display.newGroup()
        submitButton.back = display.newRoundedRect(0, 0, 80, 50, 10)
        submitButton.text = display.newText({
            text = "Submit",
            x = 0,
            y = 0,
            font = native.systemFontBold,
            fontSize = 30
        })
        submitButton.back.strokeWidth = 3
        submitButton.back:setStrokeColor(0, 0, 0)
        submitButton.back:setFillColor(0.8, 0.8, 0.8)
        submitButton.text:setFillColor(0.3, 0.8, 0.2)
        submitButton:insert(submitButton.back)
        submitButton:insert(submitButton.text)
        submitButton.x = 0
        submitButton.y = 10
        obj.group:insert(submitButton)
        obj.objects[#obj.objects + 1] = submitButton

        submitButton:addEventListener("touch", function(event)
            if event.phase == "ended" and #nestReject == 5 then
                obj.nestReject = nestReject
                -- remove the nestReject from the hand
                for i = #obj.cards, 1, -1 do
                    for j = 1, #nestReject do
                        if obj.cards[i] == nestReject[j] then
                            table.remove(obj.cards, i)
                            break
                        end
                    end
                end
                local color = pickerWheel:getValues()[1].value
                _G.game.trump = color
                _G.showTrump()
                obj.sortHand(color)
                obj.showHand()
                -- put the nest back
                putBack(nestReject)
                display.remove(pickerWheel)
                display.remove(submitButton)
                obj.myHand.touchEvent = nil
            end
            return true
        end)
    end
    obj.layCard = function(playerWithNest, submitCard)
        -- lay the card
        local layCard = function(cardID)
            local cardObj = obj.myHand.cards[cardID]
            local cardLocationX, cardLocationY = cardObj:localToContent(0, 0)
            display.currentStage:insert(cardObj)
            obj.objects[#obj.objects + 1] = cardObj
            cardObj.x = cardLocationX
            cardObj.y = cardLocationY
            _G.flipCard(cardObj)
            transition.to(cardObj, {
                x = _G.centerPilePosition.x,
                y = _G.centerPilePosition.y,
                time = _G.animationTime,
                onComplete = function()
                    display.remove(cardObj)
                end
            })
            table.remove(obj.cards, cardID)
            table.remove(obj.myHand.cards, cardID)
        end
        obj.submitCardHere = function(_card)
            local executeLay = function()
                submitCard(_card.value)
                obj.submitCardHere = nil
                layCard(_card.ID)
                obj.showHand()
            end
            -- make sure it is the color that was led
                -- or we don't have that color
                -- first check if we are laying first
                if _G.game.rounds[_G.game.thisRound].turns[1] then
                    local cardLed = _G.game.rounds[_G.game.thisRound].turns[1].card
                    -- do we have the same color
                    local haveTheColor = false
                    for c = 1, #obj.cards do
                        if _G.cardMatches(obj.cards[c], cardLed) then
                            haveTheColor = true
                            break
                        end
                    end
                    if _G.cardMatches(_card.value, cardLed) then
                        -- playing the color that was led
                        executeLay()
                    elseif not haveTheColor then
                        -- don't have the color the was led
                        executeLay()
                    end
                else
                    -- leading the round
                    executeLay()
                end
        end
        -- touch a card to lay it
        obj.myHand.touchEvent = function(event, _card)
            if event.phase == "ended" then
                if obj.cardInFocus == _card then
                    _card:lower()
                    obj.cardInFocus = nil
                end
            end
        end
    end
    obj.delete = function()
        for i = #obj.objects, 1, -1 do
            display.remove(obj.objects[i])
            table.remove(obj.objects, i)
        end
        obj.resetRound()
        display.remove(obj.group)
        obj.group = nil
    end
    return obj
end

return rtn

-- TODO:
-- on a mostly vertical drag the card should stay raised even if you slide off the edge.
-- this probably the card you want to lay.
