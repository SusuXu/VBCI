%% Derivative of function f
function [df] = df(a)
    df = 1 ./ (1+exp(a));
end

