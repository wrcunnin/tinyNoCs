# tinyNoCs

A SystemVerilog implementation of various network topologies intended as a self-study for high bandwidth accelerators. The following topologies are to be implemented:
- Ring
- Mesh (4x4, 5x3)
- Torus (4x4, 5x3)


## Dependencies
- Verilator v5.052
- FuseSoC 2.3.0
- GCC 14.2.0
- sv2v
- LibreLane


## Simulation
The Makefile contains all possible rules to simulate test-benches. For example, to run all test benches for mesh networks, you simply run:

```
make mesh-all
```

## Synthesis
To synthesize a design, you need to have sv2v and LibreLane installed. This uses a 16-endpoint mesh 5x3 network as an example:

First, run `scripts/synth-mesh-5x3/sv2v.sh`

```
./scripts/synth-mesh-5x3/sv2v.sh
```

Then, using the method used to install LibreLane, call `librelane` using `scripts/synth-mesh-5x3/config.json`.

```
librelane ~/<path to tinyNoCs>/scripts/synth-mesh-5x3config.json
```
