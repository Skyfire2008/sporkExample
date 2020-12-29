package org.skyfire2008.sporkExample.game;

import spork.core.JsonLoader.EntityFactoryMethod;
import spork.core.Entity;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.Spawner.SpawnerConfig;
import org.skyfire2008.sporkExample.game.components.Hit.HitSpawnComponent;

interface Bonus {
	/**
	 * Applies the bonus to target, thus making it stronger
	 * @param target entity that the bonus is applied to
	 */
	function apply(target: Entity, ?pos: Point): Void;

	/**
	 * Removes the bonus from target, reverting it to previous state
	 * @param target entity, that had the bonus
	 */
	function revert(target: Entity): Void;

	/**
	 * Update the bonus
	 * @param time delta time
	 */
	function update(time: Float): Void;

	function isAlive(): Bool;
}

class AbstractBonus implements Bonus {
	private var time: Float;

	public function new(maxTime: Float) {
		this.time = maxTime;
	}

	public function apply(target: Entity, ?pos: Point) {
		throw 'Method apply of class AbstractBonus is not implemented!';
	}

	public function revert(target: Entity) {
		throw 'Method apply of class AbstractBonus is not implemented!';
	}

	public function isAlive(): Bool {
		return time > 0;
	}

	public function update(time: Float) {
		this.time -= time;
	}
}

class MagnetBonus extends AbstractBonus {
	private static var game: Game;

	private var ownerPos: Point;

	public static function setup(game: Game) {
		MagnetBonus.game = game;
	}

	public function new() {
		super(10);
	}

	public override function apply(target: Entity, ?pos: Point) {
		ownerPos = pos;
	}

	public override function revert(target: Entity) {}

	public override function update(time: Float) {
		for (bonusCol in game.bonusColliders) {
			var vec = Point.difference(ownerPos, bonusCol.pos);
			vec.normalize();
			vec.mult(200 * time);
			bonusCol.pos.add(vec);
		}
		super.update(time);
	}
}

class TurretBonus implements Bonus {
	private static var game: Game;

	public static function setup(game: Game) {
		TurretBonus.game = game;
	}

	public function new() {}

	public function apply(target: Entity, ?pos: Point) {
		game.pickUpTurret();
	}

	public function isAlive(): Bool {
		return false;
	}

	public function revert(target: Entity) {}

	public function update(time: Float) {}
}

class HpBonus implements Bonus {
	public function new() {}

	public function apply(target: Entity, ?pos: Point) {
		target.heal(1);
	}

	public function isAlive(): Bool {
		return false;
	}

	public function update(time: Float) {}

	public function revert(target: Entity) {}
}

class DoubleFirerate extends AbstractBonus {
	public function new() {
		super(10);
	}

	public override function apply(target: Entity, ?pos: Point) {
		target.getWep().config.spawnTime *= 0.5;
	}

	public override function revert(target: Entity) {
		target.getWep().config.spawnTime *= 2;
	}
}

class TripleShot extends AbstractBonus {
	public function new() {
		super(10);
	}

	public override function apply(target: Entity, ?pos: Point) {
		target.getWep().config.spawnNum += 2;
	}

	public override function revert(target: Entity) {
		target.getWep().config.spawnNum -= 2;
	}
}

class ExplodeShot extends AbstractBonus {
	private static var config: SpawnerConfig = {
		entityName: "playerBullet.json",
		spawnTime: 1,
		spawnVel: 200,
		spawnNum: 6,
		spreadAngle: Math.PI / 3,
		angleRand: Math.PI / 18,
		isVelRelative: true
	};
	private var spawner: Spawner;

	private var func: () -> spork.core.Component;

	public function new() {
		super(10);
		spawner = new Spawner(config);
		func = () -> {
			return new HitSpawnComponent(spawner, false);
		};
	}

	public override function apply(target: Entity, ?pos: Point) {
		target.getWep().extraComponents.push(func);
	}

	public override function revert(target: Entity) {
		target.getWep().extraComponents.remove(func);
	}
}
