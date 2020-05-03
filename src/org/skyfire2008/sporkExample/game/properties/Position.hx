package org.skyfire2008.sporkExample.game.properties;

import nape.phys.Body;

import spork.core.PropertyHolder;

interface Position extends spork.core.SharedProperty {
	public var x(get, set): Float;
	public var y(get, set): Float;
	public var rotation(get, set): Float;
}

@noField
class BasicPosition implements Position {
	public var x(get, set): Float;
	public var y(get, set): Float;
	public var rotation(get, set): Float;

	private var _x: Float;
	private var _y: Float;
	private var _rotation: Float;

	public function new(x: Float, y: Float, rotation: Float) {
		_x = x;
		_y = y;
		_rotation = rotation;
	}

	public function attach(holder: PropertyHolder) {
		holder.position = this;
	}

	private inline function get_x(): Float {
		return _x;
	}

	private inline function set_x(_x: Float): Float {
		this._x = _x;
		return this._x;
	}

	private inline function get_y(): Float {
		return _y;
	}

	private inline function set_y(_y: Float): Float {
		this._y = _y;
		return this._y;
	}

	private inline function get_rotation(): Float {
		return _rotation;
	}

	private inline function set_rotation(_rotation: Float): Float {
		this._rotation = _rotation;
		return this._rotation;
	}
}

@noField
class BodyPosition implements Position {
	public var x(get, set): Float;
	public var y(get, set): Float;
	public var rotation(get, set): Float;

	private var body: Body;

	public function new(body: Body) {
		this.body = body;
	}

	public function attach(holder: PropertyHolder) {
		holder.position = this;
	}

	private inline function get_x(): Float {
		return body.position.x;
	}

	private inline function set_x(_x: Float): Float {
		body.position.x = _x;
		return body.position.x;
	}

	private inline function get_y(): Float {
		return body.position.y;
	}

	private inline function set_y(_y: Float): Float {
		body.position.y = _y;
		return body.position.y;
	}

	private inline function get_rotation(): Float {
		return body.rotation;
	}

	private inline function set_rotation(_rotation: Float): Float {
		body.rotation = _rotation;
		return body.rotation;
	}
}
