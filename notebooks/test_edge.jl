### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# ╔═╡ 1e980354-f51c-11ed-2b39-112a878daeb1
# ╠═╡ show_logs = false
begin
    using Pkg
    Pkg.develop("KuMo")
    using KuMo, GLMakie
end;

# ╔═╡ b274c32b-f57c-4be1-aea4-e9df8a32f876
md"""
# An interactive demo of KuMo.jl, a Cloud Morphing solution

A poster about the Cloud Morphing concept is presented by CHO Kenjiro at D1-5.

**It is recommended to go there first** (I will still answer your question anyway!).

### Some context

We expect an increase in cloud computing use and resources in the coming decade. Cloud infrastructure provides various services and more and more micro-services are requested.

Allocating these requests optimally is not feasible. However, we want to allocate resources efficiently while taking into account
- cost of using network resources
- user requirements and specificities
- job specificities (backend/frontend, duration, etc.)
- adaptive and self-stabilizing

Networks engineer or operator are unlikely to manage such allocations in real-time *by-hand*. Can we provide a tool to help them design and manage the cloud infrastructures of the future?

### Basic use

In the Julia console (REPL), using (and installing) KuMo with a graphical interface is an simple as running the following line:

```julia
using KuMo, GLMakie
```

Note that our code block below is more complicated as I am using a development version of the package.

"""

# ╔═╡ 07fa6cb7-24d5-4357-8b52-8593d9164854
md"""
To interact with our interface we create an interactive graphical `agent`. All our interactions will use this agent and will be reflected in the output window on the other screen.
"""

# ╔═╡ e1704f31-4434-4437-97aa-3a09a3a9adfc
agent = show_interactive_run();

# ╔═╡ 78c80be4-d041-40ea-9c47-f021d5fccbb4
md"""
#### Adding infrastructure and resources

Let's start by adding some nodes with capacities of 50 containers.
"""

# ╔═╡ f0957620-92dd-4441-90e0-62909c071f96
foreach(_ -> node!(agent, KuMo.Node(50)), 1:4)

# ╔═╡ 5746108a-fac2-4d79-be66-778b4492db9b
md"""
Instead of repeating this command `n` times, we could use the following iteration:

```julia
foreach(_ -> node!(agent, KuMo.Node(50)), 1:4)
```

We should also connect those nodes together. For the sake of simplicity, let's go with links with infinite capacity (and no-cost to use).
"""

# ╔═╡ e528edae-c223-4870-b699-bc614c0d12b3
begin
    link!(agent, 1, 2, KuMo.FreeLink())
    link!(agent, 2, 3, KuMo.FreeLink())
    link!(agent, 3, 4, KuMo.FreeLink())
    link!(agent, 4, 1, KuMo.FreeLink())
end;

# ╔═╡ 59fddd58-8bae-4d37-a076-2576387dd1d8
md"""
Now we have a network. Maybe we can some users and data.
```julia
user!(agent, location)
```

```julia
data!(agent, location)
```
"""

# ╔═╡ 14756ad5-8e2b-4a15-814c-d87b37e44e5a
foreach(_ -> data!(agent, rand(1:4)), 1:2)

# ╔═╡ 0e0d1ce5-6692-4cb0-ad50-785496d29a28
foreach(_ -> user!(agent, rand(1:4)), 1:2)

# ╔═╡ b3fc29e5-da48-4e93-90a3-ee6c5132961d
md"""
Let's add some jobs. Jobs can be periodic (with an optional time limit) or a single occurrence.

For a single occurrence job, we can call

```julia
job!(agent, backend, container, duration, frontend, data_id, user_id)
```

and for the periodic one

```julia
job!(agent, backend, container, duration, frontend, data_id, user_id, ν; stop = Inf)
```

And now for the real calls.
"""

# ╔═╡ ad80e9e8-53d1-4f95-b7c9-4e09a19a5eae
# job!(agent, backend, container, duration, frontend, data_id, user_id, ν; stop = Inf)
job!(agent, 0, 2, 1, 0, 2, 2, 0.02);

# ╔═╡ aaa97db5-3a6d-4ceb-a8f3-85425e93649a
sleep(2);
job!(agent, 0, 1, 1, 0, 1, 1, 0.01; stop = 5.0);

# ╔═╡ 8927ec93-88d3-4aa0-ab00-a8eaad495e11
md"""
### Pseudo-cost functions (advanced use of resources)

Our adaptive allocation model is based on the use of simple yet self-stabilizing resources through the definition of their pseudo-cost functions.

We have a small visualization tool to help, dont worry!
"""

