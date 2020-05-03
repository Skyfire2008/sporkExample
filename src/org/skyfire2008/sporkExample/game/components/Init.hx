package org.skyfire2008.sporkExample.game.components;

import org.skyfire2008.sporkExample.game.Game;

interface InitComponent extends spork.core.Component {
	@callback
	function onInit(game: Game): Void;
}
