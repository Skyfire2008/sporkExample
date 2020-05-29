package org.skyfire2008.sporkExample.game;

import haxe.ds.StringMap;

import spork.core.JsonLoader.EntityFactoryMethod;

import org.skyfire2008.sporkExample.util.Util;
import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.properties.Position;
import org.skyfire2008.sporkExample.game.properties.Position.Velocity;

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

	public function spawn(pos: Position, vel: Velocity) {
		var baseAngle = config.spawnNum * config.spreadAngle / 2.0;

		for (i in 0...config.spawnNum) {
			var ent = spawnFunc((holder) -> {
				var angle = i * config.spreadAngle + Util.rand(config.angleRand);
				angle += pos.rotation - baseAngle;
				holder.position = new Position(pos.x, pos.y, pos.rotation + angle);
				var ownVel = Point.fromPolar(angle, config.spawnVel + Util.rand(config.velRand));
				holder.velocity = new Velocity(ownVel.x, ownVel.y, 0);
				if (config.isVelRelative) {
					holder.velocity.x += vel.x;
					holder.velocity.y += vel.y;
				}
			});

			game.addEntity(ent);
		}
	}

	public function update(time: Float, pos: Position, vel: Velocity) {
		if (isSpawning) {
			curTime += time;
			while (curTime >= config.spawnTime) {
				spawn(pos, vel);
				curTime -= config.spawnTime;
			}
		} else {
			if (curTime < config.spawnTime) {
				curTime += time;
			}
		}
	}
}
