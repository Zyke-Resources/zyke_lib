import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Indicator from "./Indicator";

interface SkillCheckDifficulty {
	areaSize: number;
	speedMultiplier: number;
}

export interface SkillCheckRequest {
	difficulty: SkillCheckDifficulty | SkillCheckDifficulty[];
	inputs?: string[];
}

interface SkillCheckStage extends SkillCheckDifficulty {
	arcStart: number;
	key: string;
}

interface SkillCheckProps {
	request: SkillCheckRequest;
	onComplete: (success: boolean) => void;
}

const circleRadius = 45;
const circleCenter = 50;
const circleCircumference = 2 * Math.PI * circleRadius;
const fallbackDifficulty: SkillCheckDifficulty = { areaSize: 50, speedMultiplier: 1 };

const clamp = (value: number, min: number, max: number) =>
	Math.min(max, Math.max(min, value));

const getStages = (difficulty: SkillCheckRequest["difficulty"]) =>
	Array.isArray(difficulty) ? difficulty : [difficulty];

const normalizeKey = (key: string) => {
	const normalizedKey = key.trim().toLowerCase();
	if (normalizedKey === "space" || normalizedKey === "spacebar") return " ";
	if (normalizedKey === "esc") return "escape";

	return normalizedKey;
};

const getInputs = (inputs: SkillCheckRequest["inputs"]) =>
	inputs?.filter((input) => typeof input === "string" && input.trim() !== "").map(normalizeKey) || ["e"];

const createStage = (difficulty: SkillCheckDifficulty, inputs: string[]): SkillCheckStage => {
	const key = inputs[Math.floor(Math.random() * inputs.length)] || "e";
	const areaSize = clamp(Number.isFinite(difficulty.areaSize) ? difficulty.areaSize : fallbackDifficulty.areaSize, 5, 120);
	const earliestArcStart = 180;
	const latestArcStart = 360 - areaSize;
	const arcStart = earliestArcStart + Math.random() * (latestArcStart - earliestArcStart);

	return {
		areaSize,
		speedMultiplier: clamp(Number.isFinite(difficulty.speedMultiplier) ? difficulty.speedMultiplier : fallbackDifficulty.speedMultiplier, 0.25, 6),
		arcStart,
		key,
	};
};

const isAngleInArc = (angle: number, arcStart: number, areaSize: number) => {
	if (areaSize >= 360) return true;

	const normalizedAngle = ((angle % 360) + 360) % 360;
	const arcEnd = (arcStart + areaSize) % 360;

	if (arcEnd >= arcStart) return normalizedAngle >= arcStart && normalizedAngle <= arcEnd;

	return normalizedAngle >= arcStart || normalizedAngle <= arcEnd;
};

const displayKey = (key: string) => {
	if (key === " ") return "SPACE";
	if (key.length === 1) return key.toUpperCase();

	return key;
};

const SkillCheck = ({ request, onComplete }: SkillCheckProps) => {
	const stages = useMemo(() => getStages(request.difficulty), [request]);
	const inputs = useMemo(() => getInputs(request.inputs), [request]);
	const [stageIndex, setStageIndex] = useState(0);
	const [stage, setStage] = useState(() => createStage(stages[0] || fallbackDifficulty, inputs));
	const [angle, setAngle] = useState(0);
	const angleRef = useRef(0);
	const frameRef = useRef(0);
	const hasResolvedRef = useRef(false);
	const skillArcLength = (circleCircumference * stage.areaSize) / 360;

	useEffect(() => {
		setStageIndex(0);
		setStage(createStage(stages[0] || fallbackDifficulty, inputs));
	}, [stages, inputs]);

	const resolve = useCallback((success: boolean) => {
		if (hasResolvedRef.current) return;

		hasResolvedRef.current = true;
		window.cancelAnimationFrame(frameRef.current);
		onComplete(success);
	}, [onComplete]);

	useEffect(() => {
		let startedAt = 0;
		const duration = Math.max(350, 2100 / stage.speedMultiplier);
		hasResolvedRef.current = false;
		angleRef.current = 0;
		setAngle(0);

		const tick = (timestamp: number) => {
			if (hasResolvedRef.current) return;
			if (!startedAt) startedAt = timestamp;

			const progress = (timestamp - startedAt) / duration;
			if (progress >= 1) {
				angleRef.current = 360;
				setAngle(360);
				resolve(false);
				return;
			}

			const nextAngle = progress * 360;
			angleRef.current = nextAngle;
			setAngle(nextAngle);
			frameRef.current = window.requestAnimationFrame(tick);
		};

		frameRef.current = window.requestAnimationFrame(tick);

		return () => window.cancelAnimationFrame(frameRef.current);
	}, [resolve, stage]);

	const advance = useCallback(() => {
		const nextIndex = stageIndex + 1;
		if (nextIndex >= stages.length) {
			resolve(true);
			return;
		}

		setStageIndex(nextIndex);
		setStage(createStage(stages[nextIndex], inputs));
	}, [inputs, resolve, stageIndex, stages]);

	useEffect(() => {
		const handleKeyDown = (event: KeyboardEvent) => {
			if (event.repeat) return;

			event.preventDefault();
			const pressedKey = event.key.toLowerCase();
			if (pressedKey !== stage.key) {
				resolve(false);
				return;
			}

			if (!isAngleInArc(angleRef.current, stage.arcStart, stage.areaSize)) {
				resolve(false);
				return;
			}

			advance();
		};

		window.addEventListener("keydown", handleKeyDown);

		return () => window.removeEventListener("keydown", handleKeyDown);
	}, [advance, resolve, stage]);

	return (
		<div className="skill-check-root">
			<div className="skill-check-ring">
				<svg className="skill-check-ring-svg" viewBox="0 0 100 100" aria-hidden>
					<circle
						className="skill-check-ring-track"
						cx={circleCenter}
						cy={circleCenter}
						r={circleRadius}
					/>
					<circle
						className="skill-check-ring-area"
						cx={circleCenter}
						cy={circleCenter}
						r={circleRadius}
						strokeDasharray={`${skillArcLength} ${circleCircumference}`}
						style={{ transform: `rotate(${stage.arcStart - 90}deg)` }}
					/>
				</svg>
				<div className="skill-check-ring-inner">
					<Indicator angle={angle} />
					<div className="skill-check-key">
						<kbd>{displayKey(stage.key)}</kbd>
					</div>
				</div>
			</div>
		</div>
	);
};

export default SkillCheck;
