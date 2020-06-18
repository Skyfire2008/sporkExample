package org.skyfire2008.sporkExample.game.components;

import spork.core.PropertyHolder;
import spork.core.Component;
import spork.core.Entity;

import org.skyfire2008.sporkExample.game.components.Update;
import org.skyfire2008.sporkExample.game.components.Init;
import org.skyfire2008.sporkExample.game.properties.Health;

interface DamageComponent extends Component {
	@callback
	function damage(dmg: Int): Void;

	@callback
	function heal(dmg: Int): Void;
}

@singular
interface IsAliveComponent extends Component {
	@callback
	function isAlive(): Bool;
	@callback
	function kill(): Void;
}

class DisplayHp implements DamageComponent implements InitComponent {
	private var owner: Entity;
	private var hp: Health;
	private var callback: (value: Float) -> Void;

	public function new() {}

	public function onInit(game: Game) {
		callback = game.playerHpCallback;
		callback(hp.hp);
	}

	public function assignProps(holder: PropertyHolder) {
		hp = holder.health;
	}

	public function damage(dmg: Int) {
		callback(hp.hp);
	}

	public function heal(dmg: Int) {
		callback(hp.hp);
	}
}

class AlwaysAlive implements IsAliveComponent {
	private var owner: Entity;
	private var value: Bool;

	public function new() {
		value = true;
	}

	public function isAlive(): Bool {
		return value;
	}

	public function kill() {
		value = false;
	}
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

class HpComponent implements IsAliveComponent implements DamageComponent {
	private var health: Health;
	private var owner: Entity;

	public function new(hp: Int) {
		this.health = new Health(hp);
	}

	public function clone(): Component {
		return new HpComponent(health.maxHp);
	}

	public function damage(dmg: Int) {
		health.hp -= dmg;
	}

	public function heal(dmg: Int) {
		health.hp += dmg;
	}

	public function isAlive(): Bool {
		return health.hp > 0;
	}

	public function kill() {
		owner.damage(health.hp);
	}

	public function assignProps(holder: PropertyHolder) {
		holder.health = health;
	}
}
