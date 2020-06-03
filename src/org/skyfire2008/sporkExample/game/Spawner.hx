package org.skyfire2008.sporkExample.game;

import haxe.ds.StringMap;

import spork.core.Wrapper;
import spork.core.JsonLoader.EntityFactoryMethod;

import org.skyfire2008.sporkExample.util.Util;
import org.skyfire2008.sporkExample.geom.Point;

typedef SpawnerConfig = {
	var entityName: String;
	var spawnTime: Float;
	var spawnVel: Float;
	var spawnNum: Int;
	var isVelRelative: Bool;
	@:optional var velRand: Float;
	@:optional var spreadAngle: Float;
	@:optional var angleRand: Float;
}

class Spawner {
	private static var game: Game;
	private static var entityFactories: StringMap<EntityFactoryMethod>;

	public var spawnFunc(default, null): EntityFactoryMethod;
	public var config: SpawnerConfig;

	private var curTime: Float = 0;
	private var isSpawning: Bool = false;

	public static function setup(game: Game, entityFactories: StringMap<EntityFactoryMethod>) {
		Spawner.game = game;
		Spawner.entityFactories = entityFactories;
	}

	public function new(config: SpawnerConfig) {
		if (config.velRand == null) {
			config.velRand = 0;
		}
		if (config.spreadAngle == null) {
			config.spreadAngle = 0;
		}
		if (config.angleRand == null) {
			config.angleRand = 0;
		}
		this.config = config;
	}

	public function init() {
		spawnFunc = entityFactories.get(config.entityName);
	}

	public function clone(): Spawner {
		return new Spawner(config);
	}

	public function startSpawn() {
		isSpawning = true;
	}

	public function stopSpawn() {
		isSpawning = false;
	}

	public function spawn(pos: Point, rotation: Float, vel: Point) {
		var baseAngle = config.spawnNum * config.spreadAngle / 2.0;

		for (i in 0...config.spawnNum) {
			var ent = spawnFunc((holder) -> {
				var angle = i * config.spreadAngle + Util.rand(config.angleRand);
				angle += rotation - baseAngle;
				holder.position = pos.copy(); // new Position(pos.x, pos.y, pos.rotation + angle);
				holder.rotation = new Wrapper<Float>(rotation + angle);
				holder.angVel = new Wrapper<Float>(0);

				holder.velocity = Point.fromPolar(angle, config.spawnVel + Util.rand(config.velRand));
				if (config.isVelRelative) {
					holder.velocity.x += vel.x;
					holder.velocity.y += vel.y;
				}
			});

			game.addEntity(ent);
		}
	}

	public function update(time: Float, pos: Point, rotation: Float, vel: Point) {
		if (isSpawning) {
			curTime += time;
			while (curTime >= config.spawnTime) {
				spawn(pos, rotation, vel);
				curTime -= config.spawnTime;
			}
		} else {
			if (curTime < config.spawnTime) {
				curTime += time;
			}
		}
	}
}
