oren503 321174591
ogetzler 311229983

4.8. We will explain how we implemented intersectPlaneCheckered function:
	We assume the plane is axis-aligned, then we check if the plane is oriented
	along YZ, XZ or XY by doing so: we know that dot(n, v) = cos(theta) = 1 
	iff n and v are at the same direction, so we subtract 1 and check if 
	it is smaller than EPS. We also use abs() to make sure we catch the case where
	n is at the opposite direction.

	After we found the plane's orentation, we set the material's value
	by calling the function getMaterial (we discribed it's role at the documentation).


5.3. We implemented intersectCylinderY using the following steps:
	a.  We Check for an intersection with the top circle of the cylinder, if it's true
		we update bestHit and return. otherwise, we check for an intersection with the 
		bottom circle of the cylinder and if it's true we update bestHit and return.
	b.  If we didn't return in step a, we keep checking for an intersection with the 
		cylinder of infinite height by solving the quadratic equation.
	c.  Finally, we calculate the intersection point using the quadratic solution 
		and check if it is within the boundaries of the given height.
