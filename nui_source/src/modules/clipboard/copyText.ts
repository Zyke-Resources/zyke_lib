// The game browser only lets a page copy right after a click or key press on it, the async clipboard API is blocked
// in NUI frames, so this returns false when the copy was refused
export const copyText = (text: string) => {
	const textarea = document.createElement("textarea");

	textarea.style.position = "absolute";
	textarea.style.left = "-9999px";
	textarea.style.top = "0";
	textarea.value = text;
	document.body.appendChild(textarea);
	textarea.focus();
	textarea.select();

	const copied = document.execCommand("copy");

	document.body.removeChild(textarea);

	return copied;
};
