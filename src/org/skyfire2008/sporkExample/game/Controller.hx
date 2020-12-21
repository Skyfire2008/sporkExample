package org.skyfire2008.sporkExample.game;

import js.html.EventTarget;
import js.html.KeyboardEvent;
import js.lib.Map;
import js.lib.Set;

import org.skyfire2008.sporkExample.util.Settings;
import org.skyfire2008.sporkExample.game.components.ControlComponent.KBComponent;

typedef KeyBindings = {
	var forward: String;
	var brake: String;
	var left: String;
	var right: String;
	var fire: String;
	var deployTurret: String;
	var deployHeavyTurret: String;
	var teleport: String;
	var pause: String;
};

typedef DownAction = () -> Void;
typedef HeldAction = (Float) -> Void;

class Controller {
	private var heldKeys: Set<String>;

	private var downActions: Map<String, DownAction>;
	private var onceActions: Map<String, DownAction>; // down actions that execute without repeat
	private var upActions: Map<String, DownAction>;
	private var heldActions: Map<String, HeldAction>;

	private var components: Array<KBComponent>;

	public var pauseAction: DownAction;

	private static var inst: Controller;

	private function new(config: KeyBindings) {
		downActions = new Map<String, DownAction>();
		onceActions = new Map<String, DownAction>();
		upActions = new Map<String, DownAction>();
		heldActions = new Map<String, HeldAction>();
		components = [];
		heldKeys = new Set<String>();

		remap(config);
	}

	public static function getInstance(): Controller {
		if (inst == null) {
			inst = new Controller(Settings.getInstance().keyBindings);
		}
		return inst;
	}

	public function reset() {
		components = [];
	}

	public function addComponent(component: KBComponent) {
		components.push(component);
	}

	public function removeComponent(component: KBComponent) {
		components.remove(component);
	}

	public function remap(config: KeyBindings) {
		heldActions.clear();
		heldActions.set(config.brake, (time) -> {
			for (component in components) {
				component.brake(time);
			}
		});
		heldActions.set(config.left, (time) -> {
			for (component in components) {
				component.left(time);
			}
		});
		heldActions.set(config.right, (time) -> {
			for (component in components) {
				component.right(time);
			}
		});

		downActions.clear();
		downActions.set(config.forward, () -> {
			for (component in components) {
				component.startAccelerate();
			}
		});
		downActions.set(config.deployTurret, () -> {
			for (component in components) {
				component.deployTurret();
			}
		});
		downActions.set(config.deployHeavyTurret, () -> {
			for (component in components) {
				component.deployHeavyTurret();
			}
		});
		downActions.set(config.fire, () -> {
			for (component in components) {
				component.startFire();
			}
		});
		downActions.set(config.pause, () -> {
			pauseAction();
		});
		onceActions.set(config.teleport, () -> {
			for (component in components) {
				component.teleport();
			}
		});

		upActions.clear();
		upActions.set(config.forward, () -> {
			for (component in components) {
				component.stopAccelerate();
			}
		});
		upActions.set(config.fire, () -> {
			for (component in components) {
				component.stopFire();
			}
		});
	}

	private function onKeyDown(e: KeyboardEvent) {
		var onceAction = onceActions.get(e.code);
		if (onceAction != null && !heldKeys.has(e.code)) {
			onceAction();
		}

		heldKeys.add(e.code);
		var action = downActions.get(e.code);
		if (action != null) {
			action();
		}
	}

	private function onKeyUp(e: KeyboardEvent) {
		heldKeys.delete(e.code);
		var action = upActions.get(e.code);
		if (action != null) {
			action();
		}
	}

	public function update(time: Float) {
		for (key in heldKeys.iterator()) {
			var action = heldActions.get(key);
			if (action != null) {
				action(time);
			}
		}
	}

	public function register(target: EventTarget) {
		target.addEventListener("keydown", onKeyDown);
		target.addEventListener("keyup", onKeyUp);
	}

	public function deregister(target: EventTarget) {
		target.removeEventListener("keydown", onKeyDown);
		target.removeEventListener("keyup", onKeyUp);
	}
}
