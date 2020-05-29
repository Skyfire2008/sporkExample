package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Entity;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.Spawner;
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

interface Dummy {}

class ControlComponent implements KBComponent implements UpdateComponent implements InitComponent {
	private var keys: StringMap<Bool>;
	private var actions: StringMap<(time: Float) -> Void>;
	private var a: Float;
	private var angVel: Float;

	private var wep: Spawner;
	private var owner: Entity;
	private var vel: Velocity;
	private var pos: Position;

	private var fwKey: String;
	private var rightKey: String;
	private var leftKey: String;
	private var fireKey: String;

	public function new(a: Float, angVel: Float, fwKey: String, rightKey: String, leftKey: String, fireKey: String) {
		this.a = a;
		this.angVel = angVel;
		this.fwKey = fwKey;
		this.rightKey = rightKey;
		this.leftKey = leftKey;
		this.fireKey = fireKey;
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
		actions.set(fireKey, (time: Float) -> {});
	}

	public function onInit(game: Game) {
		wep = new Spawner({
			entityName: "playerBullet.json",
			spawnTime: 0.5,
			spawnVel: 400,
			spawnNum: 1,
			isVelRelative: false
		});
		wep.init();
		game.addControllableEntity(this.owner);
	}

	public function onKeyDown(code: String) {
		keys.set(code, true);
		if (code == fireKey) {
			wep.startSpawn();
		}
	}

	public function onKeyUp(code: String) {
		keys.remove(code);
		if (code == fireKey) {
			wep.stopSpawn();
		}
	}

	public function onUpdate(time: Float) {
		vel.rotation = 0;
		wep.update(time, pos, vel);

		for (key in keys.keys()) {
			var func = actions.get(key);
			if (func != null) {
				func(time);
			}
		}
	}

	public function assignProps(holder: PropertyHolder) {
		vel = holder.velocity;
		pos = holder.position;
	}
}
