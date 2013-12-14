-- optimisations (if needed): store an ordered hash by date_inscr to fetch only needed users

local inscriptions = redis.call("keys", "u:*:date_inscr")
local dates_inscriptions = redis.call("mget", unpack(inscriptions))
local res = {}
local conversions_sum = {0, 0, 0, 0, 0}
local durations = {0, 0, 0, 0, 0}
local ukey, dates

conversions_sum[0] = 0 -- special index (user count)

for k,v in pairs(inscriptions) do
	if dates_inscriptions[k] >= ARGV[1] and dates_inscriptions[k] <= ARGV[2] then
		ukey = string.sub(inscriptions[k], 1, string.find(inscriptions[k], ":", 3)) .. "date_"
		dates = redis.call("mget", ukey.."inscr", ukey.."validate", ukey.."activation", ukey.."development", ukey.."production", ukey.."consumer")

		conversions_sum[0] = conversions_sum[0] + 1
		for i = 1,5 do
			if dates[i] and dates[i+1] then
				conversions_sum[i] = conversions_sum[i] + 1
				durations[i] = durations[i] + dates[i+1] - dates[i]
			end
		end
	end
end

-- compute conversion rates and durations avg
local conversions = {0, 0, 0, 0, 0}
for i = 1,5 do
	conversions[i] = conversions_sum[i] / conversions_sum[i-1]
	durations[i] = durations[i] * conversions[i]
	conversions[i] = conversions[i] * 10000
end

-- rebase conversions_sum on index 1
for i = 6,1,-1 do conversions_sum[i] = conversions_sum[i-1] end

return {conversions_sum, conversions, durations}