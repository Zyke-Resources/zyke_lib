interface IndicatorProps {
	angle: number;
}

const Indicator = ({ angle }: IndicatorProps) => (
	<div
		className="skill-check-indicator"
		style={{ transform: `rotate(${angle}deg)` }}
	>
		<span className="skill-check-indicator-tick" />
	</div>
);

export default Indicator;
