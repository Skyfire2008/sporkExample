package org.skyfire2008.sporkExample.game;

import spork.core.Entity;

import org.skyfire2008.sporkExample.game.Spawner.SpawnerConfig;
import org.skyfire2008.sporkExample.game.components.Hit.HitSpawnComponent;

interface Bonus {
	/**
	 * Applies the bonus to target, thus making it stronger
	 * @param target entity that the bonus is applied to
	 */
	function apply(target: Entity): Void;

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

	public function apply(target: Entity) {
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

class DoubleFirerate extends AbstractBonus {
	public function new() {
		super(30);
	}

	public override function apply(target: Entity) {
		target.getWep().config.spawnTime *= 0.5;
	}

	public override function revert(target: Entity) {
		target.getWep().config.spawnTime *= 2;
	}
}

class TripleShot extends AbstractBonus {
	public function new() {
		super(20);
	}

	public override function apply(target: Entity) {
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
	private var index: Int;

	public function new() {
		super(20);
		spawner = new Spawner(config);
	}

	public override function apply(target: Entity) {
		index = target.getWep().extraComponents.push(() -> {
			return new HitSpawnComponent(spawner);
		});
	}

	public override function revert(target: Entity) {
		target.getWep().extraComponents = target.getWep().extraComponents.splice(index, 1);
	}
}
