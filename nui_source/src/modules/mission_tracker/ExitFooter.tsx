interface ExitFooterProps {
	label?: string;
	command: string;
}

// The strip under a mission the player may leave, with the command that leaves it
const ExitFooter = ({ label, command }: ExitFooterProps) => (
	<div className="mission-exit">
		<p className="mission-exit-label">{label}</p>
		<kbd className="mission-exit-command">{command}</kbd>
	</div>
);

export default ExitFooter;
