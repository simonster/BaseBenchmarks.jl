module IMDBGraphs

using ..ProblemBenchmarks: PROBLEM_DATA_DIR
using Compat

type IMDBNode
    name::UTF8String # actor//film name
    neighbors::Set{IMDBNode} # adjacent nodes
    IMDBNode(name::AbstractString) = new(name, Set{IMDBNode}())
end

typealias IMDBGraph Dict{UTF8String, IMDBNode}

function fetch_node!(G::IMDBGraph, name::AbstractString)
    if haskey(G, name)
        return G[name]
    else # if node doesn't exist, create it
        node = IMDBNode(name)
        G[name] = node
        return node
    end
end

function centrality_mean(G::IMDBGraph, start_name::AbstractString)
    distances = Dict{UTF8String,UInt}()
    next_names = Set{UTF8String}([UTF8String(start_name)])
    current_distance = 0
    while !(isempty(next_names))
        neighbor_names = Set{UTF8String}()
        for name in next_names
            if !haskey(distances, name)
                distances[name] = current_distance
                for node in fetch_node!(G, name).neighbors
                    push!(neighbor_names, node.name)
                end
            end
        end
        current_distance += 1
        next_names = neighbor_names
    end
    return mean(values(distances))
end

function read_graph(path)
    G, actor_names = IMDBGraph(), Set{UTF8String}()
    open(path, "r") do file
        while !(eof(file))
            k = split(strip(readline(file)), "\t")
            actor_name, movie_name = k[1], join(k[2:3], "_")
            actor_node = fetch_node!(G, actor_name)
            movie_node = fetch_node!(G, movie_name)
            push!(actor_names, actor_node.name)
            push!(actor_node.neighbors, movie_node)
            push!(movie_node.neighbors, actor_node)
        end
    end
    return G, sort!(collect(actor_names))
end

function perf_imdb_centrality(n_actors)
    path = joinpath(PROBLEM_DATA_DIR, "imdb.tsv")
    G, actor_names = read_graph(path)
    results = Dict{UTF8String, Float64}()
    for name in take(actor_names, n_actors)
        results[name] = centrality_mean(G, name)
    end
    return sort!([Pair{Float64,UTF8String}(v, k) for (k, v) in results])
end

end # module
