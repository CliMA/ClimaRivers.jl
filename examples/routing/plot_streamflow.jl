# Visualization Code
using ClimaRivers
using JLD2, Plots

data_file_path = joinpath(@__DIR__, "..", "..", "mini_data", "routing")
simulation_result_file = joinpath(
    data_file_path,
    "simulations",
    "simulations_lv05",
    "gamma_IRF",
    "streamflow_history120 days.jld2",
)
data = JLD2.load(simulation_result_file)
all_streamflows = data["streamflows"]

# basin_ids = [1.0514351e9, 1.05146043e9, 1.05142958e9, 1.05143511e9, 1.05142965e9]
streamflow_1 = Vector{Float64}(undef, length(all_streamflows))
streamflow_2 = Vector{Float64}(undef, length(all_streamflows))
streamflow_3 = Vector{Float64}(undef, length(all_streamflows))
streamflow_4 = Vector{Float64}(undef, length(all_streamflows))
streamflow_5 = Vector{Float64}(undef, length(all_streamflows))

basin_ids = collect(keys(all_streamflows[1]))
sort!(basin_ids)
println("basin_ids order: $basin_ids")

for i in eachindex(all_streamflows)
    dict = all_streamflows[i]
    streamflow_1[i] = get(dict, basin_ids[1], NaN)
    streamflow_2[i] = get(dict, basin_ids[2], NaN)
    streamflow_3[i] = get(dict, basin_ids[3], NaN)
    streamflow_4[i] = get(dict, basin_ids[4], NaN)
    streamflow_5[i] = get(dict, basin_ids[5], NaN)
end

time_steps = 1:length(all_streamflows)

p = plot(
    time_steps,
    streamflow_1,
    label = "Basin $(basin_ids[1])",
    linewidth = 2,
)
plot!(time_steps, streamflow_2, label = "Basin $(basin_ids[2])", linewidth = 2)
plot!(time_steps, streamflow_3, label = "Basin $(basin_ids[3])", linewidth = 2)
plot!(time_steps, streamflow_4, label = "Basin $(basin_ids[4])", linewidth = 2)
plot!(time_steps, streamflow_5, label = "Basin $(basin_ids[5])", linewidth = 2)

xlabel!("Time")
ylabel!("Streamflow")
title!("Streamflow Over Time for 5 Basins")
plot!(legend = :topleft)

output_file = joinpath(@__DIR__, "streamflow_plot.png")
savefig(p, output_file)

println("Plot saved as 'streamflow_plot.png'")

# River Structure
# (1) 1051429650 → (2) 1051435100 → (3) 1051460430 ← (1) 1051435110 
# (1) 1051429580 →
