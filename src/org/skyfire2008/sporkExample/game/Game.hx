package org.skyfire2008.sporkExample.game;

import spork.core.Entity;

import org.skyfire2008.sporkExample.spatial.UniformGrid;
import org.skyfire2008.sporkExample.spatial.Collider;
import org.skyfire2008.sporkExample.graphics.Renderer;

class Game {
	public static var fieldWidth(default, never) = 1280;
	public static var fieldHeight(default, never) = 720;

	private var renderer: Renderer;

	private var entities: Array<Entity> = [];
	private var controllableEntitites: Array<Entity> = [];

	private var playerColliders: Array<Collider>;
	private var enemyColliders: Array<Collider>;
	private var grid: UniformGrid;

	public function new(renderer: Renderer) {
		this.renderer = renderer;
		grid = new UniformGrid(1280, 720, 64, 64);
		playerColliders = [];
		enemyColliders = [];
	}

	public function addEntity(entity: Entity) {
		entity.onInit(this);
		entities.push(entity);
	}

	public function addCollider(collider: Collider, side: Side) {
		switch (side) {
			case Player:
				playerColliders.push(collider);
			case Enemy:
				enemyColliders.push(collider);
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

		// detect collisions
		grid.reset();
		for (col in enemyColliders) {
			grid.add(col);
		}

		for (col in playerColliders) {
			var possibleCols = grid.queryRect(col.rect());
			for (enemyCol in possibleCols) {
				if (!col.owner.isAlive()) {
					break;
				}
				if (enemyCol.owner.isAlive() && col.intersects(enemyCol)) {
					enemyCol.owner.onHit(col);
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
	}
}
