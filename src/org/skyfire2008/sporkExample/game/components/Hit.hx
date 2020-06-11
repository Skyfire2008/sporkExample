package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Entity;

import org.skyfire2008.sporkExample.game.properties.Health;
import org.skyfire2008.sporkExample.spatial.Collider;
import org.skyfire2008.sporkExample.game.Bonus.ExplodeShot;
import org.skyfire2008.sporkExample.game.Bonus.DoubleFirerate;
import org.skyfire2008.sporkExample.game.Bonus.TripleShot;

interface HitComponent extends Component {
	@callback
	function onHit(collider: Collider): Void;
}

class ApplyBonus implements HitComponent {
	private var owner: Entity;
	private static var bonuses: StringMap<() -> Bonus> = [
		"explodeShot" => () -> {
			return new ExplodeShot();
		},
		"doubleFirerate" => () -> {
			return new DoubleFirerate();
		},
		"tripleShot" => () -> {
			return new TripleShot();
		}
	];
	private var func: () -> Bonus;
	private var bonusName: String;

	private function new(bonusName: String) {
		this.bonusName = bonusName;
		func = bonuses.get(bonusName);
		if (func == null) {
			throw 'No bonus $bonusName exists';
		}
	}

	public function onHit(collider: Collider) {
		collider.owner.applyBonus(func());
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
