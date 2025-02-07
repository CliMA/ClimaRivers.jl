using ClimaRivers
using JLD2, Plots, CSV, DataFrames

# Script for visualizing streamflow plots, and streamflow vs runoff plots

# File Paths
data_file_path = joinpath(@__DIR__, "..", "..", "mini_data", "routing")
simulation_result_file = joinpath(
    data_file_path,
    "simulations",
    "simulations_lv05",
    "gamma_IRF",
    "streamflow_history120 days.jld2",
)

# Load Streamflow Data
data = JLD2.load(simulation_result_file)
all_streamflows = data["streamflows"]
basin_ids = collect(keys(all_streamflows[1]))
sort!(basin_ids)

# Load Forcing Data
timeseries_dir = joinpath(data_file_path, "timeseries", "timeseries_lv05")
basin_ids_str =
    ["1051429580", "1051429650", "1051435100", "1051435110", "1051460430"]  # mini data set
sort!(basin_ids_str)

streamflows = Dict(
    basin_id => Vector{Float64}(undef, length(all_streamflows)) for
    basin_id in basin_ids_str
)
runoffs = Dict(
    basin_id => Vector{Float64}(undef, length(all_streamflows)) for
    basin_id in basin_ids_str
)

# Split Streamflow Data
for i in eachindex(all_streamflows)
    dict = all_streamflows[i]
    for basin_id in basin_ids_str
        streamflows[basin_id][i] = get(dict, parse(Float64, basin_id), NaN)
    end
end

start_index = 121  # Date Window Offset

# Split Runoff Data
for basin_id in basin_ids_str
    timeseries_file = joinpath(timeseries_dir, "basin_$basin_id.csv")
    df = CSV.read(timeseries_file, DataFrame)

    df.sro_sum = coalesce.(df.sro_sum, 0.0)
    df.ssro_sum = coalesce.(df.ssro_sum, 0.0)

    df.total_runoff = df.sro_sum .+ df.ssro_sum

    df = df[start_index:end, :]
    runoffs[basin_id] = df.total_runoff
end

time_steps = 1:length(all_streamflows)

# Plot all Streamflow vs Runoff Plots
for basin_id in basin_ids_str
    plt = plot(
        title = "Streamflow vs Runoff (Basin $basin_id)",
        xlabel = "Time",
        ylabel = "Flow",
        legend = :topleft,
    )

    plot!(
        plt,
        time_steps,
        streamflows[basin_id],
        label = "Streamflow",
        linewidth = 2,
    )
    plot!(plt, time_steps, runoffs[basin_id], label = "Runoff", linewidth = 2)

    plot_file = joinpath(@__DIR__, "streamflow_vs_runoff_basin_$basin_id.png")
    savefig(plt, plot_file)

    println("Plot saved as 'streamflow_vs_runoff_basin_$basin_id.png'")
end


# Plot All Streamflows Together Plots
p = plot(
    title = "All Basin Streamflows",
    xlabel = "Time",
    ylabel = "Streamflow",
    legend = :topright,
)

for basin_id in basin_ids_str
    plot!(
        p,
        time_steps,
        streamflows[basin_id],
        label = "Basin $basin_id",
        linewidth = 2,
    )
end

streamflow_plot_file = joinpath(@__DIR__, "streamflow_plot.png")
savefig(p, streamflow_plot_file)

println("Plot saved as 'all_streamflows.png'")
