package org.skyfire2008.sporkExample.game;

import nape.space.Space;

import org.skyfire2008.sporkExample.graphics.Renderer;

class Game {
	private var renderer: Renderer;
	private var space: Space;

	public function new(renderer: Renderer, space: Space) {
		this.renderer = renderer;
		this.space = space;
	}
}