# ╔═╡ 2712b376-845e-41f3-8b17-52f137ceffa5
md"""
We can make or change the different resources with the following commands.

**Modifying node resources**
```julia
node!(agent, node_resource) # adding new node with `id = n` (n increases each time)
node!(agent, node_id) # remove node
node!(agent, node_id, my_node_resource) # replace the pseudo-cost function/capacity
```

**Convex pseudo-cost (default)**

Default node structure, defined by its maximal capacity and the default convex pseudo-cost function.

```julia
node_resource = KuMo.Node(42)
node!(agent, node_resource)
```

**Convex pseudo-cost: Additive**

A node structure where the default pseudo-cost is translated by the value in the `param` field.

```julia
node_resource = KuMo.AdditiveNode(capacity, param)
```

**Convex pseudo-cost: Multiplicative**

A node structure where the default pseudo-cost is multiplied by the value in the `param` field.

```julia
node_resource = KuMo.MultiplicativeNode(capacity, param)
```

**Convex pseudo-cost: IdleState**

Node structure that stays iddle until a bigger system load than the default node. The `param` field is used to set the activation threshold.

```julia
node_resource = KuMo.IdleStateNode(capacity, param)
```

**Convex pseudo-cost: Premium**

A node structure for premium resources. The `param` field set the premium threshold.

```julia
node_resource = KuMo.PremiumNode(capacity, param)
```

**Monotonic pseudo-cost: EqualLoadBalancing**

Node structure with an equal load balancing (monotonic) pseudo-cost function.

```julia
node_resource = KuMo.EqualLoadBalancingNode(capacity, param)
```

**Constant pseudo-cost: Flat**

Node structure with a constant pseudo-cost function.

```julia
node_resource = KuMo.FlatNode(capacity, param)
```

**Modifying link resources**
```julia
link!(agent, source, target, link_resource) # adding/change new/existing link
link!(agent, source, target) # remove link
```

**Monotonic pseudo-cost: Link (default)**

Default link structure with an equal load balancing (monotonic) pseudo-cost function.

```julia
link_resource = KuMo.Link(capacity)
```

**Free pseudo-cost: Free**

The pseudo-cost of such links is always zero.

```julia
link_resource = KuMo.FreeLink()
```

**Convex pseudo-cost: Convex**

Link structure with a convex pseudo-cost function.

```julia
link_resource = KuMo.ConvexLink(capacity)
```

**Constant pseudo-cost: Flat**

Link structure with a constant pseudo-cost function.

```julia
link_resource = KuMo.FlatLink(capacity, param)
```

**Managing data and users**

We can add/move users as follows

```julia
user!(agent, time, location) # add
user!(agent, time, id, location) # move
```

Similar with data

```julia
data!(agent, time, location) # add
data!(agent, time, id, location) # move
```

## Let's play!

"""

# ╔═╡ 5d6aef5c-6fc0-4337-875c-583e3c7f2258
begin
    link!(agent, 1, 2, Link(1))
    link!(agent, 2, 3, Link(1))
    link!(agent, 3, 4, Link(1))
    link!(agent, 4, 1, Link(1))
end

# ╔═╡ a0d9dc9d-bd45-428d-b3f3-3146d8dc6d1d
job!(agent, 0, 2, 1, 0, 2, 2, 0.005);

# ╔═╡ 690bc7a8-ef90-4883-8ed3-098590b35f6d
agent

# ╔═╡ 1bb0671e-a62b-4702-b81f-2916e28c202b
results(agent)

# ╔═╡ 2bb9377a-73ac-4017-ac6a-d1995a0617e0
stop!(agent)

# ╔═╡ Cell order:
# ╟─b274c32b-f57c-4be1-aea4-e9df8a32f876
# ╠═1e980354-f51c-11ed-2b39-112a878daeb1
# ╟─07fa6cb7-24d5-4357-8b52-8593d9164854
# ╠═e1704f31-4434-4437-97aa-3a09a3a9adfc
# ╟─78c80be4-d041-40ea-9c47-f021d5fccbb4
# ╠═f0957620-92dd-4441-90e0-62909c071f96
# ╟─5746108a-fac2-4d79-be66-778b4492db9b
# ╠═e528edae-c223-4870-b699-bc614c0d12b3
# ╟─59fddd58-8bae-4d37-a076-2576387dd1d8
# ╠═14756ad5-8e2b-4a15-814c-d87b37e44e5a
# ╠═0e0d1ce5-6692-4cb0-ad50-785496d29a28
# ╟─b3fc29e5-da48-4e93-90a3-ee6c5132961d
# ╠═ad80e9e8-53d1-4f95-b7c9-4e09a19a5eae
# ╠═aaa97db5-3a6d-4ceb-a8f3-85425e93649a
# ╟─8927ec93-88d3-4aa0-ab00-a8eaad495e11
# ╟─2712b376-845e-41f3-8b17-52f137ceffa5
# ╠═5d6aef5c-6fc0-4337-875c-583e3c7f2258
# ╠═a0d9dc9d-bd45-428d-b3f3-3146d8dc6d1d
# ╠═690bc7a8-ef90-4883-8ed3-098590b35f6d
# ╠═1bb0671e-a62b-4702-b81f-2916e28c202b
# ╠═2bb9377a-73ac-4017-ac6a-d1995a0617e0
