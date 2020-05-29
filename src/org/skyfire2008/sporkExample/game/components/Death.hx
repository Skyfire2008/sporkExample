package org.skyfire2008.sporkExample.game.components;

import spork.core.Component;
import spork.core.PropertyHolder;
import spork.core.Entity;

import org.skyfire2008.sporkExample.game.Spawner;
import org.skyfire2008.sporkExample.game.Spawner.SpawnerConfig;
import org.skyfire2008.sporkExample.game.components.Init.InitComponent;
import org.skyfire2008.sporkExample.game.properties.Position;
import org.skyfire2008.sporkExample.game.properties.Position.Velocity;

interface DeathComponent extends Component {
	@callback
	function onDeath(): Void;
}

class DeathSpawnComponent implements DeathComponent implements InitComponent {
	private var spawner: Spawner;
	private var pos: Position;
	private var vel: Velocity;
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
	}

	public function clone(): Component {
		return new DeathSpawnComponent(spawner.clone());
	}

	public function onDeath() {
		spawner.spawn(pos, vel);
	}

	public function onInit(game: Game) {
		this.spawner.init();
	}
}
