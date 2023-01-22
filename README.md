# Terrain_Scratch_2023

Yet another experiment in generating 3d terrains

## Some notes

Creating using triangles with an equalateral footprint. Taking most of the inspiration from the [TriBlobs.gd](https://github.com/MichaelReel/2DMapGen_2023/blob/main/PixelDrawn/TriBlobs.gd) script, but re-implementing in 3D.

### Create the Grid/Mesh

There are some important calculations involved in positioning of vertices, ordering of edges and ordering of polygons so make surfaces indexable.

#### The x/z positioning of vertices

The vertices will be places in the horzontal plane as equally as possible, in a triangle tessilation:

```
____\/____\/____\/____\/____
    /\    /\    /\    /\    
\  /  \  /  \  /  \  /  \  /
_\/____\/____\/____\/____\/_
 /\    /\    /\    /\    /\ 
/  \  /  \  /  \  /  \  /  \
____\/____\/____\/____\/____
    /\    /\    /\    /\    
\  /  \  /  \  /  \  /  \  /
 \/____\/____\/____\/____\/_
 /\    /\    /\    /\    /\ 
``` 

The difference between points on the x axis will simply be the length of the side (`s`) of a triangle.
The difference between the lateral lines (in the grid above) will be the height (`h`) of a triangle.

The height can be calculate as the root of three quarters by the length of the side:

`h = sqrt(0.75) * s`

```
 |\         h^2 + (s/2)^2 = s^2
 | \        h^2 = s^2 - (s/2)^2
 |  \s      h^2 = s^2 - (s^2 / 4)
h|   \      h^2 = (1 - 1/4) * s^2
 |    \     h^2 = ( 3/4 * s^2 )
 |_____\      h = sqrt(3/4 * s^2)
  (s/2)       h = sqrt(3/4) * s
```

#### Indexing of edges

The rules here are important to understand for the polygon creation, as this affects the ordering.

The initial set of vertices are created first. The ordering by row and then column is fairly straight forward:
```
row  |
 0   | 0_____1_____2_____3_____4
     |  \    /\    /\    /\    /
     |   \  /  \  /  \  /  \  /
 1   |   0\/___1\/___2\/___3\/
     |    /\    /\    /\    /\
     |   /  \  /  \  /  \  /  \
 2   | 0/___1\/___2\/___3\/___4\
     |  \    /\    /\    /\    /
     |   \  /  \  /  \  /  \  /
 3   |   0\/___1\/___2\/___3\/
```

The connections between vertices form the edges, and these are created in the specific order for each vertex that is: a) Not on row 0 b) Not on column 0:
1) Connect from the vertex of the lower column index on the same row (to the left)
2) Connect to one of the vertices in the row with lower index (above), with the same column index as the current point:
  a) On an `even` row this will be to the top right, if it exists.
  b) On an `odd` row this will be to the top left, if it exists.
3) Connect to the other vertex in the row with lower index (above), the column index will depend in the parity of the current row index:
  a) On an `even` row this will be to the top left, with column index less than the column index of this point in this column, if that point exists.
  b) On an `odd` row this will be to the top right, with column index greater than the column index of this point, if the point exists.

```
            Odd point connections:                    Even point connections: 
                           
         (x,z-1) *           * (x+1,z-1)         (x-1,z-1) *           * (x,z-1)
                  \         /                               \         /      
                   \       /                                 \       /       
                   [1]   [2]                                 [2]   [1]       
                     \   /                                     \   /         
                      \ /                                       \ /          
   (x-1,z) *----[0]----O (x,z)               (x-1,z) *----[0]----O (x,z)       
```

#### Indexing of Triangles/Polygons

The edges created in the previous stage will be used to form the triangles. 
The triangles will be arranged in rows and have their own grid coordinations.

Each row will have a line of triangles alternating in orientation:

```
                      point columns
             0         1         2         3   
         ,-------. ,-------. ,-------. ,-------. 
        |         |         |         |         | 
    0--    ______________________________________
           \        /\        /\        /\       
            \(0,0) /  \(2,0) /  \(4,0) /  \(6,0)  
             \    /    \    /    \    /    \    /   - Triangle row 0
              \  /(1,0) \  /(3,0) \  /(5,0) \  / 
    1--        \/________\/________\/________\/  
p              /\        /\        /\        /\  
o             /  \(1,1) /  \(3,1) /  \(5,1) /  \ 
i            /    \    /    \    /    \    /    \   - Triangle row 1
n           /(0,1) \  /(2,1) \  /(4,1) \  /(6,1)  
t   2--    /________\/________\/________\/_______
           \        /\        /\        /\       
r           \(0,2) /  \(2,2) /  \(4,2) /  \(6,2)  
o            \    /    \    /    \    /    \    /   - Triangle row 2
w             \  /(1,2) \  /(3,2) \  /(5,2) \  / 
s   3--        \/________\/________\/________\/  
               /\        /\        /\        /\  
              /  \(1,3) /  \(3,3) /  \(5,3) /  \ 
             /    \    /    \    /    \    /    \   - Triangle row 3
            /(0,3) \  /(2,3) \  /(4,3) \  /(6,3)  
    4--    /________\/________\/________\/_______
           \        /\        /\        /\       

               ^    ^    ^    ^    ^    ^    ^
               0    1    2    3    4    5    6
                       Triangle columns
```

