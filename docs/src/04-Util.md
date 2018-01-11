## Utility

Some other source code like `recv_phy.m`, `recv_power.m` ...  will be discussed here.

### recv_phy.m

Calculate the power receive by current node. (with `SNR`)

* transmition node: `event.pkt.tx`
* receiving node: `event.pkt.rv`

```c
Pr0 = recv_power(tx, rv, rmodel);
Pr = 0;
I = find(node(:, 3)>0);
for i=1:length(I)
   tx1 = I(i);
   if tx1 == rv, continue; end
   if tx1 == tx, continue; end
   Pr = Pr + recv_power(tx1, rv, rmodel);
end

N0 = white_noise_variance;
SNR = db(Pr0/(Pr+N0), 'power');

% Return with Pr0 and SNR
return;
```

Then calling `recv_power.m` to get the power value.

See more in `02-3-PHY` to see the detail. 

---

### recv_power.m

Choosing model from **Radio propagation** ( `friis(free space)`, `two-ray`, `shadowing` ), this program using `shadowing` as default value.

Before calculating the power, call `position_update.m` to refresh the position of each node.

```c
switch rmodel
    case 'friis'
        Pr = friis(Pt, Gt, Gr, lambda, L, d);
    case 'tworay'
        [Pr, crossover_dist] = tworay(Pt, Gt, Gr, lambda, L, ht, hr, d);
    case 'shadowing'
        Pr = log_normal_shadowing(Pt, Gt, Gr, lambda, L, pathLossExp, std_db, d0, d);
end
```

See more in `02-1-Radio` to see the detail.

---

### inv_recv_power.m 

Inverse version of recv_power, using the power to get the corresponding `distance`.


---

### friis.m

```c
function Pr = friis(Pt, Gt, Gr, lambda, L, d)

% Friis free space propagation model:
%        Pt * Gt * Gr * (lambda^2)
%  Pr = --------------------------
%        (4 *pi * d)^2 * L

M = lambda / (4 * pi * d);
Pr = Pt * Gt * Gr * (M * M) / L;

return;
```

### tworay.m

```c
function [Pr, crossover_dist] = tworay(Pt, Gt, Gr, lambda, L, ht, hr, d)
% if d < crossover_dist, use Friis free space model
% if d >= crossover_dist, use two ray model
% Two-ray ground reflection model:
% 	     Pt * Gt * Gr * (ht^2 * hr^2)
%   Pr = ----------------------------
%            d^4 * L
% The original equation in Rappaport's book assumes L = 1.
% To be consistant with the free space equation, L is added here.

crossover_dist = (4 * pi * ht * hr) / lambda;
if (d < crossover_dist)
	Pr = Friis(Pt, Gt, Gr, lambda, L, d);
else
	Pr = Pt * Gt * Gr * (hr * hr * ht * ht) / (d * d * d * d * L);
end

return;
```

### log_normal_shadowing.m

```c
function Pr = log_normal_shadowing(Pt, Gt, Gr, lambda, L, pathlossExp, std_db, d0, d)
% log normal shadowing radio propagation model:
% Pr0 = friss(d0)
% Pr(db) = Pr0(db) - 10*n*log(d/d0) + X0
% where X0 is a Gaussian random variable with zero mean and a variance in db
%        Pt * Gt * Gr * (lambda^2)   d0^passlossExp    (X0/10)
%  Pr = --------------------------*-----------------*10
%        (4 *pi * d0)^2 * L          d^passlossExp

% calculate receiving power at reference distance
Pr0 = friis(Pt, Gt, Gr, lambda, L, d0);

% calculate average power loss predicted by path loss model
avg_db = -10.0 * pathlossExp * log10(d/d0);

% get power loss by adding a log-normal random variable (shadowing)
% the power loss is relative to that at reference distance d0
% question: reset rand does influcence random
rstate = randn('state');
randn('state', d);
powerLoss_db = avg_db + (randn*std_db+0);  % random('Normal', 0, std_db);
randn('state', rstate);

% calculate the receiving power at distance d
Pr = Pr0 * 10^(powerLoss_db/10);

return;
```