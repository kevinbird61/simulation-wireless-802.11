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