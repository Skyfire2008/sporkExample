package org.skyfire2008.sporkExample.spatial;

import haxe.ds.Vector;

import de.polygonal.ds.HashSet;
import de.polygonal.ds.Sll;
import de.polygonal.ds.IntHashSet;

import org.skyfire2008.sporkExample.geom.Rectangle;
import org.skyfire2008.sporkExample.geom.Circle;

using Lambda;

/**
 * ...
 * @author
 */
class UniformGrid {
	private var cells: Vector<List<Circle>>;
	private var dirtyCells: IntHashSet;

	public var width(default, null): Int;
	public var height(default, null): Int;
	public var cellWidth(default, null): Int;
	public var cellHeight(default, null): Int;

	public function new(width: Int, height: Int, cellWidth: Int, cellHeight: Int) {
		this.width = width;
		this.height = height;
		this.cellWidth = cellWidth;
		this.cellHeight = cellHeight;

		this.cells = new Vector<List<Circle>>(width * height);
		for (i in 0...width * height) {
			this.cells.set(i, new List<Circle>());
		}

		this.dirtyCells = new IntHashSet(43);
	}

	public function add(elem: Circle): Void {
		var rect = elem.rect();

		var startX: Int = Std.int(rect.x / cellWidth);
		startX = startX < 0 ? 0 : startX;

		var startY: Int = Std.int(rect.y / cellHeight);
		startY = startY < 0 ? 0 : startY;

		var endX: Int = Std.int(rect.right / cellWidth);
		endX = endX > width - 1 ? width - 1 : endX;
		endX++;

		var endY: Int = Std.int(rect.bottom / cellHeight);
		endY = endY > height - 1 ? height - 1 : endY;
		endY++;

		for (x in startX...endX) {
			for (y in startY...endY) {
				var ind = cellIndex(x, y);
				cells[ind].add(elem);
				dirtyCells.set(ind);
			}
		}
	}

	public function queryRect(rect: Rectangle): List<Circle> {
		var startX: Int = Std.int(rect.x / cellWidth);
		startX = startX < 0 ? 0 : startX;

		var startY: Int = Std.int(rect.y / cellHeight);
		startY = startY < 0 ? 0 : startY;

		var endX: Int = Std.int(rect.right / cellWidth);
		endX = endX > width - 1 ? width - 1 : endX;
		endX++;

		var endY: Int = Std.int(rect.bottom / cellHeight);
		endY = endY > height - 1 ? height - 1 : endY;
		endY++;

		var res: HashSet<Circle> = new HashSet<Circle>(17, 17);
		for (x in startX...endX) {
			for (y in startY...endY) {
				var ind = cellIndex(x, y);

				cells[ind].iter(function(elem: Circle) {
					if (rect.intersects(elem.rect())) {
						res.set(elem);
					}
				});
			}
		}

		return res.list();
	}

	public function reset(): Void {
		for (i in dirtyCells) {
			cells[i] = new List<Circle>();
		}
		dirtyCells.clear();
	}

	private inline function cellIndex(x: Int, y: Int): Int {
		return x + y * width;
	}
}
