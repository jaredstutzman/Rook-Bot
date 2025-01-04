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
    -- players in order clockwise from the top left
    obj.group.x = (math.ceil((obj.ID % 4 + 1) / 2) * 2 - 3) * 80 + display.contentCenterX
    obj.group.y = (math.ceil(obj.ID / 2) * 2 - 3) * 100 + display.contentCenterY + 20
    obj.resetRound = function()
        obj.didPass = false
        obj.handIsSorted = false
        obj.tookNest = false
        obj.nestReject = nil
        obj.cards = {}
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
        obj.myHand = _G.showHand(obj.ID, "faceUp")
        obj.myHand.x = 0
        obj.myHand.y = 0
        obj.group:insert(1, obj.myHand)
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
        print(submitButton:localToContent(0, 0))

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
        end

        local colorList = {"red", "yellow", "black", "green"}
        local columnData = {{
            align = "left",
            width = 40,
            labelPadding = 5,
            startIndex = 4,
            labels = colorList
        }}

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
            end
            return true
        end)
    end
    obj.layCard = function(submitCard)
        -- lay the card
        local layCard = function(cardID)
            local cardObj = obj.myHand.cards[cardID]
            local cardLocationX, cardLocationY = cardObj:localToContent(0, 0)
            display.currentStage:insert(cardObj)
            cardObj.x = cardLocationX
            cardObj.y = cardLocationY
            _G.flipCard(cardObj)
            transition.to(cardObj, {
                x = display.contentCenterX,
                y = display.contentCenterY,
                time = _G.animationTime,
                onComplete = function()
                    display.remove(cardObj)
                end
            })
            table.remove(obj.cards, cardID)
            table.remove(obj.myHand.cards, cardID)
        end
        -- touch a card to lay it
        obj.myHand.touchEvent = function(event, _card)
            if event.phase == "ended" then
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
                        submitCard(_card.value)
                        layCard(_card.ID)
                        obj.showHand()
                    elseif not haveTheColor then
                        -- don't have the color the was led
                        submitCard(_card.value)
                        layCard(_card.ID)
                        obj.showHand()
                    end
                else
                    -- leading the round
                    submitCard(_card.value)
                    layCard(_card.ID)
                    obj.showHand()
                end
            end
        end
    end
    return obj
end

return rtn
