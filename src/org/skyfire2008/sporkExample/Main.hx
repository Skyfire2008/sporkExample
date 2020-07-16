package org.skyfire2008.sporkExample;

import haxe.DynamicAccess;
import haxe.Json;
import haxe.ds.StringMap;

import js.Browser;
import js.lib.Promise;
import js.html.Element;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.Document;
import js.html.CanvasElement;
import js.html.TableElement;
import js.html.InputElement;
import js.html.Event;
import js.html.webgl.RenderingContext;

import spork.core.Entity;
import spork.core.JsonLoader;
import spork.core.JsonLoader.EntityFactoryMethod;
import spork.core.Wrapper;

import org.skyfire2008.sporkExample.geom.Point;
import org.skyfire2008.sporkExample.graphics.Shape;
import org.skyfire2008.sporkExample.graphics.Renderer;
import org.skyfire2008.sporkExample.util.Util;
import org.skyfire2008.sporkExample.util.Scripts;
import org.skyfire2008.sporkExample.util.Settings;
import org.skyfire2008.sporkExample.game.Game;
import org.skyfire2008.sporkExample.game.Spawner;
import org.skyfire2008.sporkExample.game.Controller;
import org.skyfire2008.sporkExample.game.ScoringSystem;
import org.skyfire2008.sporkExample.game.Bonus.TurretBonus;
import org.skyfire2008.sporkExample.game.components.Update.RenderComponent;
import org.skyfire2008.sporkExample.game.components.Update.AnimComponent;
import org.skyfire2008.sporkExample.game.components.Death.DropsBonusComponent;
import org.skyfire2008.sporkExample.game.components.Death.CountedOnScreen;

using Lambda;

class Main {
	private static var gl: RenderingContext;
	private static var document: Document;

	private static var playerHpDisplay: Element;
	private static var waveDisplay: Element;
	private static var turretDisplay: Element;
	private static var preloader: Element;
	private static var content: Element;
	private static var pauseStuff: Element;
	private static var keyBindingTable: Element;
	private static var scoreDisplay: Element;
	private static var multDisplay: Element;
	private static var bgParticleCount: InputElement;

	private static var bgParticles: Array<Entity> = [];
	private static var bgParticleCreator: EntityFactoryMethod;

	private static var renderer: Renderer;
	private static var shapes: StringMap<Shape> = new StringMap<Shape>();
	private static var entFactories: StringMap<EntityFactoryMethod> = new StringMap<EntityFactoryMethod>();

	private static var game: Game;
	private static var running: Bool = true;

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

		if (running) {
			Controller.getInstance().update(delta);
			game.update(delta);
		}
		Browser.window.requestAnimationFrame(onEnterFrame);
	}

	private static function onEnterFrameFirst(timestamp: Float) {
		prevTime = timestamp;
		Browser.window.requestAnimationFrame(onEnterFrame);
	}

	private static function init() {
		document = Browser.document;

		// get HTML elements
		playerHpDisplay = document.getElementById("playerHpDisplay");
		waveDisplay = document.getElementById("waveDisplay");
		turretDisplay = document.getElementById("turretDisplay");
		content = document.getElementById("content");
		preloader = document.getElementById("preloader");
		pauseStuff = document.getElementById("pauseStuff");
		keyBindingTable = document.getElementById("keyBindingTable");
		scoreDisplay = document.getElementById("scoreDisplay");
		multDisplay = document.getElementById("multDisplay");
		bgParticleCount = cast(document.getElementById("bgParticleCount"));
		bgParticleCount.addEventListener("change", (e: Dynamic) -> {
			var number: Int = e.target.value >= 0 ? e.target.value : 0;
			if (number > bgParticles.length) {
				for (i in bgParticles.length...number) {
					var ent=bgParticleCreator((holder) -> {});
					game.addEntity(ent);
					bgParticles.push(ent);
				}
			}else{
				for(i in number...bgParticles.length){
					bgParticles[i].kill();
				}
				bgParticles.resize(number);
			}
		});

		ScoringSystem.init((score) -> {
			scoreDisplay.innerText = "" + score;
		}, (mult) -> {
				multDisplay.innerText = "x" + mult;
			}, 4);

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
					game = new Game(renderer, entFactories, (value) -> {
						playerHpDisplay.innerText = "" + value;
					}, (value) -> {
							waveDisplay.innerText = "" + value;
						}, (value) -> {
							turretDisplay.innerText = "" + value;
						});
					Spawner.setup(game, entFactories);
					DropsBonusComponent.setup(game, [
						entFactories.get("doubleFirerateBonus.json"),
						entFactories.get("explodeShotBonus.json"),
						entFactories.get("tripleShotBonus.json"),
						entFactories.get("turretBonus.json"),
						entFactories.get("hpBonus.json")
					], [2, 3, 5, 5, 4]);
					TurretBonus.setup(game);

					// add bg particles
					bgParticleCreator = entFactories.get("bgParticle.json");
					for (i in 0...1000) {
						var ent = bgParticleCreator((holder) -> {});
						bgParticles.push(ent);
						game.addEntity(ent);
					}

					game.addEntity(entFactories.get("playerShip.json")((holder) -> {
						holder.position = new Point(640, 360);
						holder.rotation = new Wrapper<Float>(0);
						holder.velocity = new Point(0, 0);
						holder.angVel = new Wrapper<Float>(0);
					}));

					Browser.window.requestAnimationFrame(onEnterFrameFirst);
					var controller = Controller.getInstance();
					controller.pauseAction = () -> {
						running = !running;
						pauseStuff.style.display = running ? "none" : "inline";
					};
					controller.register(Browser.window);

					// set up the key bindings table
					var settings = Settings.getInstance();
					var bindings: DynamicAccess<String> = cast(settings.keyBindings);
					for (key in bindings.keys()) {
						var value = bindings.get(key);
						var tr = document.createElement("tr");

						var name = document.createElement("td");
						name.innerText = key + ":";
						tr.appendChild(name);

						var binding = document.createElement("button");
						binding.innerText = value;

						// when the button with key binding is clicked...
						binding.addEventListener("mousedown", (e: MouseEvent) -> {
							// start animation
							binding.style.animationName = "bindingKey";
							binding.style.animationDuration = "0.5s";
							binding.style.animationIterationCount = "infinite";

							// deregister the controller
							controller.deregister(Browser.window);

							// listen for the key press
							var listener: (ev: KeyboardEvent) -> Void = null;
							listener = (ev: KeyboardEvent) -> {
								// on key press, update html element
								ev.stopPropagation();
								bindings.set(key, ev.code);
								binding.innerText = ev.code;

								// remap and register the controller
								controller.remap(settings.keyBindings);
								controller.register(Browser.window);

								// remove the listener
								document.removeEventListener("keydown", listener);
								binding.style.animationName = "";
							};
							document.addEventListener("keydown", listener);
						});
						tr.appendChild(binding);

						keyBindingTable.appendChild(tr);
					}

					// hide preloader and show content
					preloader.style.display = "none";
					content.style.display = "inline";
				});

				renderer.start();
				renderer.render(shapes.get("smallAsteroid.json"), 120, 120, 0, 1);
			});
		});
	}
}
