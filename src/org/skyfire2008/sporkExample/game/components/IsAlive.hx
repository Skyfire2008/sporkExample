package org.skyfire2008.sporkExample.game.components;

import spork.core.PropertyHolder;
import spork.core.Component;
import spork.core.Entity;
import spork.core.Wrapper;

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
	private var maxTime: Float;
	private var timeToLive: Wrapper<Float>;
	private var owner: Entity;

	public function new(time: Float) {
		this.maxTime = time;
		this.timeToLive = new Wrapper<Float>(time);
	}

	public function clone() {
		return new TimedComponent(maxTime);
	}

	public function isAlive(): Bool {
		return timeToLive.value > 0;
	}

	public function kill() {
		timeToLive.value = 0;
	}

	public function onUpdate(time: Float) {
		this.timeToLive.value -= time;
	}

	public function createProps(holder: PropertyHolder) {
		holder.timeToLive = this.timeToLive;
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
		if (health.hp > health.maxHp) {
			health.hp = health.maxHp;
		}
	}

	public function isAlive(): Bool {
		return health.hp > 0;
	}

	public function kill() {
		owner.damage(health.hp);
	}

	public function createProps(holder: PropertyHolder) {
		holder.health = health;
	}
}
