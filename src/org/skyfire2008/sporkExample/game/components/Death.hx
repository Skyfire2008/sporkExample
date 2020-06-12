package org.skyfire2008.sporkExample.game.components;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.JsonLoader.EntityFactoryMethod;
import spork.core.Entity;
import spork.core.Wrapper;

import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.Spawner;
import org.skyfire2008.sporkExample.game.components.Init.InitComponent;

interface DeathComponent extends Component {
	@callback
	function onDeath(): Void;
}

class CountedOnScreen implements DeathComponent {
	private static var game: Game;
	private var owner: Entity;

	public static function setup(game: Game) {
		CountedOnScreen.game = game;
	}

	public function new() {}

	public function onDeath() {
		game.asteroidsOnScreen--;
	}
}

class DropsBonusComponent implements DeathComponent {
	private static var game: Game;
	private static var bonuses: Array<EntityFactoryMethod>;

	private var owner: Entity;
	private var prob: Float;
	private var pos: Point;

	public static function setup(game: Game, entityFactories: Array<EntityFactoryMethod>) {
		DropsBonusComponent.game = game;
		DropsBonusComponent.bonuses = entityFactories;
	}

	public function new(prob: Float) {
		this.prob = prob;
	}

	public function assignProps(holder: PropertyHolder) {
		this.pos = holder.position;
	}

	public function onDeath() {
		if (Math.random() < prob) {
			var num = Std.random(bonuses.length);
			game.addEntity(bonuses[num]((holder) -> {
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