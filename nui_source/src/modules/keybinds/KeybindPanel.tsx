import { forwardRef, useEffect, useState } from "react";
import { motion } from "framer-motion";
import ItemBar from "./ItemBar";
import KeybindItem from "./KeybindItem";
import type { KeybindPanelData } from "./types";

interface KeybindPanelProps {
	data: KeybindPanelData;
}

// One resource's panel with its warning or hint floating above it, and a bar of items between them when it has one.
// The last note stays while it fades out, so it does not vanish when the panel no longer has one. It has no layout
// animation, as that scales the panel through every change of size and stretches its text
const KeybindPanel = forwardRef<HTMLDivElement, KeybindPanelProps>(({ data }, ref) => {
	const current = data.warning ?? data.hint;
	const [note, setNote] = useState({ text: current ?? "", warning: !!data.warning });

	useEffect(() => {
		if (current) setNote({ text: current, warning: !!data.warning });
	}, [current, data.warning]);

	const noteClass = ["keybinds-note", note.warning && "keybinds-note-warning", current && "keybinds-note-shown"]
		.filter(Boolean)
		.join(" ");

	return (
		<motion.div
			ref={ref}
			className="keybinds-group"
			initial={{ y: 50, opacity: 0 }}
			animate={{ y: 0, opacity: 1 }}
			exit={{ y: 50, opacity: 0 }}
			transition={{ duration: 0.25, ease: "easeOut" }}
		>
			{note.text && (
				<div className={noteClass}>
					{note.warning && <i className="keybinds-dot" />}
					{note.text}
				</div>
			)}

			<ItemBar bar={data.bar} />

			<div className="keybinds-panel">
				{data.title && (
					<div className="keybinds-header">
						<span className="keybinds-title">{data.title}</span>
						{data.detail && (
							<span className={data.detail.danger ? "keybinds-detail keybinds-detail-danger" : "keybinds-detail"}>
								{data.detail.text}
							</span>
						)}
					</div>
				)}

				{data.items.length > 0 && (
					<div className="keybinds-body">
						{data.items.map((item, index) => (
							<KeybindItem key={`${item.label}-${index}`} label={item.label} keys={item.keys} />
						))}
					</div>
				)}
			</div>
		</motion.div>
	);
});

export default KeybindPanel;