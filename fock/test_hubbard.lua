-- test fock.ket library

------------------------------------------------------------------------------
pcall(collectgarbage("generational"))
local fock_driver = require"iota.fock.driver"

print(fock_driver.version)

local complex = require"iota.complex.number"

local basis = {}
local NSITES = 2
local NFERMIONS = 2*NSITES
local basisformated = {}
for k=1,NFERMIONS do
	basis[k] = k
	basisformated[k] = k <= NSITES and string.format("%d↑",k) or string.format("%d↓",k-NSITES)
end

local tuple = fock_driver.createFermions(basis,1,NSITES*2)
--local tuple = fock_driver.createBosons(basis,NSITES)
local max = #tuple
print('Number of states:', #tuple)

local check = {}

local fancyket = function(ket)
		local k2 = tostring(ket)
		for i=1,#basisformated do k2 = k2:gsub(string.format("%d ",i),string.format("%s ",basisformated[i])) end
		return k2
end

print"BASIS OF FOCK SPACE"
for k,v in ipairs(tuple) do print(k,v) end
print"------"
for k,v in pairs(tuple) do
	if type(k) ~= 'number' then
		assert(v>0 and v<=max)
		if not check[v] then check[v] = v else error("indice existente") end
		print(v, fancyket(k) )
		assert(tuple[k] == v)
	end
end
print""

braHket = fock_driver.braHket

local CONNECT = {}
for k=1,NSITES-1 do CONNECT[#CONNECT+1] = {k,k+1} end
print"CONNECT"
for k=1,#CONNECT do print(k,'|',table.unpack(CONNECT[k])) end

local T,U = -1.0,math.pi
print""
print("Hubbard T:", T)
print("Hubbard U:", U)
print""

local Hket = function(H,ketj)
	for n=1,NSITES do
		H( U, ketj:Nf(n):Nf(n+NSITES))
	end
	for k=1,#CONNECT do
		local i,j = CONNECT[k][1],CONNECT[k][2]
		-- UP
		H(T, ketj:Af(i):Cf(j))
		H(T, ketj:Af(j):Cf(i))
		-- DOWN
		H(T, ketj:Af(NSITES+i):Cf(NSITES+j))
		H(T, ketj:Af(NSITES+j):Cf(NSITES+i))
	end
end

local Hmatrix = fock_driver.get_Hmatrix(tuple, Hket)

local eigvals = {}
for k=1,#tuple do print(k,0.0) eigvals[k] = 0.0 end -- make sequence
do
	local jacobi = require"iota.linearalgebra.jacobi"
	local evec,eval = jacobi(Hmatrix)
	print"JACOBI OUTPUT"

	for k,v in pairs(eval) do print(k,v) eigvals[k] = v end
end
table.sort(eigvals, function(a,b)return complex.real(a) < complex.real(b)  end)

-- BEGIN EXACT RESULTS
local eval = {}
-- nparticles
eval[0] = {0}
eval[1] = {T,-T,T,-T}
local D = complex.sqrt(16*T*complex.conj(T) + U*complex.conj(U))
eval[2] = {0.0,0.0,0.0,U,0.5*(U-D),0.5*(U+D)}
eval[3] = {T+U,-T+U,T+U,-T+U}
eval[4] = {2*U}
-- END EXACT RESULTS

local eval2 = {}
for n=1,4 do
	for k=1,#eval[n] do eval2[#eval2+1] = {n,eval[n][k]} end
end
table.sort(eval2,function(a,b) return complex.real(a[2])<complex.real(b[2]) end)

print"CORRECT RESULTS (2 SITES )   |        COMPUTED"
for n=1,4 do
	print("NPARTICLES",n)
	local s = {}
	local p = {}
	for k=1,#eval2 do
		if eval2[k][1] == n then
			s[#s+1] = eval2[k][2]
			p[#p+1] = k
		end
	end
	for pos=1,#s do
		local k = p[pos]
		local correct = string.format("%7.3f %7.3fi",complex.real(s[pos]),complex.imag(s[pos]))
		local computed = string.format("| %7.3f %7.3fi",complex.real(eigvals[k]),complex.imag(eigvals[k]) )
		print('\t',correct, computed)
		assert(complex.abs(complex.one*s[pos]-complex.one*eigvals[k]) < 1.0e-6)
	end
end
------------------------------------------------------------------------------
