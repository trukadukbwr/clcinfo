local mod = clcInfo

function mod.env.GetStorage() return mod.env.___e.___storage end

function mod.DisplayElementsEventDispatch(self, event, ...)
	if self.eventHooks[event] then self.eventHooks[event](self.___storage, event, ...) end
end

--  !!! self is an object not the mod
function mod.UpdateExec(self)
	-- new storage
	self.___storage = { ___parent = self }

	-- updates per second
	self.freq = 1/self.db.ups
	self.elapsed = 100 -- force instant update
	
	-- clear error codes
	self.errExec = ""

	local err
	-- exec
	self.exec, err = loadstring(self.db.exec)
	-- apply DoNothing if we have an error
	if not self.exec then
		self.exec = loadstring("")
		print("code error:", err)
		print("in:", self.db.exec)
	end
  setfenv(self.exec, mod.env)
  
  -- cleanup if required
  if self.ExecCleanup then
  	self.ExecCleanup()
  	self.ExecCleanup = nil
  end
end

function mod.DisableExec(self)
	self.exec = nil
	if self.ExecCleanup then
  	self.ExecCleanup()
  	self.ExecCleanup = nil
  end
end

function mod.UpdateExecAlert(self)
	-- defaults
  self.alerts = {}
  self.hasAlerts = 0
  
  self.errExecAlert = ""
  
  -- execute the code
  local f, err = loadstring(self.db.execAlert or "")
  if f then
  	clcInfo.env2.___e = self
  	setfenv(f, clcInfo.env2)
  	local status, err = pcall(f)
  	if not status then self.errExecAlert = err end
  else
  	print("alert code error:", err)
  	print("in:", self.db.execAlert)
  end
end

function mod.UpdateExecEvent(self)
	-- clear error codes
	self.errExecEvent = ""
	-- unregister events
	self:UnregisterAllEvents()
	self.eventHooks = {}
	
	self.errExecEvent = ""
	
	local f, err = loadstring(self.db.eventExec)
	if f then
		mod.env2.___e = self	-- make the object available on the env
		setfenv(f, mod.env2)	-- call the function
  	local status, err = pcall(f) -- check for errors
  	if not status then self.errExecEvent = err end
  else
  	print("alert code error:", err)
  	print("in:", self.db.eventExec)
	end
end

function mod.env2.AddEventListener(f, ...)
	local e = mod.env2.___e
	for i = 1, select("#", ...) do
		e.eventHooks[select(i, ...)] = f
		e:RegisterEvent(select(i, ...))
	end
end