package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Entity;
import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Wrapper;

using org.skyfire2008.sporkExample.geom.Point;

import org.skyfire2008.sporkExample.game.components.Init.InitComponent;
import org.skyfire2008.sporkExample.graphics.Renderer;
import org.skyfire2008.sporkExample.graphics.Shape;

interface UpdateComponent extends Component {
	@callback
	function onUpdate(time: Float): Void;
}

typedef SegmentData = {
	var pos: Point;
	var rotation: Float;
}

class TimeToLiveCircle implements UpdateComponent implements InitComponent {
	private var owner: Entity;
	private var pos: Point;
	private var segmentNum: Int;
	private var radius: Float;
	private var timeToLive: Wrapper<Float>;
	private var totalTime: Float;
	private var colorMult = 255.0;

	private var segLength: Float;
	private var segments: Array<SegmentData>;

	private static var segmentShape: Shape;

	public static function setSegment(shape: Shape) {
		segmentShape = shape;
	}

	public function new(segmentNum: Int, radius: Float) {
		this.segmentNum = segmentNum;
		this.radius = radius;
	}

	public function onInit(game: Game) {
		var angle = 2 * Math.PI / segmentNum;
		var polygonAngle = Math.PI - angle;
		segLength = 2 * Math.sin(angle / 2) * radius;
		segments = [];

		for (i in 0...segmentNum) {
			segments.push({
				rotation: polygonAngle / 2 + i * angle,
				pos: Point.fromPolar(i * angle, radius)
			});
		}
	}

	public function onUpdate(time: Float) {
		if (segmentNum * timeToLive.value / totalTime < segments.length - 1) {
			segments.shift();
			if (segments.length == 1) {
				colorMult = 1;
			}
		}

		for (segment in segments) {
			var currentPos = Point.translate(pos, segment.pos);
			Renderer.instance.render(segmentShape, currentPos.x, currentPos.y, segment.rotation, segLength, colorMult);
		}
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		timeToLive = holder.timeToLive;
		totalTime = timeToLive.value;
	}
}

class BgParticle implements UpdateComponent {
	private var owner: Entity;
	private var scale: Wrapper<Float>;
	private var rotation: Wrapper<Float>;
	private var projPos: Point;
	private var colorMult: Wrapper<Float>;

	private var pos: Point;
	private var z: Float;
	private var zVel: Float;

	private var focalLength: Float;
	private var startZ: Float;
	private var minVel: Float;
	private var maxVel: Float;
	private var trailLength: Float;

	public function new(focalLength: Float, startZ: Float, minVel: Float, maxVel: Float, trailLength: Float) {
		this.focalLength = focalLength;
		this.startZ = startZ;
		this.minVel = minVel;
		this.maxVel = maxVel;
		this.trailLength = trailLength;

		z = startZ;
		zVel = minVel + Math.random() * (maxVel - minVel);
		pos = new Point(640, 360);
		while (pos.x == 640 && pos.y == 360) {
			pos.x = Math.random() * 1280;
			pos.y = Math.random() * 720;
		}
		this.projPos = new Point();
		calcProj();

		this.rotation = new Wrapper<Float>(Math.atan2(pos.y - 360, pos.x - 640) + Math.PI / 2);
	}

	public function assignProps(holder: PropertyHolder) {
		this.scale = holder.scale;
		this.colorMult = holder.colorMult;
	}

	public function createProps(holder: PropertyHolder) {
		holder.position = projPos;
		holder.rotation = rotation;
	}

	public function onUpdate(time: Float) {
		if (z <= 0 || projPos.x > 1280 || projPos.x < 0 || projPos.y > 720 || projPos.y < 0) {
			z = startZ;
			calcProj();
		}

		z -= zVel;
		var prevProj = projPos.copy();
		calcProj();
		prevProj.sub(projPos);
		scale.value = Math.max(trailLength * prevProj.length, 1.0);
		colorMult.value = (startZ - z) / startZ;
	}

	private inline function calcProj() {
		var mult = focalLength / (focalLength + z);
		projPos.x = mult * (pos.x - 640) + 640;
		projPos.y = mult * (pos.y - 360) + 360;
	}
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
	private var colorMult: Wrapper<Float>;

	private var curTime: Float;
	private var curFrame: Int;

	private static var shapes: StringMap<Shape>;

	public static function setShapes(shapes: StringMap<Shape>) {
		AnimComponent.shapes = shapes;
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
		this.colorMult = new Wrapper<Float>(1.0);
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

		Renderer.instance.render(frames[curFrame], pos.x, pos.y, rotation.value, colorMult.value);
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		rotation = holder.rotation;
	}

	public function createProps(holder: PropertyHolder) {
		holder.colorMult = colorMult;
	}
}

class ChangeColorMultComponent implements UpdateComponent {
	private var owner: Entity;
	private var mult: Wrapper<Float>;
	private var startMult: Float;
	private var stopMult: Float;
	private var changeTime: Float;
	private var totalTime: Float = 0;

	public function new(startMult: Float, stopMult: Float, changeTime: Float) {
		this.startMult = startMult;
		this.stopMult = stopMult;
		this.changeTime = changeTime;
	}

	public function onUpdate(time: Float) {
		totalTime += time;
		mult.value = startMult + (stopMult - startMult) * totalTime / changeTime;
	}

	public function assignProps(holder: PropertyHolder) {
		mult = holder.colorMult;
	}
}

class ChangeScaleComponent implements UpdateComponent {
	private var owner: Entity;
	private var scale: Wrapper<Float>;
	private var startScale: Float;
	private var stopScale: Float;
	private var changeTime: Float;
	private var totalTime: Float = 0;

	public function new(startScale: Float, stopScale: Float, changeTime: Float) {
		this.startScale = startScale;
		this.stopScale = stopScale;
		this.changeTime = changeTime;
	}

	public function onUpdate(time: Float) {
		totalTime += time;
		scale.value = startScale + (stopScale - startScale) * totalTime / changeTime;
	}

	public function assignProps(holder: PropertyHolder) {
		scale = holder.scale;
	}
}

class RenderComponent implements UpdateComponent {
	private var shape: Shape;
	private var pos: Point;
	private var rotation: Wrapper<Float>;
	private var owner: Entity;
	private var colorMult: Wrapper<Float>;
	private var scale: Wrapper<Float>;

	private static var shapes: StringMap<Shape>;

	public static function setShapes(shapes: StringMap<Shape>) {
		RenderComponent.shapes = shapes;
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
		this.colorMult = new Wrapper<Float>(1.0);
		this.scale = new Wrapper<Float>(1.0);
	}

	public function onUpdate(time: Float): Void {
		Renderer.instance.render(shape, pos.x, pos.y, rotation.value, scale.value, colorMult.value);
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		rotation = holder.rotation;
	}

	public function createProps(holder: PropertyHolder) {
		holder.colorMult = colorMult;
		holder.scale = scale;
	}
}
