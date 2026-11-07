--!strict
-- Percentage-based troop orders share this integer calculation between preview and authority.

local TroopMath = {}

function TroopMath.is_valid_percent(percent: any): boolean
	return type(percent) == "number"
		and percent == percent
		and math.abs(percent) ~= math.huge
		and percent >= 1
		and percent <= 100
		and percent == math.floor(percent)
end

function TroopMath.compute_send(total_troops: any, percent: any): number?
	if
		type(total_troops) ~= "number"
		or total_troops ~= total_troops
		or math.abs(total_troops) == math.huge
		or total_troops < 0
		or not TroopMath.is_valid_percent(percent)
	then
		return nil
	end
	if total_troops < 1 then
		return 0
	end
	return math.clamp(math.floor(total_troops * percent / 100), 1, math.floor(total_troops))
end

return TroopMath
