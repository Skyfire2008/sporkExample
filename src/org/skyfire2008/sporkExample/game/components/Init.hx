package org.skyfire2008.sporkExample.game.components;

interface InitComponent extends spork.core.Component {
	@callback
	function onInit(game: Game): Void;
}
