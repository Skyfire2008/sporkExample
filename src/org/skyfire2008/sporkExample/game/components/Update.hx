package org.skyfire2008.sporkExample.game.components;

import spork.core.Component;

interface UpdateComponent extends Component {
	@callback
	function onUpdate(time: Float): Void;
}
