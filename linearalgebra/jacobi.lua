local complex = require"iota.complex.number"
local matrix = require"iota.sparse.matrix"

local abs,sqrt = complex.abs, complex.sqrt
local mtype = math.type or type

local eigsort = function (x,d,isort)
--[[
  Sorts the eigenvalues d and eigenvectors x according to the eigenvalues
  x  - eigenvectors on columns
  d  - vector of eigenvalues
  isort = 0: no sorting; > 0: ascending sorting; < 0: descending sorting
--]]

  if not isort then return x,d end
  assert(mtype(isort) == 'integer')
  assert(x.nrows == x.ncolumns and x.nrows == #d)
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

return function (a)
--[[
	Solves the eigenvalue problem of a real symmetric matrix using the Jacobi method
	a  - real symmetric matrix (lower triangle is destroyed)
	x  - modal matrix: eigenvectors on columns (output)
	d  - vector of eigenvalues
	n  - order of matrix a
	Error flag: 0 - normal execution, 1 - exceeded max. no. of iterations
--]]

	assert(a.nrows == a.ncolumns)
	local n = a.nrows
	local eps = 1e-30 -- precision criterion
	local itmax = 60 -- max no. of iterations

	local x = matrix.newmat(n,n) -- modal matrix = unit matrix
	local d = matrix.newvec(n)

	for i=1,n do -- initialization
		x[i][i] = 1.0
		d[i] = a[i][i] -- eigenvalues = diagonal elements
	end

	for it=1,itmax do -- loop of iterations
		local amax = 0.0
		for i=2,n do -- lower triangle: i>j
			for j=1,(i-1) do
				local aii, ajj, aij = d[i], d[j], abs(a[i][j])

				if aij > amax then amax = aij end -- max. non-diagonal element
				if aij > eps then -- perform rotation

					local c = 0.5*(aii-ajj)/a[i][j]
					local t = 1.0/(abs(c) + sqrt(1.0+c*c)) -- tangent

					if (complex.real(c) < 0.0) then t = -t end -- sign

					c = 1.0/sqrt(1.0+t*t) -- cos
					local s = c*t -- sin

					for k=1,(j-1) do -- columns k < j
						t = a[j][k]*c - a[i][k]*s
						a[i][k] = a[i][k]*c + a[j][k]*s
						a[j][k] = t
					end

					for k=(j+1),(i-1) do -- columns k > j
						t = a[k][j]*c - a[i][k]*s -- interchange j <> k
						a[i][k] = a[i][k]*c + a[k][j]*s
						a[k][j] = t
					end

					for k=(i+1),n do -- columns k > i
						t = a[k][j]*c - a[k][i]*s -- interchange i <> k
						a[k][i] = a[k][i]*c + a[k][j]*s -- interchange j <> k
						a[k][j] = t
					end

					for k=1,n do -- transform modal matrix
						t = x[k][j]*c - x[k][i]*s
						x[k][i] = x[k][i]*c + x[k][j]*s
						x[k][j] = t
					end

					t = 2.0 * s * c * a[i][j]
					d[i] = aii*c*c + ajj*s*s + t -- update eigenvalues
					d[j] = ajj*c*c + aii*s*s - t
					a[i][j] = 0.0
				end
			end
		end
		if (amax<=eps) then -- check convergence
			break
		end
		if (it == itmax) then
			error("Jacobi: max. no. of iterations exceeded !\n")
		end
	end

	return eigsort(x,d,1)
end

--[[
local mat = matrix.newmat(100,100)
for i=1,mat.nrows do
	mat[i][i] = i*1.0
	for j=i+1,mat.ncolumns do
		mat[i][j] = i*j*1.0
		mat[j][i] = mat[i][j]
	end
end

mat:print()

local x,d = Jacobi(mat)

print""
d.mat:print()
print""
x:print()
--]]
