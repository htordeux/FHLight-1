jps.registerRotation("PALADIN","RETRIBUTION",function()
	-- sphoenix
	local spell = nil
	local target = nil
	
	local player = jpsName

	local myTarget = jps.LowestTarget()
	local rangedTarget = "target"
		if jps.canDPS("target") then rangedTarget = "target"
		elseif jps.canDPS("focustarget") then rangedTarget = "focustarget"
		elseif jps.canDPS("targettarget") then rangedTarget = "targettarget"
		elseif jps.canDPS(myTarget) then rangedTarget = myTarget
	end
	
	local holyPower = UnitPower("player",9)
	local stance = GetShapeshiftForm()
	local targetHealth = jps.hp("target")
	  
	jps.Macro("/target "..rangedTarget)
		
------------------------
-- SPELL TABLE ------
------------------------

local spellTable_single =
{	 
	-- Kicks
	{ "Rebuke", jps.ShouldKick(rangedTarget) , rangedTarget },
	{ "Rebuke", jps.ShouldKick("focus") , "focus" },
	{ "Fist of Justice", jps.cooldown("rebuke") and jps.ShouldKick(rangedTarget) , rangedTarget },
	{ "Fist of Justice", jps.cooldown("rebuke") and jps.ShouldKick("focus") , "focus" },
	-- Buffs
	{ "Avenging Wrath", jps.UseCDs , player },
	{ "Execution Sentence", onCD and not jps.cooldown("Avenging Wrath") > 0.2 , rangedTarget },
	{ "Guardian of Ancient Kings", jps.UseCDs , rangedTarget },
	-- Single Target 
	{ "Seal of Truth", stance ~= 1 , player },
	{ "Inquisition", jps.buffDuration("Inquisition") < 5 and (holyPower > 2 or jps.buff("Divine Purpose")) , player },
	{ "Templar's Verdict", holyPower = 5 , rangedTarget},
	{ "Hammer of Wrath", true , rangedTarget }, 
	{ "Exorcism" , true , rangedTarget },
	{ "Crusader Strike" , true , rangedTarget },
	{ "Judgment" , true , rangedTarget },
	{ "Templar's Verdict", holyPower >=3 , rangedTarget },
}
	
local spellTable_multi =
{	 
	-- Kicks
	{ "Rebuke", jps.ShouldKick(rangedTarget) , rangedTarget },
	{ "Rebuke", jps.ShouldKick("focus") , "focus" },
	{ "Fist of Justice", jps.cooldown("rebuke") and jps.ShouldKick(rangedTarget) , rangedTarget },
	{ "Fist of Justice", jps.cooldown("rebuke") and jps.ShouldKick("focus") , "focus" },
	-- Buffs
	{ "Avenging Wrath", jps.UseCDs , player },
	{ "Execution Sentence", onCD and not jps.cooldown("Avenging Wrath") > 0.2 , rangedTarget },
	{ "Guardian of Ancient Kings", jps.UseCDs , rangedTarget },
	-- Single Target 
	{ "Seal of Righteousness", stance ~= 2 , player},
	{ "Inquisition", jps.buffDuration("Inquisition") < 5 and (holyPower > 2 or jps.buff("Divine Purpose")) , player },
	{ "Divine Storm", holyPower >= 3 , rangedTarget},
	{ "Hammer of Wrath", true , rangedTarget }, 
	{ "Exorcism" , true , rangedTarget },
	{ "Crusader Strike" , true , rangedTarget },
	{ "Judgment" , true , rangedTarget },
	{ "Templar's Verdict", holyPower >=3 , rangedTarget},
}
	
	
	if jps.MultiTarget then
		spell, target = parseSpellTable(spellTable_multi)
	else
		spell, target = parseSpellTable(spellTable_single)
	end
-- if you're only dps "target" you can let spell alone.
-- if you want to cast some healing spell on others targets you must return the spell and target
-- you don't need to add jps.Target = target because in fct combat jps.ThisCast,jps.Target = jps.Rotation()
	return spell,target 
end, "Default",false,true)
