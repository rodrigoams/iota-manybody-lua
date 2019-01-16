-- BASIC PACKAGE

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

-- AUXILIARY FUNCTION

local strc = function(n) -- auxiliary function for print formated complex numbers
	local complex = require"iota.complex.number"
	local real,imag = complex.real(n),complex.imag(n)
	return string.format("[%6.3f %6.3fi]",real,imag)
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
for m=1,#exact do print(m,strc(exact[m])) end

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

local Hmatrix = fock_driver.get_Hmatrix(tuple, Hket)

-- PRINT HAMILTONIAN

print"HAMILTONIAN MATRIX"
if #tuple < 10 then -- sane option
	for k=1,max do for l=1,max do
			io.write(strc(Hmatrix[k][l])," ")
	end print"" end
else print"Hamiltonian too big to be printed!" end

-- DIAGONALIZE

io.write"DIAGONALIZING THE HAMILTONIAN..."
local jacobi = require"iota.linearalgebra.jacobi"
local evec,eval = jacobi(Hmatrix)
print"OK"

-- COMPUTE EXACT VALUES FOR MANY PARTICLES

local exactene = {}
for k,_ in pairs(tuple) do	if type(k) ~= 'number' then
	local ene = 0.0
	for _,v in pairs({k:getbasis()}) do ene = ene+exact[v] end
	exactene[#exactene + 1] = ene
end end
table.sort(exactene)

-- PRINT EIGENVALUES TO COMPARE WITH EXACT ONES

local complex = require"iota.complex.number"
print("EIGENVALUES FOR "..tostring(NFERMIONS).." PARTICLES")
for k=1,#eval do
	print(k, strc(eval[k]), strc(exactene[k]) )
	assert(complex.abs(eval[k] - exactene[k]) < 1.0e-10)
end

-- THE END
