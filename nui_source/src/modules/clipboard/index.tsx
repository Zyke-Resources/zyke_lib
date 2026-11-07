import { useState } from "react";
import { listen, send } from "../../utils/Nui";
import { useModalContext } from "../../context/ModalContext";
import { copyText } from "./copyText";
import CopyCard, { COPY_MODAL_ID, type CopyRequest } from "./CopyCard";

// Z.copy. A copy made outside a click on this page is refused, then Lua gives the page focus and the card asks for one
const ClipboardModule = () => {
	const { openModal, closeModal } = useModalContext();
	const [request, setRequest] = useState<CopyRequest | null>(null);

	// The card's onClose, which runs once the modal is gone however it was closed
	const close = () => {
		setRequest(null);
		send("closed", {}, "Copy");
	};

	listen("copy", (data: CopyRequest) => {
		if (!data.text || copyText(data.text)) return;

		// A second refused copy replaces the text of the open card
		if (!request) {
			openModal(COPY_MODAL_ID);
			send("needsClick", {}, "Copy");
		}

		setRequest(data);
	});

	const copy = () => {
		if (request) copyText(request.text);

		closeModal(COPY_MODAL_ID);
	};

	return <CopyCard request={request} onCopy={copy} onClose={close} />;
};

export default ClipboardModule;
