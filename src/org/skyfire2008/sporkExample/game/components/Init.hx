package org.skyfire2008.sporkExample.game.components;

import spork.core.Entity;
import spork.core.PropertyHolder;
import spork.core.Component;
import spork.core.Wrapper;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.spatial.Collider;
import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.game.Spawner;
import org.skyfire2008.sporkExample.game.Side;
import org.skyfire2008.sporkExample.game.components.Death.DeathComponent;
import org.skyfire2008.sporkExample.game.components.Update.UpdateComponent;

interface InitComponent extends spork.core.Component {
	@callback
	function onInit(game: Game): Void;
}

class ShootsAtComponent implements InitComponent implements UpdateComponent {
	private var group: String;
	private var owner: Entity;

	private var pos: Point;
	private var vel: Point;
	private var rotation: Wrapper<Float>;

	private var targetPos: Point;
	private var game: Game;
	private var wep: Spawner;

	public static function fromJson(json: Dynamic): Component {
		return new ShootsAtComponent(json.group, new Spawner(json.wep));
	}

	public function new(group: String, wep: Spawner) {
		this.group = group;
		this.wep = wep;
	}

	public function onInit(game: Game) {
		this.game = game;
		wep.init();
		game.addTargetGroupObserver(group, this.notifyAboutTargets);
	}

	public function onUpdate(time: Float) {
		wep.update(time, pos, Math.atan2(targetPos.y - pos.y, targetPos.x - pos.x) + Math.PI / 2, vel);
	}

	private function notifyAboutTargets(targets: Array<{
		id: Int,
		pos: Point
	}>) {
		trace("starting...");
		wep.startSpawn();
		var num = Std.random(targets.length);
		targetPos = targets[num].pos;
		game.addTargetDeathObserver(targets[num].id, this.notifyAboutDeath);
	}

	private function notifyAboutDeath() {
		wep.stopSpawn();
		game.addTargetGroupObserver(group, this.notifyAboutTargets);
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		vel = holder.velocity;
		rotation = holder.rotation;
	}

	public function clone(): Component {
		return new ShootsAtComponent(group, wep.clone());
	}
}

class TargetComponent implements InitComponent implements DeathComponent {
	private var group: String;
	private var owner: Entity;

	private var pos: Point;
	private var game: Game;

	public function new(group: String) {
		this.group = group;
	}

	public function onInit(game: Game) {
		game.addTarget(owner.id, pos, group);
		this.game = game;
	}

	public function onDeath() {
		game.removeTarget(owner.id, group);
	}

	public function assignProps(holder: PropertyHolder) {
		this.pos = holder.position;
	}
}

class CollisionComponent implements InitComponent {
	private var owner: Entity;

	private var pos: Point;

	public var radius(default, null): Float;
	public var side(default, null): Side;

	public static function fromJson(json: Dynamic) {
		var side: Side = null;
		switch (json.side) {
			case "Player":
				side = Player;
			case "Enemy":
				side = Enemy;
			default:
				throw 'Unknown side ${json.side}';
		}
		return new CollisionComponent(json.radius, side);
	}

	public function new(radius: Float, side: Side) {
		this.radius = radius;
		this.side = side;
	}

	public function assignProps(holder: PropertyHolder) {
		this.pos = holder.position;
	}

	public function onInit(game: Game) {
		game.addCollider(new Collider(this.owner, pos, radius), side);
	}
}
