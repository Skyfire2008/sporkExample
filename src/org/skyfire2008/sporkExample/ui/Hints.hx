package org.skyfire2008.sporkExample.ui;

import knockout.Knockout;
import knockout.Observable;
import knockout.ObservableArray;

import org.skyfire2008.sporkExample.util.Util;

@:keep
class HintsViewModel {
	public var hints: ObservableArray<String>;
	public var hintNum: Observable<Int>;

	public function new(fileName: String) {
		hints = Knockout.observableArray([]);

		Util.fetchFile(fileName).then((result) -> {
			var loadedHints = result.split("\n");
			hints.set(loadedHints);
			hintNum.set(Std.random(loadedHints.length));
		});

		hintNum = Knockout.observable(0);
	}

	public function incHintNum() {
		if (hintNum.get() < hints.get().length - 1) {
			hintNum.set(hintNum.get() + 1);
		}
	}

	public function decHintNum() {
		if (hintNum.get() > 0) {
			hintNum.set(hintNum.get() - 1);
		}
	}
}

class Hints {
	public static function register() {
		Knockout.components.register("hints", {
			viewModel: function(params: Dynamic, componentInfo: Dynamic) {
				return new HintsViewModel(params.fileName);
			},
			template: "
				<div data-bind='if: hints().length>0'>
					<div>Hint:</div>
					<div style='width: 900px; min-height: 50px; ' data-bind='text: hints()[hintNum()]'></div>
					<div style='display: flex;'>
						<button data-bind='click: decHintNum, disable: hintNum()<=0'><<</button>
						<div style='width: 30px; text-align: center;' data-bind='text: hintNum()'></div>
						<button data-bind='click: incHintNum, disable: hintNum()>=hints().length-1'>>></button>
					</div>
				</div>
			"
		});
	}
}
