using DataFrames

using Distributed
using StatsBase


# Set up multiprocessing.
try
    num_cores = parse(Int, ENV["SLURM_CPUS_PER_TASK"])
    addprocs(num_cores)
catch
    desired_nprocs = length(Sys.cpu_info())

    if length(procs()) != desired_nprocs
        addprocs(desired_nprocs - 1)
    end
end


@everywhere using DrWatson
@everywhere quickactivate("..")
@everywhere include("model.jl")


function coordch_experiment(nagents=100; a_fitness = 2.0, 
                            homophily = [
                             collect(0.0:0.05:0.95)..., 0.99
                            ],
                            neighborhood_1_frac = collect(0.05:0.05:0.5), 
                            neighborhood_w_innovation = 1, nreplicates=10, 
                            allsteps = false)

    rep_idx = collect(1:nreplicates)

    homophily_1 = homophily
    homophily_2 = homophily

    params_list = dict_list(
        @dict homophily_1 homophily_2 group_1_frac a_fitness rep_idx
    )

    models = [coordcgh_model(nagents; group_w_innovation, params...) 
              for params in params_list]

    # adata = [(:curr_trait, fixated)]
    frac_a(v) = sum(v .== a) / length(v)

    is_minority(x) = x.home_neighborhood == 1
    frac_a_ifdata(v) = isempty(v) ? 0.0 : frac_a(collect(v))
    adata = [(:curr_trait, frac_a), 
             (:curr_trait, frac_a_ifdata, is_minority),
             (:curr_trait, frac_a_ifdata, !is_minority),
            ]

    mdata = [:a_fitness, :neighborhood_1_frac, :nagents, :rep_idx, :w_1, :w_2]

    function stopfn_fixated(model, step)
        agents = allagents(model)

        return (
            all(agent.curr_trait == a for agent in agents) ||
            all(agent.curr_trait == A for agent in agents)
        )
    end

    # For now ignore non-extremal time steps.
    when(model, step) = stopfn_fixated(model, step)
    adf, mdf = ensemblerun!(models, agent_step!, model_step!, stopfn_fixated;
                            adata, mdata, when, parallel = true, 
                            showprogress = true)
    
    res = innerjoin(adf, mdf, on = [:step, :ensemble])

    println(first(res, 15))

    return res
end
