package org.skyfire2008.sporkExample.util;

import js.lib.Object;

import haxe.Json;

import js.Browser;
import js.html.Storage;

import org.skyfire2008.sporkExample.game.Controller.KeyBindings;

typedef SettingsData = {
	var particleCount: Int;
	var keyBindings: KeyBindings;
}

class Settings {
	private static inline final ItemName = "spork_asteroids_settings";
	private static var inst: Settings = null;

	private var storage: Storage;
	private var data: SettingsData;

	public var keyBindings(get, set): KeyBindings;
	public var particleCount(get, set): Int;

	public static function getInstance(): Settings {
		if (inst == null) {
			inst = new Settings();
		}
		return inst;
	}

	private function new() {
		var data = null;
		storage = null;

		try {
			storage = Browser.getLocalStorage();
			data = storage.getItem(ItemName);
		} catch (e) {
			trace("Could not get local storage, exception: " + e);
		}

		this.data = {
			particleCount: 500,
			keyBindings: {
				forward: "KeyW",
				brake: "KeyS",
				left: "KeyA",
				right: "KeyD",
				fire: "KeyJ",
				deployTurret: "KeyK",
				deployHeavyTurret: "KeyL",
				teleport: "KeyI",
				pause: "KeyP"
			}
		};

		if (data != null) {
			var parsedData = Json.parse(data);
			this.data.keyBindings = Object.assign(this.data.keyBindings, parsedData.keyBindings);
			this.data.particleCount = parsedData.particleCount != null ? parsedData.particleCount : this.data.particleCount;
		} else {
			save();
		}
	}

	public function save() {
		if (storage != null) {
			storage.setItem(ItemName, Json.stringify(data));
		}
	}

	// GETTERS AND SETTERS
	private function get_keyBindings(): KeyBindings {
		return data.keyBindings;
	}

	private function set_keyBindings(keyBindings: KeyBindings): KeyBindings {
		data.keyBindings = keyBindings;
		return data.keyBindings;
	}

	private function get_particleCount(): Int {
		return data.particleCount;
	}

	private function set_particleCount(particleCount: Int): Int {
		if (particleCount < 0) {
			particleCount = 0;
		}
		data.particleCount = particleCount;
		return data.particleCount;
	}
}
