package org.skyfire2008.sporkExample.game.components;

import haxe.DynamicAccess;
import haxe.ds.StringMap;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.JsonLoader.EntityFactoryMethod;
import spork.core.Entity;
import spork.core.Wrapper;

import howler.Howl;

import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.Spawner;
import org.skyfire2008.sporkExample.game.ScoringSystem;
import org.skyfire2008.sporkExample.spatial.Collider;
import org.skyfire2008.sporkExample.game.components.Init.InitComponent;
import org.skyfire2008.sporkExample.game.components.Update.TimeToLiveCircle;
import org.skyfire2008.sporkExample.game.components.Init.CollisionComponent;
import org.skyfire2008.sporkExample.game.components.Update.RenderComponent;
import org.skyfire2008.sporkExample.game.components.IsAlive.TimedComponent;
import org.skyfire2008.sporkExample.game.components.Update.MoveComponent;
import org.skyfire2008.sporkExample.game.components.Hit;
import org.skyfire2008.sporkExample.game.Bonus.MagnetBonus;
import org.skyfire2008.sporkExample.game.Bonus.HpBonus;
import org.skyfire2008.sporkExample.game.Bonus.TurretBonus;
import org.skyfire2008.sporkExample.game.Bonus.TripleShot;
import org.skyfire2008.sporkExample.game.Bonus.ExplodeShot;
import org.skyfire2008.sporkExample.game.Bonus.DoubleFirerate;

interface DeathComponent extends Component {
	@callback
	function onDeath(): Void;
}

enum On {
	Death;
	Hit;
}

class GameOverOnDeath implements DeathComponent {
	private var owner: Entity;
	private static var callback: () -> Void;

	public static function init(callback: () -> Void) {
		GameOverOnDeath.callback = callback;
	}

	public function new() {}

	public function onDeath() {
		callback();
	}
}

class AddScoreOnDeath implements DeathComponent {
	private var owner: Entity;
	private var score: Int;

	public function new(score: Int) {
		this.score = score;
	}

	public function onDeath() {
		ScoringSystem.instance.addScore(score);
	}
}

class MakeSound implements DeathComponent implements HitComponent {
	private var owner: Entity;
	private var sound: Howl;
	private var soundSrc: String;
	private var on: On;

	public static function fromJson(json: Dynamic): Component {
		var on: On;
		switch (json.on) {
			case "Death":
				on = Death;
			case "Hit":
				on = Hit;
			default:
				throw 'Unknown event trigger ${json.on} for MakeSound component';
		}

		var sound = new Howl({src: json.soundSrc});

		return new MakeSound(sound, on);
	}

	public function new(sound: Howl, on: On) {
		this.sound = sound;
		this.on = on;
	}

	public function attach(owner: Entity) {
		this.owner = owner;
		switch (on) {
			case Death:
				owner.deathComponents.push(this);
			case Hit:
				owner.hitComponents.push(this);
		}
	}

	public function onDeath() {
		sound.play();
	}

	public function onHit(collider: Collider) {
		sound.play();
	}
}

class CountedOnScreen implements DeathComponent implements InitComponent {
	private var game: Game;
	private var owner: Entity;
	private var count: Int;
	private var group: String;

	public function new(count: Int, group: String) {
		this.count = count;
		this.group = group;
	}

	public function onInit(game: Game) {
		this.game = game;
		game.addCount(group, count);
	}

	public function onDeath() {
		game.removeCount(group, count);
	}
}

class DropsBonusComponent implements DeathComponent {
	private static var game: Game;
	private static var bonuses: Array<EntityFactoryMethod> = [];
	private static var factories: StringMap<EntityFactoryMethod>;

	private var owner: Entity;
	private var prob: Float;
	private var pos: Point;
	private var myBonuses: Array<EntityFactoryMethod>;

	public static function setGame(game: Game) {
		DropsBonusComponent.game = game;
	}

