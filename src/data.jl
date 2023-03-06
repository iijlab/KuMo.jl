"""
    Data
Structure to store the information related to some `Data`. Currently, only the location of such data is stored.
"""
struct Data
    location::Int
end

"""
    data(location::Int = 0)

Construct data at `location`
"""
data(location=0) = Data(location)

"""
    location(d::Data)

Returns the location of the data `d`.
"""
location(d::Data) = d.location

# location(d::Data, location) = d.location = location

#SECTION - Test Items

@testitem "Data struct" tags = [:data] begin
    import KuMo: data, location
    d = data()
    @test location(d) == 0
    # location(d, 1)
    # @test d.location == 1
end
