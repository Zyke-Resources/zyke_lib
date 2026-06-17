import { useCallback, useRef, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { listen, send } from "../../utils/Nui";
import SkillCheck, { type SkillCheckRequest } from "./SkillCheck";
import "./skill_check.css";

const SkillCheckModule = () => {
	const [request, setRequest] = useState<SkillCheckRequest | null>(null);
	const completedRef = useRef(false);

	const complete = useCallback((success: boolean) => {
		if (completedRef.current) return;

		completedRef.current = true;
		setRequest(null);
		send("complete", { success }, "SkillCheck");
	}, []);

	listen("OpenSkillCheck", (skillCheckRequest: SkillCheckRequest) => {
		completedRef.current = false;
		setRequest(skillCheckRequest);
	});

	listen("CancelSkillCheck", () => {
		complete(false);
	});

	return (
		<AnimatePresence>
			{request && (
				<motion.div
					key="skill-check"
					className="skill-check-motion-root"
					initial={{ opacity: 0, scale: 0.92 }}
					animate={{ opacity: 1, scale: 1 }}
					exit={{ opacity: 0, scale: 0.96 }}
					transition={{ duration: 0.12 }}
				>
					<SkillCheck request={request} onComplete={complete} />
				</motion.div>
			)}
		</AnimatePresence>
	);
};

export default SkillCheckModule;
