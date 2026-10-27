import BarTile from "./BarTile";
import type { KeybindBar } from "./types";

// Most tiles shown at once; past that the bar shows a window round the selected one with how many are left out
const maxShown = 9;

// A row of items over a panel, such as what the player can take into the hands
const ItemBar = ({ bar }: { bar?: KeybindBar }) => {
	// An empty Lua table may arrive as an object instead of an array
	const items = Array.isArray(bar?.items) ? bar.items : [];
	if (!bar || items.length === 0) return null;

	const start = Math.max(0, Math.min(bar.selected - Math.floor(maxShown / 2), items.length - maxShown));
	const shown = items.slice(start, start + maxShown);
	const after = items.length - start - shown.length;

	return (
		<div className="keybinds-bar">
			{start > 0 && <span className="keybinds-bar-more">+{start}</span>}

			{shown.map((item, index) => (
				<BarTile key={`${item.label}-${start + index}`} item={item} selected={start + index === bar.selected} />
			))}

			{after > 0 && <span className="keybinds-bar-more">+{after}</span>}
		</div>
	);
};

export default ItemBar;
