local mod = clcInfo.env
local mod2 = clcInfo.env2

-- expose the play function
mod.Alert = clcInfo.display.alerts.Play

--------------------------------------------------------------------------------
function mod2.AddAlertIconExpiration(alertIndex, timeLeft, sound)
	local e = mod2.___e
	e.hasAlerts = 1
	e.alerts.expiration = {
		alertIndex = alertIndex,
		timeLeft = timeLeft,
		sound = sound,
		
		last = 0,
	}
end
function mod2.AddAlertIconStart(alertIndex, sound)
	local e = mod2.___e
	e.hasAlerts = 1
	e.alerts.start = {
		alertIndex = alertIndex,
		sound = sound,
		
		last = -1,
	}
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
function mod2.AddAlertMIconExpiration(id, alertIndex, timeLeft, sound)
	local e = mod2.___e
	e.hasAlerts = 1
	if not e.alerts[id] then e.alerts[id] = {} end
	e.alerts[id].expiration = {
		alertIndex = alertIndex,
		timeLeft = timeLeft,
		sound = sound,
		
		last = 0,
	}
end
function mod2.AddAlertMIconStart(id, alertIndex, sound)
	local e = mod2.___e
	e.hasAlerts = 1
	if not e.alerts[id] then e.alerts[id] = {} end
	e.alerts[id].start = {
		alertIndex = alertIndex,
		sound = sound,
		
		last = -1,
	}
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
function mod2.AddAlertBarExpiration(alertIndex, timeLeft, sound)
	local e = mod2.___e
	e.hasAlerts = 1
	e.alerts.expiration = {
		alertIndex = alertIndex,
		timeLeft = timeLeft,
		sound = sound,
		
		last = 0,
	}
end
function mod2.AddAlertBarStart(alertIndex, sound)
	local e = mod2.___e
	e.hasAlerts = 1
	e.alerts.start = {
		alertIndex = alertIndex,
		sound = sound,
		
		last = -1,
		lastReversed = 1000000, -- some really big number
	}
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
function mod2.AddAlertMBarExpiration(id, alertIndex, timeLeft, sound)
	local e = mod2.___e
	e.hasAlerts = 1
	if not e.alerts[id] then e.alerts[id] = {} end
	e.alerts[id].expiration = {
		alertIndex = alertIndex,
		timeLeft = timeLeft,
		sound = sound,
		
		last = 0,
	}
end
function mod2.AddAlertMBarStart(id, alertIndex, sound)
	local e = mod2.___e
	e.hasAlerts = 1
	if not e.alerts[id] then e.alerts[id] = {} end
	e.alerts[id].start = {
		alertIndex = alertIndex,
		sound = sound,
		
		last = -1,
		lastReversed = 1000000, -- some really big number
	}
end
--------------------------------------------------------------------------------