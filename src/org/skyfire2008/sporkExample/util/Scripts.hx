package org.skyfire2008.sporkExample.util;

#if macro
import spork.core.EntityDef;
import spork.core.EntityDef.ComponentDef;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.io.Path;
import StringBuf;
import sys.io.File;
import sys.FileSystem;
#end

typedef DirContent = {
	path:String,
	kids:Array<DirContent>
};

#if macro
class Scripts {
	// used to convert entites' json files to new format
	public static function changeEntities(src:String):Void {
		for (file in FileSystem.readDirectory(src)) {
			var path = Path.join([src, file]);
			var readFp = File.read(path, false);

			var buf:StringBuf = new StringBuf();
			while (!readFp.eof()) {
				buf.add(readFp.readLine());
			}
			readFp.close();

			var json:Dynamic = Json.parse(buf.toString());
			var components:DynamicAccess<Dynamic> = json.components;
			var newComponents:Array<ComponentDef> = [];
			for (compoName in components.keys()) {
				newComponents.push({name: compoName, params: components.get(compoName)});
			}
			json.components = newComponents;

			var writeFp = File.write(path, false);
			writeFp.writeString(Json.stringify(json, null, "	"));
			writeFp.flush();
			writeFp.close();
		}
	}

	// I use initialization macros instead of writing scripts
	public static function copyDir(src:String, dst:String):Void {
		if (!FileSystem.exists(dst)) {
			FileSystem.createDirectory(dst);
		}

		for (file in FileSystem.readDirectory(src)) {
			var curSrcPath = Path.join([src, file]);
			var curDstPath = Path.join([dst, file]);

			if (FileSystem.isDirectory(curSrcPath)) {
				copyDir(curSrcPath, curDstPath);
			} else {
				File.copy(curSrcPath, curDstPath);
			}
		}
	}

	private static function getContent(parent:String, path:String):DirContent {
		var result:DirContent = {
			path: path,
			kids: []
		};
		var parentPath = Path.join([parent, path]);

		for (file in FileSystem.readDirectory(parentPath)) {
			if (FileSystem.isDirectory(Path.join([parentPath, file]))) {
				result.kids.push(getContent(parentPath, file));
			} else {
				result.kids.push({path: file, kids: null});
			}
		}

		return result;
	}

	public static function createContentsJson(path:String):Void {
		var contents:Array<DirContent> = [];

		for (file in FileSystem.readDirectory(path)) {
			if (FileSystem.isDirectory(Path.join([path, file]))) {
				contents.push(getContent(path, file));
			} else {
				contents.push({path: file, kids: null});
			}
		}

		var output = File.write(Path.join([path, "contents.json"]), false);
		output.writeString(Json.stringify(contents, "   "));
		output.close();
	}
}
#end
