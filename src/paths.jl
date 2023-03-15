"""
    AbstractAlgorithm

An abstract supertype for algorithms.
"""
abstract type AbstractAlgorithm end

"""
    ShortestPath <: AbstractAlgorithm

A ShortestPath algorithm.
"""
struct ShortestPath <: AbstractAlgorithm end
