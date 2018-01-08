## Event

Listing all event types in simulation.

### Sim1

#### send_phy

When current event's node is idle & `nav` is not busy -> will using this node as `transmitter` 

And then set up the other nodes as `receiver`: (2 mode) 

1. **broadcast**
    * broadcast from this transmitter
    * impact all idle node (using `overlay` meachanism to identify), and those nodes will schedule a `recv_phy` event for each one of them.
2. **unicast**
    * This part will illustrate `unicast` from *event.node* to *event.pkt.rv*
    * First set `event.pkt.rv` to receiver mode
    * Then set number of `n` nodes into `receiver mode`

After all setting above, setup the transmitter's finish event: `send_phy_finish` ( in `t+txtime+eps` later, which `t+txtime` is `recv_phy` event )

Check `event.pkt.type`:

*  = `rts`:
    * set timeout timer for RTS
    * schedule event `timeout_rts` after `t + (txtime + SIFS + cts_tx_time)*2`
    * And record this node as pending id (waiting mode)
* = `data` & (`event.pkt.rv` != 0):
    * set timeout for DATA
    * schedule event `timeout_data` after `t + (txtime + SIFS + ack_tx_time)*2`

Node not `idle` or `nav` is block 

* -> schedule `wait_for_channel` after `t + cca_time`
* push it into *waiting queue*


![](../gliffy/sim1-send_phy.png)

#### send_phy_finish

Set node back into `idle` mode.

And then checkout this node's MAC queue -> 

* if **empty**, then `reset` the *MAC status*
* if **non-empty**, then pop out current element, and schedule `wait_for_channel` after `t + cca_time`
    * Make it prepare to use the radio resource!

![](../gliffy/sim1-send_phy_finish.png)

#### send_mac

* set `event.pkt.type` as `data`
* `event.pkt.nav` equal to `SIFS + cts_tx_time + SIFS + tx_time(event.pkt) + SIFS + ack_tx_time`
* if `event.pkt.rv` != 0 (i.e. *unicast*)
    * then set `event.pkt.type` as `rts`
* if this node is free, but still have packets waiting in MAC queue:
    * then *report error*
* if MAC queue `empty`, and MAC status = 1
    * true, then push event(i.e. packet) into MAC queue
    * false, means node is busy, then schedule `wait_for_channel` event after time `t + cca_time` 

![](../gliffy/sim1-send_mac.png)

#### recv_mac

![](../gliffy/sim1-recv_mac.png)

#### recv_phy

* switch to `idle` mode
* And then check its `virtual collision`: 
    * if **occur**: drop packet directly
    * if **not occur**: 
        * call `recv_phy` ***function*** ( e.g. `recv_phy.m` )
        * calculate the probability of receiving process ( 0 or 1 ) 
            * if == 1
                * if this packet is for this node ( broadcast or unicast )
                    * schedule `recv_mac` event !
                * if not for this node, use its `nav`:
                    * Update those:
                        * `nav.start` and `nav.end` of `event.pkt.rv` 

![](../gliffy/sim1-recv_phy.png)

#### wait_for_channel

* If node is idle and channel is free
    * `true`:
        * If backoff_counter of this node > 0
            * `true`: 
                * resume (restart) the backoff, then schedule `backoff` event after time `t + slot_time` for this node!
            * `false`:
                * start backoff from `DIFS` first, then schedule `backoff_start` event after time `t + DIFS` for this node!
    * `false`:
        * means node is not idle, then it must be receiving process; 
        * need to wait until the current process end
        * so schedule `wait_for_channel` event after `t + cca_time` again!

![](../gliffy/sim1-wait.png)

#### backoff

* If node is still idle & channel is free (→ continue doing backoff)
    * `true`:
        * If backoff_counter of node > 1
            * `true`:
                * decrease this counter by 1
                * and then re-schedule `backoff` event after `t + slot_time`
        * or backoff_counter == 0 (i.e. *ready to send packet !*)
            * schedule `send_phy` event after time `t` for this node
    * `false`: (i.e. node is not idle / channel is busy when backoff occur)
        * If backoff_counter of node > 1
            * `true`: 
                * just decrease by 1
        * or == 0
            * `true`:
                * start a new backoff counter, which ***more larger than*** current one! (You can see more in contention window part → MAC Layer)
        * If not > 1, or == 0 (not match with above case)
            * then schedule `wait_for_channel` event after time `t + cca_time` for this node

![](../gliffy/sim1-bo.png)

#### backoff_start

(after waiting `DIFS`, start `backoff`!)

* If node is still idle, and channel is free
    * `true`: 
        * then schedule `backoff` event after `t + slot_time` for this node
    * `false`:
        * means that channel during `DIFS` becomes busy!
        * then schedule `wait_for_channel`, to wait until the channel is free.

![](../gliffy/sim1-bos.png)

#### timeout_rts

![](../gliffy/sim1-timeout-rts.png)

#### timeout_data

![](../gliffy/sim1-timeout-data.png)

#### timeout_rreq

![](../gliffy/sim1-timeout-rreq.png)

#### send_net

![](../gliffy/sim1-send_net.png)

#### send_net2

![](../gliffy/sim1-send_net2.png)

#### recv_net

![](../gliffy/sim1-recv_net.png)

#### send_app

![](../gliffy/sim1-send_app.png)

#### recv_app

![](../gliffy/sim1-recv_app.png)