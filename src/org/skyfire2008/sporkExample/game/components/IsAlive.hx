package org.skyfire2008.sporkExample.game.components;

import spork.core.Component;
import spork.core.Entity;

@singular
interface IsAliveComponent extends Component {
	@callback
	function isAlive(): Bool;
}

class HpComponent implements IsAliveComponent {
	private var hp: Float;
	private var owner: Entity;

	public function new(hp: Float) {
		this.hp = hp;
	}

	public function isAlive(): Bool {
		return hp > 0;
	}

	public function attach(e: Entity) {
		e.isAliveComponent = this;
		owner = e;
	}
}
