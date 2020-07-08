package org.skyfire2008.sporkExample.game.components;

import spork.core.Entity;
import spork.core.PropertyHolder;
import spork.core.Component;
import spork.core.Wrapper;

import org.skyfire2008.sporkExample.spatial.Collider;
import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.game.Spawner;
import org.skyfire2008.sporkExample.game.Side;
import org.skyfire2008.sporkExample.game.properties.Health;
import org.skyfire2008.sporkExample.game.components.Death.DeathComponent;
import org.skyfire2008.sporkExample.game.components.Update.UpdateComponent;
import org.skyfire2008.sporkExample.game.components.Props.PropsComponent;

using org.skyfire2008.sporkExample.geom.Point;

interface InitComponent extends spork.core.Component {
	@callback
	function onInit(game: Game): Void;
}

class ChasesComponent implements InitComponent implements UpdateComponent {
	private var group: String;
	private var owner: Entity;
	private var angVel: Float;
	private var game: Game;

	private var pos: Point;
	private var vel: Point;
	private var rotation: Wrapper<Float>;
	private var targetPos: Point = null;

	public function new(group: String, angVel: Float) {
		this.group = group;
		this.angVel = angVel;
	}

	public function onInit(game: Game) {
		this.game = game;
		game.addTargetGroupObserver(group, this.notifyAboutTargets);
	}

	public function onUpdate(time: Float) {
		if (targetPos != null) {
			var dir = targetPos.difference(pos);

			var yAxis = new Point(-vel.y, vel.x);

			var angle = angVel * time;
			var requiredAngle = Math.acos(Point.dot(dir, vel) / (dir.length * vel.length));
			angle = angle >= requiredAngle ? requiredAngle : angle;

			if (dir.dot(yAxis) > 0) {
				vel.turn(angle);
				rotation.value += angle;
			} else {
				vel.turn(-angle);
				rotation.value -= angle;
			}
		}
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		vel = holder.velocity;
		rotation = holder.rotation;
	}

	private function notifyAboutTargets(targets: Array<{
		id: Int,
		pos: Point
	}>) {
		if (targetPos == null) {
			var num: Int = 0;
			var closest: Float = Math.POSITIVE_INFINITY;
			for (i in 0...targets.length) {
				var current = targets[i];
				var currentLength = Point.difference(current.pos, pos).length2;
				if (currentLength < closest) {
					num = i;
					closest = currentLength;
				}
			}
			targetPos = targets[num].pos;
			game.addTargetDeathObserver(targets[num].id, this.notifyAboutDeath);
		}
	}

	private function notifyAboutDeath() {
		targetPos = null;
		game.addTargetGroupObserver(group, this.notifyAboutTargets);
	}
}

class ShootsAtComponent implements InitComponent implements UpdateComponent implements PropsComponent {
	private var group: String;
	private var owner: Entity;

	private var pos: Point;
	private var vel: Point;
	private var rotation: Wrapper<Float>;

	private var targetPos: Point = null;
	private var game: Game;
	private var wep: Spawner;
	private var rotates: Bool;
	private var aimsAtClosest: Bool;

	public static function fromJson(json: Dynamic): Component {
		var rotates = false;
		if (json.rotates != null) {
			rotates = json.rotates;
		}
		var aimsAtClosest = false;
		if (json.aimsAtClosest != null) {
			aimsAtClosest = json.aimsAtClosest;
		}

		return new ShootsAtComponent(json.group, new Spawner(json.wep), rotates);
	}

	public function new(group: String, wep: Spawner, rotates: Bool) {
		this.group = group;
		this.wep = wep;
		this.rotates = rotates;
	}

	public function onInit(game: Game) {
		this.game = game;
		wep.init();
		game.addTargetGroupObserver(group, this.notifyAboutTargets);
	}

	public function onUpdate(time: Float) {
		if (targetPos != null) {
			var angle = Math.atan2(targetPos.y - pos.y, targetPos.x - pos.x) + Math.PI / 2;
			if (rotates) {
				rotation.value = angle;
			}
			wep.update(time, pos, angle, vel);
		}
	}

	public function getWep(): Spawner {
		return wep;
	}

	private function notifyAboutTargets(targets: Array<{
		id: Int,
		pos: Point
	}>) {
		if (targetPos == null) {
			wep.startSpawn();
			var num: Int = 0;
			if (aimsAtClosest) {
				var closest: Float = Math.POSITIVE_INFINITY;
				for (i in 0...targets.length) {
					var current = targets[i];
					var currentLength = Point.difference(current.pos, pos).length2;
					if (currentLength < closest) {
						num = i;
						closest = currentLength;
					}
				}
			} else {
				num = Std.random(targets.length);
			}
			targetPos = targets[num].pos;
			game.addTargetDeathObserver(targets[num].id, this.notifyAboutDeath);
		}
	}

	private function notifyAboutDeath() {
		wep.stopSpawn();
		targetPos = null;
		game.addTargetGroupObserver(group, this.notifyAboutTargets);
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		vel = holder.velocity;
		rotation = holder.rotation;
	}

	public function clone(): Component {
		return new ShootsAtComponent(group, wep.clone(), rotates);
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
			case "Bonus":
				side = Bonus;
			default:
				throw 'Unknown side ${json.side}';
		}
		return new CollisionComponent(json.radius, side);
	}

	public function new(radius: Float, side: Side) {
		this.radius = radius;
		this.side = side;
	}

	public function createProps(holder: PropertyHolder) {
		holder.colliderRadius = radius;
		holder.side = side;
	}

	public function assignProps(holder: PropertyHolder) {
		this.pos = holder.position;
	}

	public function onInit(game: Game) {
		game.addCollider(new Collider(owner, pos, radius), side);
	}
}
