package org.skyfire2008.sporkExample.game;

class ScoringSystem {
	public static var instance(default, null): ScoringSystem;

	public var score(default, null): Int;
	public var mult(default, null): Int;
	public var maxMult(default, null): Int;
	public var nextMultPoints(default, null): Float;
	public var multPoints(default, null): Float;

	private var scoreCallback: (Int) -> Void;
	private var multCallback: (Int) -> Void;
	private var multDecayTime(default, null): Float;
	private var running: Bool = true;

	public static function init(scoreCallback: (Int) -> Void, multCallback: (Int) -> Void, multDecayTime: Float) {
		ScoringSystem.instance = new ScoringSystem(scoreCallback, multCallback, multDecayTime);
	}

	private function new(scoreCallback: (Int) -> Void, multCallback: (Int) -> Void, multDecayTime) {
		this.scoreCallback = scoreCallback;
		this.multCallback = multCallback;
		this.multDecayTime = multDecayTime;
		score = 0;
		mult = 1;
		maxMult = 1;
		multPoints = 0;
		nextMultPoints = calcNextMultPoints(mult);
	}

	public function update(time: Float) {
		if (running) {
			multPoints -= time / multDecayTime * nextMultPoints;
			if (multPoints < 0) {
				mult--;
				if (mult < 1) {
					mult = 1;
				}
				nextMultPoints = calcNextMultPoints(mult);
				multPoints += nextMultPoints;

				multCallback(mult);
			}
		}
	}

	public function addScore(extraScore: Int) {
		if (running) {
			score += extraScore * mult;
			multPoints += extraScore;
			while (multPoints > nextMultPoints) {
				multPoints -= nextMultPoints;
				mult++;
				if (mult > maxMult) {
					maxMult = mult;
				}
				multCallback(mult);
				nextMultPoints = calcNextMultPoints(mult);
			}
			scoreCallback(score);
		}
	}

	public function resetMult() {
		mult = 1;
		multPoints = 0;
		nextMultPoints = calcNextMultPoints(mult);
		multCallback(mult);
	}

	public function reset() {
		resetMult();
		maxMult = 1;
		score = 0;
		running = true;
		multCallback(mult);
		scoreCallback(score);
	}

	public function freeze() {
		running = false;
	}

	private static function calcNextMultPoints(mult: Int): Float {
		return 2 * mult;
	}
}
