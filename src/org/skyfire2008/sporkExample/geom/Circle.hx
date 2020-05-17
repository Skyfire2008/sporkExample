package org.skyfire2008.sporkExample.geom;

import de.polygonal.ds.Hashable;

class Circle implements Hashable {
	public var pos: Point;
	public var radius: Float;
	public var x(get, set): Float;
	public var y(get, set): Float;
	public var key(default, null): Int;

	private static var currentKey: Int = 0;

	public function new(x: Float = 0, y: Float = 0, radius: Float = 1) {
		this.pos = new Point(x, y);
		this.radius = radius;
		this.key = currentKey++;
	}

	public function clone(): Circle {
		return new Circle(x, y, radius);
	}

	public function rect(): Rectangle {
		return new Rectangle(x - radius, y - radius, radius * 2, radius * 2);
	}

	public function intersects(other: Circle): Bool {
		var dx = x - other.x;
		var dy = y - other.y;
		var rSum = radius + other.radius;

		return dx * dx + dy * dy < rSum * rSum;
	}

	// GETTERS AND SETTERS
	private inline function get_x(): Float {
		return pos.x;
	}

	private inline function set_x(x: Float): Float {
		return pos.x = x;
	}

	private inline function get_y(): Float {
		return pos.y;
	}

	private inline function set_y(y: Float): Float {
		return pos.y = y;
	}
}
