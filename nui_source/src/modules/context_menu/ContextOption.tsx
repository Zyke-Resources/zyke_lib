import { FC, useState } from "react";
import { Box, ButtonBase } from "@mui/material";
import MaterialIcon from "../../components/MaterialIcon";
import iconRegistry from "../../components/IconRegistry";
import CheckIcon from "@mui/icons-material/Check";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import ImageNotSupportedIcon from "@mui/icons-material/ImageNotSupported";

interface ContextMetadata {
	label: string;
	value: any;
	progress?: number;
	colorScheme?: string;
}

interface ContextOptionData {
	title: string;
	description?: string;
	icon?: string;
	iconColor?: string;
	disabled?: boolean;
	readOnly?: boolean;
	menu?: string | any;
	onSelect?: any;
	arrow?: boolean;
	event?: string;
	serverEvent?: string;
	args?: any;
	metadata?: ContextMetadata[];
	progress?: number;
	colorScheme?: string;
	image?: string;
	value?: any;
}

interface ContextOptionProps {
	option: ContextOptionData;
	index: number;
	mode: "action" | "select" | "multiselect";
	selected: boolean;
	onHover: (index: number | null, element?: HTMLElement | null) => void;
	onClick: (index: number) => void;
}

const resolveIcon = (icon?: string) => {
	if (!icon) return null;
	if (iconRegistry[icon]) return iconRegistry[icon];
	return <MaterialIcon name={icon} />;
};

const ContextOption: FC<ContextOptionProps> = ({
	option,
	index,
	mode,
	selected,
	onHover,
	onClick,
}) => {
	const isDisabled = option.disabled || false;
	const isReadOnly = option.readOnly || false;
	const hasMenu = option.menu !== undefined && option.menu !== null;
	const showArrow = option.arrow !== undefined ? option.arrow : hasMenu;
	const [imgError, setImgError] = useState(false);

	const progressColor = option.colorScheme
		? `rgb(var(--${option.colorScheme}, var(--blue1)))`
		: "rgb(var(--blue1))";

	const handleClick = () => {
		if (isDisabled || isReadOnly) return;
		onClick(index);
	};

	const iconSize = "1.8rem";

	return (
		<Box
			sx={{
				transition: "background 0.2s, border 0.2s",
				borderRadius: "var(--lborderRadius)",
				margin: "0.25rem 0 0 0",
				opacity: isDisabled ? 0.4 : 1,
				display: "flex",
				alignItems: "center",
				overflow: "hidden",
				// gap: "0rem",
				...(selected
					? {
						background: "rgb(var(--grey))",
						border: "1px solid rgb(var(--grey3))",
					}
					: {
						"&:hover": {
							background: "rgba(var(--dark2))",
						},
					}),
			}}
		>
			<ButtonBase
				disableRipple={isDisabled || isReadOnly}
				sx={{
					width: "100%",
					display: "flex",
					alignItems: "center",
					// gap: "0.8rem",
					justifyContent: "flex-start",
					padding: "var(--spadding) var(--mpadding) var(--spadding) 0",
					cursor: isDisabled || isReadOnly ? "default" : "pointer",
					"& .MuiTouchRipple-child": {
						backgroundColor:
							"rgba(255, 255, 255, 0.25) !important",
					},
				}}
				onMouseEnter={(e) => {
					if (!isReadOnly)
						onHover(index, e.currentTarget as HTMLElement);
				}}
				onMouseLeave={() => onHover(null, null)}
				onClick={handleClick}
			>
				{(option.icon || option.image) && (
					<Box
						sx={{
							display: "flex",
							alignItems: "center",
							justifyContent: "center",
							flexShrink: 0,
							width: "4rem",
							height: "4rem",
							overflow: "hidden",
							borderRadius: "0.3rem",
							boxSizing: "border-box",
							...(option.image && !imgError
								? {
									// background: "rgba(var(--dark2))",
									// border: "1px solid rgb(var(--dark3))",
									// boxSizing: "border-box",
									// boxShadow: "0 0 3px 0px rgba(0, 0, 0, 0.3)",
									// width: "4rem",
									// height: "4rem",
									padding: "0.5rem",
								}
								: {}),
							color: option.iconColor || "rgb(var(--icon))",

							["& svg"]: {
								fontSize: iconSize,
							}
						}}
					>
						{option.image && !imgError ? (
							<img
								src={option.image}
								alt=""
								onError={() => setImgError(true)}
								style={{
									width: "100%",
									height: "100%",
									objectFit: "contain",
								}}
							/>
						) : option.image && imgError ? (
							<ImageNotSupportedIcon
								sx={{
									opacity: 0.4,
								}}
							/>
						) : (
							resolveIcon(option.icon)
						)}
					</Box>
				)}

				<div
					style={{
						flex: 1,
						minWidth: 0,
						overflow: "hidden",
						display: "grid",
						justifyItems: "start",
						alignItems: "center",
					}}
				>
					<p
						style={{
							margin: 0,
							fontSize: "1.7rem",
							fontWeight: 400,
							color: isReadOnly
								? "rgba(var(--secText))"
								: "rgb(var(--text))",
							whiteSpace: "nowrap",
							overflow: "hidden",
							textOverflow: "ellipsis",
							userSelect: "none",
							lineHeight: 1.5,
						}}
					>
						{option.title}
					</p>

					{option.description && (
						<p
							style={{
								margin: "-0.3rem 0 0 0",
								// margin: 0,
								color: "rgba(var(--secText))",
								fontSize: "1.3rem",
								whiteSpace: "nowrap",
								overflow: "hidden",
								textOverflow: "ellipsis",
								userSelect: "none",
								lineHeight: 1.3,
							}}
						>
							{option.description}
						</p>
					)}

					{option.progress !== undefined && (
						<div
							style={{
								height: "3px",
								borderRadius: "2px",
								background: "rgba(var(--dark3))",
								overflow: "hidden",
								marginTop: "0.2rem",
								width: "100%",
							}}
						>
							<div
								style={{
									height: "100%",
									borderRadius: "2px",
									width: `${Math.min(
										100,
										Math.max(0, option.progress)
									)}%`,
									background: progressColor,
									transition: "width 0.3s ease",
								}}
							/>
						</div>
					)}
				</div>

				<div
					style={{
						display: "flex",
						alignItems: "center",
						gap: "0.3rem",
						flexShrink: 0,
						marginLeft: "0.3rem",
					}}
				>
					{mode !== "action" && !isDisabled && !isReadOnly && (
						<div
							style={{
								width: "1.5rem",
								height: "1.5rem",
								borderRadius:
									mode === "select"
										? "50%"
										: "var(--borderRadius)",
								border: selected
									? "2px solid rgb(var(--blue1))"
									: "2px solid rgba(var(--grey3))",
								display: "flex",
								alignItems: "center",
								justifyContent: "center",
								background: selected
									? "rgb(var(--blue1))"
									: "transparent",
								transition: "all 0.15s",
							}}
						>
							{selected && (
								<CheckIcon
									sx={{
										fontSize: "1.1rem",
										color: "white",
									}}
								/>
							)}
						</div>
					)}
					{showArrow && !isDisabled && (
						<ChevronRightIcon
							sx={{
								fontSize: "2rem",
								color: "rgba(var(--secIcon))",
							}}
						/>
					)}
				</div>
			</ButtonBase>
		</Box>
	);
};

export default ContextOption;
