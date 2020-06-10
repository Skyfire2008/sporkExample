package org.skyfire2008.sporkExample.game.components;

import spork.core.Entity;
import spork.core.PropertyHolder;
import spork.core.Component;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.game.Bonus;
import org.skyfire2008.sporkExample.game.components.Update.UpdateComponent;
import org.skyfire2008.sporkExample.game.components.Init.InitComponent;
import org.skyfire2008.sporkExample.spatial.Collider;

@singular
interface BonusComponent extends Component {
	@callback
	function applyBonus(bonus: Bonus): Void;
}

class GetsBonuses implements BonusComponent implements InitComponent implements UpdateComponent {
	private var owner: Entity;
	private var pos: Point;
	private var radius: Float;

	private var bonuses: Array<Bonus>;

	public function new() {
		bonuses = [];
	}

	public function assignProps(holder: PropertyHolder) {
		pos = holder.position;
		radius = holder.colliderRadius;
	}

	public function applyBonus(bonus: Bonus) {
		bonuses.push(bonus);
		bonus.apply(owner);
	}

	public function onUpdate(time: Float) {
		var newBonuses: Array<Bonus> = [];
		for (bonus in bonuses) {
			bonus.update(time);

			if (bonus.isAlive()) {
				newBonuses.push(bonus);
			} else {
				bonus.revert(owner);
			}
		}

		bonuses = newBonuses;
	}

	public function onInit(game: Game) {
		game.addBonusGetter(new Collider(owner, pos, radius));
	}
}
