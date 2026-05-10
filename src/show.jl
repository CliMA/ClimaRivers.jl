function Base.show(io::IO, ::MIME"text/plain", x::DateWindow)
    println(io, "DateWindow")
    println(io, "  start : ", x.start_date)
    println(io, "  end   : ", x.end_date)
    print(io, "  step  : ", x.date_step)
end

function Base.summary(io::IO, x::DateWindow)
    print(io, "DateWindow (", x.start_date, " to ", x.end_date, ")")
end

function Base.show(io::IO, ::MIME"text/plain", x::StaticEnvironment)
    println(io, "StaticEnvironment")
    println(io, "  n_basins   : ", length(x.basin_ids))
    println(
        io,
        "  attributes : ",
        size(x.attributes, 1),
        " rows × ",
        size(x.attributes, 2),
        " cols",
    )
    print(io, "  graph_dict : ", length(x.graph_dict), " entries")
end

function Base.summary(io::IO, x::StaticEnvironment)
    n = length(x.basin_ids)
    print(io, "StaticEnvironment (", n, n == 1 ? " basin)" : " basins)")
end

function Base.show(io::IO, ::MIME"text/plain", x::DynamicEnvironment)
    println(io, "DynamicEnvironment")
    println(io, "  n_basins   : ", length(x.forcing_timeseries))
    println(
        io,
        "  date_range : ",
        x.date_window.start_date,
        " to ",
        x.date_window.end_date,
    )
    print(io, "  output_dir : ", x.output_dir)
end

function Base.summary(io::IO, x::DynamicEnvironment)
    n = length(x.forcing_timeseries)
    print(
        io,
        "DynamicEnvironment (",
        n,
        n == 1 ? " basin, " : " basins, ",
        x.date_window.start_date,
        " to ",
        x.date_window.end_date,
        ")",
    )
end

function Base.show(io::IO, ::MIME"text/plain", x::Environment)
    println(io, "Environment")
    println(io, "  n_basins   : ", length(x.static_env.basin_ids))
    println(
        io,
        "  date_range : ",
        x.dynamic_env.date_window.start_date,
        " to ",
        x.dynamic_env.date_window.end_date,
    )
    print(io, "  output_dir : ", x.dynamic_env.output_dir)
end

function Base.summary(io::IO, x::Environment)
    n = length(x.static_env.basin_ids)
    print(io, "Environment (", n, n == 1 ? " basin)" : " basins)")
end

function Base.show(io::IO, ::MIME"text/plain", x::MizurouteHillslopeV1)
    println(io, "MizurouteHillslopeV1{", typeof(x.shape), "}")
    println(io, "  shape     : ", x.shape)
    println(io, "  timescale : ", x.timescale, " day")
    print(io, "  t_max     : ", x.t_max, " day")
end

function Base.summary(io::IO, x::MizurouteHillslopeV1)
    print(
        io,
        "MizurouteHillslopeV1 (shape=",
        x.shape,
        ", timescale=",
        x.timescale,
        " day)",
    )
end

function Base.show(io::IO, ::MIME"text/plain", x::MizurouteChannelV1)
    println(io, "MizurouteChannelV1{", typeof(x.wave_velocity), "}")
    println(io, "  wave_velocity : ", x.wave_velocity, " m/day")
    println(io, "  diffusivity   : ", x.diffusivity, " m²/day")
    print(io, "  t_max         : ", x.t_max, " day")
end

function Base.summary(io::IO, x::MizurouteChannelV1)
    print(
        io,
        "MizurouteChannelV1 (C=",
        x.wave_velocity,
        " m/day, D=",
        x.diffusivity,
        " m²/day)",
    )
end

function Base.show(io::IO, ::MIME"text/plain", x::HillslopeChannelRiverModel)
    println(io, "HillslopeChannelRiverModel")
    println(io, "  hillslope : ", typeof(x.hillslope_model))
    print(io, "  channel   : ", typeof(x.channel_model))
end

function Base.summary(io::IO, x::HillslopeChannelRiverModel)
    print(
        io,
        "HillslopeChannelRiverModel (",
        nameof(typeof(x.hillslope_model)),
        " + ",
        nameof(typeof(x.channel_model)),
        ")",
    )
end

function Base.show(io::IO, ::MIME"text/plain", x::HillslopeChannelRiverState)
    println(io, "HillslopeChannelRiverState")
    println(io, "  n_basins   : ", length(x.channel_state))
    println(
        io,
        "  date_range : ",
        x.date_window.start_date,
        " to ",
        x.date_window.end_date,
    )
    lag =
        isempty(x.hillslope_state) ? 0 :
        length(first(values(x.hillslope_state)))
    print(io, "  lag_steps  : ", lag)
end

function Base.summary(io::IO, x::HillslopeChannelRiverState)
    n = length(x.channel_state)
    print(
        io,
        "HillslopeChannelRiverState (",
        n,
        n == 1 ? " basin)" : " basins)",
    )
end
