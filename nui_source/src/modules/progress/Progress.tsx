import { useEffect, useState } from "react";
import { Progress as MantineProgress } from "@mantine/core";
import HourglassEmptyIcon from "@mui/icons-material/HourglassEmpty";
import MaterialIcon from "../../components/MaterialIcon";
import iconRegistry from "../../components/IconRegistry";

const resolveIcon = (icon: string) => {
	if (iconRegistry[icon]) return iconRegistry[icon];
	return <MaterialIcon name={icon} />;
};

export interface ProgressData {
	id: number;
	type: "bar" | "circle";
	duration: number;
	label?: string;
	description?: string;
	icon?: string;
	position?: "middle" | "bottom";
	canCancel?: boolean;
}

interface ProgressProps {
	data: ProgressData;
}

const Progress = ({ data }: ProgressProps) => {
	const [percent, setPercent] = useState(0);
	const circleRadius = 41;
	const circleCircumference = 2 * Math.PI * circleRadius;

	useEffect(() => {
		setPercent(0);
		let frame = 0;
		let startedAt = 0;

		const tick = (timestamp: number) => {
			if (!startedAt) startedAt = timestamp;

			const elapsed = timestamp - startedAt;
			const nextPercent = Math.min(100, (elapsed / data.duration) * 100);

			setPercent(nextPercent);
			if (nextPercent < 100) frame = window.requestAnimationFrame(tick);
		};

		frame = window.requestAnimationFrame(tick);

		return () => window.cancelAnimationFrame(frame);
	}, [data.id, data.duration]);

	const barTransition = "width 80ms linear";
	const circleTransition = "stroke-dashoffset 80ms linear";
	const circleOffset = circleCircumference - (percent / 100) * circleCircumference;
	const usesDefaultIcon = !data.icon;
	const icon = data.icon ? resolveIcon(data.icon) : <HourglassEmptyIcon />;

	if (data.type === "circle") {
		return (
			<div className="progress-root progress-root-circle progress-position-bottom">
				<div className="progress-circle-shell">
					<svg viewBox="0 0 96 96" className="progress-circle-svg" aria-label={data.label || "Progress"}>
						<circle className="progress-circle-track" cx="48" cy="48" r={circleRadius} />
						<circle
							className="progress-circle-fill"
							cx="48"
							cy="48"
							r={circleRadius}
							strokeDasharray={circleCircumference}
							strokeDashoffset={circleOffset}
							style={{ transition: circleTransition }}
						/>
					</svg>
					<div className="progress-circle-inner">
						<span>{Math.round(percent)}%</span>
					</div>
				</div>
			</div>
		);
	}

	return (
		<div
			className={`progress-root progress-root-bar progress-position-bottom ${
				data.description ? "progress-has-description" : ""
			}`}
		>
			<div className="progress-bar-header">
				<div className="progress-title">
					<span className={`progress-title-icon ${usesDefaultIcon ? "progress-title-icon-default" : ""}`}>
						{icon}
					</span>
					<p>{data.label || "Progress"}</p>
				</div>
				<p className="progress-percent">{Math.round(percent)}%</p>
			</div>
			{data.description && <p className="progress-description">{data.description}</p>}
			<MantineProgress
				value={percent}
				size="0.95rem"
				radius="0.35rem"
				striped
				animate
				aria-label={data.label || "Progress"}
				styles={{
					root: {
						backgroundColor: "rgb(var(--grey4))",
						border: "1px solid rgb(var(--grey5))",
						boxSizing: "border-box",
					},
					bar: {
						backgroundColor: "rgb(var(--blue2))",
						backgroundSize: "1.85rem 1.85rem",
						backgroundImage:
							"linear-gradient(45deg, rgb(var(--blue1)) 25%, transparent 25%, transparent 50%, rgb(var(--blue1)) 50%, rgb(var(--blue1)) 75%, transparent 75%, transparent)",
						transition: barTransition,
					},
				}}
			/>
			<div className="progress-footer context-menu-footer">
				<p className="context-menu-footer-instruction">
					{data.canCancel ? (
						<>
							Press <kbd style={{ fontSize: "1.1rem" }}>X</kbd> to cancel
						</>
					) : (
						"This action cannot be cancelled"
					)}
				</p>
			</div>
		</div>
	);
};

export default Progress;
