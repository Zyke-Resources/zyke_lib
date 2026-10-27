import { useEffect, useState } from "react";
import type { KeybindBarItem } from "./types";

interface BarTileProps {
	item: KeybindBarItem;
	selected: boolean;
}

// One item on the bar: its inventory icon, how many there are and its name. The icon's frame stays empty where the
// inventory has none, so the tiles line up
const BarTile = ({ item, selected }: BarTileProps) => {
	const [missing, setMissing] = useState(false);

	useEffect(() => setMissing(false), [item.image]);

	return (
		<div className={selected ? "keybinds-tile keybinds-tile-selected" : "keybinds-tile"}>
			<div className="keybinds-tile-image">
				{item.image && !missing && <img src={item.image} alt="" onError={() => setMissing(true)} />}
			</div>
			{item.amount !== undefined && <span className="keybinds-tile-amount">{item.amount}</span>}
			<p className="keybinds-tile-label">{item.label}</p>
		</div>
	);
};

export default BarTile;
