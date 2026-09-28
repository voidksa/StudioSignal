local Session = {}
Session.__index = Session
function Session.new(now)
    return setmetatable(
        { startedAt = now, lastInput = now, lastTick = now, activeSeconds = 0, totals = {} },
        Session
    )
end
function Session:touch(now)
    self.lastInput = now
end
function Session:startFocus(minutes, now)
    if minutes ~= 25 and minutes ~= 50 then
        return
    end
    self.focusStarted = now
    self.focusEnds = now + minutes * 60
    self.focusComplete = false
    self:touch(now)
end
function Session:stopFocus()
    self.focusStarted = nil
    self.focusEnds = nil
end
function Session:isIdle(minutes, now)
    return (minutes or 0) > 0
        and now - self.lastInput >= minutes * 60
        and not (self.focusEnds and now < self.focusEnds)
end
function Session:tick(now, mode, active)
    local dt = math.clamp(now - self.lastTick, 0, 5)
    self.lastTick = now
    if active then
        self.activeSeconds += dt
        self.totals[mode] = (self.totals[mode] or 0) + dt
    end
    if self.focusEnds and now >= self.focusEnds then
        self:stopFocus()
        self.focusComplete = true
        self:touch(now)
    end
end
return Session
