--[====================================================================================================================[
Locally Optimal Block Preconditioned Conjugate Gradient Method (LOBPCG)

References:
https://bitbucket.org/joseroman/blopex
https://github.com/scipy/scipy/blob/v1.2.0/scipy/sparse/linalg/eigen/lobpcg/lobpcg.py

License: MIT

Author: Rodrigo A. Moreira

Version: JAN/2019
--]====================================================================================================================]

local optcheck = function(number, default, typestr, arg)
	local type = type
	assert(math.type(number) == 'integer' and number > 0, "first argument must be an integer > 0.")
	local str = string.format("wrong argument %d: ", number)
	if default == nil then assert(arg ~= nil, str.."arg is mandatory, and must be ~= nil") end
	if arg == nil then arg = default end
	if typestr == 'integer' then type = math.type end
	if 	typestr == 'number'	or
			typestr == 'integer' or
			typestr == 'string'	or
			typestr == 'table'	or
			typestr == 'userdata'
		then assert(type(arg) == typestr, str.."type(arg) ~= typestr")
	elseif type(arg) == 'userdata' then
		local mt = getmetatable(arg)
		assert(mt, str.."inexistent metatable for 'arg'.")
		local name = mt.__name
		assert(name, str.."inexistent __name filed in metatable of 'arg'.")
		assert(string.find(name,typestr), str.."wrong __name identification.")
	else
		error( string.format("%s '%s' expected, got '%s'.",str, typestr, type(arg)) )
	end
	return arg
end

local description =
[====================================================================================================================[

	A : The symmetric linear operator of the problem, usually a sparse matrix.  Often called the "stiffness matrix".
	X : Initial approximation to the k eigenvectors. If A has shape=(n,n) then X should have shape shape=(n,k).

	B : optional, the right hand side operator in a generalized eigenproblem. By default, B = Identity often called the "mass matrix".
	M : optional, preconditioner to A; by default M = Identity. M should approximate the inverse of A.
	Y : optional, n-by-sizeY matrix of constraints, sizeY < n. The iterations will be performed in the B-orthogonal complement of the column-space of Y. Y must be full rank.

	Returns:
	w : complex.array. Array of k eigenvalues
  v : complex.array. An array of k eigenvectors.  V has the same shape as X.

	Optional parameters:
  tol : number. Solver tolerance (stopping criterion), by default: tol=n*sqrt(eps)
  maxiter : integer. Maximum number of iterations, by default: maxiter=min(n,20)
	smallest : boolean. When True, solve for the smallest eigenvalues, otherwise the largest, by default: smallest = true.
	verbosity : integer. Controls solver output, by default: verbosityLevel = 0.
  lambdahistory : boolean. Whether to return eigenvalue history.
	residualnormshistory : boolean. Whether to return history of residual norms.

]====================================================================================================================]

local lobpcg = function(A, X, B, M, Y, tol, maxiter, largest, verbosity, lambdahistory, residualnormhistory)

	local A = optcheck(1, nil, 'table', A)
	local X = optcheck(2, nil, 'table', X)

	local B = optcheck(3, false, 'table', B)
	local M = optcheck(4, false, 'table', M)
	local Y = optcheck(5, false, 'table', Y)

	local tol = optcheck(6, A.shape[1] * math.sqrt(eps), 'number', tol)
	local maxiter = optcheck(7, 20, 'integer', maxiter)

end

return lobpcg
