import { useEffect, useState } from "react";
import { AnimatePresence } from "framer-motion";
import { listen, send } from "../../utils/Nui";
import KeybindPanel from "./KeybindPanel";
import type { KeybindPanelEntry, KeybindPosition } from "./types";
import "./keybinds.css";

const positions: KeybindPosition[] = ["bottom-left", "bottom-center", "bottom-right"];

/**
 * Keybinds Module
 *
 * The key panels of every resource from Z.keybinds. Each screen position has its own stack, with the first shown
 * panel at the bottom and later ones above it
 */
const KeybindsModule = () => {
	const [panels, setPanels] = useState<KeybindPanelEntry[]>([]);

	// An empty Lua table may arrive as an object instead of an array
	listen("SetKeybindPanels", (data: { panels: KeybindPanelEntry[] }) => {
		setPanels(Array.isArray(data?.panels) ? data.panels : []);
	});

	useEffect(() => {
		send("ready", {}, "Keybinds");
	}, []);

	return (
		<>
			{positions.map((position) => (
				<div key={position} className={`keybinds-stack keybinds-${position}`}>
					<AnimatePresence mode="popLayout">
						{panels
							.filter((panel) => panel.data.position === position)
							.map((panel) => (
								<KeybindPanel key={panel.id} data={panel.data} />
							))}
					</AnimatePresence>
				</div>
			))}
		</>
	);
};

export default KeybindsModule;