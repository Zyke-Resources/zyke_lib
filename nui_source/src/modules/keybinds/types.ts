export interface KeybindItemData {
	label: string;
	// The caps of the keys, such as ["LMB"]
	keys: string[];
}

export interface KeybindBarItem {
	label: string;
	// The inventory icon, an nui:// path
	image?: string;
	// How many there are, left out for none shown
	amount?: number;
}

export interface KeybindBar {
	items: KeybindBarItem[];
	// From 0, -1 for none
	selected: number;
}

export type KeybindPosition = "bottom-left" | "bottom-center" | "bottom-right";

export interface KeybindPanelData {
	items: KeybindItemData[];
	title?: string;
	// Shown beside the title, in red when danger is set
	detail?: { text: string; danger?: boolean };
	// Why what the panel is about can not be done, floating above it
	warning?: string;
	// What to do next, floating above it; a warning takes its place
	hint?: string;
	position: KeybindPosition;
	// A row of items over the panel
	bar?: KeybindBar;
}

export interface KeybindPanelEntry {
	// The resource's name and a number
	id: string;
	data: KeybindPanelData;
}