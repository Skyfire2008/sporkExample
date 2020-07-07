package org.skyfire2008.sporkExample.util;

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
		storage = Browser.getLocalStorage();
		var data = storage.getItem(ItemName);
		if (data == null) {
			this.data = {
				particleCount: 500,
				keyBindings: {
					forward: "KeyW",
					brake: "KeyS",
					left: "KeyA",
					right: "KeyD",
					fire: "Space",
					deployTurret: "KeyF",
					deployAllTurrets: "KeyR",
					pause: "KeyP"
				}
			};
			save();
		} else {
			this.data = Json.parse(data);
		}
	}

	public function save() {
		storage.setItem(ItemName, Json.stringify(data));
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
