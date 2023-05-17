using GLMakie
using DataFrames

# Assuming df is your DataFrame
df = DataFrame(x=rand(3600), y=rand(3600))  # 3600 points for 1 minute at 60fps

# Convert columns to Float32 if they aren't already
df[!, :x] = convert(Vector{Float32}, df[!, :x])
df[!, :y] = convert(Vector{Float32}, df[!, :y])

# Create an empty scatter plot with Float32 vectors
fig = Figure()
ax = Axis(fig[1, 1])
sc = scatter!(ax, rand(Float32, 0), rand(Float32, 0), color=:blue)

# Create Observables to store the x and y coordinates
x_data = Observable(rand(Float32, 0))
y_data = Observable(rand(Float32, 0))

# Function to update the data
function update_data(n)
    if n <= nrow(df)
        push!(x_data[], df[n, :x])
        push!(y_data[], df[n, :y])
    end
end

# Update the scatter plot when data changes
on(x_data) do _
    @info "doing stuff"
    sc[1].positions = Point2f.(x_data[], y_data[])
    fig
end

# Display the figure
display(fig)

# Loop to update data
for i in 1:nrow(df)
    @info "doing stuff 0"
    update_data(i)
    sleep(1 / 60)  # wait for 1/60 seconds before next update
end
