package org.skyfire2008.sporkExample.game;

import haxe.ds.StringMap;

import nape.space.Space;

import spork.core.Entity;

import org.skyfire2008.sporkExample.game.properties.Position;
import org.skyfire2008.sporkExample.graphics.Shape;
import org.skyfire2008.sporkExample.graphics.Renderer;

class RenderData {
	public var owner(default, null): Entity;
	public var shape(default, null): Shape;
	public var pos(default, null): Position;

	public function new(owner: Entity, shape: Shape, pos: Position) {
		this.owner = owner;
		this.shape = shape;
		this.pos = pos;
	}
}

class Game {
	private var renderer: Renderer;

	private var renderList: Array<RenderData> = [];
	private var updateList: Array<Entity> = [];

	private var space: Space;

	public function new(renderer: Renderer, space: Space) {
		this.renderer = renderer;
		renderer.start();
		this.space = space;
	}

	public function addUpdatable(entity: Entity) {
		updateList.push(entity);
	}

	public function update(time: Float) {
		renderer.clear();

		for (entity in updateList) {
			entity.onUpdate(time);
		}

		for (data in renderList) {
			renderer.render(data.shape, data.pos.x, data.pos.y, data.pos.rotation, 1);
		}

		// remove dead entities
		var newUpdateList: Array<Entity> = [];
		for (entity in updateList) {
			if (!entity.isAlive()) {
				newUpdateList.push(entity);
			}
		}
		updateList = newUpdateList;

		var newRenderList: Array<RenderData> = [];
		for (data in renderList) {
			if (!data.owner.isAlive()) {
				newRenderList.push(data);
			}
		}
		renderList = newRenderList;
	}
}
