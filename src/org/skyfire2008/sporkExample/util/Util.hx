package org.skyfire2008.sporkExample.util;

import js.html.XMLHttpRequest;
import js.html.ProgressEvent;
import js.lib.Promise;

class Util {
	public static inline function rand(val: Float): Float {
		return val * (Math.random() - 0.5);
	}

	public static inline function fetchFile(path: String): Promise<String> {
		return new Promise<String>((resolve, reject) -> {
			var xhr = new XMLHttpRequest();
			xhr.addEventListener("load", (e: ProgressEvent) -> {
				resolve(xhr.responseText);
			});
			xhr.addEventListener("error", () -> {
				reject('Could not fetch file $path');
			});
			xhr.open("GET", path);
			xhr.send();
		});
	}
}
