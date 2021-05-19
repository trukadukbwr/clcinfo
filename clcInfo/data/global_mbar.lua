local mod = clcInfo.env


function mod.AddMBar(id, alpha, r, g, b, a, visible, ...)
	if visible then
		mod.___e:___AddBar(id, alpha, r, g, b, a, ...)
	else
		if id then mod.___e:___HideBar(id) end
	end
end
