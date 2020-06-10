package org.skyfire2008.sporkExample.game.components;

import org.skyfire2008.sporkExample.geom.Point;

import spork.core.PropertyHolder;
import spork.core.Component;
import spork.core.Entity;

import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.game.Spawner;
import org.skyfire2008.sporkExample.game.components.Init;
import org.skyfire2008.sporkExample.game.components.Update;

@singular
interface PropsComponent extends Component {
	@callback
	public function getWep(): Spawner;
}

class ExposePlayerWeapon implements PropsComponent {
	private var owner: Entity;
	private var wep: Spawner;

	public function new() {}

	public function getWep(): Spawner {
		return wep;
	}

	public function assignProps(holder: PropertyHolder) {
		wep = holder.wep;
	}
}
