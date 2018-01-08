## Radio Propagation

Edit: `Kevin Cyu`

---

This part introduce `3 model` on power delivery: 

* free space propagation
* two-ray ground reflection model
* lognormal shadowing model

### Free Space

* transmit/receive antenna **without any influence of the earth surface** , so called “free space”
* Equation: `w = pT * Gt/ (4 * p * d^2).`, is the power which this transmitter can provide.
    * d: antenna coverage range
    * pT : power ( transmitter )
    * Gt : antenna gain
    * 4 p d2 : coverage area size
* This equation represent an `sphere`, where transmitter is in the `center`, and the `radius` is `d`
    * `4 p d^2` is the area which the power delivery by transmitter can reach.

#### Path Loss Theorem

* When distance of propagation increase, the radiated `energy` will decrease, so called `path loss`
    * power and `d^2` is inversely(成反比).

```
P' = P - 20*log(d'/d)
```

### Two-ray ground reflection model

* A more realistic model compare to `free space`
* Not only calculate the transmission of node to node, also consider the `reflection` of from the earth.
* In this model, the result in `short-distance` is worse because the **oscillation combination from constructive and destructive ray**.

### Lognormal shadowing model

* The above 2 model are all in the ideal case in `cycle`.
* Practically, received power will be an `random variable` which based on `multi-path propagation` in the specific distance, a.k.a `fading effects`
    * Need to consider: `path loss model`, `variation of received power(in specific distance)`
* `shadowing model` extends the ideal circle model to a sophisticated model, a more realistic model.