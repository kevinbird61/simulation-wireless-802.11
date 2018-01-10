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

* check if  `event.pkt.rv == 0 & strcmp(event.pkt.type, 'data') == 0`
* broadcast but not data packet
	* if so, report error
* if `event.node == 1` 
	* myself sent this packet, no action
	* return
* else switch `event.pkt.type`
	* rts
		* send back a CTS, keep the data size, rate, and id as RTS packet
		* Schedule event `send_phy` in t
	* cts
		* remove pending id for RTS
        * if `pending_id(j) != event.pkt.id` //probably this CTS is in response to an earlier RTS, so we just ignore this CTS.
        *  return 
        * send data
        * schedule event `send_phy` in `t + SIFS`
        * keep the data size and rate as before
        * `newevent.pkt.type = 'data'`
        * create a new id for the data packet
        * `newevent.pkt.id = new_id(j)`
	* data
		* should check that this is not a duplicated or out-of-order packet
		* if `event.pkt.rv != 0`
			* schedule event `send_phy` in `t + SIFS`
			* keep the data size, rate, and id the same as DATA packet
		* Schedule a new event to send data up to network layer
        	* Make sure the ACK is sent out before processing this data packet 
        	* if `event.pkt.rv != 0` 
        	*  `newevent.instant = t + SIFS + ack_tx_time + 2*eps`
        * else
    		* `newevent.instant = t  + 2*eps`
		* Schedule event `recv_net` in time(just mention)
		* end
	* ack 
		* make sure the acknowledged packet is the just sent DATA packet
		* if `pending_id(j) != event.pkt.id`
        	* probably this is a duplicated ACK (same reason as the above CTS case)
        	* return 
		* remove pending id for DATA
    	* `pending_id(j) = 0`
    	* `retransmit(j) = 0`
        * if isempty(mac_queue(j).list) is false
          * more packets are waiting to be sent
          * Schedule event `waiting_for_channel` in `t + cca_time`
          * the packet setup is already done in `send_mac`
        * else 
          * reset mac layer
          * `mac_status(j) = 0`

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

