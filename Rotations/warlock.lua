wl = {}
wl.maxIntCastLength = 1
wl.dottableUnits = {
	"target",
	"focus",
	"mouseover",
	"boss1",
	"boss2",
	"boss3",
	"boss4",
}

local function toSpellName(id) name = GetSpellInfo(id); return name end

wl.spells = {}
-- All Specs
wl.spells["opticalBlast"] = toSpellName(119911)
wl.spells["spellLock"] = toSpellName(19647)
wl.spells["mortalCoil"] = toSpellName(6789)
wl.spells["createHealthstone"] = toSpellName(6201)
wl.spells["curseOfTheElements"] = toSpellName(1490)
wl.spells["demonicCircleSummon"] = toSpellName(48018)
wl.spells["demonicCircleTeleport"] = toSpellName(48020)
wl.spells["demonicGateway"] = toSpellName(113901)
wl.spells["grimoireOfSacrifice"] = toSpellName(108503)
wl.spells["enslaveDemon"] = toSpellName(1098)
wl.spells["unendingResolve"] = toSpellName(104773)
wl.spells["twilightWard"] = toSpellName(6229)
wl.spells["commandDemon"] = toSpellName(119898)
wl.spells["darkIntent"] = toSpellName(109773)
wl.spells["fear"] = toSpellName(5782)
wl.spells["banish"] = toSpellName(710)
wl.spells["soulshatter"] = toSpellName(29858)
wl.spells["singeMagic"] = toSpellName(132411)
wl.spells["sacrificialPact"] = toSpellName(108416)
wl.spells["burningRush"] = toSpellName(111400)
wl.spells["soulStone"] = toSpellName(20707)
wl.spells["shadowfory"] = toSpellName(30283)
--Affliction
wl.spells["corruption"] = toSpellName(172)
wl.spells["darkSoulMisery"] = toSpellName(113860)
wl.spells["felFlame"] = toSpellName(77799)
wl.spells["haunt"] = toSpellName(48181)
wl.spells["seedOfCorruption"] = toSpellName(27243)
wl.spells["maleficGrasp"] = toSpellName(103103)
wl.spells["drainSoul"] = toSpellName(1120)
wl.spells["lifeTap"] = toSpellName(1454)
wl.spells["soulSwap"] = toSpellName(86121)
wl.spells["soulburn"] = toSpellName(74434)
wl.spells["drainSoul"] = toSpellName(1120)
wl.spells["maleficGrasp"] = toSpellName(103103)
--Destruction
wl.spells["immolate"] = toSpellName(348)
wl.spells["felFlame"] = toSpellName(77799)
wl.spells["backdraft"] = toSpellName(117896)
wl.spells["rainOfFire"] = toSpellName(5740)
wl.spells["darkSoulInstability"] = toSpellName(113858)
wl.spells["havoc"] = toSpellName(80240)
wl.spells["fireAndBrimstone"] = toSpellName(108683)
wl.spells["emberTap"] = toSpellName(114635)
wl.spells["felFlame"] = toSpellName(77799)
wl.spells["shadowburn"] = toSpellName(17877)
wl.spells["chaosBolt"] = toSpellName(116858)
wl.spells["incinerate"] = toSpellName(29722)
wl.spells["conflagrate"] = toSpellName(17962)
--Demonology
wl.spells["darkSoulKnowledge"] = toSpellName(113861)
wl.spells["metamorphosis"] = toSpellName(103958)
wl.spells["handOfGuldan"] = toSpellName(105174)
wl.spells["shadowflame"] = toSpellName(47960)
wl.spells["shadowBolt"] = toSpellName(686)
wl.spells["soulFire"] = toSpellName(6353)
wl.spells["doom"] = toSpellName(603)
wl.spells["metaDoom"] = toSpellName(124913)
wl.spells["touchOfChaos"] = toSpellName(103964)
wl.spells["voidRay"] = toSpellName(115422)
wl.spells["chaosWave"] = toSpellName(124916)
wl.spells["immolationAura"] = toSpellName(104025)
wl.spells["carrionSwarm"] = toSpellName(103967)
wl.spells["commandDemon"] = toSpellName(119898)
wl.spells["impSwarm"] = toSpellName(104316)
wl.spells["auraOfTheElements"] = toSpellName(116202)
wl.spells["curseOfEnfeeblement"] = toSpellName(109466)
wl.spells["auraOfEnfeeblement"] = toSpellName(116198)
wl.spells["hellfire"] = toSpellName(1949)
wl.spells["demonicLeap"] = toSpellName(109151)
wl.spells["grimoireFelguard"] = toSpellName(111898)
wl.spells["grimoireOfService"] = toSpellName(108501)
wl.spells["harvestLife"] = toSpellName(689)
wl.spells["moltenCore"] = toSpellName(140074)

-- Professions
wl.spells["lifeblood"] = toSpellName(121279)


