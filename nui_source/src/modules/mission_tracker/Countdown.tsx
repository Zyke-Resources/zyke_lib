import { useEffect, useState } from "react";

interface CountdownProps {
	expiresIn: number;
	totalMs?: number;
}

// Under this share of the mission's time the timer turns orange, and red in the last minute
const urgentShare = 0.2;

const format = (ms: number) => {
	const seconds = Math.ceil(ms / 1000);
	const hours = Math.floor(seconds / 3600);
	const minutes = Math.floor((seconds % 3600) / 60);
	const rest = String(seconds % 60).padStart(2, "0");

	return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${rest}` : `${minutes}:${rest}`;
};

const Countdown = ({ expiresIn, totalMs }: CountdownProps) => {
	const [left, setLeft] = useState(expiresIn);

	useEffect(() => {
		const endsAt = Date.now() + expiresIn;
		const tick = () => setLeft(Math.max(0, endsAt - Date.now()));

		tick();
		const interval = window.setInterval(tick, 1000);

		return () => window.clearInterval(interval);
	}, [expiresIn]);

	const urgency = left <= 60000 ? " critical" : totalMs && left <= totalMs * urgentShare ? " urgent" : "";

	return <p className={`mission-countdown${urgency}`}>{format(left)}</p>;
};

export default Countdown;
