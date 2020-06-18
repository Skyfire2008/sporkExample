package org.skyfire2008.sporkExample.game.properties;

import spork.core.PropertyHolder;

class Health {
	public var hp: Int;
	public var maxHp(default, null): Int;

	public function new(maxHp: Int) {
		this.maxHp = maxHp;
		hp = maxHp;
	}
}
