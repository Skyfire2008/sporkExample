package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Entity;
import spork.core.Wrapper;

import howler.Howl;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.Spawner;
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
	private var angA: Float;
	private var maxAngVel: Float;
	private var brakeMult: Float;

	private var wep: Spawner;
	private var owner: Entity;
	private var vel: Point;
	private var pos: Point;
	private var rotation: Wrapper<Float>;
	private var angVel: Wrapper<Float>;

	private var fwKey: String;
	private var rightKey: String;
	private var leftKey: String;
	private var fireKey: String;
	private var brakeKey: String;
	private var angBrake: Float;
	private var angMult: Float = 0;

	private var soundSrc: String;

	public function new(a: Float, angA: Float, maxAngVel: Float, angBrake: Float, brakeMult: Float, fwKey: String, rightKey: String, leftKey: String,
			fireKey: String, brakeKey: String, soundSrc: String) {
		this.a = a;
		this.angA = angA;
		this.maxAngVel = maxAngVel;
		this.angBrake = angBrake;
		this.brakeMult = brakeMult;
		this.fwKey = fwKey;
		this.rightKey = rightKey;
		this.leftKey = leftKey;
		this.fireKey = fireKey;
		this.brakeKey = brakeKey;
		this.keys = new StringMap<Bool>();

		// assign actions
		actions = new StringMap<(time: Float) -> Void>();
		actions.set(fwKey, (time: Float) -> {
			vel.add(Point.fromPolar(rotation.value, a * time));
		});
		actions.set(rightKey, (time: Float) -> {
			angMult += 1;
		});
		actions.set(leftKey, (time: Float) -> {
			angMult -= 1;
		});
		actions.set(fireKey, (time: Float) -> {});
		actions.set(brakeKey, (time: Float) -> {
			vel.mult(Math.pow(brakeMult, 60 * time));
		});
		wep = new Spawner({
			entityName: "playerBullet.json",
			spawnTime: 0.5,
			spawnVel: 400,
			spawnNum: 1,
			spreadAngle: 5.0 * Math.PI / 180.0,
			isVelRelative: false,
			soundSrc: soundSrc
		});

		this.soundSrc = soundSrc;
	}

	public function onInit(game: Game) {
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
		wep.update(time, pos, rotation.value, vel);

		for (key in keys.keys()) {
			var func = actions.get(key);
			if (func != null) {
				func(time);
			}
		}

		if (angMult == 0 || sgn(angMult) != sgn(angVel.value)) {
			angVel.value *= Math.pow(angBrake, 60 * time);
		}
		angVel.value += angMult * time * angA;
		if (angVel.value > maxAngVel) {
			angVel.value = maxAngVel;
		}
		if (angVel.value < -maxAngVel) {
			angVel.value = -maxAngVel;
		}

		angMult = 0;
	}

	private inline function sgn(a: Float): Int {
		var result: Int = 0;
		if (a != 0) {
			result = (a > 0) ? 1 : -1;
		}
		return result;
	}

	public function createProps(holder: PropertyHolder) {
		holder.wep = wep;
	}

	public function assignProps(holder: PropertyHolder) {
		vel = holder.velocity;
		pos = holder.position;
		rotation = holder.rotation;
		angVel = holder.angVel;
	}
}
