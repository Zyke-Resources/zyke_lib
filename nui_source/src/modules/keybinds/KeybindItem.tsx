import type { KeybindItemData } from "./types";

// The keys of one prompt and what they do. Spans, not kbd, so the global kbd style stays out
const KeybindItem = ({ label, keys }: KeybindItemData) => (
	<div className="keybinds-item">
		<div className="keybinds-keys">
			{keys.map((name) => (
				<span key={name} className="keybinds-key">
					{name}
				</span>
			))}
		</div>
		<p className="keybinds-label">{label}</p>
	</div>
);

export default KeybindItem;