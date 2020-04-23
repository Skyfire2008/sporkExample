package org.skyfire2008.sporkExample;

import haxe.Json;

import js.Browser;
import js.html.Document;
import js.html.CanvasElement;
import js.html.webgl.RenderingContext;

import org.skyfire2008.sporkExample.util.Util;
import org.skyfire2008.sporkExample.util.Scripts;

class Main {
	private static var gl: RenderingContext;
	private static var document: Document;

	public static function main() {
		Browser.window.addEventListener("load", init);
	}

	private static function init() {
		document = Browser.document;

		gl = cast(document.getElementById("mainCanvas"), CanvasElement).getContextWebGL();
		if (gl == null) {
			Browser.alert("WebGL is not supported!");
		}

		// load assets
		Util.fetchFile("assets/contents.json").then((text) -> {
			var contents: DirContent = Json.parse(text);
			for (dir in contents.kids) {
				if (dir.path == "shapes") {}
			}
		});
	}
}
