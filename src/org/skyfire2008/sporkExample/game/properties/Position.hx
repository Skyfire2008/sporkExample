package org.skyfire2008.sporkExample.game.properties;

import spork.core.SharedProperty;
import spork.core.PropertyHolder;

class Position implements spork.core.SharedProperty {
	public var x: Float;
	public var y: Float;
	public var rotation: Float;

	public function new(x: Float, y: Float, rotation: Float) {
		this.x = x;
		this.y = y;
		this.rotation = rotation;
	}

	public function attach(holder: PropertyHolder) {
		holder.position = this;
	}
}

class Velocity extends Position {
	public function new(x: Float, y: Float, rotation: Float) {
		super(x, y, rotation);
	}

	public override function clone() {
		return new Velocity(x, y, rotation);
	}

	public override function attach(holder: PropertyHolder) {
		holder.velocity = this;
	}
}
