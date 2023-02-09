using Agents
using DrWatson: @dict
using StatsBase


@enum Trait a A


mutable struct Agent <: AbstractAgent
    
    id::Int

    home_neighborhood::Int
    home_learnprob::Float64

    work_neighborhood::Int
    work_learnprob::Float64

    curr_trait::Trait
    next_trait::Trait

end


function model_step!(model)

    agents = allagents(model)

    for agent in agents
        agent.curr_trait = agent.next_trait
    end
end


function select_teacher(focal_agent, model, location)

    # Begin payoff-biased social learning from teacher within selected group.
    if location == "work"
        prospective_teachers = 
            filter(agent -> ((agent.work_neighborhood == focal_agent.work_neighborhood) 
                              && (agent != focal_agent)), 
                   collect(allagents(model)))

    elseif location == "home"
        prospective_teachers = 
            filter(agent -> ((agent.home_neighborhood == focal_agent.home_neighborhood) 
                              && (agent != focal_agent)), 
                   collect(allagents(model)))
        
    else
        error("location $location must be 'work' or 'home'")

    end

    teacher_weights = 
        map(agent -> model.trait_fitness_dict[agent.curr_trait], 
            prospective_teachers)

    # Renormalize weights.
    denom = Float64(sum(teacher_weights))
    teacher_weights ./= denom

    # Select teacher.
    return sample(prospective_teachers, Weights(teacher_weights))
end


# Agent step represents one work day for an agent, half day at work, half at home.
function agent_step!(focal_agent::Agent, model::ABM)

    # Do each sub-step corresponding to agent's day at work or home.
    loc_step!(focal_agent::Agent, model::ABM, "work")
    loc_step!(focal_agent::Agent, model::ABM, "home")

end


# Generic function for agent step either at "home" or "work" `loc`ation.
function loc_step!(focal_agent::Agent, model::ABM, location::String)

    learnprob = location == "work" ? focal_agent.work_learnprob :
                                     focal_agent.home_learnprob

    # Use probability of learning for location to maybe learn from a teacher.
    if rand() < learnprob
        teacher = select_teacher(focal_agent, model, location)
        focal_agent.next_trait = deepcopy(teacher.curr_trait) 
    end
end

##
# w_i: "preference" for workplace in one's own neighborhood i
# work_learnprob_i: probability agent learns from workplace in neighborhood i
# home_learnprob_i: probability agent learns when home from others in neighborhood
#
function coordchg_model(nagents = 100; neighborhood_1_frac = 0.05, 
                       neighborhood_w_innovation = 1,
                       A_fitness = 1.0, a_fitness = 1.2, 
                       w_1 = 0.5, w_2 = 0.5, work_learnprob_1 = 1.0, work_learnprob_2 = 1.0,
                       home_learnprob_1 = 1.0, home_learnprob_2 = 1.0, rep_idx = nothing, 
                       model_parameters...)

    trait_fitness_dict = Dict(a => a_fitness, A => A_fitness)

    if typeof(neighborhood_w_innovation) == String
        if neighborhood_w_innovation != "Both"
            neighborhood_w_innovation = parse(Int, neighborhood_w_innovation)
        end
    end


    properties = @dict trait_fitness_dict a_fitness w_1 w_2 neighborhood_1_frac rep_idx nagents w_1 w_2 work_learnprob_1 work_learnprob_2 home_learnprob_1 home_learnprob_2

    model = ABM(Agent, scheduler = Schedulers.fastest; properties)
    flcutoff = ceil(neighborhood_1_frac * nagents)
    N_1 = Int(flcutoff)
    
    for aidx in 1:nagents

        # For now we assume two groups and one or two agents have de novo innovation.
        if aidx ≤ N_1

            # Set neighborhood, workplace details.
            home_neighborhood = 1
            work_neighborhood = rand() < w_1 ? 1 : 2

            if work_neighborhood == 1
                work_learnprob = work_learnprob_1
            else
                work_learnprob = work_learnprob_2
            end

            home_learnprob = home_learnprob_1

            # Determine whether the agent should start with coord charge trait.
            if (((neighborhood_w_innovation == 1) 
                  || (neighborhood_w_innovation == "Both")) 
                  && (aidx == 1))

                trait = a
            else
                trait = A
            end
        else

            # Set neighborhood, workplace details.
            home_neighborhood = 2
            work_neighborhood = rand() < w_2 ? 2 : 1
            if work_neighborhood == 1
                work_learnprob = work_learnprob_1
            else
                work_learnprob = work_learnprob_2
            end
            home_learnprob = home_learnprob_2


            # Determine whether the agent should start with innovation or not.
            if (((neighborhood_w_innovation == 2) || (neighborhood_w_innovation == "Both")) 
                && (aidx == N_1 + 1))

                trait = a
            else
                trait = A
            end
        end
        
        agent_to_add = Agent(aidx, 
                             home_neighborhood, home_learnprob, 
                             work_neighborhood, work_learnprob, 
                             trait, trait)

        add_agent!(agent_to_add, model)
    end
    
    agents = collect(allagents(model))

    return model
end
