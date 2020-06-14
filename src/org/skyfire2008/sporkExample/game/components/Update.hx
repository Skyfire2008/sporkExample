package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Entity;
import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Wrapper;

using org.skyfire2008.sporkExample.geom.Point;

import org.skyfire2008.sporkExample.graphics.Renderer;
import org.skyfire2008.sporkExample.graphics.Shape;

interface UpdateComponent extends Component {
	@callback
	function onUpdate(time: Float): Void;
}

class SineMovement implements UpdateComponent {
	private var vel: Point;
	private var owner: Entity;
	private var amplitude: Float;
	private var length: Float;

	private var dv: Point;
	private var perp: Point;
	private var velLength: Float;
	private var totalLength: Float;

	public function new(amplitude: Float, length: Float) {
		this.amplitude = amplitude;
		this.length = length;
		this.dv = new Point();
		this.totalLength = 0;
	}

	public function assignProps(holder: PropertyHolder) {
		this.vel = holder.velocity;
		perp = vel.copy();
		perp.turn(Math.PI / 2);
		perp.normalize();
		velLength = vel.length;
	}

	public function onUpdate(time: Float) {
		totalLength += velLength * time;
		while (velLength > length) {
			totalLength -= length;
		}

		vel.sub(dv);
		dv = perp.scale(amplitude * Math.sin(totalLength / length * Math.PI * 2));
		vel.add(dv);
	}
}

/**
 * Updates the entity's position according to its velocity
 */
class MoveComponent implements UpdateComponent {
	private var pos: Point;
	private var rotation: Wrapper<Float>;
	private var vel: Point;
	private var angVel: Wrapper<Float>;
	private var owner: Entity;

	public function new() {}

	public function onUpdate(time: Float) {
		pos.add(Point.scale(vel, time));
		rotation.value += angVel.value * time;

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

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		vel = holder.velocity;
		rotation = holder.rotation;
		angVel = holder.angVel;
	}
}

class AnimComponent implements UpdateComponent {
	private var frames: Array<Shape>;
	private var pos: Point;
	private var owner: Entity;
	private var rotation: Wrapper<Float>;
	private var frameTime: Float;

	private var curTime: Float;
	private var curFrame: Int;

	private static var shapes: StringMap<Shape>;
	private static var renderer: Renderer;

	public static function setShapes(shapes: StringMap<Shape>) {
		AnimComponent.shapes = shapes;
	}

	public static function setRenderer(renderer: Renderer) {
		AnimComponent.renderer = renderer;
	}

	public static function fromJson(json: Dynamic): AnimComponent {
		var frames: Array<Shape> = [];
		var shapeRefs: Array<String> = cast json.shapeRefs;
		for (shapeRef in shapeRefs) {
			var shape = AnimComponent.shapes.get(shapeRef);
			if (shape == null) {
				throw 'No shape for ${shapeRef} exists';
			}
			frames.push(shape);
		}
		return new AnimComponent(frames, json.frameTime);
	}

	public function new(frames: Array<Shape>, frameTime: Float) {
		this.frames = frames;
		this.frameTime = frameTime;
		this.curTime = 0;
		this.curFrame = 0;
	}

	public function onUpdate(time: Float) {
		curTime += time;
		while (curTime > frameTime) {
			curTime -= frameTime;
			curFrame++;
		}
		curFrame = curFrame % frames.length;

		AnimComponent.renderer.render(frames[curFrame], pos.x, pos.y, rotation.value, 1);
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		rotation = holder.rotation;
	}
}

class RenderComponent implements UpdateComponent {
	private var shape: Shape;
	private var pos: Point;
	private var rotation: Wrapper<Float>;
	private var owner: Entity;

	private static var shapes: StringMap<Shape>;
	private static var renderer: Renderer;

	public static function setShapes(shapes: StringMap<Shape>) {
		RenderComponent.shapes = shapes;
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
		RenderComponent.renderer.render(shape, pos.x, pos.y, rotation.value, 1);
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		rotation = holder.rotation;
	}
}
