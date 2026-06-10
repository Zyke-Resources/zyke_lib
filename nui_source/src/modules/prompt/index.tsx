import { useState } from "react";
import { AnimatePresence } from "framer-motion";
import { listen } from "../../utils/Nui";
import type { PromptData, RemovePromptData } from "../../types";
import Prompt from "./Prompt";
import "./prompt.css";

const getPromptKey = (prompt: Pick<PromptData, "id" | "resource">) =>
	`${prompt.resource}:${prompt.id}`;

/**
 * Prompt Module
 *
 * Shows prompts on the screen / text uis to display interactions you can make with a keybind key
 */
const PromptModule = () => {
	const [prompts, setPrompts] = useState<PromptData[]>([]);

	listen("ShowPrompt", (prompt: PromptData) => {
		setPrompts(prev =>
			prev.some(p => getPromptKey(p) === getPromptKey(prompt))
				? prev.map(p => (getPromptKey(p) === getPromptKey(prompt) ? prompt : p))
				: [...prev, prompt]
		);
	});

	listen("RemovePrompt", ({ id, resource }: RemovePromptData) => {
		setPrompts(prev =>
			prev.filter(p => p.resource !== resource || (typeof id === "string" && p.id !== id))
		);
	});

	return (
		<div className="prompt-container">
			<AnimatePresence>
				{prompts.map(prompt => (
					<Prompt key={getPromptKey(prompt)} prompt={prompt} />
				))}
			</AnimatePresence>
		</div>
	);
};

export default PromptModule;
