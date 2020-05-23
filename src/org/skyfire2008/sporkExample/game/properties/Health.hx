package org.skyfire2008.sporkExample.game.properties;

import spork.core.SharedProperty;
import spork.core.PropertyHolder;

class Health implements SharedProperty {
	public var hp: Float;
	public var maxHp(default, null): Float;

	public function new(maxHp: Float) {
		this.maxHp = maxHp;
		hp = maxHp;
	}

	public function attach(holder: PropertyHolder) {
		holder.health = this;
	}
}
