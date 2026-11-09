export type MissionStepState = "done" | "current" | "pending" | "failed";
export type MissionTrackerPosition = "top-left" | "top-right" | "center-left" | "center-right" | "bottom-left" | "bottom-right";

export interface MissionStep {
	label: string;
	detail?: string;
	state: MissionStepState;
}

export interface MissionCountdown {
	// Time left when the message was sent, the countdown runs from there
	expiresIn: number;
	totalMs?: number;
}

export interface Mission {
	key: string;
	resource: string;
	title: string;
	// Lua sends an empty table as an object
	steps: MissionStep[] | Record<string, never>;
	countdown?: MissionCountdown;
}

export interface MissionTrackerData {
	missions: Mission[] | Record<string, never>;
	position: MissionTrackerPosition;
	// Gap to the screen edges, in percent of the screen height so both sides match
	offset: { x: number; y: number };
}
