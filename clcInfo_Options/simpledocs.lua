-- exposed vars
local mod = clcInfo_Options
local AceRegistry = mod.AceRegistry
local options = mod.options
clcInfo_Options.simpleDocs = {}
local simpleDocs = clcInfo_Options.simpleDocs

-- get an alphabetically sorted function list from clcInfo.env
local funclist = {}
for k, v in pairs(clcInfo.env) do
	if type(v) == "function" then
		funclist[#funclist+1] = k
	end
end
table.sort(funclist)

local funcdocs = {
["IconAura"] = {
["declaration"] = [[
IconAura(filter, unitTarget, spell [, unitCaster ])



filter: a list of filters to use separated by the pipe '|' character; e.g. "RAID|PLAYER" will query group buffs cast by the player (string)
____| HARMFUL: show debuffs only
____| HELPFUL: show buffs only
____| CANCELABLE: show auras that can be cancelled
____| NOT_CANCELABLE: show auras that cannot be cancelled
____| PLAYER: show auras the player has cast
____| RAID: when used with a HELPFUL filter it will show auras the player can cast on party/raid members (as opposed to self buffs). If used with a HARMFUL filter it will return debuffs the player can cure

unitTarget: unit that will be scanned

spell: name of the aura

unitCaster: if specified, it will check caster of the buff against this unit
]],
},


["IconAuraID"] = {
["declaration"] = [[
IconAuraID(filter, unitTarget, id [, unitCaster ])



filter: a list of filters to use separated by the pipe '|' character; e.g. "RAID|PLAYER" will query group buffs cast by the player (string)
____| HARMFUL: show debuffs only
____| HELPFUL: show buffs only
____| CANCELABLE: show auras that can be cancelled
____| NOT_CANCELABLE: show auras that cannot be cancelled
____| PLAYER: show auras the player has cast
____| RAID: when used with a HELPFUL filter it will show auras the player can cast on party/raid members (as opposed to self buffs). If used with a HARMFUL filter it will return debuffs the player can cure

unitTarget: unit that will be scanned

id: id of the aura

unitCaster: if specified, it will check caster of the buff against this unit
]],
},


["IconSpell"] = {
["declaration"] = [[
IconSpell(spell [, checkRange [, showWhen ] ])



spell: name or id of the spell to track

checkRange:
____| nil or false: do nothing
____| true: display range of spell specified in spellName
____| string: display range of spell specified in string

showWhen:
____| nil or false: do nothing
____| "ready": display spell only when ready
____| "not ready": display spell only when not ready
]],
},


["IconItem"] = {
["declaration"] = [[
IconItem(itemId [, equipped [, showWhen ] ])



item: id of the item

equipped: if true, the item must be equipped or it will be ignored

showWhen:
____| nil or false: do nothing
____| "ready": display spell only when ready
____| "not ready": display spell only when not ready
]],
},


["IconICD"] = {
["declaration"] = [[
IconICD(spellId, icd, alpha1, alpha2, alpha3)



spellId: id of the buff to track

icd: duration of the internal cooldown

alpha1, alpha2, alpha3: alpha values of the 3 states
____| 1: ready to proc
____| 2: proc active
____| 3: proc on cooldown
]],
},


["IconMICD"] = {
["declaration"] = [[
IconMICD(icd, alpha1, alpha2, alpha3, ...)



icd: duration of the internal cooldown

alpha1, alpha2, alpha3: alpha values of the 3 states
____| 1: ready to proc
____| 2: proc active
____| 3: proc on cooldown

...: list of id for the buffs generated


info: used for items that generate variable procs, like DBW
]],
},


["IconMAura"] = {
["declaration"] = [[
IconMAura(filter, unitTarget, ...)



filter: a list of filters to use separated by the pipe '|' character; e.g. "RAID|PLAYER" will query group buffs cast by the player (string)
____| HARMFUL: show debuffs only
____| HELPFUL: show buffs only
____| CANCELABLE: show auras that can be cancelled
____| NOT_CANCELABLE: show auras that cannot be cancelled
____| PLAYER: show auras the player has cast
____| RAID: when used with a HELPFUL filter it will show auras the player can cast on party/raid members (as opposed to self buffs). If used with a HARMFUL filter it will return debuffs the player can cure

unitTarget: unit that will be scanned

...: list of aura names to check

info: scans a specified target for a list of auras and displays first one found, used for multiple auras with the same effect
]],
},


["IconAction"] = {
["declaration"] = [[
IconAction(slot [, checkRange [, showWhen ] ])



slot: action bar slot to check

checkRange:
____| nil or false: do nothing
____| true: display range of the action slot
____| string: display range of spell specified in string

showWhen:
____| nil or false: do nothing
____| "ready": display only when ready
____| "not ready": display only when not ready
]],
},


["IconSingleTargetRaidBuff"] = {
["declaration"] = [[
IconSingleTargetRaidBuff(spell [, scope ])



spell: name of the aura to track

scope:
____| nil or "numRoster": scans all players in raid
____| "numRosterPets": scans all players and pets
____| "numRosterPetsBosses": scans all players and pets and boss1, boss2, boss3, boss4

info: used for spells like beacon of light or earth shield
]],
},


["IconSingleTargetRaidBuffID"] = {
["declaration"] = [[
IconSingleTargetRaidBuffID(id [, scope ])



id: id of the aura to track

scope:
____| nil or "numRoster": scans all players in raid
____| "numRosterPets": scans all players and pets
____| "numRosterPetsBosses": scans all players and pets and boss1, boss2, boss3, boss4

info: used for spells like sacred shield
]],
},

["IconRune"] = {
["declaration"] = [[
IconRune(rune)



rune: the number of the rune, 1-6
]],
},


["IconStagger"] = {
["declaration"] = [[
IconStagger()



info: displays the stagger debuff and shows the value
]],
},


["BarSpell"] = {
["declaration"] = [[
BarSpell(spell [, timeRight ])



spell: name or id of the spell to track

timeRight: if true, timer will be displayed on the right side in seconds
]],
},


["BarAura"] = {
["declaration"] = [[
BarAura(filter, unitTarget, spell [, unitCaster [, showStack [, timeRight [, dtext ] ] ] ])



filter: a list of filters to use separated by the pipe '|' character; e.g. "RAID|PLAYER" will query group buffs cast by the player (string)
____| HARMFUL: show debuffs only
____| HELPFUL: show buffs only
____| CANCELABLE: show auras that can be cancelled
____| NOT_CANCELABLE: show auras that cannot be cancelled
____| PLAYER: show auras the player has cast
____| RAID: when used with a HELPFUL filter it will show auras the player can cast on party/raid members (as opposed to self buffs). If used with a HARMFUL filter it will return debuffs the player can cure

unitTarget: unit on witch to check the auras

spell: name of the aura

unitCaster: if specified, it will check caster of the buff against this unit

showStack: specifies where the stack value is positioned
____| false/nil: hidden
____| "before": before name
____| not false/nil: after name

timeRight: if true, timer will be displayed on the right side in seconds

dtext: specifies the main text on the bar
____| false/nil: aura name
____| "unit": unit name
____| "unitaura" or "auraunit": combination
]],
},


["BarAuraID"] = {
["declaration"] = [[
BarAuraID(filter, unitTarget, spellID [, unitCaster [, showStack [, timeRight [, dtext ] ] ] ])



filter: a list of filters to use separated by the pipe '|' character; e.g. "RAID|PLAYER" will query group buffs cast by the player (string)
____| HARMFUL: show debuffs only
____| HELPFUL: show buffs only
____| CANCELABLE: show auras that can be cancelled
____| NOT_CANCELABLE: show auras that cannot be cancelled
____| PLAYER: show auras the player has cast
____| RAID: when used with a HELPFUL filter it will show auras the player can cast on party/raid members (as opposed to self buffs). If used with a HARMFUL filter it will return debuffs the player can cure

unitTarget: unit on witch to check the auras

spellID: id of the aura

unitCaster: if specified, it will check caster of the buff against this unit

showStack: specifies where the stack value is positioned
____| false/nil: hidden
____| "before": before name
____| not false/nil: after name

timeRight: if true, timer will be displayed on the right side in seconds

dtext: specifies the main text on the bar
____| false/nil: aura name
____| "unit": unit name
____| "unitaura" or "auraunit": combination
]],
},


["BarItem"] = {
["declaration"] = [[
BarItem(itemId [, equipped [, timeRight ] ])



itemId: id of the item

equipped: if true, the item must be equipped or it will be ignored

timeRight: if true, timer will be displayed on the right side in seconds
]],
},


["BarSingleTargetRaidBuff"] = {
["declaration"] = [[
BarSingleTargetRaidBuff(spell [, showStack [, timeRight [, scope] ] ])



spell: name of the aura

showStack: specifies where the stack value is positioned
____| false/nil: hidden
____| "before": before name
____| not false/nil: after name

scope:
____| nil or "numRoster": scans all players in raid
____| "numRosterPets": scans all players and pets
____| "numRosterPetsBosses": scans all players and pets and boss1, boss2, boss3, boss4

info: track buffs like Beacon of Light or Earth Shield on party/raid members.
]],
},


["BarSingleTargetRaidBuffID"] = {
["declaration"] = [[
BarSingleTargetRaidBuffID(id [, showStack [, timeRight [, scope] ] ])



id: name of the aura

showStack: specifies where the stack value is positioned
____| false/nil: hidden
____| "before": before name
____| not false/nil: after name

scope:
____| nil or "numRoster": scans all players in raid
____| "numRosterPets": scans all players and pets
____| "numRosterPetsBosses": scans all players and pets and boss1, boss2, boss3, boss4

info: track buffs like Beacon of Light or Earth Shield on party/raid members.
]],
},


["MIconRaidUnitAuras"] = {
["declaration"] = [[
MIconRaidUnitAuras(unitName, filter)


unitName: unit in raid to scan

filter: a list of filters to use separated by the pipe '|' character; e.g. "RAID|PLAYER" will query group buffs cast by the player (string)
____| HARMFUL: show debuffs only
____| HELPFUL: show buffs only
____| CANCELABLE: show auras that can be cancelled
____| NOT_CANCELABLE: show auras that cannot be cancelled
____| PLAYER: show auras the player has cast
____| RAID: when used with a HELPFUL filter it will show auras the player can cast on party/raid members (as opposed to self buffs). If used with a HARMFUL filter it will return debuffs the player can cure

info: shows auras on a specific unit in raid, useful for example when tanks want to swap at a certain amount of stacks

]],
},



["MIconProtPCooldowns"] = {
["declaration"] = [[
MIconProtPCooldowns()



info: populates an micon control with important buffs active on the prot pala
]],
},


["TextVengeance"] = {
["declaration"] = [[
TextVengeance([ unit ])



unit: unit to check vengeance buff on ("player", "target", "raid1", etc...), defaults to "player".
]],
},


["AddMIcon"] = {
["declaration"] = [[
AddMIcon(id, ...)



id: some string to id the icon in this group, can be nil (planning to use it for alerts)

...: rest of the arguments returned by icon functions

info: add icons to a multi icon element using the normal icon functions
]],
},


["AddMBar"] = {
["declaration"] = [[
AddMBar(id, alpha, r, g, b, a, ...)



id: some string to id the bar in this group, can be nil (planning to use it for alerts)

alpha: alpha of the bar

r, g, b, a: color of the bar's statusbar

...: rest of the arguments returned by bar functions

info: add bars to a multi bar element using the normal bar functions
]],
},


["IconSpellReadyGCD"] = {
["declaration"] = [[
IconSpellReadyGCD(spell, gcdSpell [, maxcd ])


spell: spell to display

gcdSpell: spell to use for gcd value, it needs to be on gcd and not have a cooldown (example: arcane shot)

maxcd: if cd - gcd < maxcd then display, default is 0.1

info: experimental function, displays the spell if it's ready to be used when next GCD finishes
]],
},


["IconSpellReadyNOGCD"] = {
["declaration"] = [[
IconSpellReadyNOGCD(spell [, maxcd ])
]],
},

--
-- [""] = {
-- ["declaration"] = [[
-- ]],
-- },
--

}

function mod:LoadSimpleDocs()
	options.args.simpleDocs = {
		order = 900, type = "group", name = "Docs", childGroups = "tab",
		args = {
			functions = {
				order = 100,
				type = "group",
				name = "Functions",
				args = {},
			},
		},
	}

	local cat = options.args.simpleDocs.args.functions.args
	for i = 1, #funclist do
		local name = funclist[i] 
		if funcdocs[name] then
			local docs = funcdocs[name]
			cat[name] = {
				type = "group",
				name = name,
				args = {
					["declaration"] = {
						type = "description",
						name = docs["declaration"],
					},
				},
			}
		--else
		--	print(name)
		end
	end	

	AceRegistry:NotifyChange("clcInfo")
end