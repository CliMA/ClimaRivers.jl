#!/bin/bash

#SBATCH --job-name=thinned_era5_grid_to_basin
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --time=12:00:00
#SBATCH --mem=16GB
#SBATCH --mail-user=achiang@caltech.edu
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

set -euo pipefail # kill the job if anything fails
set -x # echo script
module load julia/1.11.3
julia --project=. grid_to_basin.jl
echo done