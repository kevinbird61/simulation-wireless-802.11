## Event

Listing all event types in simulation.

### Sim1

* send_phy

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

* send_phy_finish

![](../gliffy/sim1-send_phy_finish.png)

* send_mac

![](../gliffy/sim1-send_mac.png)

* recv_mac

![](../gliffy/sim1-recv_mac.png)

* recv_phy

![](../gliffy/sim1-recv_phy.png)

* wait_for_channel

![](../gliffy/sim1-wait.png)

* backoff

![](../gliffy/sim1-bo.png)

* backoff_start

![](../gliffy/sim1-bos.png)

* timeout_rts

![](../gliffy/sim1-timeout-rts.png)

* timeout_data

![](../gliffy/sim1-timeout-data.png)

* timeout_rreq

![](../gliffy/sim1-timeout-rreq.png)

* send_net

![](../gliffy/sim1-send_net.png)

* send_net2

![](../gliffy/sim1-send_net2.png)

* recv_net

![](../gliffy/sim1-recv_net.png)

* send_app

![](../gliffy/sim1-send_app.png)

* recv_app

![](../gliffy/sim1-recv_app.png)