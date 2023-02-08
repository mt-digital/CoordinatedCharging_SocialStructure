# Coordinated Charging and Social Structure

This repository contains code and supporting documentation for the agent-based model analyzed in upcoming work tentatively called "Components for a theory of culture to promote the spread of coordinated charging behaviors." It is a fork of [eehh-stanford/SustainableCBA](https://github.com/eehh-stanford/SustainableCBA) in the process of being repurposed for analyzing the spread of the more specific climate change-adaptive behavior, coordinated charging. In this model, there will be two populations living in two separate neighborhoods, and they preferentially work in their own neighborhood. They have the option to engage in a coordinated charging behavior or not, which could be workplace charging or vehicle-to-building, delayed charging in morning instead of directly after work, etc.


## Quick start

To get started, clone this repository, e.g., execute the following in the
terminal: 

```
git clone https://github.com/mt-digital/CoordinatedCharging_SocialStructure
```

After cloning the repository, install all dependencies by first starting the
[Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/) then run

```
julia> using Pkg; Pkg.activate("."); Pkg.instantiate()
```


## Unit tests

We developed our model using test-driven development, which uses small, executable code snippets to confirm the model works as expected and to document model mechanics; see [`src/test/model.jl`](https://github.com/mt-digital/CoordinatedCharging_SocialStructure/blob/main/src/test/model.jl) to view the test suite.

While still in the REPL, run the unit tests to make sure all is working well:

```
julia> include("src/test/model.jl")
```

This should print two "Test Summary" outputs where all tests are shown to pass.
The tests initialize specially-initialized models and checks that model outputs
are as expected. 

# Run the model and analyze results

## Model and computational experiments

The model is implemented in [`src/model.jl`](src/model.jl) and the computational experiments that run the model over all parameter settings for the desired number of trials and used by the Slurm scripts (below) is in [`src/experiment.jl`](src/experiment.jl).

## Run all simulations on Slurm cluster

To run simulations on a Slurm cluster, log in to the cluster then execute the following commands from the project directory, first
```
./scripts/slurm/main.sh
```
to run the main analyses, and
```
./scripts/slurm/supplement.sh
```
to run the supplemental analyses. This creates a fresh, distinct version of simulation results that can be analyzed as we explain below, using archived data of the simulations used to create our results in the submitted version of the paper.

## Analysis

Use `main_asymm_heatmaps` to create the main heatmap results of _success rate_ as a function of $h_\mathrm{min}$ and $h_\mathrm{maj}$, which can be found in [`scripts/plot.R`](https://github.com/mt-digital/CoordinatedCharging_SocialStructure/blob/main/scripts/plot.R#L72). For creating the heatmaps of average time to model fixation, pass the keyword argument `measure = "step"` to `main_asymm_heatmaps`. Similarly, to create supplemental analyses use the `supp_asymm_heatmaps` function in [`scripts/plot.R`](https://github.com/mt-digital/CoordinatedCharging_SocialStructure/blob/main/scripts/plot.R#L15).

To create time series of individual model runs, use the `make_all_group_prevalence_comparisons` function in [`scripts/analysis.jl`](https://github.com/mt-digital/CoordinatedCharging_SocialStructure/blob/main/scripts/analysis.jl#L290).
