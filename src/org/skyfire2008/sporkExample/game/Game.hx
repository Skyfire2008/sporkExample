package org.skyfire2008.sporkExample.game;

import haxe.ds.StringMap;
import haxe.ds.IntMap;

import spork.core.Entity;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.spatial.UniformGrid;
import org.skyfire2008.sporkExample.spatial.Collider;
import org.skyfire2008.sporkExample.graphics.Renderer;

typedef TargetObserver = (Array<{id: Int, pos: Point}>) -> Void;
typedef TargetDeathObserver = () -> Void;

class Game {
	public static var fieldWidth(default, never) = 1280;
	public static var fieldHeight(default, never) = 720;

	private var renderer: Renderer;

	private var entities: Array<Entity> = [];
	private var controllableEntitites: Array<Entity> = [];

	private var playerColliders: Array<Collider>;
	private var enemyColliders: Array<Collider>;
	private var grid: UniformGrid;
	private var bonusColliders: Array<Collider>;
	private var bonusGrid: UniformGrid;
	private var bonusGetterColliders: Array<Collider>;

	private var targetGroups: StringMap<IntMap<Point>>;
	private var targetObservers: StringMap<Array<TargetObserver>>;
	private var targetDeathObservers: IntMap<Array<TargetDeathObserver>>;

	public function new(renderer: Renderer) {
		this.renderer = renderer;
		grid = new UniformGrid(1280, 720, 64, 64);
		targetGroups = new StringMap<IntMap<Point>>();
		targetObservers = new StringMap<Array<TargetObserver>>();
		targetDeathObservers = new IntMap<Array<TargetDeathObserver>>();
		playerColliders = [];
		enemyColliders = [];

		bonusColliders = [];
		bonusGrid = new UniformGrid(1280, 720, 128, 120);
		bonusGetterColliders = [];
	}

	public function addTargetGroupObserver(groupName: String, obs: TargetObserver) {
		var group = targetGroups.get(groupName);
		// if group is empty...
		if (group == null || !group.keys().hasNext()) {
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
			for (target in group.keyValueIterator()) {
				foo.push({id: target.key, pos: target.value});
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
			group = new IntMap<Point>();
			targetGroups.set(groupName, group);
		}
		// if group was empty previously, notify target group observers
		if (!group.iterator().hasNext()) {
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
		targetGroups.get(groupName).remove(entId);
		// notify all observers waiting for death of target and remove them
		for (obs in targetDeathObservers.get(entId)) {
			obs();
		}
		targetDeathObservers.set(entId, []);
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

	public function addControllableEntity(entity: Entity) {
		controllableEntitites.push(entity);
	}

	public function onKeyDown(code: String) {
		for (entity in controllableEntitites) {
			entity.onKeyDown(code);
		}
	}

	public function onKeyUp(code: String) {
		for (entity in controllableEntitites) {
			entity.onKeyUp(code);
		}
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
			if (col.owner.isAlive()) {
				newPlayerColliders.push(col);
			}
		}
		playerColliders = newPlayerColliders;

		var newEnemyColliders: Array<Collider> = [];
		for (col in enemyColliders) {
			if (col.owner.isAlive()) {
				newEnemyColliders.push(col);
			}
		}
		enemyColliders = newEnemyColliders;

		var newBonusColliders: Array<Collider> = [];
		for (col in bonusColliders) {
			if (col.owner.isAlive()) {
				newBonusColliders.push(col);
			}
		}
		bonusColliders = newBonusColliders;
	}
}
