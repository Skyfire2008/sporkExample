package org.skyfire2008.sporkExample.util;

#if macro
import haxe.io.Path;

import sys.io.File;
import sys.FileSystem;

class Macro {
	// I use initialization macros instead of writing scripts
	public static function copyHtml(): Void {
		File.copy("src/index.html", "bin/index.html");
	}

	public static function copyDir(src: String, dst: String): Void {
		for (file in FileSystem.readDirectory(src)) {
			var curSrcPath = Path.join([src, file]);
			var curDstPath = Path.join([dst, file]);

			if (FileSystem.isDirectory(curSrcPath)) {
				if (!FileSystem.exists(curDstPath)) {
					FileSystem.createDirectory(curDstPath);
				}

				copyDir(curSrcPath, curDstPath);
			} else {
				File.copy(curSrcPath, curDstPath);
			}
		}
	}
}
#end
