% Test file for singfun/rdivide.m

function pass = test_rdivide(pref)

% Get preferences.
if ( nargin < 1 )
    pref = singfun.pref.singfun;
end

% Generate a few random points to use as test values.
seedRNG(666);
x = 2 * rand(100, 1) - 1;

pass = zeros(1, 7);   % Pre-allocate pass vector
tol = 1e3*pref.eps;   % loose tolerance for rdivide

%%
% Check operation in the case of empty arguments.
f = singfun();
g = singfun(@(x) 1./(1+x), [-1, 0]);
pass(1) = (isempty(f./g) && isempty(g./f) && isempty(f./f));

%%
% Check division with a double.

fh = @(x) 1./((1+x).*(1-x));
f = singfun(fh, [-1, -1]);
% A random double:
g = rand();
pass(2) = test_division_by_scalar(f, fh, g, x, tol);

%%
% Check reciprocal of a singfun.
fh = @(x) 0*x + 1;
f = singfun(fh, [], {'none', 'none'}, pref);
gh = @(x) cos(x);
g = singfun(gh, [], {'none', 'none'}, pref);
pass(3) = test_divide_function_by_function(f, fh, g, gh, x, tol);

%% 
% Check division of two singfun objects.
fh = @(x) cos(x);
f = singfun(fh, [], {'none', 'none'}, pref);
pass(4) = test_divide_function_by_function(f, fh, f, fh, x, tol);

fh = @(x) sin(x);
f = singfun(fh, [], [], pref);

gh = @(x) (1+x).*(1-x);  %
g = singfun(gh, [], [], pref);
pass(5) = test_divide_function_by_function(f, fh, g, gh, x, tol);

fh = @(x) sin(1e2*x);
f = singfun(fh, [], [], pref);
pass(6) = test_divide_function_by_function(f, fh, g, gh, x, tol);

%%
% Check that direct construction and RDIVIDE give comparable results.

f = singfun(@(x) sin(pi/2*x), [], [], pref);
g = singfun(@(x) cos(pi/2*x) - 1, [], [], pref);
h1 = f./g;
h2 = singfun(@(x) sin(pi/2*x)./cos(pi/2*x), [], [], pref);
pass(7) = norm(feval(h1, x) - feval(h2, x), inf) < tol;


end

% Test the division of a SINGFUN F, specified by Fh, by a scalar C using
% a grid of points X for testing samples.
function result = test_division_by_scalar(f, fh, c, x, tol)
    g = f./c;
    g_exact = @(x) fh(x)./c;
    result = norm(feval(g, x) - g_exact(x), inf) <= tol;
end

% Test the division of two SINGFUN objects F and G, specified by FH and
% GH, using a grid of points X for testing samples.
function result = test_divide_function_by_function(f, fh, g, gh, x, tol)
    h = f./g;
    h_exact = @(x) fh(x)./gh(x);
    result = norm(feval(h, x) - h_exact(x), inf) <= tol;
end
