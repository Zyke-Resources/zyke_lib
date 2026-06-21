import { motion } from "framer-motion";
import type { PromptData } from "../../types";

interface Props {
    prompt: PromptData;
}

const getPromptKeys = (key: PromptData["key"]) => Array.isArray(key) ? key : [key];

const Prompt = ({ prompt }: Props) => (
    <motion.div
        className="prompt-item"
        initial={{ marginLeft: "-20rem", opacity: 0 }}
        animate={{ marginLeft: "1rem", opacity: 1 }}
        exit={{ marginLeft: "-20rem", opacity: 0 }}
        transition={{ duration: 0.15, ease: "easeOut" }}
    >
        <div className="prompt-keys">
            {getPromptKeys(prompt.key).map((key, idx) => (
                <kbd key={`${key}:${idx}`}>{key}</kbd>
            ))}
        </div>
        <p>{prompt.label}</p>
    </motion.div>
);

export default Prompt;
