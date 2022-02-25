# Depot CSP

A variation of the TSP which involves two salesman that
can exchange orders through a depot, modeled with 
[MiniZinc](https://www.minizinc.org).

It has been taken from [here](https://github.com/MiniZinc/minizinc-benchmarks/blob/master/depot-placement/depot_placement.mzn) but modeled in a slightly different way
due to some differences: the
original one restricts the maximum amount of exchanged orders to one, and this version
removes that restriction.

## Problem
There are two warehouses, A and B. Each one has a disjoint fixed 
set of customers and a truck, which is allowed also to deliver to 
customers of the other warehouse.

This is possible through a "depot" where both trucks can 
interchange goods for delivery. Its location is a decision
variable, ranging over customers and warehouse locations.

We want to minimize the maximum of the distances traveled
by the trucks when, starting from their respective
warehouse, deliver the goods to all the customers and 
then return back to their warehouse.

## Parameters

- **PSize**: number of customers per warehouse. Type `1..6`.
- **AllDist**: matrix of distances between all places. Type `array[1..14, 1..14] of Nat` and an example is provided in [this file](./data.dzn).

## Run

It can be run from the [MiniZinc IDE](https://www.minizinc.org/ide/) or
from the command line as follows:

```sh
minizinc depot.mzn data.dzn \
  --solver Gecode \
  --output-time \
  --cmdline-data "PSize = 4"
```

## Output examples

```sh
# PSize = 4
Truck A: [1, 2, 3, 4, 1] (distance is 87)
Truck B: [6, 4, 5, 7, 8, 10, 9, 6] (distance is 103)
Depot is 4
% time elapsed: 0.40 s

# PSize = 5
Truck A: [1, 2, 3, 4, 5, 1] (distance is 103)
Truck B: [7, 5, 6, 9, 12, 11, 10, 8, 7] (distance is 108)
Depot is 5
% time elapsed: 2.78 s

# PSize = 6
Truck A: [1, 2, 3, 4, 5, 6, 1] (distance is 123)
Truck B: [8, 10, 11, 12, 13, 14, 9, 6, 7, 8] (distance is 123)
Depot is 6
% time elapsed: 38.02 s
```
