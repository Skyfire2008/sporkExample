package org.skyfire2008.sporkExample.game;

import haxe.ds.StringMap;

import js.lib.Map;

import spork.core.Wrapper;
import spork.core.Entity;
import spork.core.JsonLoader.EntityFactoryMethod;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.spatial.UniformGrid;
import org.skyfire2008.sporkExample.spatial.Collider;
import org.skyfire2008.sporkExample.graphics.Renderer;

using js.lib.HaxeIterator;

typedef TargetObserver = (Array<{id: Int, pos: Point}>) -> Void;
typedef TargetDeathObserver = () -> Void;

class Game {
	public static var fieldWidth(default, never) = 1280;
	public static var fieldHeight(default, never) = 720;

	private var renderer: Renderer;

	private var entities: Array<Entity> = [];

	private var playerColliders: Array<Collider>;
	private var enemyColliders: Array<Collider>;
	private var grid: UniformGrid;
	private var bonusColliders: Array<Collider>;
	private var bonusGrid: UniformGrid;
	private var bonusGetterColliders: Array<Collider>;
	private var collidersToRemove: Map<Side, Array<Int>>;

	private var targetGroups: Map<String, Map<Int, Point>>;
	private var targetObservers: Map<String, Array<TargetObserver>>;
	private var targetDeathObservers: Map<Int, Array<TargetDeathObserver>>;

	private var createMediumAsteroid: EntityFactoryMethod;
	private var createSmallAsteroid: EntityFactoryMethod;
	private var createHardAsteroid: EntityFactoryMethod;
	private var createUfo: EntityFactoryMethod;
	private var createTurret: EntityFactoryMethod;
	private var createHeavyTurret: EntityFactoryMethod;
	private var lvl: Int;
	private var entityCount: Map<String, Int>;
	private var currentUfoTime: Float;

	private var availableTurrets: Int;

	public var playerHpCallback(default, null): (value: Float) -> Void;
	private var turretCallback(default, null): (value: Int) -> Void;
	private var waveCallback: (value: Int) -> Void;

	public function new(renderer: Renderer, factoryFuncs: StringMap<EntityFactoryMethod>, playerHpCallback: (value: Float) -> Void,
			waveCallback: (value: Int) -> Void, turretCallback: (value: Int) -> Void) {
		this.renderer = renderer;
		grid = new UniformGrid(1280, 720, 64, 64);
		targetGroups = new Map<String, Map<Int, Point>>();
		targetObservers = new Map<String, Array<TargetObserver>>();
		targetDeathObservers = new Map<Int, Array<TargetDeathObserver>>();

		playerColliders = [];
		enemyColliders = [];
		bonusColliders = [];
		bonusGrid = new UniformGrid(1280, 720, 128, 120);
		bonusGetterColliders = [];
		collidersToRemove = new Map<Side, Array<Int>>();
		collidersToRemove.set(Player, []);
		collidersToRemove.set(Enemy, []);
		collidersToRemove.set(Bonus, []);

		lvl = 0;
		entityCount = new Map<String, Int>();
		currentUfoTime = 0;
		createMediumAsteroid = factoryFuncs.get("mediumAsteroid.json");
		createSmallAsteroid = factoryFuncs.get("smallAsteroid.json");
		createHardAsteroid = factoryFuncs.get("hardAsteroid.json");
		createUfo = factoryFuncs.get("ufo.json");
		createTurret = factoryFuncs.get("turret.json");
		createHeavyTurret = factoryFuncs.get("heavyTurret.json");

		this.playerHpCallback = playerHpCallback;
		this.waveCallback = waveCallback;
		this.turretCallback = turretCallback;

		this.availableTurrets = 0;
	}

	private static inline function getUfoNum(lvl: Int) {
		return Std.int(Math.sqrt(lvl));
	}

	private static inline function getUfoSpawnInterval(lvl: Int) {
		return 5 + 5 / Math.sqrt(lvl);
	}

	private static inline function getSmallAsteroidNum(lvl: Int): Int {
		return Std.int(3 * Math.sqrt(lvl) + 2);
	}

	private static inline function getMediumAsteroidNum(lvl: Int): Int {
		return Std.int(4 + lvl / 2);
	}

