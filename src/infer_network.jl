# Helper functions for inferring a network from a data file

# Gets an array of all Nodes from a data file. It is assumed that the first
# line of the file is headers (which are discarded) and the subsequent lines
# each represent one node, and are of the form:
# Label    data_value1  data_value2 ...
# although a different delimiter may be specified.
#
# Keyword arguments:
# - delim: the file's delimiter. Leave as false if it is whitespace
# - discretizer: algorithm for discretizing the data
# - estimator: algorithm for estimating the probability distribution
#   "maximum_likelihood" is recommended for PUC and PIDC (see InferredNetwork
#   type for more details)
# - number_of_bins: will be overwritten if using "bayesian_blocks"
function get_nodes(data_file_path::String; delim::Union{Char,Bool} = false, discretizer = "bayesian_blocks",
    estimator = "maximum_likelihood", number_of_bins = 10)

    if delim == false
        lines = readdlm(open(data_file_path); skipstart = 1)
    else
        lines = readdlm(open(data_file_path), delim; skipstart = 1)
    end
    number_of_nodes = size(lines, 1)
    nodes = Array{Node}(number_of_nodes)

    for i in 1:number_of_nodes
        nodes[i] = Node(lines[i:i, 1:end], discretizer, estimator, number_of_bins)
    end

    return nodes

end

# Writes a network file from an InferredNetwork type. Each line of the file
# will contain an edge, and since networks are assumed undirected, each edge
# will be written in both directions with the same weight:
# ...
# LabelX   LabelY  WeightXY
# LabelY   LabelX  WeightXY
# ...
function write_network_file(file_path::String, inferred_network::InferredNetwork)

    out_file = open(file_path, "w")

    for edge in inferred_network.edges
        nodes = edge.nodes
        write(out_file, string(
            nodes[1].label, "\t", nodes[2].label, "\t",
            edge.weight, "\n",
            nodes[2].label, "\t", nodes[1].label, "\t",
            edge.weight, "\n"
        ))
    end

    close(out_file)

end

# Gets an edge list array from an InferredNetwork object.
function get_edge_list(inferred_network::InferredNetwork)
    edge_list = Tuple{String,String,Float64}[]

    for edge in inferred_network.edges
        nodes = edge.nodes
        push!(edge_list, (nodes[1].label, nodes[2].label, edge.weight))
    end

    return edge_list
end

# Infers a network, given a data file and a network inference algorithm. It
# is assumed that the first line of the file is headers (which are
# discarded) and the subsequent lines each represent one node, and are of
# the form:
# Label    data_value1  data_value2 ...
# although a different delimiter may be specified.
#
# Keyword arguments:
# - delim: the file's delimiter. Leave as false if it is whitespace
# - discretizer: algorithm for discretizing the data
# - estimator: algorithm for estimating the probability distribution
#   "maximum_likelihood" is recommended for PUC and PIDC (see InferredNetwork
#   type for more details)
# - number_of_bins: will be overwritten if using "bayesian_blocks"
# - base: base for the information measures
# - out_file_path: path to output file. If left as empty string, no file will
# be written.
function infer_network(data_file_path::String, inference::AbstractNetworkInference; delim::Union{Char,Bool} = false,
    discretizer = "bayesian_blocks", estimator = "maximum_likelihood", number_of_bins = 10, base = 2,
    out_file_path = "")

    println("Getting nodes...")
    nodes = get_nodes(
        data_file_path,
        delim = delim,
        discretizer = discretizer,
        estimator = estimator,
        number_of_bins = number_of_bins
    )

    println("Inferring network...")
    inferred_network = InferredNetwork(inference, nodes, estimator = estimator, base = base)

    if length(out_file_path) > 1
        println("Writing network to file...")
        write_network_file(out_file_path, inferred_network)
    end

    return inferred_network

end
