package org.skyfire2008.sporkExample.game.components;

import haxe.ds.StringMap;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Entity;
import spork.core.Wrapper;

import howler.Howl;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.Controller;
import org.skyfire2008.sporkExample.game.Spawner;
import org.skyfire2008.sporkExample.game.components.Update;
import org.skyfire2008.sporkExample.game.components.Init.InitComponent;
import org.skyfire2008.sporkExample.game.components.Death.DeathComponent;

interface KBComponent {
	function startAccelerate(): Void;

	function stopAccelerate(): Void;

	function brake(time: Float): Void;

	function left(time: Float): Void;

	function right(time: Float): Void;

	function startFire(): Void;

	function stopFire(): Void;

	function deployTurret(): Void;

	function deployHeavyTurret(): Void;

	function teleport(): Void;
}

class ControlComponent implements UpdateComponent implements InitComponent implements DeathComponent implements KBComponent {
	private var game: Game;
	private var keys: StringMap<Bool>;
	private var actions: StringMap<(time: Float) -> Void>;
	private var a: Float;
	private var angA: Float;
	private var maxAngVel: Float;
	private var brakeMult: Float;
	private var maxVel: Float;
	private var mju: Float;
	private var accelerating: Bool = false;

	private var wep: Spawner;
	private var teleSpawner: Spawner;
	private var owner: Entity;
	private var vel: Point;
	private var pos: Point;
	private var rotation: Wrapper<Float>;
	private var angVel: Wrapper<Float>;

	private var angBrake: Float;
	private var angMult: Float = 0;

	private var soundSrc: String;

	public function new(a: Float, angA: Float, maxAngVel: Float, maxVel: Float, angBrake: Float, brakeMult: Float, mju: Float, soundSrc: String) {
		this.a = a;
		this.angA = angA;
		this.maxAngVel = maxAngVel;
		this.angBrake = angBrake;
		this.brakeMult = brakeMult;
		this.maxVel = maxVel;
		this.mju = mju;

		wep = new Spawner({
			entityName: "playerBullet.json",
			spawnTime: 0.5,
			spawnVel: 400,
			spawnNum: 1,
			spreadAngle: 5.0 * Math.PI / 180.0,
			isVelRelative: true,
			soundSrc: soundSrc
		});

		teleSpawner = new Spawner({
			entityName: "teleSpark.json",
			spawnTime: 1,
			spawnVel: 100,
			velRand: 200,
			spawnNum: 30,
			spreadAngle: 0,
			angleRand: 2 * Math.PI,
			isVelRelative: true
		});

		this.soundSrc = soundSrc;
	}

	public function startAccelerate() {
		accelerating = true;
	}

	public function stopAccelerate() {
		accelerating = false;
	}

	public function brake(time: Float) {
		vel.mult(Math.pow(brakeMult, 60 * time));
	}

	public function right(time: Float) {
		angMult += 1;
	}

	public function left(time: Float) {
		angMult -= 1;
	}

	public function startFire() {
		wep.startSpawn();
	}

	public function stopFire() {
		wep.stopSpawn();
	}

	public function deployTurret() {
		game.placeTurret(pos);
	}

	public function deployHeavyTurret() {
		game.placeHeavyTurret(pos);
	}

	public function teleport() {
		pos.x = Math.random() * 1280;
		pos.y = Math.random() * 720;
		teleSpawner.spawn(pos, rotation.value, vel);
	}

	public function onInit(game: Game) {
		wep.init();
		teleSpawner.init();
		this.game = game;
		Controller.getInstance().addComponent(this);
	}

	public function onDeath() {
		Controller.getInstance().removeComponent(this);
	}

	public function onUpdate(time: Float) {
		wep.update(time, pos, rotation.value, vel);

		if (accelerating) {
			var aVec = Point.fromPolar(rotation.value, a * time);
			var dot = Point.dot(vel, aVec);
			if (dot > 0) {
				aVec.mult(1.0 - (vel.length / maxVel));
			} else {
				// vel.mult(mju);
			}
			vel.add(aVec);
		} else {
			// vel.mult(mju);
		}

		vel.mult(mju);

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
