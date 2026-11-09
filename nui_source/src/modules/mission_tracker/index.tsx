import { useEffect, useState } from "react";
import { AnimatePresence } from "framer-motion";
import { listen, send } from "../../utils/Nui";
import MissionCard from "./MissionCard";
import type { Mission, MissionTrackerData } from "./types";
import "./mission_tracker.css";

/**
 * Mission Tracker Module
 *
 * The missions of every resource from Z.missionTracker, one card each, stacked in one column in the corner set in
 * zyke_lib's config. The pause menu sends an empty list, so the cards leave with it
 */
const MissionTrackerModule = () => {
	const [tracker, setTracker] = useState<MissionTrackerData>();

	listen("SetMissionTracker", setTracker);

	useEffect(() => {
		send("ready", {}, "MissionTracker");
	}, []);

	// An empty Lua table may arrive as an object instead of an array
	const missions: Mission[] = Array.isArray(tracker?.missions) ? tracker.missions : [];
	const [vertical, horizontal] = (tracker?.position ?? "top-left").split("-");
	const fromLeft = horizontal !== "right";

	return (
		<div
			className={`mission-tracker-stack v-${vertical} h-${fromLeft ? "left" : "right"}`}
			style={{ padding: `${tracker?.offset?.y ?? 2.5}vh ${tracker?.offset?.x ?? 2.5}vh` }}
		>
			<AnimatePresence mode="popLayout">
				{missions.map((mission) => (
					<MissionCard key={mission.key} mission={mission} fromLeft={fromLeft} />
				))}
			</AnimatePresence>
		</div>
	);
};

export default MissionTrackerModule;
