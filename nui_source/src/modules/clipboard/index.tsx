import { listen } from "../../utils/Nui";

/** Copy text to the clipboard using a hidden textarea fallback. */
const copyText = (text: string) => {
    const textarea = document.createElement("textarea");
    textarea.style.position = "absolute";
    textarea.style.left = "-9999px";
    textarea.style.top = "0";
    textarea.value = text;
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand("copy");
    document.body.removeChild(textarea);
};

/**
 * Clipboard Module (Ported from the legacy javascript/copy.js)
 */
const ClipboardModule = () => {
    listen("copy", ({ text }: { text: string }) => {
        if (text) copyText(text);
    });

    return null;
};

export default ClipboardModule;
