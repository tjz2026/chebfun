function F = mtimes( F, G )
%*  mtimes for chebfun2v.
%
%  c*F or F*c multiplies each component of a chebfun2v by a scalar.
%
%  A*F multiplies the vector of functions F by the matrix A assuming that
%  size(A,2) == size(F,1).
%
%  F*G calculates the inner product between F and G if size(F,3) ==
%  size(G,1). If the sizes are appropriate then F*G = dot(F.',G).
%
% See also TIMES.

% Copyright 2013 by The University of Oxford and The Chebfun Developers.
% See http://www.maths.ox.ac.uk/chebfun/ for Chebfun information.


% Empty check:
if ( ( isempty(F) ) || ( isempty(G) ) )
    F = chebfun2v;
    return
end

% If the chebfun2v object is transposed, then compute (g.'*f.').'
if ( isa( F, 'chebfun2v' ) && ~isa( G,  'chebfun2v' ) )
    if ( F.isTransposed )
        F = mtimes( g.', F.' );
        return
    end
end

if ( isa(G, 'chebfun2v') && ~isa(F, 'chebfun2v') )
    if ( G.isTransposed )
        F = mtimes( g.' , F.' ).' ;
        return
    end
end

if ( isa( F, 'double' ) )      % doubles * chebfun2v
    if ( numel(F) == 1 )       % scalar * chebfun2v
        const = F;
        F = G;
        for j = 1:F.nComponents
            F.components{j} = const * F.components{j};
        end
    elseif ( size(F, 2) == G.nComponents )   % matrix * column chebfun2v
        vec = F;
        nG = G.nComponents;
        if ( size(vec, 1) == 1 ) 
            F = vec(1, 1) * G.components{1};
            for jj = 1:nG
                F = vec(1, jj) * G.components{jj};
            end
        else
            store = {}; 
            for jj = 1:size(vec, 1) 
                store{jj} = mtimes(vec(jj,:), G); 
            end
            F = chebfun2v(store); 
        end
    else
        error('CHEBFUN2v:mtimes:double','Dimension mismatch.');
    end
    
elseif( isa(G, 'double') )          % chebfun2v * double
    
    if ( numel( G ) == 1 )          % chebfun2v * scalar
        F = mtimes( G, F );
    else
        error('CHEBFUN2v:mtimes:double','Chebfun2v and double size mismatch.');
    end
elseif (isa(F,'chebfun2v') && isa(G,'chebfun2v') ) % dot product if dimensions are right.
    
    if ( ( F.isTransposed ) && ( ~G.isTransposed ) )
        F = dot( F, g );
    else
        error('CHEBFUN2v:mtimes:sizes', 'Dimensions mismatch.');
    end
    
elseif isa(F,'chebfun2v') && isa(g,'chebfun2')
    
    F = mtimes( g , F );
    
else 
    error('CHEBFUN2v:mtimes:inputs','Chebfun2v can only mtimes to chebfun2v or double');
end
end