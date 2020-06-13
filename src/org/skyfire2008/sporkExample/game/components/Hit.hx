package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Entity;
import spork.core.Wrapper;

import org.skyfire2008.sporkExample.game.components.Init;
import org.skyfire2008.sporkExample.game.properties.Health;
import org.skyfire2008.sporkExample.spatial.Collider;
import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.Bonus.ExplodeShot;
import org.skyfire2008.sporkExample.game.Bonus.DoubleFirerate;
import org.skyfire2008.sporkExample.game.Bonus.TripleShot;

interface HitComponent extends Component {
	@callback
	function onHit(collider: Collider): Void;
}

class HitSpawnComponent implements HitComponent implements InitComponent {
	private var spawner: Spawner;
	private var pos: Point;
	private var rotation: Wrapper<Float>;
	private var vel: Point;
	private var owner: Entity;

	public static function fromJson(json: Dynamic): Component {
		return new HitSpawnComponent(new Spawner(json));
	}

	public function new(spawner: Spawner) {
		this.spawner = spawner;
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		vel = holder.velocity;
		rotation = holder.rotation;
	}

	public function clone(): Component {
		return new HitSpawnComponent(spawner.clone());
	}

	public function onHit(collider: Collider) {
		spawner.spawn(pos, rotation.value, vel);
	}

	public function onInit(game: Game) {
		this.spawner.init();
	}
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
