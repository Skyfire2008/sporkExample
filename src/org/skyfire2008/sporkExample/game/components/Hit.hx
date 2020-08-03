package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Entity;
import spork.core.Wrapper;
import spork.core.JsonLoader.EntityFactoryMethod;

import org.skyfire2008.sporkExample.game.components.Init;
import org.skyfire2008.sporkExample.game.components.Update;
import org.skyfire2008.sporkExample.game.properties.Health;
import org.skyfire2008.sporkExample.spatial.Collider;
import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.game.ScoringSystem;
import org.skyfire2008.sporkExample.game.Bonus.ExplodeShot;
import org.skyfire2008.sporkExample.game.Bonus.DoubleFirerate;
import org.skyfire2008.sporkExample.game.Bonus.TripleShot;
import org.skyfire2008.sporkExample.game.Bonus.TurretBonus;
import org.skyfire2008.sporkExample.game.Bonus.HpBonus;

using org.skyfire2008.sporkExample.geom.Point;

interface HitComponent extends Component {
	@callback
	function onHit(collider: Collider): Void;
}

class SpawnsHealthShip implements HitComponent {
	private var owner: Entity;
	private var health: Health;
	private static var game: Game;
	private static var healthShipSpawnFunc: EntityFactoryMethod;

	public static function init(game: Game, healthShipSpawnFunc: EntityFactoryMethod) {
		SpawnsHealthShip.game = game;
		SpawnsHealthShip.healthShipSpawnFunc = healthShipSpawnFunc;
	}

	public function new() {}

	public function onHit(collider: Collider) {
		if (health.hp == 1 && game.getCount("HealthShip") == 0) {
			game.addEntity(healthShipSpawnFunc((holder) -> {
				holder.position = new Point(0, 360);
				holder.velocity = new Point(100, 0);
				holder.rotation = new Wrapper<Float>(0);
				holder.angVel = new Wrapper<Float>(0);
			}));
		}
	}

	public function assignProps(holder: PropertyHolder) {
		health = holder.health;
	}
}

class ResetMultOnHit implements HitComponent {
	private var owner: Entity;

	public function new() {}

	public function onHit(collider: Collider) {
		ScoringSystem.instance.resetMult();
	}
}

class BounceOnHit implements HitComponent {
	private var owner: Entity;
	private var pos: Point;
	private var vel: Point;

	public function new() {}

	public function onHit(collider: Collider) {
		var axis = pos.difference(collider.pos);
		if (Point.dot(axis, vel) < 0) {
			axis.normalize();
			var len = Point.dot(vel, axis);
			axis.mult(-2 * len);
			vel.add(axis);
		}
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		vel = holder.velocity;
	}
}

class TempInvulnOnHit implements HitComponent implements UpdateComponent implements InitComponent {
	private var owner: Entity;
	private var side: Side;
	private var invulnTime: Float;
	private var blinkTime: Float;
	private var game: Game;
	private var radius: Float;
	private var pos: Point;
	private var colorMult: Wrapper<Float>;

	private var curTime: Float;
	private var curBlinkTime: Float;
	private var isInvuln: Bool;

	public function new(invulnTime: Float, blinkTime: Float) {
		this.invulnTime = invulnTime;
		this.blinkTime = blinkTime;
		curTime = 0;
		curBlinkTime = 0;
		isInvuln = false;
	}

	public function assignProps(holder: PropertyHolder) {
		side = holder.side;
		radius = holder.colliderRadius;
		pos = holder.position;
		colorMult = holder.colorMult;
	}

	public function onInit(game: Game) {
		this.game = game;
	}

	public function onHit(collider: Collider) {
		isInvuln = true;
		curBlinkTime = 0;
		colorMult.value = 0;
		game.removeCollider(owner.id, side);
	}

	public function onUpdate(time: Float) {
		if (isInvuln) {
			curTime += time;
			curBlinkTime += time;
			if (curBlinkTime >= blinkTime) {
				curBlinkTime -= blinkTime;
				colorMult.value = 1.0 - colorMult.value;
			}
			if (curTime >= invulnTime) {
				colorMult.value = 1;
				curTime = 0;
				isInvuln = false;
				game.addCollider(new Collider(owner, pos, radius), side);
			}
		}
	}
}

class HitSpawnComponent implements HitComponent implements InitComponent {
	private var spawner: Spawner;
	private var pos: Point;
	private var rotation: Wrapper<Float>;
	private var vel: Point;
	private var owner: Entity;
	private var spawnAtCollider: Bool;

	public static function fromJson(json: Dynamic): Component {
		return new HitSpawnComponent(new Spawner(json), json.spawnAtCollider);
	}

	public function new(spawner: Spawner, spawnAtCollider: Bool) {
		this.spawner = spawner;
		this.spawnAtCollider = spawnAtCollider;
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		vel = holder.velocity;
		rotation = holder.rotation;
	}

	public function clone(): Component {
		return new HitSpawnComponent(spawner.clone(), spawnAtCollider);
	}

	public function onHit(collider: Collider) {
		if (spawnAtCollider) {
			spawner.spawn(collider.pos, Point.difference(collider.pos, pos).angle, vel);
		} else {
			spawner.spawn(pos, rotation.value, vel);
		}
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
		},
		"hpBonus" => () -> {
			return new HpBonus();
		},
		"turret" => () -> {
			return new TurretBonus();
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
		owner.damage(1);
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