* To begin with, Check whether or not there is a `pending id` being equal to `waiting RTS id` `i.e., (pending_id(i) == event.pkt.id)`
	* if so,
		* start re-transmit `i.e., retransmit(i)=retransmit(i)+1` 
        * if retransmit(i) > max_retries
			* if so, (node i has so many to transmit RTS)
				* drop packet `retransmit(i) = 0` ,`pending_id(i) = 0`
				* Check whether or not there are many packets waiting to be sent in queue
					* yes
						* `mac_status(i) = 1`
						* Schedule `wait_for_channel` event  after `t + cca_time`
					* No
						* mac_status(i) = 0` (cannot send RTS successfully, reset MAC layer)
			* No ,
				* (retransmit the RTS)
				* Schedule `wait_for_channel` event  after `t + cca_time`
	* No, display(pending id does not match the waiting RTS id)

![](../gliffy/sim1-timeout-rts.png)

#### timeout_data

![](../gliffy/sim1-timeout-data.png)

* if `pending_id(i) == event.pkt.id`
	* data packet needs to be retransmit
	*  if `retransmit(i) < max_retransmit`
		* retransmit the DATA
		* `retransmit(i) += 1`
		* Schedule event `waiting_for_channel` in `t + cca_time`
	* else, reach the trying limit, drop data packet
		* set `retransmit(i) = 0`,  `pending_id(i) = 0`
		* check if mac_queue is empty
			* if so, set `mac_status(i) = 0`
			* else 
				* Schedule event from `mac_queue(i).list(1)` to `waiting for channel` in `t + cca_time`; 
* 

#### timeout_rreq

* Check how many pending RREQ ids are there in the node id `temp = find(net_pending(i).id == event.net.id)` *the function find will return a indices of non-zero element*
	* if len(temp = 0) 
		* if yes →every RREQ is acknowledged , do nothing → return
	* if len(temp >1 ) 
		* if yes → error(“node i has more than one pending RREQs with  `net.id`
	* The RREQ is not acknowledged yet by an RREP
		* Start re-transmit → `net_pending(i).retransmit(temp) = net_pending(i).retransmit(temp) + 1` 
		* if there are so many retries → `net_pending(i).retransmit(temp) > net_max_retries` 
			* If so,
				* -Drop the RREQ i.e., `net_pending(i).id(temp)=[]` , `net_pending(i).retransmit(temp)=[]`
				* -if network_queue is not empty (so redundant) 
					* clear network queue →`net_queue(i).list(1)=[]`
					* Schedule `send_net2` event after `t`
			* No, retransmit RREQ by
				* -Schedule `send_mac` event after `t`
				* -set new_id for re-transmission
					* `newevent.net.id = new_id(i)`
					* `net_pending(i).id(temp) = newevent.net.id`
					* `rreq_out(i)=rreq_out(i)+1`
				* -Sent RREQ out via crosslayer  if type of application is defined ‘crosslayer_searching’  i.e., `if(strcmp(newevent.app.type, 'crosslayer_searching')->rreq_out_crosslayer(i) = rreq_out_crosslayer(i) + 1`
				* -Set timeout timer for the retransmitted RREQ
					* -Schedule `timeout_rreq` event after `t+rreq_timeout`
					* -Save the new id of the pending RREQ by `net_pending(i).id(temp)=newevent.net.id` 

![](../gliffy/sim1-timeout-rreq.png)

#### send_net

![](../gliffy/sim1-send_net.png)

* Event provides `net.dst`, `net.src`, `net.size`
* if net_queue is not empty
	* wait in queue
	* `net_queue(i).list = [net_queue(i).list event] `
* else
	* Schedule `send_net2` event	

#### send_net2

![](../gliffy/sim1-send_net2.png)

 * Event provides net.dst, net.src, net.size
 * if `event.net.dst` == 0  
	* broadcast
	* Schedule event `send_mac` in `t`
	* `newevent.net.type = data`
	* `newevent.pkt.type=data`
 * else
	* run unicast to find the route by RREP-RREQ
	* schedule event `send_mac` in `t`
	* `newevent.net.type = rreq`
	* set timeout timer for RREQ
	* Schedule event `timeout_rreq` in time `t + rreq_timeout`
	* save the id of pending RREQ
	* `net_pending(i).retransmit = [net_pending(i).retransmit 0]`
	 


#### recv_net

* Decrease  time to live(TTL) by 1 unit
* event.pkt.ttl = event.pkt.ttl - 1;
	* if(event.pkt.ttl<0)
		* drop packet , return
	* if the destination node is as same as transmission node 
		* no action , return
	* Check type of network layer
		* `rreq`
			* Change flag of rreq_in → rreq_in(i)=rreq_in(i)+1
			* Enable rreq for crosslayer if app.type is ‘'crosslayer_searching’ i.e., `rreq_in_crosslayer(j) = rreq_in_crosslayer(j) + 1`
			* if node `j` is member of the route in network
				* Yes, already found the route, do noting , return
				* No, append node `j` to the route i.e., `event.net.route = [event.net.route j]`
			* If node j is equal to the given destination by `event.net.dst`
				* Yes
					* node `j` am the destination of this RREQ: send RREP back
					* `send_rrep = -1`
					* if rrep_table is empty 
						* yes, `k = 1` and `send_rrep = 1`
						* No, rrep table is not empty ,
							* Check at the source whether there are saved RREQ or not()`if (rrep_table(j).list(k).route(1)==i)`
								* yes, 
									* set `send_rrep = 1`, if the RREQ is table is old i.e., `if rrep_table(j).list(k).id < event.net.id`
									* if RREQ id in table is equal to `event.net.id`
										* Yes, if the matric of event.net is smaller than rreq table,`send_rrep = 1`, Otherwise, `send_rrep = 0` `//not a better route: ignore`
									* No,  `send_rrep = 0` `//reply to the newer`
					* If `send_rrep != 0`
						* Yes, Change flag rrep_out → `rrep_out(j) = rrep_out(j) + 1`
							* rrep_out_crosslayer(j) = rrep_out_crosslayer(j) + 1 if event.app.type = 'crosslayer_searching'
							* if(`send_rrep<0)` → k = length(rrep_table(j).list) + 1 — no early saved RREQ from this src: add one
							* initialize `rreq_table`
							* Schedule `send_mac` event after `t`
							* newevent.net.type =`'rrep'` 
							* newevent.pkt.type=`'data'`;
							* newevent.pkt.tx = j;
							* newevent.pkt.rv = newevent.net.route(temp - 1); % next hop 
							* newevent.pkt.id=0   -- will be updated in 'send_phy'
							* newevent.pkt.nav=0; -- will be updated in lower layer
							* return
					* No,  do nothing ,return
			* Node j is not the destination of the RREQ , re-broadcast it
			* if event.pkt.ttl<0
				* Yes, drop it ,return
				* No,
					* if event.net.id > bcast_table(j, event.net.src)
						* Yes, forward this RREQ only if meduim have not forwarded the same broadcast RREQ from the same source before
						* Enable rreq for crosslayer if app.type is ‘'crosslayer_searching’ i.e.,`rreq_forward_crosslayer(j) = rreq_forward_crosslayer(j) + 1`
						* update braodcast table `bcast_table(j, event.net.src) = event.net.id`
						* Schedule `send_mac` event after `t + rand*slot_time` 
		* `rrep`
			* Change flag of rrep_in → rrep_in(i)=rrep_in(i)+1
			* Enable rrep for crosslayer if app.type is ‘'crosslayer_searching’ i.e.,`rrep_in_crosslayer(j) = rrep_in_crosslayer(j) + 1`
			* If route is empty , return — node j is receiving a RREP without any route entry
			* temp = find(event.net.route == j) — examine node j is in the route or not
				* If there are node J more than once in route(RREP) ,  do noting , return
				* If there is node J more than once in route(RREP), do nothing, return
				* if the number of node J == 1 
					* Yes //find the requesting node so this RREP is suspected
						* Check how many RREQ in the route
						* `(temp2 = find(net_pending(j).id == event.net.id)`
							* if there is no RREQ , node j receives an RREP without a corresponding pending RREQ, return
							* if there are RREQ more than once in the route, return
						* Removes the pending RREQ
							* net_pending(j).id(temp2) = []
							* net_pending(j).retransmit(temp2) = []
						* If event.app.type = ‘crosslayer_searching’
							* Yes
								* `rrep_destination_crosslayer(j) = rrep_destination_crosslayer(j) + 1`
								* Schedule `recv_app` event after `t`
							* No
								* Schedule `send_mac` event after `t`
								* newevent.net.type =`'data'` 
								* newevent.net.id = `new_id(j)`
								* newevent.pkt.tx = j;
								* newevent.pkt.rv = newevent.net.route(temp - 1); % next hop 
								* newevent.pkt.type=`'data'`;
								* newevent.pkt.id=0   -- will be updated in 'send_phy'
								* newevent.pkt.nav=0; -- will be updated in lower layer
					* No, 
						* Schedule `send_mac` event after `t`
						* newevent.net.type =`'rrep'`
						* newevent.pkt.tx = j;
						* newevent.pkt.rv = newevent.net.route(temp - 1); % next hop 
		* `data`
			* if (event.net.dst == 0)
				* Yes, `//a network layer broadcast packet`
					* if event.pkt.rv != 0, waring `node j receives a broadcast at NET, but not at MAC`
					* if event.net.id is new than bcast_table(j, event.net.src)
						* update bcast_table(j, event.net.src) = event.net.id
						* Schedule `send_mac` event after `t + rand*slot_time`
					* return
			* if route is empty `//receives a unicast data packet at network layer`
				* ‘Node j is receiving a Net_DATA without any route entry` , return
			* temp = find(event.net.route == j) `// find there are node j in the route or not`
			* if find node `j` more than once in the data packet, return
			* if there is no node `j` in the data packet, return
			* if node `j` is the destination
				* Yes
					* Schedule `recv_app` event after `t`
				* No
					* Schedule `send_mac` event after `t`
					* newevent.pkt.tx = j;
					* newevent.pkt.rv = newevent.net.route(temp + 1)
					* `Forward this data packet to the next hop towards the destination`

![](../gliffy/sim1-recv_net.png)

#### send_app

* Check type of application layer `event.app.type`
	* Crosslayer_Searching
		* node i sends a a crosslayer searching request for key(node) e.g.,`event.app.key`
		* Schedule `send_net` event
		* from source `newevent.net.src = i` to destination `newevent.net.dst = newevent.app.key`
	* dht_serching
		* Schedule `send_net`
		* check whether or not there is dht overlay route →(`if isempty(newevent.app.route)`)
			* No,
				* initialize dht overlay searching
					* -newevent.app.route = [i]
					* -random one node for build the path →( tempn = floor(rand*log2(n));)
					* if tempn > 0
						* Random node again by `tempx = ceil(rand*n)`
							* if the destination (newevent.app.route newevent.app.key) have never made as route i.e,`if isempty(find([newevent.app.route newevent.app.key]==tempx))` 
								* -use app.key as the destination of node i i.e., `newevent.app.route = [newevent.app.route newevent.app.key]` ,`newevent.net.dst = newevent.app.route(2)`
	* Undefined type
		* display (Undefined application layer type) → end

![](../gliffy/sim1-send_app.png)

#### recv_app

![](../gliffy/sim1-recv_app.png)

* Check `event.app.type`
	* case `crosslayer_searching`
		* Record `traffic_id`, `topo_id`, `end_time`, `hop_count`, `requesting node`, `requesting key`
	* case `dht_searching`
		* `tempi = find(event.app.route == event.node)`
		* if `isempty(tempi)` or `length(tempi)>1`
			* receives a wrong DHT searching request 
			* return 
		* `tempi == length(event.app.route)`
			* Schedule event `send_net` in `t + SIFS + ack_tx_time + 2*eps`
			* `newevent.net.dst = newevent.app.route(1)`
		* if tempi == 1
			* requester just received the answer from the destination
			* Record `traffic_id`, `topo_id`, `start_time`, `start_hop_count(=0)`, `requesting node`, `requesting key`, `overlay route length`
		* if not matching any
			* Schedule event `send_net in t + SIFS + ack_tx_time + 2*eps`
			* Make sure the previous ACK at MAC layer is finish
    		*  `newevent.net.dst = event.app.route(tempi + 1)`
* End