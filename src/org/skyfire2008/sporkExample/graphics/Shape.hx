package org.skyfire2008.sporkExample.graphics;

import js.lib.Float32Array;
import js.lib.Int32Array;
import js.html.webgl.RenderingContext;
import js.html.webgl.VertexArrayObject;
import js.html.webgl.Buffer;
import js.html.webgl.GL;

// copied from TDS
class Shape {
	private var positions: Float32Array;
	private var colors: Float32Array;
	private var indices: Int32Array;

	private var vertNum: Int;
	public var indexNum(default, null): Int;

	public var vao(default, null): VertexArrayObject;
	private var posVbo: Buffer;
	private var colorVbo: Buffer;
	private var indexVbo: Buffer;

	public function new(positions: Array<Float>, colors: Array<Float>, indices: Array<Int>) {
		this.positions = new Float32Array(positions);
		this.colors = new Float32Array(colors);
		this.indices = new Int32Array(indices);

		this.vertNum = positions.length >> 1;
		this.indexNum = indices.length;
	}

	public function init(gl: RenderingContext) {
		var ext = gl.getExtension("OES_vertex_array_object");

		// create VAO
		vao = ext.createVertexArrayOES();
		ext.bindVertexArrayOES(vao);

		// create positions VBO
		posVbo = gl.createBuffer();
		gl.bindBuffer(GL.ARRAY_BUFFER, posVbo);
		gl.bufferData(GL.ARRAY_BUFFER, positions, GL.STATIC_DRAW);
		gl.enableVertexAttribArray(0);
		gl.vertexAttribPointer(0, 2, GL.FLOAT, false, 0, 0);

		// create colors VBO
		colorVbo = gl.createBuffer();
		gl.bindBuffer(GL.ARRAY_BUFFER, colorVbo);
		gl.bufferData(GL.ARRAY_BUFFER, colors, GL.STATIC_DRAW);
		gl.enableVertexAttribArray(1);
		gl.vertexAttribPointer(1, 3, GL.FLOAT, false, 0, 0);

		// create index VBO
		indexVbo = gl.createBuffer();
		gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexVbo);
		gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, indices, GL.STATIC_DRAW);

		// unbind
		// ext.bindVertexArrayOES(null);
		// gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
	}
}
