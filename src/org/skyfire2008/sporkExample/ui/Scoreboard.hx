package org.skyfire2008.sporkExample.ui;

import io.newgrounds.NG;
import io.newgrounds.objects.ScoreBoard;

import knockout.Knockout;
import knockout.Observable;
import knockout.DependentObservable;

import org.skyfire2008.sporkExample.util.Util;

typedef Score = {
	var number: Int;
	var score: Int;
	var username: String;
	var iconUrl: String;
}

@:keep
class ViewModel {
	private var scoreboard: ScoreBoard;
	private var pos: Observable<Int> = Knockout.observable(0);
	private var scoreboardLoaded: Observable<Bool> = Knockout.observable(false);
	private var page: Observable<Int>;
	private var pages: Observable<Int> = Knockout.observable(1);
	private var indices: DependentObservable<Array<Int>>;

	private function getScore(index: Int): Score {
		if (index < scoreboard.scores.length) {
			return {
				number: index + 1,
				score: scoreboard.scores[index].value,
				username: scoreboard.scores[index].user.name,
				iconUrl: scoreboard.scores[index].user.icons.small
			};
		} else {
			return {
				number: index + 1,
				score: 0,
				username: "",
				iconUrl: ""
			};
		}
	}

	public function new(scoreboardId: Int) {
		page = Knockout.observable(1);

		indices = Knockout.computed(() -> {
			var validPage = Util.min(Util.max(page.get(), 1), pages.get());

			var offset = 10 * (validPage - 1);
			var result: Array<Int> = [];
			for (i in 0...10) {
				result.push(offset + i);
			}
			return result;
		});

		NG.onCoreReady.add(() -> {
			NG.core.onScoreBoardsLoaded.add(() -> {
				scoreboard = NG.core.scoreBoards.get(scoreboardId);
				scoreboard.onUpdate.add(() -> {
					pages.set(Std.int(scoreboard.scores.length / 10) + 1);
					scoreboardLoaded.set(false);
					scoreboardLoaded.set(true);
				});
			});
		});
	}
}

class Scoreboard {
	public static function register() {
		Knockout.components.register("scoreboard", {
			viewModel: function(params: Dynamic, componentInfo: Dynamic) {
				return new ViewModel(params.id);
			},
			template: "
			<div data-bind='if: scoreboardLoaded' style='overflow-y: auto;'>
				<table>
					<thead>
						<tr>
							<th>Pos.</th>
							<th colspan='2'>User</th>
							<th>Score</th>
						</tr>
					</thead>
					<tbody data-bind='foreach: indices'>
						<tr data-bind='with: $parent.getScore($data)' height='36px'>
							<td data-bind='text: $data.number' style='min-width: 100px'></td>
							<td style='width: 25px'>
								<img data-bind='attr: {src: $data.iconUrl}'></img>
							</td>
							<td data-bind='text: $data.username' style='min-width: 400px'></td>
							<td data-bind='text: $data.score' style='min-width: 100px'></td>
						</tr>
					</tbody>
					<tfoot>
						<tr>
							<td colspan='4'>
								<span>Page:</span>
								<input type='number' min='1' data-bind='value: page, attr: {max: pages}' style='pointer-events: all;'></input>
								/
								<span data-bind='text: pages'></span>
							</td>
						</tr>
					</tfoot>
				</table>
			</div>
			<div data-bind='ifnot: scoreboardLoaded' style='animation-name: preloader; animation-duration: 0.5s; animation-iteration-count: infinite;'>
				Loading scoreboard...
			</div>
			"
		});

		Knockout.applyBindings(null);
	}
}