	public function placeTurret(pos: Point) {
		if (availableTurrets > 0) {
			var ent = createTurret((holder) -> {
				holder.position = pos.copy();
				holder.rotation = new Wrapper<Float>(0);
			});
			this.addEntity(ent);
			availableTurrets--;
			turretCallback(availableTurrets);
		}
	}

	public function placeHeavyTurret(pos: Point) {
		if (availableTurrets >= 5) {
			var ent = createHeavyTurret((holder) -> {
				holder.position = pos.copy();
				holder.rotation = new Wrapper<Float>(0);
			});
			this.addEntity(ent);
			availableTurrets -= 5;
			turretCallback(availableTurrets);
		}
	}

	public function pickUpTurret() {
		availableTurrets++;
		turretCallback(availableTurrets);
	}

	public function addCount(group: String, count: Int) {
		if (entityCount.has(group)) {
			entityCount.set(group, entityCount.get(group) + count);
		} else {
			entityCount.set(group, count);
		}
	}

	public function removeCount(group: String, count: Int) {
		entityCount.set(group, entityCount.get(group) - count);
	}

	public function getCount(group: String): Int {
		if (entityCount.has(group)) {
			return entityCount.get(group);
		} else {
			return 0;
		}
	}

	public function addTargetGroupObserver(groupName: String, obs: TargetObserver) {
		var group = targetGroups.get(groupName);
		// if group is empty...
		if (group == null || group.size == 0) {
			// add the observer to map
			var observers = targetObservers.get(groupName);
			if (observers == null) {
				targetObservers.set(groupName, [obs]);
			} else {
				observers.push(obs);
			}
		} else {
			// if group is not empty, just call the observer
			var foo: Array<{id: Int, pos: Point}> = [];
			for (entry in group.entries()) {
				foo.push({id: entry.key, pos: entry.value});
			}
			obs(foo);
		}
	}

	public function addTargetDeathObserver(targetId: Int, obs: TargetDeathObserver) {
		var observers = targetDeathObservers.get(targetId);
		if (observers == null) {
			targetDeathObservers.set(targetId, [obs]);
		} else {
			observers.push(obs);
		}
	}

	/**
	 * Adds a new target to be aimed at
	 * @param entId	id of entity that this target represents
	 * @param pos target's position
	 * @param groupName name of target group
	 */
	public function addTarget(entId: Int, pos: Point, groupName: String) {
		var group = targetGroups.get(groupName);
		if (group == null) {
			group = new Map<Int, Point>();
			targetGroups.set(groupName, group);
		}
		// if group was empty previously, notify target group observers
		if (group.size == 0) {
			var observers = targetObservers.get(groupName);
			if (observers != null) {
				for (obs in observers) {
					obs([{id: entId, pos: pos}]);
				}
			}
		}
		group.set(entId, pos);
	}

	public function removeTarget(entId: Int, groupName: String) {
		targetGroups.get(groupName).delete(entId);
		// notify all observers waiting for death of target and remove them
		var observers = targetDeathObservers.get(entId);
		if (observers != null) {
			for (obs in observers) {
				obs();
			}
		}
		targetDeathObservers.delete(entId);
	}

	/**
	 * Adds a new entity to the game
	 * @param entity entity to add
	 */
	public function addEntity(entity: Entity) {
		entity.onInit(this);
		entities.push(entity);
	}

	public function addBonusGetter(collider: Collider) {
		bonusGetterColliders.push(collider);
	}

	public function addCollider(collider: Collider, side: Side) {
		switch (side) {
			case Player:
				playerColliders.push(collider);
			case Enemy:
				enemyColliders.push(collider);
			case Bonus:
				bonusColliders.push(collider);
		}
	}

	public function removeCollider(ownerId: Int, side: Side) {
		collidersToRemove.get(side).push(ownerId);
	}

