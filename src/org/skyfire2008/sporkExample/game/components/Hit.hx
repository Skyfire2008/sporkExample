package org.skyfire2008.sporkExample.game.components;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Entity;

import org.skyfire2008.sporkExample.game.properties.Health;
import org.skyfire2008.sporkExample.spatial.Collider;

interface HitComponent extends Component {
	@callback
	function onHit(collider: Collider): Void;
}

class DoubleFirerateBonus implements HitComponent {
	private var owner: Entity;

	public function new() {}

	public function onHit(collider: Collider) {
		collider.owner.getWep().config.spawnTime *= 0.5;
	}
}

class DamagedOnHit implements HitComponent {
	private var owner: Entity;
	private var health: Health;

	public function new() {}

	public function onHit(collider: Collider) {
		health.hp--;
	}

	public function assignProps(holder: PropertyHolder) {
		this.health = holder.health;
	}
}

class DiesOnHit implements HitComponent {
	private var owner: Entity;

	public function new() {}

	public function onHit(collider: Collider) {
		owner.kill();
	}
}
