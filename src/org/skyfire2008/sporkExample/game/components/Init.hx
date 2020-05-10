package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Entity;
import spork.core.PropertyHolder;

import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.graphics.Renderer;
import org.skyfire2008.sporkExample.graphics.Shape;
import org.skyfire2008.sporkExample.game.properties.Position;

interface InitComponent extends spork.core.Component {
	@callback
	function onInit(game: Game): Void;
}

class ShapeRenderComponent implements InitComponent {
	private var shape: Shape;
	private var pos: Position;
	private var owner: Entity;

	private static var shapes: StringMap<Shape> = new StringMap<Shape>();

	public static function addShapes(name: String, shape: Shape) {
		shapes.set(name, shape);
	}

	/**
	 * Factory function to create a ShapeRenderComponent from JSON template
	 * Properties: shapeRef
	 * @param json json object containing the configuration
	 * @return ShapeRenderComponent
	 */
	public static function fromJson(json: Dynamic): ShapeRenderComponent {
		if (!shapes.exists(json.shapeRef)) {
			throw 'No shape for ${json.shapeRef} exists';
		}
		return new ShapeRenderComponent(shapes.get(json.shapeRef));
	}

	public function new(shape: Shape) {
		this.shape = shape;
	}

	public function onInit(game: Game): Void {}

	public function attach(entity: Entity) {
		this.owner = entity;
		entity.initComponents.push(this);
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
	}
}
