local rtn = {}

rtn.isPaused = false
rtn.timers = {}
local lastFrameTime = system.getTimer()

-- customAction can be "pauseResume", "pauseCancel", "pauseComplete", "pauseIgnore" or "pauseReset"
-- default is "pauseResume"
rtn.new = function(_callBack,delay,args,customAction)
    local thisTimer = {}
    thisTimer.onComplete = _callBack
    thisTimer.args = args
    thisTimer.delay = delay
    thisTimer.totalDelay = delay
    thisTimer.postPauseAction = customAction
    if not thisTimer.postPauseAction then
        thisTimer.postPauseAction = "pauseResume"
    end
    rtn.timers[#rtn.timers+1] = thisTimer
end

rtn.pauseAll = function()
    rtn.isPaused = true
    for i = #rtn.timers,1,-1 do
        local timeThisFrame = system.getTimer()-lastFrameTime
        lastFrameTime = system.getTimer()
        rtn.timers[i].thisTimer.delay = rtn.timers[i].thisTimer.delay - timeThisFrame
        if rtn.timers[i].thisTimer.customAction == "pauseComplete" then
            rtn.timers[i].onComplete(unpack(rtn.timers[i].args))
            table.remove(rtn.timers,i)
        elseif rtn.timers[i].thisTimer.customAction == "pauseCancel" then
            table.remove(rtn.timers,i)
        elseif rtn.timers[i].thisTimer.customAction == "pauseReset" then
            rtn.timers[i].thisTimer.delay = rtn.timers[i].thisTimer.totalDelay
        end
    end
end

rtn.resumeAll = function()
    rtn.isPaused = false
end

local time = 0
local normalTurnTime = 0
local waitTime = 30
local averageFPS = 0
local frameTimes = {}
local update = function()
    local timeThisFrame = system.getTimer()-lastFrameTime
    lastFrameTime = system.getTimer()
    if not rtn.isPaused then
        for i = #rtn.timers,1,-1 do
            rtn.timers[i].thisTimer.delay = rtn.timers[i].thisTimer.delay - timeThisFrame
            if rtn.timers[i].thisTimer.delay <= 0 then
                rtn.timers[i].onComplete(unpack(rtn.timers[i].args))
                table.remove(rtn.timers,i)
            end
        end
    else
        for i = #rtn.timers,1,-1 do
            if rtn.timers[i].customAction == "endpauseIgnore" then
                rtn.timers[i].thisTimer.delay = rtn.timers[i].thisTimer.delay - timeThisFrame
                if rtn.timers[i].thisTimer.delay <= 0 then
                    rtn.timers[i].onComplete(unpack(rtn.timers[i].args))
                    table.remove(rtn.timers,i)
                end
            end
        end
    end
end
Runtime:addEventListener("enterFrame", update)

return rtn