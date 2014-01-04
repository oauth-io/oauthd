local userapps = redis.call("keys", "u:*:apps")
local userid, apps

for k,v in pairs(userapps) do
	userid = string.sub(userapps[k], 3, string.find(userapps[k], ":", 3) - 1)
	apps = redis.call("smembers", "u:"..userid..":apps")

	for k,v in pairs(apps) do
		redis.call("set", "a:"..apps[k]..":owner", userid)
	end
end
