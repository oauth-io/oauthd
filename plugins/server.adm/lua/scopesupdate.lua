local scopes_keys = redis.call("keys", "scopes:" .. ARGV[1] .. ":*:u:*")
local scopes_values = redis.call("mget", unpack(scopes_keys))

local matches
local provs = {}

local event = "error"

local function pack(...)
	return { n = select("#", ...), ... }
end

for k,v in pairs(scopes_keys) do
	matches = pack(scopes_keys[k]:find("^scopes:([^:]+):[^:]+:u:([^:]+):(.*)$"))
	if matches and matches[3] and matches[4] and matches[5] and matches[5] ~= "" then
		if not provs[matches[3]] then
			provs[matches[3]] = {}
			provs[matches[3]].batches = {}
		end
		if not provs[matches[3]].batches[matches[5]] then
			provs[matches[3]].batches[matches[5]] = {}
		end
		provs[matches[3]].batches[matches[5]][matches[4]] = scopes_values[k]
		redis.call("echo", matches[3] .. '.' .. matches[5] .. '.' .. matches[4] .. ' = ' .. scopes_values[k])
	end
end

local scopes
local ratio
local scope_count
local results = {{},{},{}}
for provider_name,provider in pairs(provs) do
	provider.scope = {}
	for scope,scope_infos in pairs(provider.batches) do
		redis.call("echo", provider_name .. ' batch ' .. scope)
		if not scope_infos[event] then
			scope_infos[event] = 0
		end
		if not scope_infos.total then
			scope_infos.total = 1 -- this should have never happen....
		end
		scope_infos[event] = tonumber(scope_infos[event])
		scope_infos.total = tonumber(scope_infos.total)
		scopes = {}
		scope_count = 0
		for scope_elt in scope:gmatch("[^ ]+") do
			table.insert(scopes,scope_elt)
			scope_count = scope_count + 1
		end

		ratio = math.pow(scope_infos[event] / scope_infos.total, 1.0 / scope_count)
		redis.call("echo", provider_name .. ' -> ' .. scope .. ' | ' .. ratio)
		for k,scope_elt in pairs(scopes) do
			redis.call("echo", scope_elt)
			if not provider.scope[scope_elt] then
				provider.scope[scope_elt] = {}
				provider.scope[scope_elt].total = 0
				provider.scope[scope_elt].wsum = 0
			end
			provider.scope[scope_elt].total = provider.scope[scope_elt].total + scope_infos.total
			provider.scope[scope_elt].wsum = provider.scope[scope_elt].wsum + ratio * scope_infos.total
		end
	end

	for scope_elt,scope in pairs(provider.scope) do
		scope.wsum = scope.wsum / scope.total
		redis.call("echo", provider_name .. '.' .. scope_elt .. ' = ' .. tostring(scope.wsum*100) .. '%')
		table.insert(results[1], provider_name .. '.' .. scope_elt)
		table.insert(results[2], scope.wsum*10000)
		table.insert(results[3], scope.total)
	end
end

return results