package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Entity;
import spork.core.Component;
import spork.core.PropertyHolder;

import org.skyfire2008.sporkExample.game.properties.Position;
import org.skyfire2008.sporkExample.graphics.Renderer;
import org.skyfire2008.sporkExample.graphics.Shape;

interface UpdateComponent extends Component {
	@callback
	function onUpdate(time: Float): Void;
}

/**
 * Updates the entity's position according to its velocity
 */
class MoveComponent implements UpdateComponent {
	private var pos: Position;
	private var vel: Position;
	private var owner: Entity;

	public function new() {}

	public function onUpdate(time: Float) {
		pos.x += vel.x * time;
		pos.y += vel.y * time;
		pos.rotation += vel.rotation * time;

		// wrap
		if (pos.x < 0) {
			pos.x += Game.fieldWidth;
		} else if (pos.x > Game.fieldWidth) {
			pos.x -= Game.fieldWidth;
		}

		if (pos.y < 0) {
			pos.y += Game.fieldHeight;
		} else if (pos.y > Game.fieldHeight) {
			pos.y -= Game.fieldHeight;
		}
	}

	public function attach(owner: Entity) {
		owner.updateComponents.push(this);
		this.owner = owner;
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		vel = holder.velocity;
	}
}

class RenderComponent implements UpdateComponent {
	private var shape: Shape;
	private var pos: Position;
	private var owner: Entity;

	private static var shapes: StringMap<Shape> = new StringMap<Shape>();
	private static var renderer: Renderer;

	public static function setShape(name: String, shape: Shape) {
		shapes.set(name, shape);
	}

	public static function setRenderer(renderer: Renderer) {
		RenderComponent.renderer = renderer;
	}

	/**
	 * Factory function to create a ShapeRenderComponent from JSON template
	 * Properties: shapeRef
	 * @param json json object containing the configuration
	 * @return ShapeRenderComponent
	 */
	public static function fromJson(json: Dynamic): RenderComponent {
		if (!shapes.exists(json.shapeRef)) {
			throw 'No shape for ${json.shapeRef} exists';
		}
		return new RenderComponent(shapes.get(json.shapeRef));
	}

	public function new(shape: Shape) {
		this.shape = shape;
	}

	public function onUpdate(time: Float): Void {
		RenderComponent.renderer.render(shape, pos.x, pos.y, pos.rotation, 1);
	}

	public function attach(entity: Entity) {
		this.owner = entity;
		entity.updateComponents.push(this);
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
	}
}
/*enum Side {
	PLAYER;
	ENEMY;
	}

	class CollisionComponent implements UpdateComponent {
	private var radius: Float;
	private var pos: Position;
	private var side: Side;

	public function new()
	}
 */
