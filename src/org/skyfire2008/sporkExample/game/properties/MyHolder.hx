package org.skyfire2008.sporkExample.game.properties;

import spork.core.Wrapper;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.Spawner;

class MyHolder {
	public var position: Point;
	public var rotation: Wrapper<Float>;
	public var velocity: Point;
	public var angVel: Wrapper<Float>;
	public var health: Health;
	public var wep: Spawner;
	public var colliderRadius: Float;
}