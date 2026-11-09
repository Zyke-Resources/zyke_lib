import { forwardRef } from "react";
import { motion } from "framer-motion";
import Countdown from "./Countdown";
import StepList from "./StepList";
import type { Mission } from "./types";

interface MissionCardProps {
	mission: Mission;
	fromLeft: boolean;
}

// One mission: its title with the time left, and its steps. It moves by position only, as a layout animation of its
// size would stretch its text when its steps change
const MissionCard = forwardRef<HTMLDivElement, MissionCardProps>(({ mission, fromLeft }, ref) => (
	<motion.div
		ref={ref}
		className="mission-card"
		layout="position"
		initial={{ opacity: 0, x: fromLeft ? -14 : 14 }}
		animate={{ opacity: 1, x: 0 }}
		exit={{ opacity: 0, x: fromLeft ? -8 : 8 }}
		transition={{ type: "spring", stiffness: 480, damping: 36, opacity: { duration: 0.14 } }}
	>
		<div className="mission-card-header">
			<p className="mission-card-title">{mission.title}</p>
			{mission.countdown && <Countdown expiresIn={mission.countdown.expiresIn} totalMs={mission.countdown.totalMs} />}
		</div>

		<StepList steps={Array.isArray(mission.steps) ? mission.steps : []} />
	</motion.div>
));

export default MissionCard;
