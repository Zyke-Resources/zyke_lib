import StepIcon from "./StepIcon";
import type { MissionStep } from "./types";

// The node column carries a line down to the next step, the detail line only shows while the step is not done
const StepList = ({ steps }: { steps: MissionStep[] }) => (
	<ol className="mission-steps">
		{steps.map((step, index) => (
			<li key={index} className={`mission-step state-${step.state}`}>
				<StepIcon state={step.state} />
				<div className="mission-step-text">
					<p className="mission-step-label">{step.label}</p>
					{step.detail && step.state !== "done" && <p className="mission-step-detail">{step.detail}</p>}
				</div>
			</li>
		))}
	</ol>
);

export default StepList;
