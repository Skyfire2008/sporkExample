package org.skyfire2008.sporkExample;

import org.skyfire2008.sporkExample.util.Util;

class Main {
	public static function main() {
		Util.fetchFile("assets/shapes/temp.json").then((text) -> {
			trace(text);
		});
	}
}
