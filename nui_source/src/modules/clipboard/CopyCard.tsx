import { Code } from "@mantine/core";
import Modal from "../modal/Modal";
import Button from "../../components/Button";
import iconRegistry from "../../components/IconRegistry";

export const COPY_MODAL_ID = "zyke_copy";

export interface CopyRequest {
	text: string;
	title: string;
	button: string;
}

interface CopyCardProps {
	request: CopyRequest | null;
	onCopy: () => void;
	onClose: () => void;
}

// Asks for the click a copy needs when it was not made from one, and shows the text for when it still fails
const CopyCard = ({ request, onCopy, onClose }: CopyCardProps) => (
	<Modal id={COPY_MODAL_ID} title={request?.title} icon={iconRegistry.copy} closeButton width="22rem" onClose={onClose}>
		<div style={{ display: "flex", flexDirection: "column", gap: "0.5rem" }}>
			<Code block style={{ whiteSpace: "pre-wrap", wordBreak: "break-all", maxHeight: "8rem", overflowY: "auto" }}>
				{request?.text}
			</Code>
			<Button icon={iconRegistry.copy} color="var(--blue2)" wide onClick={onCopy} iconStyling={{ marginRight: "0.5rem" }}>
				{request?.button}
			</Button>
		</div>
	</Modal>
);

export default CopyCard;
