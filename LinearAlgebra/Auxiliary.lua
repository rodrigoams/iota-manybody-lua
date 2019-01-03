local mtype = math.type
local gen = {}

local complex = require"iota.complex.number"

gen.EigSort = function (x,d,isort)
--[[
	Sorts the eigenvalues d and eigenvectors x according to the eigenvalues
	x  - eigenvectors on columns
	d  - vector of eigenvalues
	isort = 0: no sorting; > 0: ascending sorting; < 0: descending sorting
--]]

	if not isort then return x,d end
	assert(mtype(isort) == 'integer')
	assert(x.nrows == x.ncolumns and x.nrows == d.length)
	local n = x.nrows

	for j=1,n-1 do
		jmax = j; dmax = d[j] -- find column of maximum eigenvalue

		for i=j+1,n do
			if complex.real(isort*(dmax-d[i])) > 0.0 then
				jmax = i; dmax = d[i]
			end
		end

		if jmax ~= j then
			d[jmax] = d[j]
			d[j] = dmax -- swap current component with maximum
			for i=1,n do
				t = x[i][j]
				x[i][j] = x[i][jmax]
				x[i][jmax] = t

			end
		end
	end
	return x,d
end

return gen
