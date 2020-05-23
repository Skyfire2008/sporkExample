package org.skyfire2008.sporkExample.game.components;

import spork.core.Component;

interface DeathComponent extends Component {
	@callback
	function onDeath(): Void;
}