	private static function makeBonus(screenCount: Int, timeToLive: Int, shapeRef: String, func: () -> Bonus): EntityFactoryMethod {
		var components: Array<Component> = [
			new MoveComponent(),
			new CountedOnScreen(screenCount, "Bonus"),
			new TimedComponent(timeToLive),
			RenderComponent.fromJson({
				shapeRef: shapeRef
			}),
			new CollisionComponent(15, Side.Bonus),
			new MakeSound(new Howl({src: ["assets/sound/powerup.wav"]}), On.Hit),
			new TimeToLiveCircle(8, 12.5),
			new ApplyBonus(func)
		];

		var factory = (assignments: (holder: PropertyHolder) -> Void) -> {
			// init entity
			var result = new Entity();

			// init holder
			var holder = new PropertyHolder();

			// clone components and create properties
			var clones: Array<Component> = [];
			for (comp in components) {
				var clone = comp.clone();
				clone.createProps(holder);
				clones.push(clone);
			}

			// assign values to properties
			assignments(holder);

			// assign properties to clones and attach them to entity
			for (clone in clones) {
				clone.assignProps(holder);
				clone.attach(result);
			}

			return result;
		};

		return factory;
	}

	private static function makeBonusArray(probs: StringMap<Int>): Array<EntityFactoryMethod> {
		var bonuses: Array<EntityFactoryMethod> = [];

		for (key in probs.keys()) {
			for (j in 0...probs.get(key)) {
				var factory = factories.get(key);
				if (factory == null) {
					throw 'No factory for bonus called "${key}"';
				}
				bonuses.push(factory);
			}
		}

		return bonuses;
	}

	public static function setup(probs: StringMap<Int> = null) {
		DropsBonusComponent.factories = new StringMap<EntityFactoryMethod>();
		factories.set("doubleFirerate", DropsBonusComponent.makeBonus(1, 20, "doubleFirerate.json", () -> {
			return new DoubleFirerate();
		}));
		factories.set("explodeShot", DropsBonusComponent.makeBonus(1, 20, "explodeShot.json", () -> {
			return new ExplodeShot();
		}));
		factories.set("tripleShot", DropsBonusComponent.makeBonus(1, 20, "tripleShot.json", () -> {
			return new TripleShot();
		}));
		factories.set("turretBonus", DropsBonusComponent.makeBonus(1, 20, "turretBonus.json", () -> {
			return new TurretBonus();
		}));
		factories.set("hpBonus", DropsBonusComponent.makeBonus(0, 40, "hpBonus.json", () -> {
			return new HpBonus();
		}));
		factories.set("magnetBonus", DropsBonusComponent.makeBonus(5, 20, "magnet.json", () -> {
			return new MagnetBonus();
		}));

		if (probs != null) {
			DropsBonusComponent.bonuses = makeBonusArray(probs);
		} else {
			for (value in factories.iterator()) {
				DropsBonusComponent.bonuses.push(value);
			}
		}
	}

	public static function fromJson(json: Dynamic): DropsBonusComponent {
		var myBonuses: Array<EntityFactoryMethod> = bonuses;

		if (json.myProbs != null) {
			var probsObject: DynamicAccess<Dynamic> = json.myProbs;
			var probs = new StringMap<Int>();

			for (key in probsObject.keys()) {
				probs.set(key, probsObject.get(key));
			}
			myBonuses = DropsBonusComponent.makeBonusArray(probs);
		}

		return new DropsBonusComponent(json.prob, myBonuses);
	}

	public function new(prob: Float, myBonuses: Array<EntityFactoryMethod>) {
		this.prob = prob;
		this.myBonuses = myBonuses;
	}

	public function assignProps(holder: PropertyHolder) {
		this.pos = holder.position;
	}

	public function onDeath() {
		var newProb = prob / (Math.log(game.getCount("Bonus") + 1) / Math.log(2));

		if (Math.random() < newProb) {
			var num = Std.random(myBonuses.length);
			game.addEntity(myBonuses[num]((holder) -> {
				holder.position = pos.copy();
				holder.velocity = new Point();
				holder.rotation = new Wrapper<Float>(0);
				holder.angVel = new Wrapper<Float>(0);
			}));
		}
	}
}

class DeathSpawnComponent implements DeathComponent implements InitComponent {
	private var spawner: Spawner;
	private var pos: Point;
	private var rotation: Wrapper<Float>;
	private var vel: Point;
	private var owner: Entity;

	public static function fromJson(json: Dynamic): Component {
		return new DeathSpawnComponent(new Spawner(json));
	}

	public function new(spawner: Spawner) {
		this.spawner = spawner;
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		vel = holder.velocity;
		rotation = holder.rotation;
	}

	public function clone(): Component {
		return new DeathSpawnComponent(spawner.clone());
	}

	public function onDeath() {
		spawner.spawn(pos, rotation.value, vel);
	}

	public function onInit(game: Game) {
		this.spawner.init();
	}
}
