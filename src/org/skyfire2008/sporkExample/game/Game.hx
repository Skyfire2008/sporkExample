package org.skyfire2008.sporkExample.game;

import haxe.ds.StringMap;

import spork.core.Entity;

import org.skyfire2008.sporkExample.game.properties.Position;
import org.skyfire2008.sporkExample.graphics.Shape;
import org.skyfire2008.sporkExample.graphics.Renderer;

class Game {
	private var renderer: Renderer;

	private var updateList: Array<Entity> = [];

	public function new(renderer: Renderer) {
		this.renderer = renderer;
		renderer.start();
	}

	public function addUpdatable(entity: Entity) {
		updateList.push(entity);
	}

	public function update(time: Float) {
		renderer.clear();

		for (entity in updateList) {
			entity.onUpdate(time);
		}

		// remove dead entities
		var newUpdateList: Array<Entity> = [];
		for (entity in updateList) {
			if (!entity.isAlive()) {
				newUpdateList.push(entity);
			}
		}
		updateList = newUpdateList;
	}
}
