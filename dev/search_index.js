var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = KuMo","category":"page"},{"location":"#KuMo","page":"Home","title":"KuMo","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for KuMo.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [KuMo]","category":"page"},{"location":"#KuMo.SCENARII","page":"Home","title":"KuMo.SCENARII","text":"SCENARII\n\nCollection of scenarii.\n\n\n\n\n\n","category":"constant"},{"location":"#KuMo.AbstractAlgorithm","page":"Home","title":"KuMo.AbstractAlgorithm","text":"AbstractAlgorithm\n\nAn abstract supertype for algorithms.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.AbstractJob","page":"Home","title":"KuMo.AbstractJob","text":"AbstractJob\n\nAn abstract supertype for jobs.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.AbstractRequests","page":"Home","title":"KuMo.AbstractRequests","text":"AbstractRequests\n\nAn abstract supertype for job requests.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.AbstractResource","page":"Home","title":"KuMo.AbstractResource","text":"AbstractResource\n\nAn abstract supertype for resources in a cloud morphing architecture. Any type MyResource <: AbstractResource needs to either:\n\nhave a field capacity::T where T <: Number,\nimplement a capacity(r::MyResource) method.\n\nOptionally, one can implement a specific pseudo_cost(r::MyResource, charge) method.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.AdditiveNode","page":"Home","title":"KuMo.AdditiveNode","text":"AdditiveNode{T1 <: Number, T2 <: Number} <: AbstractNode\n\nA node structure where the default pseudo-cost is translated by the value in the param field.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.ConvexLink","page":"Home","title":"KuMo.ConvexLink","text":"ConvexLink <: KuMo.AbstractLink\n\nLink structure with a convex pseudo-cost function.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.Data","page":"Home","title":"KuMo.Data","text":"Data\n\nStructure to store the information related to some Data. Currently, only the location of such data is stored.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.EqualLoadBalancingNode","page":"Home","title":"KuMo.EqualLoadBalancingNode","text":"EqualLoadBalancingNode{T <: Number} <: AbstractNode\n\nNode structure with an equal load balancing (monotonic) pseudo-cost function.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.FreeLink","page":"Home","title":"KuMo.FreeLink","text":"FreeLink <: AbstractLink\n\nThe pseudo-cost of such links is always zero.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.IdleStateNode","page":"Home","title":"KuMo.IdleStateNode","text":"IdleStateNode{T1 <: Number, T2 <: Number} <: AbstractNode\n\nNode structure that stays iddle until a bigger system load than the default node. The param field is used to set the activation treshold.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.Job","page":"Home","title":"KuMo.Job","text":"Job <: AbstractJob\n\nThe most generic job type.\n\nArguments:\n\nbackend::Int: size of the backend data to be sent from data location to the server\ncontainers::Int: number of containers required to execute the job\ndata_location::Int: location of the data (node id)\nduration::Float64: job duration\nfrontend::Int: size of the frontend data to be sent from the user location to the server\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.Link","page":"Home","title":"KuMo.Link","text":"Link{T <: Number} <: AbstractLink\n\nDefault link structure with an equal load balancing (monotonic) pseudo-cost function.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.Load","page":"Home","title":"KuMo.Load","text":"Load\n\nA structure describing an increase of the total load.\n\nArguments:\n\nocc::Float64: time when the load occurs\nnode::Int: node at which the request is executed\njob::Job: the job request\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.MinCostFlow","page":"Home","title":"KuMo.MinCostFlow","text":"MinCostFlow{O<:MathOptInterface.AbstractOptimizer} <: AbstractAlgorithm\n\nA structure to construct a MinCostFlow algorithm associated with an NLP Optimizer, such as Ipopt.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.MultiplicativeNode","page":"Home","title":"KuMo.MultiplicativeNode","text":"MultiplicativeNode{T1 <: Number, T2 <: Number} <: AbstractNode\n\nA node structure where the default pseudo-cost is multiplied by the value in the param field.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.Node","page":"Home","title":"KuMo.Node","text":"Node{T <: Number} <: AbstractNode\n\nDefault node structure, defined by its maximal capacity and the default convex pseudo-cost function.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.PeriodicRequests","page":"Home","title":"KuMo.PeriodicRequests","text":"PeriodicRequests{J < :AbstractJob} <: AbstractRequests\n\nA structure to handle job that\n\nArguments:\n\njob::J: the job being requested periodically\nperiod::Float64\nstart::Float64\nstop::Float64\n`PeriodicRequests(j, p; start = -Inf, stop = Inf): default constructor\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.PremiumNode","page":"Home","title":"KuMo.PremiumNode","text":"PremiumNode{T1 <: Number, T2 <: Number} <: AbstractNode\n\nA node structure for premium resources. The param field set the premium treshold.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.Request","page":"Home","title":"KuMo.Request","text":"Request{J <: AbstractJob}\n\nSingle unrepeated request.\n\nArguments:\n\njob::J: the job being requested periodically\nstart::Float64\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.Requests","page":"Home","title":"KuMo.Requests","text":"Requests{J <: AbstractJob} <: AbstractRequests\n\nA collection of aperiodic requests.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.Scenario","page":"Home","title":"KuMo.Scenario","text":"Scenario{N <: AbstractNode, L <: AbstractLink, U <: User}\n\nStructure to store the information of a scenario.\n\nArguments:\n\ndata::Dictionary{Int, Data}: data collection (currently not in use)\nduration::Real: optional duration of the scenario\ntopology::Topology{N, L}: network's topology\nusers::Dictionary{Int, U}: collection of users\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.ShortestPath","page":"Home","title":"KuMo.ShortestPath","text":"ShortestPath <: AbstractAlgorithm\n\nA ShortestPath algorithm.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.SnapShot","page":"Home","title":"KuMo.SnapShot","text":"SnapShot\n\nA structure to take snapshot from the state of network and its resources at a specific instant.\n\nArguments:\n\nstate::State: state at instant\ntotal::Float64: total load at instant\nselected::Int: selected node at instant; value is zero if load is removed\nduration::Float64: duration of all the actions taken during corresponding to the state of this snap\nsolving_time::Float64: time taken specifically by the solving algorithm (<: AbstractAlgorithm)\ninstant::Float64\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.State","page":"Home","title":"KuMo.State","text":"State\n\nA structure to store the state of the different resources, e.g. nodes and links, during a simualtion.\n\nArguments:\n\nlinks::SparseMatrixCSC{Float64, Int64}: sparse matrice with the links loads\nnodes::SparseVector{Float64, Int64}: sparse vector with the nodes loads\nState(n): inner constructor given the number of nodes n\nState(links, nodes): inner constructor given the links and nodes of an existing state\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.Topology","page":"Home","title":"KuMo.Topology","text":"Topology{N<:AbstractNode,L<:AbstractLink}\n\nA structure to store the topology of a network. Beside the graph structure itself, it also stores the kinds of all nodes and links.\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.Unload","page":"Home","title":"KuMo.Unload","text":"Unload\n\nA structure describing a decrease of the total load.\n\nArguments:\n\nocc::Float64: time when the unload occurs\nnode::Int: node at which the request was executed\nvload::Int: the number of freed containers\nlloads::SparseMatrixCSC{Float64, Int64}: the freed loads on each link\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.User","page":"Home","title":"KuMo.User","text":"User{R<:AbstractRequests}\n\nA structure to store a user information. A user is defined through a sequence of requests and a location (node id).\n\n\n\n\n\n","category":"type"},{"location":"#KuMo.add_load!-NTuple{5, Any}","page":"Home","title":"KuMo.add_load!","text":"add_load!(state, links, containers, v, n)\n\nAdds load to a given state.\n\nArguments:\n\nstate\nlinks: the load increase to be added on links\ncontainers: the containers load to be added to v\nv: node selected to execute a task\nn: amount of available nodes\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.capacity-Tuple{R} where R<:KuMo.AbstractResource","page":"Home","title":"KuMo.capacity","text":"capacity(r::R) where {R<:AbstractResource}\n\nReturn the capacity of a resource r.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.clean-Tuple{Any}","page":"Home","title":"KuMo.clean","text":"clean(snaps)\n\nClean the snapshots by merging snaps occuring at the same time.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.execute_valid_load","page":"Home","title":"KuMo.execute_valid_load","text":"execute_valid_load(s, task, g, capacities, state, algo, demands, ii = 0)\n\nCompute the best load allocation and return if it is a valid one.\n\nArguments:\n\ns: scenario being simulated\ntask: task being requested\ng: graph of the network topology\ncapacities: capacities of the network\nstate: current state of resources\nalgo: algo used for computing the best allocation cost\ndemands: if algo is MinCostFlow, demands are required\nii: a counter to measure the approximative progress of the simulation\n\n\n\n\n\n","category":"function"},{"location":"#KuMo.graph-Tuple{KuMo.Topology, Any}","page":"Home","title":"KuMo.graph","text":"graph(topo::Topology, algorithm::AbstractAlgorithm)\n\nCreates an appropriate digraph using Graph.jl based on a topology and the requirement of an algorithm.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.init_simulate-NTuple{4, Any}","page":"Home","title":"KuMo.init_simulate","text":"init_simulate(s, algo, tasks, start)\n\nInitialize structures before the simualtion of scenario s.\n\nArguments:\n\ns: the scenario being simulated\nalgo: algorithm allocating resources at best known lower costs resources\ntasks: sorted container of tasks to be simulated\nstart: instant when the simulation started\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.init_simulate-Tuple{Val{0}}","page":"Home","title":"KuMo.init_simulate","text":"init_simulate(::Val{0})\n\nInitialize a synchronous simulation.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.init_simulate-Tuple{Val}","page":"Home","title":"KuMo.init_simulate","text":"init_simulate(::Val)\n\nInitialize an asynchronous simulation.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.init_user-Tuple{Scenario, KuMo.User, Any, PeriodicRequests}","page":"Home","title":"KuMo.init_user","text":"init_user(s::Scenario, u::User, tasks, ::PeriodicRequests)\n\nInitialize user u periodic requests.\n\nArguments:\n\ns: scenario that is about to be simulated\nu: a user id\ntasks: container of sorted tasks\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.init_user-Tuple{Scenario, KuMo.User, Any, Requests}","page":"Home","title":"KuMo.init_user","text":"init_user(::Scenario, u::User, tasks, ::Requests)\n\nInitialize user u non-periodic requests.\n\nArguments:\n\nu: a user id\ntasks: container of sorted tasks\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.inner_queue","page":"Home","title":"KuMo.inner_queue","text":"inner_queue(\n    g, u, j, nodes, capacities, state, algo::MinCostFlow, ii = 0;\n    lck = ReentrantLock(), demands, links = nothing\n)\n\nThe inner queue step of the resource allocation of a new request. Uses a MinCostFlow algorithm.\n\nArguments:\n\ng: a graph representing the topology of the network\nu: user location\nj: requested job\nnodes: nodes capacities\ncapacities: links capacities\nstate: current state of the network\nalgo: MinCostFlow <: AbstractAlgorithm\nii: a counter to mesure the progress in the simulation\nlck: a lck for asynchronous simulation\ndemands: flow demands for MinCostFlow algorithm\nlinks: not needed for MinCostFlow algorithm\n\n\n\n\n\n","category":"function"},{"location":"#KuMo.inner_queue-2","page":"Home","title":"KuMo.inner_queue","text":"inner_queue(g, u, j, nodes, capacities, state, ::ShortestPath, ii = 0; lck = ReentrantLock(), demands = nothing, links)\n\nDOCSTRING\n\nArguments:\n\ng: a graph representing the topology of the network\nu: user location\nj: requested job\nnodes: nodes capacities\ncapacities: links capacities\nstate: current state of the network\nalgo: ShortestPath <: AbstractAlgorithm\nii: a counter to mesure the progress in the simulation\nlck: a lck for asynchronous simulation\ndemands: not needed for ShortestPath algorithm\nlinks: description of the links topology\n\n\n\n\n\n","category":"function"},{"location":"#KuMo.insert_sorted!","page":"Home","title":"KuMo.insert_sorted!","text":"insert_sorted!(w, val, it = iterate(w))\n\nInsert element in a sorted collection.\n\nArguments:\n\nw: sorted collection\nval: value to be inserted\nit: optional iterator\n\n\n\n\n\n","category":"function"},{"location":"#KuMo.job-Tuple","page":"Home","title":"KuMo.job","text":"job(backend::Int, containers::Int, data_location::Int, duration::Float64, frontend::Int)\n\nMethod to create new jobs.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.job_distributions-Tuple{}","page":"Home","title":"KuMo.job_distributions","text":"job_distributions(; backend, container, data_locations, duration, frontend)\n\nConstruct a dictionary with random distributions to generate new jobs. Beside data_locations, the other arguments should be a 2-tuple defining normal distributions as in the Distributions.jl package.\n\nArguments:\n\nbackend\ncontainer\ndata_locations: a collection/range of possible data location\nduration\nfrontend\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.make_df-Tuple{Scenario}","page":"Home","title":"KuMo.make_df","text":"make_df(s::Scenario; verbose = true)\n\nMake a DataFrame to describe the scenario s.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.make_df-Tuple{Vector{KuMo.SnapShot}, Any}","page":"Home","title":"KuMo.make_df","text":"make_df(snapshots::Vector{SnapShot}, topo; verbose = true)\n\nMake a DataFrame from the raw snapshots.\n\nArguments:\n\nsnapshots: A collection of snapshots\ntopo: topology of the network\nverbose: if set to true, it will print a description of the snapshots in the terminal\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.make_links-Tuple{Any}","page":"Home","title":"KuMo.make_links","text":"make_links(links)\n\nCreates links.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.make_nodes-Tuple{Any}","page":"Home","title":"KuMo.make_nodes","text":"make_nodes(nodes)\n\nCreate nodes.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.make_users-Tuple{Int64, Any, Any, Any, Any}","page":"Home","title":"KuMo.make_users","text":"make_users(args...)\n\nCreate users.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.marks-Tuple{Any}","page":"Home","title":"KuMo.marks","text":"marks(df::DataFrame)\n\nReturns a 4-tuple (a, b, c, d) that marks the start and end of the nodes and links columns in the dataframe.\n\n(a, b) mark the start and end indices of the nodes columns\n(c, d) mark the start and end indices of the links columns\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.mincost_flow","page":"Home","title":"KuMo.mincost_flow","text":"mincost_flow\n\nCall the internal mincost_flow method.\n\n\n\n\n\n","category":"function"},{"location":"#KuMo.param-Tuple{R} where R<:KuMo.AbstractResource","page":"Home","title":"KuMo.param","text":"param(r::R) where {R<:AbstractResource}\n\nDefault accessor for an optional parameter for R. If no param field exists, returns nothing.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.plot_links-Tuple{Any}","page":"Home","title":"KuMo.plot_links","text":"plot_links(df::DataFrame; kind=:plot)\n\nA simple function to quickly plot the load allocation of the links. The kind keyarg can take the value :plot (default) or :areaplot. Both corresponds to the related methods in Plots.jl and StatsPlots.jl.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.plot_nodes-Tuple{Any}","page":"Home","title":"KuMo.plot_nodes","text":"plot_nodes(df::DataFrame; kind=:plot)\n\nA simple function to quickly plot the load allocation of the nodes. The kind keyarg can take the value :plot (default) or :areaplot. Both corresponds to the related methods in Plots.jl and StatsPlots.jl.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.plot_resources-Tuple{Any}","page":"Home","title":"KuMo.plot_resources","text":"plot_resources(df::DataFrame; kind=:plot)\n\nA simple function to quickly plot the load allocation of all resources. The kind keyarg can take the value :plot (default) or :areaplot. Both corresponds to the related methods in Plots.jl and StatsPlots.jl.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.plot_snaps-Tuple{Any}","page":"Home","title":"KuMo.plot_snaps","text":"plot_snaps(df::DataFrame; target=:all, plot_type=:all, title=\"\")\n\nPlots the snapshots in df in a single multiplot figure.\n\ntarget defines the targetted resources: :all (default), :nodes, :links, resources\nplot_type defines the kind of plots that will be generated: :all (default), :plot, :areaplot\nan optional title\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.post_simulate-NTuple{4, Any}","page":"Home","title":"KuMo.post_simulate","text":"post_simulate(s, snapshots, verbose, output)\n\nPost-simulation process that covers cleaning the snapshots and producing an output.\n\nArguments:\n\ns: simulated scenario\nsnapshots: resulting snapshots (before cleaning)\nverbose: if set to true, prints information about the output and the snapshots\noutput: output path\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.pseudo_cost","page":"Home","title":"KuMo.pseudo_cost","text":"pseudo_cost(cap, charge, resource, param...)\npseudo_cost(r::<:AbstractResource, charge)\n\nMethods to compute the pseudo-cost of various resources.\n\n\n\n\n\n","category":"function"},{"location":"#KuMo.pseudo_cost-Union{Tuple{R}, Tuple{R, Any}} where R<:KuMo.AbstractResource","page":"Home","title":"KuMo.pseudo_cost","text":"pseudo_cost(r::R, charge) where {R<:AbstractResource}\n\nCompute the pseudo-cost of r given its charge.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.push_snap!-NTuple{8, Any}","page":"Home","title":"KuMo.push_snap!","text":"push_snap!(snapshots, state, total, selected, duration, solving_time, instant, n)\n\nAdd a snapshot to an existing collection of snapshots.\n\nArguments:\n\nsnapshots: collection of snapshots\nstate: current state\ntotal: load\nselected: node where a request is executed\nduration: duration of the whole resource allocation for the request\nsolving_time: time taken specifically by the solving algorithm (<: AbstractAlgorithm)\ninstant: instant when the request is received\nn: number of available nodes\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.rand_job-Tuple{Any}","page":"Home","title":"KuMo.rand_job","text":"rand_job(jd::Dict)\n\nCreate a random job given a job_distribution dictionary.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.rem_load!-NTuple{5, Any}","page":"Home","title":"KuMo.rem_load!","text":"rem_load!(state, links, containers, v, n)\n\nRemoves load from a given state.\n\nArguments:\n\nstate\nlinks: the load increase to be removed from links\ncontainers: the containers load to be removed from v\nv: node where a task is endind\nn: amount of available nodes\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.requests-Tuple","page":"Home","title":"KuMo.requests","text":"requests(requests_lst...)\n\nConstruct a collection of requests.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.requests-Tuple{KuMo.Job, Int64, Distributions.UnivariateDistribution, Real, Real}","page":"Home","title":"KuMo.requests","text":"requests(j::Job, n::Int, d::UnivariateDistribution, lower::Real, upper::Real)\n\nGenerate a sequence of n requests with the same job following the distribution d. Limits, lower and upper, can be specified to truncate d.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.requests-Tuple{PeriodicRequests}","page":"Home","title":"KuMo.requests","text":"requests(pr::PeriodicRequests)\n\nGenerate a sequence of aperiodic requests from a periodic request pr.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.retrieve_path-Tuple{Any, Any, Any}","page":"Home","title":"KuMo.retrieve_path","text":"retrieve_path(u, v, paths)\n\nRetrieves the path from u to v.\n\nArguments:\n\nu: source vertex\nv: target vertex\npaths: list of shortest paths within a network\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.scenario-Tuple{}","page":"Home","title":"KuMo.scenario","text":"scenario(; duration, links = nothing, nodes, users, job_distribution = nothing, request_rate = nothing)\n\nBuild a scenario.\n\nArguments:\n\nduration: duration of the interval where requests can be started\nlinks: collection of links resources\nnodes: collection of nodes resources\nusers: collections of users information\njob_distribution: (optional) distributions used to generate jobs\nrequest_rate: (optional) average request rate\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.simulate-Tuple{Scenario, Any}","page":"Home","title":"KuMo.simulate","text":"simulate(s::Scenario, algo; speed = 0, output = \"\", verbose = true)\n\nSimulate a scenario.\n\nArguments:\n\ns: simulation targetted scenario\nalgo: algorithm used to estimate the best allocation regarding to the pseudo-cost\nspeed: simulation speed. If set to 0, the requests are handled sequentially without computing time limits. Otherwise the requests are made as independant asynchronous processes\noutput: path to save the output, if empty (default), nothing is saved\nverbose: if set to true, prints information about the simulation\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.simulate_and_plot-Tuple{Any, Any}","page":"Home","title":"KuMo.simulate_and_plot","text":"simulate_and_plot(\n    s::Scenario, algo<:AbstractAlgorithm;\n    speed=0, output=\"\", verbose=true, target=:all, plot_type=:all,\n    title=\"Cloud Morphing: a responsive allocation of resources\",\n)\n\nSimulate and plot the snapshots generate through scenario in a single multiplot figure.\n\nverbose defines if the simulation is verbose or not (default to true)\ntarget defines the targetted resources: :all (default), :nodes, :links, resources\nplot_type defines the kind of plots that will be generated: :all (default), :plot, :areaplot\nan optional title\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.simulate_loop-Tuple{Any, Any, Any, Any, Any, Any, Val{0}}","page":"Home","title":"KuMo.simulate_loop","text":"simulate_loop(s, algo, _, start, containers, args_loop, ::Val{0})\n\nInner loop of the simulation of scenario s.\n\nArguments:\n\ns: scenario being simulated\nalgo: algo solving the resource allocation dynamically at each step\n_: simulation speed (unrequired)\nstart: starting time of the simulation\ncontainers: containers generated to allocate tasks dynamically during the run\nargs_loop: arguments required by this loop\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.simulate_loop-Tuple{Any, Any, Any, Any, Any, Any, Val}","page":"Home","title":"KuMo.simulate_loop","text":"simulate_loop(s, algo, speed, start, containers, args_loop, ::Val)\n\nInner loop of the simulation of scenario s.\n\nArguments:\n\ns: scenario being simulated\nalgo: algo solving the resource allocation dynamically at each step\nspeed: asynchronous simulation speed\nstart: starting time of the simulation\ncontainers: containers generated to allocate tasks dynamically during the run\nargs_loop: arguments required by this loop\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.smooth-NTuple{4, Any}","page":"Home","title":"KuMo.smooth","text":"smooth(j, δ, π1, π2)\n\nGenerate a collection of requests for job j in [π1, π2] that grows smoothly in intensity. Requests are emitted every δ interval.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.spike-Tuple{Any, Any, Any}","page":"Home","title":"KuMo.spike","text":"spike(j, t, intensity)\n\nGenerate a spike of requests for job j at instant t. The number of requests is defined by intensity.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.steady-NTuple{5, Any}","page":"Home","title":"KuMo.steady","text":"steady(j, δ, π1, π2, intensity)\n\nGenerate a collection of requests for job j in [π1, π2] with a constant intensity. Requests are emitted every δ interval.\n\n\n\n\n\n","category":"method"},{"location":"#KuMo.user","page":"Home","title":"KuMo.user","text":"user(job_distributions::Dict, period, loc; start=-Inf, stop=Inf)\nuser(job, period, loc; start=-Inf, stop=Inf)\nuser(jr::Vector{R}, loc::Int) where {R<:Request}\nuser(jr, loc::Int)\nuser(jr, loc)\n\nA serie of methods to generate users.\n\n\n\n\n\n","category":"function"},{"location":"#KuMo.vtx-Tuple{MinCostFlow}","page":"Home","title":"KuMo.vtx","text":"vtx(algorithm::AbstractAlgorithm)\n\nReturn the number of additional vertices required by the algorithm used to allocate resources in the network.\n\n\n\n\n\n","category":"method"}]
}
