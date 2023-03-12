using Random, Test
 
include("../model.jl")

# Somehow seed is constant if this is not included and tests are run through REPL,
# so we have to set a new one for each time tests are `include`d in REPL.
Random.seed!()


# @testset "home and work neighborhoods are initialized as expected" begin

#     m = coordchg_model(4; neighborhood_1_frac = 0.5, 
#                           home_is_work_prob_1 = 1.0, home_is_work_prob_2 = 1.0, a_fitness = 2.0)

#     agents = collect(allagents(m))
#     @test length(agents) == 4

#     n_home_neigh_1 = length(filter(agent -> agent.home_neighborhood == 1, agents))
#     n_home_neigh_2 = length(filter(agent -> agent.home_neighborhood == 2, agents))

#     n_work_neigh_1 = length(filter(agent -> agent.work_neighborhood == 1, agents))
#     n_work_neigh_2 = length(filter(agent -> agent.work_neighborhood == 2, agents))

#     @test n_home_neigh_1 == 2 
#     @test n_home_neigh_1 == n_home_neigh_2 

#     @test n_work_neigh_1 == 2 
#     @test n_work_neigh_1 == n_work_neigh_2 

#     @test m[1].home_neighborhood == 1
#     @test m[2].home_neighborhood == 1
#     @test m[3].home_neighborhood == 2
#     @test m[4].home_neighborhood == 2

#     @test m[1].work_neighborhood == 1
#     @test m[2].work_neighborhood == 1
#     @test m[3].work_neighborhood == 2
#     @test m[4].work_neighborhood == 2

#     @test m[1].curr_trait == a
#     @test m[2].curr_trait == A
#     @test m[3].curr_trait == A
#     @test m[4].curr_trait == A

#     m = coordchg_model(4; neighborhood_1_frac = 0.25, neighborhood_w_innovation = 2, 
#                           home_is_work_prob_1 = 1.0, home_is_work_prob_2 = 1.0, a_fitness = 2.0)

#     @test m[1].home_neighborhood == 1
#     @test m[2].home_neighborhood == 2
#     @test m[3].home_neighborhood == 2
#     @test m[4].home_neighborhood == 2

#     @test m[1].work_neighborhood == 1
#     @test m[2].work_neighborhood == 2
#     @test m[3].work_neighborhood == 2
#     @test m[4].work_neighborhood == 2

#     @test m[1].curr_trait == A
#     @test m[2].curr_trait == a
#     @test m[3].curr_trait == A
#     @test m[4].curr_trait == A


#     m = coordchg_model(1_000_000; neighborhood_1_frac = 0.15, 
#                               neighborhood_w_innovation = 1,
#                               home_is_work_prob_1 = 0.25, home_is_work_prob_2 = 0.8)

#     agents = collect(allagents(m))
#     @test length(agents) == 1_000_000
    
#     n_home_neigh_1 = length(filter(agent -> agent.home_neighborhood == 1, agents))
#     n_home_neigh_2 = length(filter(agent -> agent.home_neighborhood == 2, agents))

#     n_work_neigh_1 = length(filter(agent -> agent.work_neighborhood == 1, agents))
#     n_work_neigh_2 = length(filter(agent -> agent.work_neighborhood == 2, agents))

#     @test n_home_neigh_1 == 150_000
#     @test n_home_neigh_2 == 850_000

#     @test n_work_neigh_1 ≈ (n_home_neigh_1 * 0.25) + (n_home_neigh_2 * 0.2) rtol=0.01
#     @test n_work_neigh_2 ≈ (n_home_neigh_1 * 0.75) + (n_home_neigh_2 * 0.8) rtol=0.01

    
# end


@testset verbose = true "Teacher selection and learning works as expected" begin

    # ntrials = 10000

    # TODO this should check that there are enough teachers for the out-group
    # to learn from to understand why no agents who live in neighborhood 2
    # are learning from those who live in neighborhood 1.
    @testset "Teacher-group and teacher selection works as expected in home neighborhood" begin
        # TODO
        m = coordchg_model(4; neighborhood_1_frac = 0.25, home_is_work_prob_1 = 1.0, home_is_work_prob_2 = 1.0)
   end

    @testset "Teacher-group and teacher selection works as expected at work" begin
        m = coordchg_model(4; neighborhood_1_frac = 0.25, 
                           home_is_work_prob_1 = 1.0, home_is_work_prob_2 = 1.0,
                           learn_at_work_prob_1 = 1.0, learn_at_work_prob_2 = 1.0,
                           a_fitness = 10000.)

        # Manually set workplaces for testing; let all work in 2.
        m[1].work_neighborhood = 2
        m[2].work_neighborhood = 2
        m[3].work_neighborhood = 2
        m[4].work_neighborhood = 2

        @assert m[1].curr_trait == a
        @assert m[2].curr_trait == A
        @assert m[3].curr_trait == A
        @assert m[4].curr_trait == A

        for aidx in 2:4
            teacher = select_teacher(m[aidx], m, "work")
            @test teacher == m[1]
        end

        for aidx in 2:4
            loc_step!(m[aidx], m, "work")
            @test m[aidx].next_trait == a
        end

        model_step!(m)

        for aidx in 2:4
            loc_step!(m[aidx], m, "work")
            @test m[aidx].curr_trait == a
        end
        
    end
end

#     # Confirm groups are initialized as expected and that teacher selection 
#     # works as expected for asymmetric, non-zero w. 
#     m = coordchg_model(4; group_1_frac = 0.5, w_1 = 0.75, 
#                      w_2 = 0.25, a_fitness = 1e2)

#     agents = collect(allagents(m))

#     @testset "Groups properly initialized according to group_1_frac" begin
#         group1 = filter(a -> a.group == 1, agents)
#         n_group1 = length(group1)

#         group2 = filter(a -> a.group == 2, agents)
#         n_group2 = length(group2)

#         @test n_group1 == 2
#         @test n_group2 == 2
#     end

#     @testset "Asymmetric w produces correct teacher selection stats (Agent $ii)" for ii in 1:4

#         teachers_selected = [
#             select_teacher(m[ii], m, sample_group(m[ii], m))
#             for _ in 1:ntrials
#         ]

#         @test ii ∉ map(a -> a.id, teachers_selected)

#         # Contants below multiplying ntrials calculated
#         # from w values given above.
#         if ii ∈ [1, 2]
#             @test length(filter(a -> a.group == 1, teachers_selected)) ≈ (0.875 * ntrials) rtol=0.1
#             @test length(filter(a -> a.group == 2, teachers_selected)) ≈ (0.125 * ntrials) rtol=0.1
#         else
#             @test length(filter(a -> a.group == 1, teachers_selected)) ≈ (0.375 * ntrials) rtol=0.1
#             @test length(filter(a -> a.group == 2, teachers_selected)) ≈ (0.625 * ntrials) rtol=0.1
#         end

#     end

# end
