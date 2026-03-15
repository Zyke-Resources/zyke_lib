import { Checkbox as _Checkbox, Box } from "@mantine/core";
import "../../styling/checkbox.css";
import CheckCircleOutlineIcon from "@mui/icons-material/CheckCircleOutline";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { GrTooltip } from "react-icons/gr";
import Tooltip from "../Tooltip";

interface CheckboxProps {
	label?: string;
	checked?: boolean;
	onChange?: (event: React.ChangeEvent<HTMLInputElement>) => void;
	description?: string;
	error?: React.ReactNode;
	disabled?: boolean;
	asterisk?: boolean;
	style?: any;
	box?: boolean; // Boxed style
	tooltip?: string;
}

const Checkbox: React.FC<CheckboxProps> = ({
	label,
	checked,
	onChange,
	description,
	error,
	disabled,
	asterisk,
	style,
	box, // Boxed style
	tooltip,
}) => {
	return box ? (
		<div
			style={{
				position: "relative",
			}}
		>
			{disabled ? (
				<div
					style={{
						position: "absolute",
						background: "rgba(var(--dark), 0.5)",
						width: "100%",
						height: "100%",
						borderRadius: "var(--mborderRadius)",
						zIndex: 100,
					}}
				></div>
			) : null}
			<Box
				sx={{
					background: checked
						? "rgb(var(--blue1))"
						: "rgb(var(--dark4))",
					display: "flex",
					justifyContent: "start",
					alignItems: "center",
					padding: "0.25rem 0.5rem !important",
					borderRadius: "var(--mborderRadius)",
					height: "2.25rem",
					overflow: "hidden",
					cursor: "pointer",
					transition: "0.2s background",
				}}
				onClick={(e: any) => onChange && onChange(e)}
			>
				<div
					style={{
						display: "flex",
						alignItems: "center",
						marginRight: "0.5rem",
					}}
				>
					<CheckCircleIcon
						style={{
							position: "absolute",
							opacity: checked ? 1.0 : 0,
							transition: "0.2s opacity",
						}}
					/>

					<CheckCircleOutlineIcon
						style={{
							opacity: checked ? 0 : 1.0,
							color: "rgba(var(--secIcon)",
							transition: "0.2s opacity",
						}}
					/>
				</div>

				<p
					className="truncate"
					style={{
						fontSize: "1.3rem",
						color: checked
							? "rgba(var(--text))"
							: "rgba(var(--secText))",
						transition: "0.2s color",
					}}
				>
					{label}
				</p>
			</Box>
		</div>
	) : (
		<div className="checkbox-root" style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
			<_Checkbox
				label={label}
				checked={checked}
				onChange={onChange}
				description={description}
				error={error}
				disabled={disabled}
				style={style}
			/>
			{tooltip && (
				<Tooltip label={tooltip} position="top" withArrow>
					<GrTooltip className="tooltip-icon" />
				</Tooltip>
			)}
		</div>
	);
};

export default Checkbox;
