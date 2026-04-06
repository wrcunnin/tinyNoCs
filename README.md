# tinyNoCs

A SystemVerilog implementation of various network topologies intended as a self-study for high bandwidth accelerators. The following topologies are to be implemented:
- Ring
- Mesh (WIP)
- Torus (WIP)


## Dependencies
- Verilator v5.036
- FuseSoC 2.3.0
- GCC 14.2.0
- sv2v
- LibreLane


## Simulation
The Makefile contains all possible rules to simulate test-benches. For example, to run all test benches for ring networks, you simply run:

```
make ring-all
```

## Synthesis
To synthesize a design, you need to have sv2v and LibreLane installed. This uses a 16-endpoint ring network as an example:

First, run `scripts/synth-ring-16/sv2v.sh`

```
./scripts/synth-ring-16/sv2v.sh
```

Then, using the method used to install LibreLane, call `librelane` using `scripts/synth-ring-16/config.json`.

```
librelane ~/<path to tinyNoCs>/scripts/synth-ring-16/config.json
```
