function [uout, tout] = spinsphere(varargin)
%SPINSPHERE  Solve a time-dependent PDE on the sphere with the double Fourier 
%sphere method and IMEX time-stepping algorithms.
%
%   UOUT = SPINSPHERE(PDECHAR) solves the PDE specified by the string PDECHAR,
%   and plots a movie of the solution as it computes it; it is a demo mode.
%   The space and time intervals and the initial condition are chosen to produce
%   beautiful movies. Strings available include 'AC' for Allen-Cahn equation, 
%   'GL' for Ginzburg-Landau equation, 'GM' for Gierer-Meinhardt equations and 
%   'NLS' for nonlinear Schrodinger equation. See Remark 1 and Examples 1-4. 
%   The output UOUT is a SPHEREFUN corresponding to the solution at the final 
%   time (a CHEBMATRIX for systems of equations, each row representing one 
%   variable).
%
%   UOUT = SPINSPHERE(S, N, DT) solves the PDE specified by the SPINOPSPHERE S 
%   with N grid points in each direction and time-step DT. It plots a movie of 
%   the solution as it computes it. See HELP/SPINOPSPHERE and Example 5.
%
%   UOUT = SPINSPHERE(S, N, DT, PREF) allows one to use the preferences 
%   specified by the SPINPREFSPHERE object PREF. See HELP/SPINPREFSPHERE and 
%   Example 6.
%
%   UOUT = SPINSPHERE(S, N, DT, 'PREF1', VALUEPREF1, 'PREF2', VALUEPREF2, ...) 
%   is an alternative to the previous syntax. See Example 6.
%
%   [UOUT, TOUT] = SPINSPHERE(...) also returns the times chunks TOUT at which 
%   UOUT was computed.
%
% Remark 1: Available (case-insensitive) strings PDECHAR are
%
%    - 'AC' for Allen-Cahn equation,
%    - 'GL' for Ginzburg-Landau equation,
%    - 'GM' for Gierer-Meinhardt equations,
%    - 'NLS' for focusing nonlinear Schroedinger equation.
%
% Example 1: Allen-Cahn equation (metastable solutions)
%
%        u = spinsphere('AC');
%
%    solves the Allen-Cahn equation
%
%        u_t = 1e-2*laplacian(u) + u - u^3
%
%    on the sphere from t=0 to t=60, with initial condition
%
%        u0(x, y, z) = cos(cosh(5*x.*z) - 10*y).
%
% Example 2: Ginzburg-Landau equation (spiral waves)
%
%        u = spinsphere('GL');
%
%    solves the Ginzburg-Landau equation
%
%        u_t = 5e-4*laplacian(u) + u - (1+1.5i)*u*|u|^2,
%
%    on the sphere from t=0 to t=100 with a RANDNFUNSPHERE initial condition.   
%    The movie plots the real part of u.
%
% Example 3: Gierer-Meinhardt equations (pattern formation - dots)
%
%        u = spinsphere('GM);
%
%    solves the Gierer-Meinhardt equations,
%
%       u_t = 4e-3*laplacian(u) + u.^2/v - u,
%       v_t = 4e-2*laplacian(v) + u^2 - v,
%
%    on the sphere from t=0 to t=80, with initial condition
%
%       u0(x,y,z) = 1 + .1*(cos(20*x) + cos(20*y) + cos(20*z)),
%       v0(x,y,z) = 1 - .1*(cos(20*x) + cos(20*y) + cos(20*z)).
%
% Example 4: Nonlinear Schroedinger equation (spherical harmonic + breather)
%
%        u = spinsphere('NLS');
%
%    solves the focusing nonlinear Schroedinger equation
%
%        u_t = 1i*laplacian(u) + 1i*u|u|^2,
%
%    on the sphere from t=0 to t=3, with initial condition
%
%     u0(lam, th) = .1*(2*B^2./(2 - sqrt(2)*sqrt(2-B^2)*cos(A*B*th)) - 1)*A 
%                  + Y_8^6(lam, th), with A=1 and B=1.
%
%    The movie plots the absolute value of u.
%
% Example 5: PDE specified by a SPINOPSPHERE
%
%       tspan = [0 100];
%       S = spinopsphere(tspan);
%       S.lin = @(u) 5e-4*lap(u);
%       S.nonlin = @(u) u - (1 + 1.5i)*u.*(abs(u).^2);
%       S.init = randnfunsphere(.1);
%       S.init = S.init/norm(S.init, inf);
%       u = spinsphere(S, 128, 1e-1);
%
%   is equivalent to u = spinsphere('GL');
%
% Example 6: Using preferences
%
%       pref = spinprefsphere('Clim', [-1 1]);
%       S = spinopsphere('ac');
%       u = spinsphere(S, 128, 1e-1, pref);
%   or simply,
%       u = spinsphere(S, 128, 1e-1, 'Clim', [-1 1]);
%
%   solves the Allen-Cahn equation using N=128 grid points in each direction,
%   a time-step dt=1e-1 and set the limits of the colobar to [-1 1].
%
% See also SPINOPSPHERE, SPINPREFSPHERE, IMEX.

% Copyright 2017 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org/ for Chebfun information.

% We are going to parse the inputs and call SOLVEPDE in the following ways,
%
%       SPINOPERATOR.SOLVEPDE(S, N, dt)
%  or
%       SPINOPERATOR.SOLVEPDE(S, N, dt, pref)
%
% where S is a SPINOPSPHERE object, N is the number of grid points in each 
% direction, DT is the time-step and PREF is a SPINPREFSPHERE oject.

if ( nargin == 1 ) % e.g., u = spinsphere('gl')
    try spinopsphere(varargin{1});
    catch
        error('Unrecognized PDE. See HELP/SPINSPHERE for the list of PDEs.')
    end
    [S, N, dt, pref] = parseInputs(varargin{1});
    varargin{1} = S;
    varargin{2} = N;
    varargin{3} = dt;
    varargin{4} = pref;
elseif ( nargin == 3 ) % e.g., u = spinsphere(S, 128, 1e-1)
    % Nothing to do here.
elseif ( nargin == 4 ) % e.g., u = spinsphere(S, 128, 1e-1, pref)
    % Nothing to do here.
elseif ( nargin >= 5 ) % u.g., u = spinsphere(S, 128, 1e-1, 'plot', 'off')
    % In this case, put the options in a SPINPREFSPHERE object.
    pref = spinprefsphere();
    j = 4;
    while j < nargin
        pref.(varargin{j}) = varargin{j+1};
        varargin{j} = [];
        varargin{j+1} = [];
        j = j + 2;
    end
    varargin{end + 1} = pref;
    varargin = varargin(~cellfun(@isempty, varargin));
end

% SPINSPHERE is a wrapper for SOLVPDE:
[uout, tout] = spinoperator.solvepde(varargin{:});

end

function [S, N, dt, pref] = parseInputs(pdechar)
%PARSEINPUTS   Parse the inputs.

pref = spinprefsphere();
S = spinopsphere(pdechar);
if ( strcmpi(pdechar, 'AC') == 1 )
    dt = 1e-1;
    N = 128;
    pref.Clim = [-1 1];
    pref.iterplot = 2;
    pref.Nplot = 256;
elseif ( strcmpi(pdechar, 'GL') == 1 )
    dt = 1e-1;
    N = 128;
    pref.Clim = [-1 1];
    pref.iterplot = 2;
    pref.Nplot = 256;
elseif ( strcmpi(pdechar, 'GM') == 1 )
    dt = 2e-1;
    N = 64;
    pref.Clim = [0 3 0.5 2];
    pref.iterplot = 4;
    pref.Nplot = 128;
elseif ( strcmpi(pdechar, 'NLS') == 1 )
    dt = 1e-2;
    N = 128;
    pref.colormap = 'jet';
    pref.dataplot = 'abs';
    pref.Clim = [0 1];
    pref.iterplot = 1;
    pref.Nplot = 256;
end

end