local sparse_arpack = require"iota.sparse.arpack"
local complex = require"iota.complex.number"

print(sparse_arpack)
for k,v in pairs(sparse_arpack) do print(k,v) end

local arpack = sparse_arpack.standard

local n = 1.0e3
local diag = {}
for k=-n,n,1 do diag[#diag+1] = k end
local N = #diag
local t = {}
for k=1,N do t[k] = true end

local time1 = 0.0
local matvec = function(a)
	local time = os.clock()
	local I = complex.I
	local diag = diag
	for k=1,#a do
		a[k] = a[k]*(diag[k]+I)
		--rawset(a,k,rawget(a,k)*(diag[k]+complex.I))
	end
	time1 = time1 + (os.clock() - time)
end

local time2 = 0.0
arpack(#diag, 5, matvec)
print("arpack time: ", os.clock()-time2)
print("matvec time:", time1)
print("MEMORY:", collectgarbage("count")/1024,"MiB")
