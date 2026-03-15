import { Button } from "@mui/material";
// @ts-ignore
import chroma from "chroma-js";
import Tooltip from "./Tooltip";
import React from "react";

interface HollowButtonProps {
	text?: string;
	onClick?: () => void;
	icon?: React.ReactNode;
	color?: string;
	margin?: string | number;
	disabled?: boolean;
	iconButton?: boolean;
	children?: React.ReactNode;
	tooltipLabel?: string;
	tooltipArrow?: boolean;
	height?: string | number;
	width?: string | number;
	removeBackground?: boolean;
	removeHover?: boolean;
	tooltipDisabled?: boolean;
}

const HollowButton: React.FC<HollowButtonProps> = ({
	text,
	onClick,
	icon,
	color,
	margin,
	disabled,
	iconButton,
	children,
	tooltipLabel,
	tooltipArrow,
	height,
	width,
	removeBackground,
	removeHover,
	tooltipDisabled,
}) => {
	if (color) {
		if (color.includes("--")) {
			const startIndex = color.indexOf("--");
			const extractedValue = color.slice(startIndex, -1).trim();
			const root = document.querySelector(":root");
			const fetchedColor = root ? getComputedStyle(root)
				.getPropertyValue(extractedValue)
				.trim() : "";

			color = fetchedColor;
		}
	} else {
		color = "#4caf50";
	}

	return (
		<Tooltip
			disabled={tooltipDisabled}
			label={tooltipLabel}
			withArrow={tooltipArrow}
		>
			<div
				style={{
					background: "rgba(var(--dark))",
					borderRadius: "3px",
					margin: margin || "0",
					width: width || "fit-content",
					boxSizing: "border-box",
				}}
			>
				<Button
					variant="contained"
					onClick={onClick}
					disabled={disabled || false}
					style={{
						height: height,
						fontSize: "1.3rem",
						display: "flex",
						justifyContent: "center",
						alignItems: "center",
						textTransform: "none",
						padding: iconButton ? "0.75rem" : "0.3rem 0.6rem",
						minWidth: iconButton ? "0" : "64px",
						width: width || "fit-content",
						background: (removeBackground
							? "none"
							: !disabled && chroma(color).alpha(0.2)) as string,
						pointerEvents: (!disabled && "auto") as any,
						boxShadow: (removeBackground && "none") as string,
						borderRadius: "3px",
						boxSizing: "border-box",
					}}
					sx={{
						["& p"]: {
							color: !disabled ? color : "grey",
							fontSize: "1.4rem",
							margin: "0.15rem 0.2rem 0 0",
						},
						["&:hover"]: {
							background: !removeHover
								? chroma(color).alpha(0.3) + "!important"
								: undefined,
						},
						["& .MuiSvgIcon-root"]: {
							marginRight: iconButton ? "0" : "0.5rem",
							fontSize: "1.5rem",
							color: !disabled ? color : "grey",
							fill: !disabled ? color : "grey",
						},
					}}
				>
					<>
						{children ? (
							children
						) : (
							<>
								{icon}
								<p>{text || "EMPTY TEXT"}</p>
							</>
						)}
					</>
				</Button>
			</div>
		</Tooltip>
	);
};

export default HollowButton;
