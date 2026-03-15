import { Box, Slider as MantineSlider } from "@mantine/core";
import "../../styling/slider.css";
import { GrTooltip } from "react-icons/gr";
import Tooltip from "../Tooltip";

interface SliderProps {
	label?: string;
	description?: string;
	icon?: React.ReactNode;
	displayLabel?: React.ReactNode;
	displayLabelAlwaysOn?: boolean;
	value?: number;
	onChange?: (value: number) => void;
	error?: React.ReactNode;
	asterisk?: boolean;
	disabled?: boolean;
	width?: string | number;
	rootStyle?: any;
	style?: any;
	min?: number;
	max?: number;
	step?: number;
	marks?: { value: number; label?: React.ReactNode }[];
	addValueToLabel?: boolean | ((value: number | undefined) => string);
	margin?: any;
	tooltip?: string;
}

const Slider: React.FC<SliderProps> = ({
	label,
	description,
	icon,
	displayLabel,
	displayLabelAlwaysOn,
	value,
	onChange,
	error,
	asterisk,
	disabled,
	width,
	rootStyle,
	style,
	min,
	max,
	step,
	marks,
	addValueToLabel,
	margin,
	tooltip,
}) => {
	const labelAddition = addValueToLabel
		? addValueToLabel !== true
			? typeof addValueToLabel === 'function' ? addValueToLabel(value) : ""
			: " - " + value
		: "";

	return (
		<Box className="slider-root" style={rootStyle}>
			<Box
				style={{
					marginBottom: "0.4rem",
				}}
			>
				<div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
					<p
						style={{
							fontSize: "1.3rem",
							color: "rgba(var(--text))",
						}}
					>
						{label} {labelAddition}
					</p>
					{tooltip && (
						<Tooltip label={tooltip} position="top" withArrow>
							<GrTooltip className="tooltip-icon" />
						</Tooltip>
					)}
				</div>
				<p
					style={{
						fontSize: "1.1rem",
						color: "rgba(var(--secText))",
						marginTop: "-0.3rem",
						lineHeight: "1",
					}}
				>
					{description}
				</p>
			</Box>
			<Box className="slider-box">
				{icon && (
					<Box
						sx={{
							display: "flex",
							alignItems: "center",
							justifyContent: "center",
							marginRight: "0.25rem",
						}}
					>
						{icon}
					</Box>
				)}
				<MantineSlider
					label={displayLabel}
					labelAlwaysOn={displayLabelAlwaysOn}
					marks={marks}
					sx={{
						width: width || "100%",
						...style,
					}}
					min={min}
					max={max}
					step={step}
					value={value}
					onChange={onChange}
					disabled={disabled}
				/>
			</Box>
		</Box>
	);
};

export default Slider;
