import { useState } from "react";
import { AnimatePresence } from "framer-motion";
import { listen } from "../../utils/Nui";
import type { PromptData } from "../../types";
import Prompt from "./Prompt";
import "./prompt.css";

/**
 * Prompt Module
 *
 * Shows prompts on the screen / text uis to display interactions you can make with a keybind key
 */
const PromptModule = () => {
	const [prompts, setPrompts] = useState<PromptData[]>([]);

	listen("ShowPrompt", ({ id, key, label }: PromptData) => {
		setPrompts(prev =>
			prev.some(p => p.id === id)
				? prev.map(p => (p.id === id ? { id, key, label } : p))
				: [...prev, { id, key, label }]
		);
	});

	listen("RemovePrompt", ({ id }: { id: string }) => {
		setPrompts(prev => prev.filter(p => p.id !== id));
	});

	return (
		<div className="prompt-container">
			<AnimatePresence>
				{prompts.map(prompt => (
					<Prompt key={prompt.id} prompt={prompt} />
				))}
			</AnimatePresence>
		</div>
	);
};

export default PromptModule;
