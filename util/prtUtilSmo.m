function [alpha,beta] = prtUtilSmo(x,y,gramm,c,tol)
%   SMO Sequential Minimal Optimization
%
% Syntax: [alpha,beta] = prtUtilSmo(x,y,gramm,c,tol); %Called internally by generateSVM
%
%   Reference: J. Platt, Sequential Minimal Optimization: A Fast Algorithm
%   for Training Support Vector Machines, Microsoft Research Technical
%   Report MSR-TR-98-14, (1998). 

% Copyright 2010, New Folder Consulting, L.L.C.

% For debugging:
% rand('state',0) %randomness is used in randperm

alpha = zeros(size(x,1),1);
beta = 0;

y = double(y);
y(y == 0) = -1;

numChanged = 0;
examineAll = 1;

ITER = 1;

while (numChanged > 0 || examineAll)
    numChanged = 0;
    
    if examineAll
        I = 1:size(x,1);
    else
        I = find(alpha ~= 0 & alpha ~= c);
    end
    
    for i = 1:length(I);
        [n,alpha,beta] = examineExample(x,y,alpha,beta,gramm,I(i),tol,c);
        numChanged = numChanged + n;
    end

    if examineAll == 1
        examineAll = 0;
    elseif numChanged == 0
        examineAll = 1;
    end

    ITER = ITER+1;
end
alpha = alpha.*y;


function [bool,alpha,beta] = examineExample(x,y,alpha,beta,gramm,IND,tol,c)

bool = 0;

S = (alpha.*y)' * gramm + -beta;
y2 = y(IND);
a2 = alpha(IND);
e2 = S(IND)-y2;
r2 = e2*y2;

if ((r2 < -tol) && (a2 < c)) || ((r2 > tol) && (a2 > 0))
    Aind = find(alpha ~= 0 & alpha ~= c);
    
    if length(Aind) > 1
        E1vector = S(Aind) - y(Aind)';
        E1mE2 = abs(E1vector - e2);
        [v,i1] = max(E1mE2);
        i1 = i1(1);
        
        [bool,alpha,beta] = takeStep(x,y,alpha,beta,gramm,Aind(i1),IND,tol,c);
        if bool 
            return
        end
    end
    if ~bool
        for j = randperm(length(Aind));
            [bool,alpha,beta] = takeStep(x,y,alpha,beta,gramm,Aind(j),IND,tol,c);
            if bool 
                return;
            end
        end
    end
    if ~bool
        for j = randperm(size(x,1));
            [bool,alpha,beta] = takeStep(x,y,alpha,beta,gramm,j,IND,tol,c);
            if bool 
                return;
            end
        end
    end
end

function [bool,alpha,beta] = takeStep(x,y,alpha,beta,gramm,i1,i2,tol,c)

if i1 == i2
    bool = 0;
    return;
end

S = (alpha.*y)' * gramm + -beta;
alph1 = alpha(i1);
alph2 = alpha(i2);
y1 = y(i1);
y2 = y(i2);
e1 = S(i1) - y1;
e2 = S(i2) - y2;
s = y1*y2;

%get L,H:
if y1 ~= y2
    L = max([0,alpha(i2)-alpha(i1)]);
    H = min([c,c + alpha(i2)-alpha(i1)]);
elseif y1 == y2
    L = max([0,alpha(i2)+alpha(i1)-c]);
    H = min([c,alpha(i1)+alpha(i2)]);
end

if L == H 
    bool = 0;
    return
end

k11 = gramm(i1,i1);
k12 = gramm(i1,i2);
k22 = gramm(i2,i2);
eta = k11+k22-2*k12;

if eta > 0
    a2 = alph2 + y2*(e1-e2)/eta;
    if a2 < L
        a2 = L;
    elseif a2 > H
        a2 = H;
    end
else
    aTEMP = alpha;
    aTEMP(i2) = L;
    Lobj = - sum(aTEMP) + 1/2 * (aTEMP.*y)' * gramm * (aTEMP.*y);    
    
    aTEMP = alpha;
    aTEMP(i2) = H;
    Hobj = - sum(aTEMP) + 1/2 * (aTEMP.*y)' * gramm * (aTEMP.*y);
    
    if Lobj < Hobj - eps
        a2 = L;
    elseif Lobj > Hobj + eps
        a2 = H;
    else 
        a2 = alph2;
    end
end

if abs(a2-alph2) < eps*(a2+alph2+eps)
    bool = 0;
    return
end

a1 = alph1 + s*(alph2-a2);

%update Beta:
b1 = e1 + y1*(a1 - alph1)*k11 + y2*(a2 - alph2)*k12 + beta;
b2 = e2 + y1*(a1 - alph1)*k12 + y2*(a2 - alph2)*k22 + beta;

if a1 ~= 0 && a1 ~= c
    beta = b1;
elseif a2 ~= 0 && a2 ~= c
    beta = b2;
else
    beta = mean([b1,b2]);
end

alpha(i1) = a1;
alpha(i2) = a2;
bool = 1;
