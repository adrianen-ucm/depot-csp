include "globals.mzn";

%---------- Problem --------------------------------------%
% There are two warehouses, A and B. Each one has a 
% disjoint fixed set of customers and a truck, which is 
% allowed also to deliver to customers of the other 
% warehouse.

% This is possible through a "depot" where both trucks can 
% interchange goods for delivery. Its location is a decision
% variable, ranging over customers and warehouse locations.

% We want to minimize the maximum of the distances traveled
% by the trucks when, starting from their respective
% warehouse, deliver the goods to all the customers and 
% then return back to their warehouse.

%---------- Parameters -----------------------------------%

% Number of customers per warehouse.
1..6: PSize; 

% Matrix of distances between all places.
array[1..14, 1..14] of Nat: AllDist; 

%---------------------------------------------------------%


%---------- Derived parameters and utilities--------------%

% Set of integers greater or equal than 0.
set of int: Nat = 0..infinity;

% Total places: warehouses A and B, and its customers.
int: TotalPlaces = (PSize + 1) * 2;
set of int: Places = 1..TotalPlaces;

% Denotes the absence of place, as opt cannot be used 
% due to the distribute function not working for an array
% of opt values.
int: None = -1;

% Maximum possible length is when the depot is the other
% warehouse for the truck that does all the deliveries.
% Minimum one is when the depot is its own warehouse and 
% the other truck does all the deliveries. In this last
% case, we have considered the path to be 
% [Warehouse, Warehouse] for avoiding to deal with 
% corner cases.
int: MaxPathLength = TotalPlaces + 1;
set of int: PathLengths = 2..MaxPathLength;

% Warehouse locations.
Places: WarehouseA = 1;
Places: WarehouseB = PSize + 2;

% Sets of warehouse customers.
set of int: WarehouseCustomersA = 
  (WarehouseA + 1)..(WarehouseA + PSize);

set of int: WarehouseCustomersB = 
  (WarehouseB + 1)..(WarehouseB + PSize);

% Calculate the total length of a path.
function var int: pathDist(
  array[int] of var int: Path, 
  var int: limit
) = sum([
  AllDist[Path[i], Path[i + 1]] | i in 1..limit - 1
]);

% Naive solution objective. By using this as an upper bound
% we skip valid solutions but reach faster the optimal one.
% Set it to infinity to not restrict the solutions.
Nat: NaiveDist = fix(max(
  pathDist(
    [WarehouseA] ++ WarehouseCustomersA ++ [WarehouseA], 
    PSize + 2
  ),
  pathDist(
    [WarehouseB] ++ WarehouseCustomersB ++ [WarehouseB], 
    PSize + 2
  )
));

%---------------------------------------------------------%


%---------- Variables ------------------------------------%

% Depot place variable. It is one of the existent places or
% None if it is not required.
var Places union {None}: Depot;

% Path variables. Length and visited places by its visit 
% order. Extra trailing positions are assigned to None.
var PathLengths: PathLengthA;
var PathLengths: PathLengthB;
array[1..MaxPathLength] of var Places union {None}: PathA;
array[1..MaxPathLength] of var Places union {None}: PathB;

%---------------------------------------------------------%


%---------- Derived variables ----------------------------%

% Path Place-cardinalities. Heavily used by the 
% constraints.
array[Places] of var Nat: CardinalityA = 
  distribute(Places, PathA);

array[Places] of var Nat: CardinalityB = 
  distribute(Places, PathB);

% Path distances.
var 0..NaiveDist: distA = pathDist(PathA, PathLengthA);
var 0..NaiveDist: distB = pathDist(PathB, PathLengthB);

%---------------------------------------------------------%


%---------- Constraints ----------------------------------%

% Each path must start and end in its warehouse.
constraint PathA[1] = WarehouseA;
constraint PathB[1] = WarehouseB;
constraint PathA[PathLengthA] = WarehouseA;
constraint PathB[PathLengthB] = WarehouseB;

% Each path must contain its warehouse exactly twice.
constraint CardinalityA[WarehouseA] = 2;
constraint CardinalityB[WarehouseB] = 2;

% The other warehouse must not appear in the path except if
% it is the depot. In that case it must appear once.
constraint CardinalityA[WarehouseB] = 
  if Depot = WarehouseB then 1 else 0 endif;

constraint CardinalityB[WarehouseA] = 
  if Depot = WarehouseA then 1 else 0 endif;

% All customers must appear exactly once in one of the 
% paths, except if it is the depot. In that case, it 
% must appear exactly once in both paths.
constraint 
  forall(p in Places diff {WarehouseA, WarehouseB})
    (if p = Depot
      then CardinalityA[p] = 1 /\ CardinalityB[p] = 1
      else CardinalityA[p] + CardinalityB[p] = 1
    endif);

% There must not be any customer of the other warehouse
% (strictly) before a depot visit.
constraint 
  forall(i in 1..PathLengthA where PathA[i] = Depot)
    (forall(j in 2..i - 1)
      (PathA[j] in WarehouseCustomersA)
    );

constraint 
  forall(i in 1..PathLengthB where PathB[i] = Depot)
    (forall(j in 2..i - 1)
      (PathB[j] in WarehouseCustomersB) 
    );

% The depot is required iff some path contains an extra
% customer.
constraint Depot = None <-> sum(
  [CardinalityA[p] | p in WarehouseCustomersB diff {Depot} ] ++
  [CardinalityB[p] | p in WarehouseCustomersA diff {Depot} ]
) = 0;

% A path value is None iff it is beyond its length.
constraint 
  forall(i in 1..MaxPathLength)
    (PathA[i] = None <-> i > PathLengthA);

constraint 
  forall(i in 1..MaxPathLength)
    (PathB[i] = None <-> i > PathLengthB);

% This constraint on the path lengths is already implied 
% by the other constraints, but may help to improve the 
% search.
constraint redundant_constraint(
  PathLengthA + PathLengthB = 
    4 + 2*PSize + if Depot = None then 0 else 1 endif
);

%---------------------------------------------------------%


%---------- Solve ----------------------------------------%

% Minimize the maximum of the path distances. This search 
% annotation seems to achieve a significant search time 
% reduction for big problems.
solve :: int_search(
    PathA ++ PathB, 
    first_fail, 
    indomain_min
  ) minimize max(distA, distB);

output [ "Truck A: \([PathA[i] | i in 1..PathLengthA])" 
       , " (distance is \(distA))\n"
       , "Truck B: \([PathB[i] | i in 1..PathLengthB])"
       , " (distance is \(distB))\n"
       , if fix(Depot) = None 
           then "No depot\n" 
           else "Depot is \(Depot)\n" 
         endif
       ];

%---------------------------------------------------------%
