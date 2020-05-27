package org.skyfire2008.sporkExample.game;

import haxe.ds.StringMap;

import spork.core.JsonLoader.EntityFactoryMethod;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.properties.Position;
import org.skyfire2008.sporkExample.game.properties.Position.Velocity;

class Spawner {
	private static var game: Game;
	private static var entityFactories: StringMap<EntityFactoryMethod>;

	private var entityName: String;
	public var spawnFunc(default, null): EntityFactoryMethod;
	public var spawnTime(default, null): Float;
	public var spawnVel(default, null): Float;
	public var spawnNum(default, null): Int;
	public var spreadAngle(default, null): Float;
	public var isVelRelative(default, null): Bool;
	public var isRotationRandomized(default, null): Bool;

	private var curTime: Float = 0;
	private var isSpawning: Bool = false;

	public static function setup(game: Game, entityFactories: StringMap<EntityFactoryMethod>) {
		Spawner.game = game;
		Spawner.entityFactories = entityFactories;
	}

	public function new(entityName: String, spawnTime: Float, spawnVel: Float, spawnNum: Int, spreadAngle: Float, isVelRelative: Bool,
			isRotationRandomized: Bool) {
		this.entityName = entityName;
		this.spawnTime = spawnTime;
		this.spawnVel = spawnVel;
		this.spawnNum = spawnNum;
		this.spreadAngle = spreadAngle;
		this.isVelRelative = isVelRelative;
		this.isRotationRandomized = isRotationRandomized;
	}

	public function init() {
		spawnFunc = entityFactories.get(entityName);
	}

	public function clone(): Spawner {
		return new Spawner(entityName, spawnTime, spawnVel, spawnNum, spreadAngle, isVelRelative, isRotationRandomized);
	}

	public function startSpawn() {
		isSpawning = true;
	}

	public function stopSpawn() {
		isSpawning = false;
	}

	public function spawn(pos: Position, vel: Velocity) {
		for (i in 0...spawnNum) {
			var ent = spawnFunc((holder) -> {
				var angle = i * spreadAngle + pos.rotation;
				holder.position = new Position(pos.x, pos.y, pos.rotation + angle);
				var ownVel = Point.fromPolar(angle, spawnVel);
				holder.velocity = new Velocity(ownVel.x, ownVel.y, 0);
				if (isVelRelative) {
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
			while (curTime >= spawnTime) {
				spawn(pos, vel);
				curTime -= spawnTime;
			}
		} else {
			if (curTime < spawnTime) {
				curTime += time;
			}
		}
	}
}
