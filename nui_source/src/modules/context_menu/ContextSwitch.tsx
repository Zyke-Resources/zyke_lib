import { FC } from "react";

interface ContextSwitchProps {
	checked: boolean;
}

/** Display-only switch; the option row handles the click so the whole row toggles. */
const ContextSwitch: FC<ContextSwitchProps> = ({ checked }) => (
	<span
		className={`context-switch${checked ? " is-checked" : ""}`}
		role="switch"
		aria-checked={checked}
	>
		<span className="context-switch-thumb" />
	</span>
);

export default ContextSwitch;
