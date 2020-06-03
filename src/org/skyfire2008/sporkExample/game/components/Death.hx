package org.skyfire2008.sporkExample.game.components;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Entity;
import spork.core.Wrapper;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.Spawner;
import org.skyfire2008.sporkExample.game.Spawner.SpawnerConfig;
import org.skyfire2008.sporkExample.game.components.Init.InitComponent;

interface DeathComponent extends Component {
	@callback
	function onDeath(): Void;
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
