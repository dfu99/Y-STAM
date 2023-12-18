function rate = glue_update(s, m)
% Disassembly rate update rule
% Calculates rb from glue strength s and memory strength m
    % m>0 case
    rpos = (1-s)*(2/(1+exp(-m)) - 1);
    % m<0 case
    rneg = (s) * (2/(1+exp(-m)) - 1);
    rate = s + (m>0 * rpos) + (m<0 * rneg);
end