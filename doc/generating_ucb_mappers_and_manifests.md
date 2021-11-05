## Generating UCB Mappers and Mapper Manifest


### Creating the mappers
This will create mappers for each profile in a separate subdirectory of `data/mappers/ucb/release_#_#`:

Note that releases are labeled as such: 
`6.0 -> release_6_0`


`exe/ccu mappers write -p all -o data/mappers/ucb/release_# -s y`

For details on the options:

`ccu mappers help write`


### Validating the newly created mappers
See the description under `ccu mappers help validate` for what this checks.

The following will recursively validate (in all the subdirectories) all the mappers created in the previous step.


`exe/ccu mappers validate -i data/mappers/ucb/release_#_#`


### Creating the manifest

The following will create a manifest listing all valid **UCB** mappers created above:

`exe/ccu mappers manifest -i ucb/release_#_# -o data/mapper_manifests/ucb_profile_mappers_release_#_#.json`