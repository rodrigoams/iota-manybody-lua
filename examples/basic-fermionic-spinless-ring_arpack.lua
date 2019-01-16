-- BASIC PACKAGE

local complex = require"iota.complex.number"
local fock_driver = require"iota.fock.driver"

-- NUMBER OF SITES AND PARTICLES

local NSITES = 7
local NFERMIONS = math.floor(NSITES/2)

-- CREATE TUPLE WITH THAT IDENTIFY FOCK SPACE

local tuple = true
do
	-- SIMPLE SEQUENCE THAT ENUMERATES THE FERMIONIC CREATION DEGREES, IN THIS CASE, ONE PER SITE
	local basis = {}
	for k=1,NSITES do basis[k] = k end
	tuple = fock_driver.createFermions(basis,NFERMIONS)
end
local max = #tuple
print('Number of Fock states:', #tuple)

-- PRINT FOCK SPACE

for k,v in pairs(tuple) do
	if type(k) == 'number' then print(k,v) -- basis[] and respective symmetires
	else print("\t",v,k) end -- Id coef |ket>
end

-- EXACT VALUES FOR ONE PARTICLE

print"EXACT VALUES FOR ONE PARTICLE"
local exact = {} -- one particle
if NSITES%2 == 0 then -- even
	for m=1,NSITES do exact[#exact+1] = 2*math.cos(2*math.pi*m/NSITES) end
else -- odd
	for m=-(NSITES)/2,(NSITES-1)/2 do exact[#exact+1] = 2*math.cos(2*math.pi*m/NSITES) end
end
table.sort(exact)
for m=1,#exact do print(m,exact[m]) end

-- COMPUTE HAMILTONIAN MATRIX

-- non-interacting spinless fermionic ring Hamiltonian
local Hket = function(H,ketj)
	for i=1,NSITES-1 do
		H(-1.0, ketj:Af(i):Cf(i+1))
		H(-1.0, ketj:Af(i+1):Cf(i))
	end
	H(-1.0, ketj:Af(1):Cf(NSITES))
	H(-1.0, ketj:Af(NSITES):Cf(1))
end

-- DIAGONALIZE USING ARPACK

local time1,time2 = 0.0,0.0
local f = function(a)
	local tuple = tuple
	assert(#a == #tuple)
	local b = {}
	for k=1,#a do b[k] = 0.0 end
	local H = function(coef,ket)
		local time = os.clock()
		local n = tuple[ket]
		if n then
			rawset(b,n, rawget(b,n) + coef*ket:getcoef())
		end
		time1 = time1 + os.clock()-time
	end
	local time = os.clock()
	local max = #tuple
	local count = 0
	for k,v in pairs(tuple) do
			if type(k) ~= 'number' then
				Hket(H,k:setcoef(a[v]))
				--[[
				count = count+1
				local percent = math.floor(100.0*count/max)
				if percent > 0 then
					local bins = 100
					if percent%5 == 0 then
						local nsquares = bins - math.floor(bins*(1.0 - percent/100.0))
						io.write(string.format("\r%3d %% |"..string.rep("\u{2588}",nsquares)..string.rep(" ",bins - nsquares).."|",percent))
					end
				end
				--]]
			end
	end
	time2 = time2 + os.clock()-time
	assert(#a == #b and #b == #tuple)
	for k=1,#b do
		a[k] = b[k]
		b[k] = nil
	end
	b = nil
end

local sparse_arpack = require"iota.sparse.arpack"
io.write"DIAGONALIZING THE HAMILTONIAN..."
print("#tuple:", #tuple)

local nameevals,nameevecs = sparse_arpack.standard(#tuple, 15, f)
print(nameevals,nameevecs)

print("TIME TO CALL Hket:", time2, "s")
print("TIME TO CALL tuple[]:", time1,"s")

-- COMPUTE EXACT VALUES FOR MANY PARTICLES

local exactene = {}
for k,_ in pairs(tuple) do	if type(k) ~= 'number' then
	local ene = 0.0
	for _,v in pairs({k:getbasis()}) do ene = ene+exact[v] end
	exactene[#exactene + 1] = ene
end end
table.sort(exactene)

-- PRINT EIGENVALUES TO COMPARE WITH EXACT ONES

local eval = {}
do
	local octave = require"iota.parser.octave"
	local map = octave.load_ascii(nameevals)
	for k=1,#map do eval[k] = map[k][1] end
	table.sort(eval,function(a,b) return complex.abs(a) > complex.abs(b) end)
end

print("EIGENVALUES FOR "..tostring(NFERMIONS).." PARTICLES")
for k=1,#eval do
	print(k, eval[k], exactene[k] )
end

-- THE END
