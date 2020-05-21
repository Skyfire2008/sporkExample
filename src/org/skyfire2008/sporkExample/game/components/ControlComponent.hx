package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Entity;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.properties.Position;
import org.skyfire2008.sporkExample.game.properties.Position.Velocity;
import org.skyfire2008.sporkExample.game.components.Update;
import org.skyfire2008.sporkExample.game.components.Init.InitComponent;

interface KBComponent extends Component {
	@callback
	function onKeyDown(code: String): Void;

	@callback
	function onKeyUp(code: String): Void;
}

class ControlComponent implements KBComponent implements UpdateComponent implements InitComponent {
	private var keys: StringMap<Bool>;
	private var actions: StringMap<(time: Float) -> Void>;
	private var a: Float;
	private var angVel: Float;

	private var owner: Entity;
	private var vel: Velocity;
	private var pos: Position;

	private var fwKey: String;
	private var rightKey: String;
	private var leftKey: String;

	public function new(a: Float, angVel: Float, fwKey: String, rightKey: String, leftKey: String) {
		this.a = a;
		this.angVel = angVel;
		this.fwKey = fwKey;
		this.rightKey = rightKey;
		this.leftKey = leftKey;
		this.keys = new StringMap<Bool>();

		// assign actions
		actions = new StringMap<(time: Float) -> Void>();
		actions.set(fwKey, (time: Float) -> {
			var dv = Point.fromPolar(pos.rotation, a * time);
			vel.x += dv.x;
			vel.y += dv.y;
		});
		actions.set(rightKey, (time: Float) -> {
			vel.rotation = angVel;
		});
		actions.set(leftKey, (time: Float) -> {
			vel.rotation = -angVel;
		});
	}

	public function onInit(game: Game) {
		game.addControllableEntity(this.owner);
	}

	public function onKeyDown(code: String) {
		keys.set(code, true);
	}

	public function onKeyUp(code: String) {
		keys.remove(code);
	}

	public function onUpdate(time: Float) {
		vel.rotation = 0;

		for (key in keys.keys()) {
			var func = actions.get(key);
			if (func != null) {
				func(time);
			}
		}
	}

	public function attach(entity: Entity) {
		entity.updateComponents.push(this);
		entity.kBComponents.push(this);
		entity.initComponents.push(this);
		owner = entity;
	}

	public function assignProps(holder: PropertyHolder) {
		vel = holder.velocity;
		pos = holder.position;
	}
}