	public function update(time: Float) {
		renderer.clear();

		// update every entity
		for (entity in entities) {
			entity.onUpdate(time);
		}

		// detect collisions player <-> enemy
		grid.reset();
		// add all enemy colliders to the grid
		for (col in enemyColliders) {
			grid.add(col);
		}

		// use the grid to check for collision with player colliders
		for (col in playerColliders) {
			var possibleCols = grid.queryRect(col.rect());
			for (enemyCol in possibleCols) {
				if (!col.owner.isAlive()) {
					break;
				}
				if (enemyCol.owner.isAlive() && col.intersects(enemyCol)) {
					enemyCol.owner.onHit(col);
					col.owner.onHit(enemyCol);
				}
			}
		}

		// detect collisions bonus <-> bonus getter
		bonusGrid.reset();

		for (col in bonusColliders) {
			bonusGrid.add(col);
		}

		for (col in bonusGetterColliders) {
			var possibleCols = bonusGrid.queryRect(col.rect());
			for (bonusCol in possibleCols) {
				if (!col.owner.isAlive()) {
					break;
				}
				if (bonusCol.owner.isAlive() && col.intersects(bonusCol)) {
					bonusCol.owner.onHit(col);
					bonusCol.owner.kill();
				}
			}
		}

		// remove dead entities
		var newEntities: Array<Entity> = [];
		for (entity in entities) {
			if (entity.isAlive()) {
				newEntities.push(entity);
			} else {
				entity.onDeath();
			}
		}
		entities = newEntities;

		// remove dead colliders
		var newPlayerColliders: Array<Collider> = [];
		for (col in playerColliders) {
			if (col.owner.isAlive() && !collidersToRemove.get(Player).contains(col.owner.id)) {
				newPlayerColliders.push(col);
			}
		}
		playerColliders = newPlayerColliders;
		collidersToRemove.set(Player, []);

		var newEnemyColliders: Array<Collider> = [];
		for (col in enemyColliders) {
			if (col.owner.isAlive() && !collidersToRemove.get(Enemy).contains(col.owner.id)) {
				newEnemyColliders.push(col);
			}
		}
		enemyColliders = newEnemyColliders;
		collidersToRemove.set(Enemy, []);

		var newBonusColliders: Array<Collider> = [];
		for (col in bonusColliders) {
			if (col.owner.isAlive() && !collidersToRemove.get(Bonus).contains(col.owner.id)) {
				newBonusColliders.push(col);
			}
		}
		bonusColliders = newBonusColliders;
		collidersToRemove.set(Bonus, []);

		// update level and spawn new asteroids
		if (getCount("Asteroid") <= 0) {
			lvl++;
			waveCallback(lvl);
			for (i in 0...getSmallAsteroidNum(lvl)) {
				var ent = createSmallAsteroid((holder) -> {
					holder.position = new Point();

					if (Std.random(2) == 0) {
						holder.position.x = 1280 * Math.random();
					} else {
						holder.position.y = 720 * Math.random();
					}

					holder.velocity = Point.fromPolar(Math.random() * Math.PI * 2, 100);

					holder.rotation = new Wrapper<Float>(2 * Math.PI * Math.random());
					holder.angVel = new Wrapper<Float>(Math.PI * (Math.random() - 0.5));
				});
				this.addEntity(ent);
			}

			for (i in 0...getMediumAsteroidNum(lvl)) {
				var creationFunc = createMediumAsteroid;
				if (Math.random() < lvl / 100.0) {
					creationFunc = createHardAsteroid;
				}
				var ent = creationFunc((holder) -> {
					holder.position = new Point();

					if (Std.random(2) == 0) {
						holder.position.x = 1280 * Math.random();
					} else {
						holder.position.y = 720 * Math.random();
					}

					holder.velocity = Point.fromPolar(Math.random() * Math.PI * 2, 50);

					holder.rotation = new Wrapper<Float>(2 * Math.PI * Math.random());
					holder.angVel = new Wrapper<Float>(Math.PI * (Math.random() - 0.5));
				});
				this.addEntity(ent);
			}
		}

		// spawn ufos
		var maxUfoNum = getUfoNum(lvl);
		if (getCount("Ufo") < maxUfoNum) {
			currentUfoTime += time;
			if (currentUfoTime >= getUfoSpawnInterval(lvl)) {
				currentUfoTime -= getUfoSpawnInterval(lvl);
				var maxSpawnNum = Std.int(Math.min(Math.pow(lvl, 1.0 / 3.0), maxUfoNum - getCount("Ufo")));
				for (i in 0...maxSpawnNum) {
					var ent = createUfo((holder) -> {
						holder.position = new Point(0, Math.random() * 720);
						holder.velocity = new Point((150 + Math.random() * 50) * (Std.random(2) * 2 - 1), 0);
						holder.rotation = new Wrapper<Float>(0);
						holder.angVel = new Wrapper<Float>(0);
					});

					this.addEntity(ent);
				}
			}
		}
	}
}
