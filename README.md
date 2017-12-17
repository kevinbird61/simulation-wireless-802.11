# simulation-wireless-802.11

simulation of wireless 802.11 in MATLAB.

## Usage

* branch `octave` is worked on `octave 4.0.0`. (If you don't have MATLAB)
    * But original one is running on `MATLAB`
    * So have missing function, like `db` for signal-to-noise ration.  
    * And `sim1.m` has some problems need to be solved.

* branch `master`,`matlab (for additional program usage.)` is worked on `MATLAB R2016a`.
    * Without any bugs.


## Functionality

* Entries:
    * sim1.m (crosslayer)
    * sim2.m (crosslayer + mobility)

* This program provide:
    * Radio Propagation
        * free space
        * two-ray
        * lognormal shadowing
    * Mobility
        * random waypoint model
    * PHY
        * SNR-based packet capture
        * broadcast
        * dynamic transimission rate and power
    * MAC
        * IEEE 802.11 (CSMA/CA, virtual carrier sense, and RTS-CTS-DATA-ACK)
    * NET
        * ad-hoc routing
    * APP
        * overlay routing protocols