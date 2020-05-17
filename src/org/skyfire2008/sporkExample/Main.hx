package org.skyfire2008.sporkExample;

import haxe.Json;
import haxe.ds.StringMap;

import js.Browser;
import js.lib.Promise;
import js.html.Document;
import js.html.CanvasElement;
import js.html.webgl.RenderingContext;

import spork.core.JsonLoader;

import org.skyfire2008.sporkExample.graphics.Shape;
import org.skyfire2008.sporkExample.graphics.Renderer;
import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.util.Util;
import org.skyfire2008.sporkExample.util.Scripts;

using Lambda;

class Main {
	private static var gl: RenderingContext;
	private static var document: Document;

	private static var renderer: Renderer;
	private static var shapes: StringMap<Shape> = new StringMap<Shape>();

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
		var loadPromises: Array<Promise<Void>> = [];
		Util.fetchFile("assets/contents.json").then((text) -> {
			var contents: Array<DirContent> = Json.parse(text);

			var shapesDir = contents.find((item) -> {
				return item.path == "shapes";
			});

			var entsDir = contents.find((item) -> {
				return item.path == "entities";
			});

			for (kid in shapesDir.kids) { // load every shape
				loadPromises.push(Util.fetchFile('assets/shapes/${kid.path}').then((file) -> {
					trace('loaded ${kid.path}');
					var shape = Shape.fromJson(Json.parse(file));
					shape.init(gl);
					shapes.set(kid.path, shape);
					return;
				}));
			}

			var rendererPromises = [
				Util.fetchFile("assets/shaders/basic.vert"),
				Util.fetchFile("assets/shaders/basic.frag")
			];
			loadPromises.push(Promise.all(rendererPromises).then((shaders) -> { // load shaders
				renderer = new Renderer(gl, shaders[0], shaders[1]);
				return;
			}));

			Promise.all(loadPromises).then((_) -> {
				trace("all loaded!");
				renderer.start();
				renderer.clear();
				trace(shapes);
				renderer.render(shapes.get("brick.json"), 120, 120, 0, 1);
			});
		});
	}
}
