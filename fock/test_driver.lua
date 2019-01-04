pcall(collectgarbage("generational"))
local complex = require"iota.complex.number"
local fock_driver = require"iota.fock.driver"

local basis = {}
local N = 26
for k=1,N do basis[k] = k end

local tuple = fock_driver.createFermions(basis,math.tointeger(N/2))
--local tuple = fock_driver.createBosons(basis,math.tointeger(N/2))
local max = #tuple
print('Number of states:', #tuple)

local check = {}

for k,v in pairs(tuple) do
	if type(k) == 'number' then
		print(k,v)
	else
		assert(v>0 and v<=max)
		if not check[v] then check[v] = v else error("indice existente") end
		print(string.format("%15d",v),k)
		assert(tuple[k] == v)
	end
end

braHket = fock_driver.braHket

local Hket = function(H,ketj)
	H(-0.5, ketj)
end

local iHj = function(i,j,Hij)
	assert(i == j)
	assert(i > 0)
	assert(Hij == -0.5*complex.one)
	--print(i,j,Hij)
end

braHket(tuple, Hket, iHj)

-- non-interacting ring
local Hket = function(H,ketj)
	for i=1,N-1 do
		H( 2.5, ketj:Nf(i):Nf(i+1))
		H(-1.0, ketj:Af(i):Cf(i+1))
		H(-1.0, ketj:Af(i+1):Cf(i))
	end
	H( 2.5, ketj:Nf(N):Nf(1))
	H(-1.0, ketj:Af(1):Cf(N))
	H(-1.0, ketj:Af(N):Cf(1))
end

local Hmatrix = fock_driver.get_Hmatrix(tuple, Hket)

fock_driver.write_H('H', tuple, Hket)
