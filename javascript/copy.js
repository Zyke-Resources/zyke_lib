const copyText = (text) => {
    const textarea = document.createElement("textarea");
    textarea.style.position = "absolute";
    textarea.style.left = "-9999px";
    textarea.style.top = "0";
    textarea.value = text;
    document.body.appendChild(textarea);
    textarea.focus();
    textarea.select();
    const result = document.execCommand("copy");
    document.body.removeChild(textarea);

    return result;
};

window.addEventListener("message", (e) => {
    const event = e.data.event;
    const text = e.data.text;

    if (event == "copy") {
        copyText(text);
    }
});
