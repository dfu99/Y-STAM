# Y-STAM

## Description
The Y-STAM simulation code evaluates DNA-based tile assemblies generated from the Branching Signal-Passing Tile Assembly Model (Y-STAM) using various parameterizations.

## Installation
Runs on MATLAB Release 2022. Scripts have been divided up categorically into folders. Run main.m to load all subdirectories before trying to run any simulations.

## Examples
Several examples are available in src/EXAMPLES to test out parameters of the model.
- eg_savedata: Saving data
- eg_rw_nonb: Non-branching random walk
- eg_rw_bran: Branching random walk
- eg_degrad: Degradation
- eg_fb_hit: Feedback hit time w/wo feedback
- eg_ecm_rate: Effect of memory on assembly rate
- eg_ecm_hit: Effect of memory on hit time
- eg_chem_a: Chemoattraction
- eg_chem_r: Chemorepulsion
- eg_trail: Chemical trail
- eg_tileconc: Effect of tile concentration on assembly size
- eg_chem_ga: Chemoattractive field at goal
- eg_trunk: Trunk at source
- eg_deadzone: Obstacle navigation
- eg_tile_bias: Directional control of assembly using non-uniform tile concentration
- eg_2d: Basic 2d model simulation, single source tile
- eg_2d_fb_ecm: 2d model w/ feedback, w/wo ECM
- eg_2d_multiseeds, 2d model, multiple source tiles
- eg_2d_space: 2d model, multiple seeds, space-filling rate
- eg_2d_majority: 2d model, two assemblies, multiple goal tiles
- eg_2d_obstacle: U-shaped obstacle well
- eg_2d_b_space: branching vs space-filling rate

![Example output](/src/EXAMPLES/example.jpg "Example output")

## References
This work was published in the Journal of Royal Society Interface. We humbly ask that you cite the following if you use our work:

[1] Fu D, Reif J. A Biomimetic Branching Signal-Passing Tile-Assembly Model with Dynamic Growth and Disassembly. Journal of Royal Society Interface. 2024 Aug 21;21(217):20230755. [DOI: 10.1098/rsif.2023.0755](https://doi.org/10.1098/rsif.2023.0755)
