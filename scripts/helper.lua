local H = {}

function split(str, deli)
	local result = {}
	local r_count = 0
	for i in string.gmatch(str, deli) do
		result[r_count] = i
		r_count = r_count + 1
	end
	return result
end

function contains(list, object)
	for key,value in pairs(list) do
		if (value == object) then
			return true
		end
	end
	return false
end

function find_min(list)
	local ans = list[0]
	local num = 0
	for i=0, (# list) do
		if ((# ans) > (# list[i])) then
			ans = list[i]
			num = i
		end
	end
	return num
end

H.split = split
H.contains = contains
H.find_min = find_min

return H