## Mobility

### Random waypoint model

Random model for the movement of mobile users, and how their `location`, `velocity` and `acceleration` **change** over time.

So this part is going to simulate the status of movement of the mobile user randomly!

* Why this model is most popular `mobility model` for **mobile ad-hoc network(MANET)** routing protocol?
    * simplicity
    * wide availability

=> 
each `mobile node` in this random mobility simulation model is `independent`, and all using a `random` way to move (without any constraint); Also, its `destination`, `speed`, `direction` all using choose randomly.

=>
In each simulation routine (i.e. tick), will let each node choose randomly on `destination`, `speed` again, until simulation clock end.


* Have two variation:
    * random walk model
    * random direction model