using CSV
using DataFrames
using CairoMakie
using Dates
#using NoveltyColors

function py_datetime_parser(datetime)
    # convert the python datetime instance to julia datetime instance
    y = parse(Int64, datetime[1:4])
    m = parse(Int64, datetime[6:7])
    d = parse(Int64, datetime[9:10])
    h = parse(Int64, datetime[12:13])
    min = parse(Int64, datetime[15:16])
    s = parse(Int64, datetime[18:19])
    ms = parse(Int64, datetime[21:23])
    return DateTime(y, m, d, h, min, s, ms)
end

function find_data_indices_for_date(dataframe, date_debut, date_fin)
    # find the first and last indices of the relevent data to get only the data from the chosen time interval
    # We like that because it's in O(n)
    # But honestly there's probably a built-in way to do this but I wanted to create an algorithm from scratch for fun
    index_debut = 0
    index_fin = 0
    index_counter = 1
    for row in eachrow(dataframe)
        if row["Datetime"] >= date_debut && row["Datetime"] <= date_fin
            if index_debut == 0
                index_debut = index_counter
            end
        index_fin = index_counter
        end
        index_counter += 1
    end
    return index_debut, index_fin
end

function hours_tick_format(tick)
    # set the tick format for Makie
    tick = unix2datetime.(tick)
    return Dates.format.(tick, "HHhMM")
end

function analyse_principale(date_debut=today(), date_fin=now(); couleurs=Makie.wong_colors())
    df = DataFrame(CSV.File("drunk_table.csv")) # get the dataframe
    df[!, "Datetime"] = py_datetime_parser.(df[!, "Datetime"]) # convert from python datetime to julia datetime
    indices_date = find_data_indices_for_date(df, date_debut, date_fin)
    df = df[indices_date[1]:indices_date[2], :] # get only the relevent data from the csv
    println(df) # show the relevent data (so you can look for errors)

    volume_total = round(cumsum(df[!, "Alcool Pur"])[end], digits=1) # get the total pure alcohol volume

    noms = Dict()
    # separate the data relevent to each name
    for row in eachrow(df)
        if haskey(noms, row["Joueur"])
            # if the entry in the "noms" dict already exists, add the value to this key
            nom = convert(String, row["Joueur"])
            append!(noms[nom], DataFrame(row))
        else
            # if the name is not already in the dict, add the key and the value
            noms[row["Joueur"]] = DataFrame(row)
        end
    end

    noms_total = Dict()
    alcool_values = DataFrame()
    # get the total pure alcohol volume for each player in a DataFrame
    # this is so we can sort it for the plots
    for nom in keys(noms)
        noms_total[nom] = cumsum(noms[nom][!, "Alcool Pur"])[end]
        append!(alcool_values, DataFrame(noms=nom, alcool_value=cumsum(noms[nom][!, "Alcool Pur"])[end]))
    end
    alcool_values = sort!(alcool_values, [:alcool_value], rev=true)
    println(alcool_values)

    nombre_personnes = length(collect(keys(noms_total))) # number of distinct names

    # plot with CairoMakie
    fig = Figure() # create the fig to add axes to
    ax = Axis(fig[1, 1], xticks=(1:nombre_personnes, alcool_values[!, :noms]), ylabel="Volume d'alcool pur [ml]") # create the ax to draw the barplot
    ax2 = Axis(fig[2, 1], ylabel="Volume d'alcool pur cumulatif [ml]", xlabel="Heure de consommation", xticks=LinearTicks(8)) # create the ax to draw the scatterlines
    ylims!(ax, (0, nothing)) # crop the barplot to 0
    colors = couleurs # set the colors
    markers = [:circle, :rect, :pentagon, :utriangle, :diamond, :dtriangle] # set the markers (this is only for 6 people)
    cl = collect(1:1:nombre_personnes) # set the indices to select the colors for each person
    barplot!(ax, alcool_values[!, :alcool_value], color=colors[cl]) # barplot
    ax2.xtickformat = hours_tick_format # set the time tick format
    for (i, row) in enumerate(eachrow(alcool_values))
        # plot a line with markers for each person
        nom = row[:noms]
        scatterlines!(ax2, datetime2unix.(noms[nom][!, "Datetime"]), cumsum(noms[nom][!, "Alcool Pur"]), label=nom, color=colors[i], marker=markers[i], markersize=10)
    end
    Legend(fig[:, 2], ax2) # create a legend from the labels of the lines
    consommations = size(df, 1) # get the total number of drinks (the number of entries in the dataframe)
    fig[0, :] = Label(fig, "Quantité totale d'éthanol consommée: $volume_total ml\nNombre total de consommations: $consommations") # add title to top
    date_debut = Dates.format(date_debut, "yyyy-mm-dd") # format the date for the png file
    save("$date_debut.png", fig, px_per_unit=5) # save a png file. px_per_unit sets the resolution
    display(fig) # show the plots
end

analyse_principale(DateTime(2022, 5, 24, 0), DateTime(2022, 5, 25, 3)) # this shows the plot posted on Reddit
