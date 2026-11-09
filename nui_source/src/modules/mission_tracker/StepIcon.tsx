import type { MissionStepState } from "./types";

const StepIcon = ({ state }: { state: MissionStepState }) => (
	<span className={`mission-step-node state-${state}`}>
		{state === "done" && (
			<svg viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
				<path d="M2.6 6.3 5 8.6 9.4 3.6" />
			</svg>
		)}
		{state === "failed" && (
			<svg viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
				<path d="M3.4 3.4 8.6 8.6M8.6 3.4 3.4 8.6" />
			</svg>
		)}
	</span>
);

export default StepIcon;
