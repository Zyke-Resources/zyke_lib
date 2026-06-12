import { useCallback, useRef, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { listen } from "../../utils/Nui";
import Progress, { type ProgressData } from "./Progress";
import "./progress.css";

type ProgressUpdateData = Partial<ProgressData> & {
	id: number;
};

const ProgressModule = () => {
	const [data, setData] = useState<ProgressData | null>(null);
	const cleanupTimer = useRef<number | null>(null);

	const clearCleanupTimer = useCallback(() => {
		if (cleanupTimer.current === null) return;

		window.clearTimeout(cleanupTimer.current);
		cleanupTimer.current = null;
	}, []);

	listen("OpenProgress", (progressData: ProgressData) => {
		clearCleanupTimer();
		setData(progressData);
	});

	listen("UpdateProgress", (progressData: ProgressUpdateData) => {
		setData((current) => {
			if (!current || current.id !== progressData.id) return current;

			return {
				...current,
				...progressData,
			};
		});
	});

	listen("CloseProgress", ({ id }: { id: number }) => {
		setData((current) => {
			if (!current || current.id !== id) return current;

			return null;
		});
	});

	return (
		<AnimatePresence>
			{data && (
				<motion.div
					key={data.id}
					className="progress-motion-root"
					initial={{
						opacity: 0,
						y: 18,
						scale: 0.94,
						filter: "blur(0.25rem)",
					}}
					animate={{
						opacity: 1,
						y: 0,
						scale: 1,
						filter: "blur(0)",
					}}
					exit={{
						opacity: 0,
						y: 6,
						scale: 0.98,
						filter: "blur(0.12rem)",
					}}
					transition={{
						type: "spring",
						stiffness: 520,
						damping: 34,
						mass: 0.72,
						opacity: { duration: 0.12 },
						filter: { duration: 0.16 },
					}}
				>
					<Progress data={data} />
				</motion.div>
			)}
		</AnimatePresence>
	);
};

export default ProgressModule;
