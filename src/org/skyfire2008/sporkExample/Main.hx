package org.skyfire2008.sporkExample;

import org.skyfire2008.sporkExample.game.components.Update.AnimComponent;

import haxe.Json;
import haxe.ds.StringMap;

import js.Browser;
import js.lib.Promise;
import js.html.KeyboardEvent;
import js.html.Document;
import js.html.CanvasElement;
import js.html.webgl.RenderingContext;

import spork.core.JsonLoader;
import spork.core.JsonLoader.EntityFactoryMethod;

import org.skyfire2008.sporkExample.graphics.Shape;
import org.skyfire2008.sporkExample.graphics.Renderer;
import org.skyfire2008.sporkExample.util.Util;
import org.skyfire2008.sporkExample.util.Scripts;
import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.game.Spawner;
import org.skyfire2008.sporkExample.game.components.Update.RenderComponent;
import org.skyfire2008.sporkExample.game.properties.Position;
import org.skyfire2008.sporkExample.game.properties.Position.Velocity;

using Lambda;

class Main {
	private static var gl: RenderingContext;
	private static var document: Document;

	private static var renderer: Renderer;
	private static var shapes: StringMap<Shape> = new StringMap<Shape>();
	private static var entFactories: StringMap<EntityFactoryMethod> = new StringMap<EntityFactoryMethod>();

	private static var game: Game;

	private static var prevTime: Float = -1;
	private static var timeStore: Float = 0;
	private static var timeCount: Float = 0;

	public static function main() {
		Browser.window.addEventListener("load", init);
	}

	private static function onEnterFrame(timestamp: Float) {
		var delta = (timestamp - prevTime) / 1000;
		timeStore += delta;
		timeCount++;
		if (timeCount >= 300) {
			trace("fps: " + timeCount / timeStore);
			timeStore = 0;
			timeCount = 0;
		}
		prevTime = timestamp;

		game.update(delta);
		Browser.window.requestAnimationFrame(onEnterFrame);
	}

	private static function onEnterFrameFirst(timestamp: Float) {
		prevTime = timestamp;
		Browser.window.requestAnimationFrame(onEnterFrame);
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
				// when shaders are loaded, set the shapes for render component and init the renderer
				RenderComponent.setShapes(shapes);
				AnimComponent.setShapes(shapes);
				renderer = new Renderer(gl, shaders[0], shaders[1]);
				RenderComponent.setRenderer(renderer);
				AnimComponent.setRenderer(renderer);
				return;
			}));

			Promise.all(loadPromises).then((_) -> {
				// when all shapes and renderer are loaded, load the entities
				var entPromises: Array<Promise<Void>> = [];
				for (ent in entsDir.kids) {
					entPromises.push(Util.fetchFile('assets/entities/${ent.path}').then((file) -> {
						entFactories.set(ent.path, JsonLoader.makeLoader(Json.parse(file)));
						return;
					}));
				}
				// when all entities are loaded, create the game object
				Promise.all(entPromises).then((_) -> {
					game = new Game(renderer);
					Spawner.setup(game, entFactories);

					game.addEntity(entFactories.get("playerShip.json")((holder) -> {
						holder.position = new Position(640, 360, 0);
						holder.velocity = new Velocity(0, 0, 0);
					}));

					for (i in 1...20) {
						game.addEntity(entFactories.get("ufo.json")((holder) -> {
							holder.position = new Position(Math.random() * 1280, Math.random() * 720, 0 /*Math.random() * Math.PI * 2*/);
							holder.velocity = new Velocity(Math.random() * 50, Math.random() * 5, 0 /*, Math.random() * Math.PI * 2*/);
						}));
					}

					Browser.window.requestAnimationFrame(onEnterFrameFirst);
					Browser.window.addEventListener("keydown", (e: KeyboardEvent) -> {
						game.onKeyDown(e.code);
					});
					Browser.window.addEventListener("keyup", (e: KeyboardEvent) -> {
						game.onKeyUp(e.code);
					});
				});

				renderer.start();
				renderer.render(shapes.get("smallAsteroid.json"), 120, 120, 0, 1);
			});
		});
	}
}