-- check if our procs are up
function wl.hasProc(min)
	local power = 0
	if jps.buff(wl.spells.darkSoulMisery) then power = power +2 end 
	if jps.buff(126577) then power = power +1 end  --Inner Brilliance, int
	if jps.buff(138703) then power = power +1 end  --Acceleration, haste
	if jps.buff(139133) then power = power +1 end  --Mastermind, int
	if jps.buff(125487) then power = power +1 end 	--Lightweave, int
	if jps.bloodlusting() then power = power +1 end 
	if jps.buff(105702) then power = power +2 end  --potion of jade serpent
	if jps.buff(128985) then power = power +1 end 	--Blessing of the Celestials, int
	if jps.buff(104423) then power = power +1 end 	--Windsong, haste
	if jps.buff(96230) then power = power +1 end 	--Synapse Springs
	if jps.buff(104993) then power = power +0.5 end --Jade Spirit, int
	if jps.buff(126659) then power = power +1 end --Quickened Tongues,haste
	if jps.buff(138786) then power = power +1 end --Wushoolay's Lightning,  int
	if jps.buff(138788) then power = power +1 end --Electrified, int
	if jps.debuff(138002) then power = power +1 end  --fluidity jinrokh, dmg
	if jps.buff(112879) then power = power +1 end  -- primal nutriment jikun, dmg
	if jps.buff(138963) then power = power +1 end  --Perfect Aim, 1005 crit
	if jps.buff(114207) then power = power +1 end  --skullbanner, 20% crit
	--t16
	if jps.buff(146046) then power = power +1 end  -- expanded mind, immerseus trinket, int
	if jps.buff(148906) then power = power +1 end  -- toxic power, shamans trinket, int
	if jps.buff(146184) then power = power +1 end  -- garrosh trinket, int
	if power >= min then return true else return false end
end

function wl.hasKilJaedensCunning()
	local selected, talentIndex = GetTalentRowSelectionInfo(6)
	return talentIndex == 17
end


local function npcId(unit)
	if UnitExists(unit) then return tonumber(UnitGUID(unit):sub(6, 10), 16) end
	return -1
end

local interruptSpellTables = {}
function wl.getInterruptSpell(unit)
	return function()
		if not interruptSpellTables[unit] then interruptSpellTables[unit] = {{"macro", "/cast " .. wl.spells.commandDemon }, false , unit} end
		local canInterrupt = false
		if jps.canCast(wl.spells.opticalBlast, unit) then -- Observer Pet 
			canInterrupt = true
		elseif jps.canCast(wl.spells.spellLock, unit) then -- Felhunter Pet
			canInterrupt = true
		elseif jps.canCast(wl.spells.commandDemon, unit) and select(3,GetSpellInfo(wl.spells.commandDemon))=="Interface\\Icons\\Spell_Shadow_MindRot" then -- GoSac Felhunter
			canInterrupt = true
		end
		local shouldInterrupt = jps.Interrupts and jps.ShouldKick(unit) and jps.CastTimeLeft(unit) < wl.maxIntCastLength
		interruptSpellTables[unit][2] = canInterrupt and shouldInterrupt
		return interruptSpellTables[unit]
	end
end

-- stop spam curse of the elements at invalid targets @ mop
function wl.isCotEBlacklisted(unit) 
	local table_noSpamCotE = {
		56923, -- Twilight Sapper
		56341, 56575, -- Burning Tendons 4.3.0/5.2.0
		53889, -- Corrupted Blood
		60913, -- Energy Charge
		60793, -- Celestial Protector
	}
	for i,j in pairs(table_noSpamCotE) do
		if npcId(unit) == j then return true end
	end
	return false
end

function wl.isTrivial(unit)
	local minHp = 1000000
	if IsInGroup() or IsInRaid() then minHp = minHp * GetNumGroupMembers() end
	return	UnitHealth(unit) <= minHp
end

wl.attackFocus = jps.cachedValue(function()
	return UnitExists("focus") ~= nil and UnitGUID("target") ~= UnitGUID("focus") and not UnitIsFriend("player", "focus")
end)

function wl.hasPet()
	if UnitExists("pet") == nil then return false end
	return true
end
	
-- Deactivate Burning Rush after n seconds of not moving
local burningRushNotMovingSeconds = 0
function wl.deactivateBurningRushIfNotMoving(seconds)
	if not seconds then seconds = 0 end
	if jps.Moving or not jps.buff(wl.spells.burningRush) then
		burningRushNotMovingSeconds = 0
	else
		if burningRushNotMovingSeconds >= seconds then
			RunMacroText("/cancelaura Burning Rush")
		else
			burningRushNotMovingSeconds = burningRushNotMovingSeconds + jps.UpdateInterval
		end
	end
end

-- Interrupt SpellTable for all specs
wl.interruptSpellTable = {
	-- Interrupts
	wl.getInterruptSpell("target"),
	wl.getInterruptSpell("focus"),
	wl.getInterruptSpell("mouseover"),
}

-- Soulstone Table
function wl.soulStone(unit)
	if not unit then unit = "target" end
	local soulStoneTable = {wl.spells.soulStone, false, unit}
	return function()
		soulStoneTable[2] = IsControlKeyDown() ~=nil and jps.cooldown(wl.spells.soulStone) == 0 and UnitIsDeadOrGhost(unit) == 1 and UnitIsFriend("player",unit) == 1
		return soulStoneTable
	end
end
