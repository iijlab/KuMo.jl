"""
    Data
Structure to store the information related to some `Data`. Currently, only the location of such data is stored.
"""
struct Data
    location::Int
end

data(location = 0) = Data(location)

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
