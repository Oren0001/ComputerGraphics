oren503 321174591
ogetzler 311229983

Part 1, article 6: why do separate vertices for each face cause flat shading?
When MakeFlatShaded method is used, each triangle gets a unique set of 3 vertices, 
and the normal of each vertex in a given set is affected solely by the other vertices in the set.
However, if we don't use the method then triangles share vertices, and the normal of
each vertex is affected by vertices of it's triangles.
