package org.skyfire2008.sporkExample.game.components;

import spork.core.Entity;
import spork.core.PropertyHolder;

import org.skyfire2008.sporkExample.spatial.Collider;
import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.game.Side;
import org.skyfire2008.sporkExample.game.properties.Position;

interface InitComponent extends spork.core.Component {
	@callback
	function onInit(game: Game): Void;
}

class CollisionComponent implements InitComponent {
	private var owner: Entity;

	private var pos: Position;

	public var radius(default, null): Float;
	public var side(default, null): Side;

	public static function fromJson(json: Dynamic) {
		var side: Side = null;
		switch (json.side) {
			case "Player":
				side = Player;
			case "Enemy":
				side = Enemy;
			default:
				throw 'Unknown side ${json.side}';
		}
		return new CollisionComponent(json.radius, side);
	}

	public function new(radius: Float, side: Side) {
		this.radius = radius;
		this.side = side;
	}

	public function assignProps(holder: PropertyHolder) {
		this.pos = holder.position;
	}

	public function onInit(game: Game) {
		game.addCollider(new Collider(this.owner, pos, radius), side);
	}
}
