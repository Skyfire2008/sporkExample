package org.skyfire2008.sporkExample.game;

import spork.core.Entity;

import org.skyfire2008.sporkExample.graphics.Renderer;

class Game {
	public static var fieldWidth(default, never) = 1280;
	public static var fieldHeight(default, never) = 720;

	private var renderer: Renderer;

	private var entities: Array<Entity> = [];

	public function new(renderer: Renderer) {
		this.renderer = renderer;
	}

	public function addEntity(entity: Entity) {
		entity.onInit(this);
		entities.push(entity);
	}

	public function update(time: Float) {
		renderer.clear();

		// update every entity
		for (entity in entities) {
			entity.onUpdate(time);
		}

		// remove dead entities
		var newEntities: Array<Entity> = [];
		for (entity in entities) {
			if (entity.isAlive()) {
				newEntities.push(entity);
			}
		}
		entities = newEntities;
	}
}
