% self-construct
function [result] = db(X,type)

% calculate "signal-to-noise ratio"
% SNR(db) = 10*log10(P_singal/P_noise) = 20*log10(A_singal/A_noise);
% Here implement for matlab usage

switch type
  case 'power'
    result=10*log10(X)
  case 'voltage'
    result=20*log10(X)
end

return;