package org.skyfire2008.sporkExample.ui;

import io.newgrounds.NG;
import io.newgrounds.objects.ScoreBoard;

import knockout.Knockout;
import knockout.Observable;

@:keep
class ViewModel {
	private var scoreboard: ScoreBoard;
	private var pos: Observable<Int> = Knockout.observable(0);
	private var scoreboardLoaded: Observable<Bool> = Knockout.observable(false);

	public function new(scoreboardId: Int) {
		NG.onCoreReady.add(() -> {
			NG.core.onScoreBoardsLoaded.add(() -> {
				scoreboard = NG.core.scoreBoards.get(scoreboardId);
				scoreboard.onUpdate.add(() -> {
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
					<tbody data-bind='foreach: scoreboard.scores'>
						<tr>
							<td data-bind='text: $index()+1'></td>
							<td>
								<img data-bind='attr: {src: $data.user.icons.small}'></img>
							</td>
							<td data-bind='text: $data.user.name'></td>
							<td data-bind='text: $data.value'></td>
						</tr>
					</tbody>
				</table>
			</div>
			"
		});

		Knockout.applyBindings(null);
	}
}