For each row of points there will be a row of triangles, except for the last row of points.
For each column of points there will be 2 columns of triangles, except the last row for which there'll be none if all the points rows are the same length.

- `triangle_rows = points_row - 1`
- `triangles_per_row = (points_per_row - 1) * 2`


For each triangle with the coordinates `(tx,tz)`, the first (`px0, pz0`) second (`px1, pz1`) and third (`px2, pz2`) points will be the anti-clockwise rotational positions, and this will depend on the parity of the row and column.

Assume all division is integer division such that the result of `a/b` is the same as `floor(a/b)`.

|     | column (`tx`) | row (`tz`) |(`px0`,    | `pz0`)|(`px1`,    |  `pz1`)|(`px2`,    |  `pz2`)|
| --- | ------------- | ---------- |-----------|-------|-----------|--------|-----------|--------|
| a)  | even          | even       |(`tx/2`,   | `tz` )|(`tx/2`,   | `tz+1`)|(`tx/2+1`, | `tz`  )|
| b)  | odd           | even       |(`tx/2+1`, | `tz` )|(`tx/2`,   | `tz+1`)|(`tx/2+1`, | `tz+1`)|
| c)  | even          | odd        |(`tx/2`,   | `tz` )|(`tx/2`,   | `tz+1`)|(`tx/2+1`, | `tz+1`)|
| d)  | odd           | odd        |(`tx/2`,   | `tz` )|(`tx/2+1`, | `tz+1`)|(`tx/2+1`, | `tz`  )|


```
a)                  b)                 c)                d)                 
  p0____________p2          p0                 p0          p0____________p2 
    \          /            /\                 /\            \          /   
     \(tx, ty)/            /  \               /  \            \(tx, ty)/    
      \      /            /    \             /    \            \      /     
       \    /            /      \           /      \            \    /      
        \  /            /(tx, ty)\         /(tx, ty)\            \  /       
         \/            /__________\       /__________\            \/        
         p1          p1            p2   p1            p2          p1        
```

Of course, where the column is even, the `floor` and `ceil` calls on the `tx` value are essentially irrelevant, but it can be helpful to include them.

#### Sanity checking the above with examples

The Triangle at position t(4,2) should have the points: `[p(2,2), p(2,3), p(3,2)]`

- `p0 = (4/2, 2)`
- `p1 = (4/2, 2+1)`
- `p2 = (4/2+1, 2)`

```
p(2,2)\/________\p(3,2)
      /\        /\ 
        \t(4,2)/   
         \    /    
          \  /     
          _\/__
           /p(2,3)
```

The Triangle at position t(3,2) should have the points: `[p(2,2), p(1,3), p(2,3)]`

- `p0 = (3/2+1, 2)`
- `p1 = (3/2, 2+1)`
- `p2 = (3/2+1, 2+1)`

```
     p(2,2)\/_
           /\   
          /  \  
         /    \ 
        /t(3,2)\       
      \/________\/______
 p(1,3)\        /p(2,3)
```

The Triangle at position t(4,3) should have the points: `[p(2,3), p(2,4), p(3,4)]`

- `p0 = (4/2, 3)`
- `p1 = (4/2, 3+1)`
- `p2 = (4/2+1, 3+1)`

```
     p(2,3)\/_
           /\   
          /  \  
         /    \ 
        /t(4,3)\       
      \/________\/______
 p(2,4)\        /p(3,4)
```

The Triangle at position (5,3) should have the points: `[p(2,3), p(3,4), p(3,3)]`

- `p0 = (5/2, 3)`
- `p1 = (5/2+1, 3+1)`
- `p2 = (5/2+1, 3)`

```
p(2,3)\/________\p(3,3)
      /\        /\ 
        \t(5,3)/   
         \    /    
          \  /     
          _\/__
           /p(3,4)
```

### Creating an Island

Rather than using noise for the height map, this will begin with finding an outline for the island to act as a coast. This can be done a bunch of ways, but the requirement is to have an outline to a solid shape in the grid.

One approach, that will likely be used initially, is an expanding front of polygons that will upon filling a certain number of triangles, will be outlined and filled for gaps.

### Creating lakes

Lakes shall be regions within the island shape, these will be used by the height generation to retain bodies of water.

### Getting the height map

The coastal points will be set as sea-level. Outward points will drop with each movement away from the coast. Inward points will rise with eash movement from the coast, but will envelop lakes. Lake edges will take a height and will drop within their bounds.
