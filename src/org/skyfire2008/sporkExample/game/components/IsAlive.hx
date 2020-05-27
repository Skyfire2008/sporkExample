package org.skyfire2008.sporkExample.game.components;

import spork.core.PropertyHolder;
import spork.core.Component;
import spork.core.Entity;

import org.skyfire2008.sporkExample.game.components.Update;
import org.skyfire2008.sporkExample.game.properties.Health;

@singular
interface IsAliveComponent extends Component {
	@callback
	function isAlive(): Bool;
	@callback
	function kill(): Void;
}

class TimedComponent implements IsAliveComponent implements UpdateComponent {
	private var time: Float;
	private var owner: Entity;

	public function new(time: Float) {
		this.time = time;
	}

	public function isAlive(): Bool {
		return time > 0;
	}

	public function kill() {
		time = 0;
	}

	public function onUpdate(time: Float) {
		this.time -= time;
	}
}

class HpComponent implements IsAliveComponent {
	private var health: Health;
	private var owner: Entity;

	public function new(hp: Float) {
		this.health = new Health(hp);
	}

	public function clone(): Component {
		return new HpComponent(health.maxHp);
	}

	public function isAlive(): Bool {
		return health.hp > 0;
	}

	public function kill() {
		health.hp = 0;
	}

	public function assignProps(holder: PropertyHolder) {
		holder.health = health;
	}
}
