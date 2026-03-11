import { motion } from "framer-motion";
import type { PromptData } from "../../types";

interface Props {
    prompt: PromptData;
}

const Prompt = ({ prompt }: Props) => (
    <motion.div
        className="prompt-item"
        initial={{ marginLeft: "-20rem", opacity: 0 }}
        animate={{ marginLeft: "1rem", opacity: 1 }}
        exit={{ marginLeft: "-20rem", opacity: 0 }}
        transition={{ duration: 0.15, ease: "easeOut" }}
    >
        <kbd>{prompt.key}</kbd>
        <p>{prompt.label}</p>
    </motion.div>
);

export default Prompt;
