import { FC, useState, useRef, useEffect, useMemo } from "react";
import { Box, ButtonBase } from "@mui/material";
import MaterialIcon from "../../components/MaterialIcon";
import iconRegistry from "../../components/IconRegistry";
import CheckIcon from "@mui/icons-material/Check";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import ImageNotSupportedIcon from "@mui/icons-material/ImageNotSupported";
import MouseIcon from "@mui/icons-material/Mouse";
import {
	resolveTemplate,
	type ContextMetadata,
	type ContextAmount,
	type ContextOptionData,
} from "./ContextMenu";

interface ContextOptionProps {
	option: ContextOptionData;
	index: number;
	mode: "action" | "select" | "multiselect";
	selected: boolean;
	onHover: (index: number | null, element?: HTMLElement | null) => void;
	onClick: (index: number) => void;
	currentAmount?: number;
	onAmountChange: (index: number, delta: number) => void;
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
	currentAmount,
	onAmountChange,
}) => {
	const isDisabled = option.disabled || false;
	const isReadOnly = option.readOnly || false;
	const hasMenu = option.menu !== undefined && option.menu !== null;
	const showArrow = option.arrow !== undefined ? option.arrow : hasMenu;
	const [imgError, setImgError] = useState(false);

	const hasAmount = option.amount !== undefined;
	const amountVars = option.amount?.vars;

	const titleHasTpl = hasAmount && option.title.includes("{");
	const descHasTpl = hasAmount && !!option.description && option.description.includes("{");

	const resolvedTitle = useMemo(() => {
		if (!titleHasTpl) return option.title;
		return resolveTemplate(option.title, currentAmount ?? 0, amountVars);
	}, [titleHasTpl, option.title, currentAmount, amountVars]);

	const resolvedDescription = useMemo(() => {
		if (!descHasTpl) return option.description;
		return resolveTemplate(option.description, currentAmount ?? 0, amountVars);
	}, [descHasTpl, option.description, currentAmount, amountVars]);

	const progressColor = option.colorScheme
		? `rgb(var(--${option.colorScheme}, var(--blue1)))`
		: "rgb(var(--blue1))";

	const handleClick = () => {
		if (isDisabled || isReadOnly) return;
		onClick(index);
	};

	const boxRef = useRef<HTMLDivElement>(null);

	const handleWheel = (e: WheelEvent) => {
		if (!hasAmount || isDisabled || isReadOnly) return;
		e.preventDefault();
		e.stopPropagation();
		const base = e.deltaY < 0 ? 1 : -1;
		onAmountChange(index, e.shiftKey ? base * 5 : base);
	};

	useEffect(() => {
		const el = boxRef.current;
		if (!el || !hasAmount) return;
		el.addEventListener("wheel", handleWheel, { passive: false });
		return () => el.removeEventListener("wheel", handleWheel);
	}, [hasAmount, isDisabled, isReadOnly, onAmountChange, index]);

	const iconSize = "1.8rem";

	return (
		<Box
			ref={boxRef}
			sx={{
				transition: "background 0.2s, border 0.2s",
				borderRadius: "var(--lborderRadius)",
				margin: "0.25rem 0 0 0",
				opacity: isDisabled ? 0.4 : 1,
				display: "flex",
				alignItems: "center",
				overflow: "hidden",
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
						{resolvedTitle}
					</p>

					{resolvedDescription && (
						<p
							style={{
								margin: "-0.3rem 0 0 0",
								color: "rgba(var(--secText))",
								fontSize: "1.3rem",
								whiteSpace: "nowrap",
								overflow: "hidden",
								textOverflow: "ellipsis",
								userSelect: "none",
								lineHeight: 1.3,
							}}
						>
							{resolvedDescription}
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
					{hasAmount && !showArrow && (
						<MouseIcon
							sx={{
								fontSize: "1.4rem",
								color: "rgba(var(--secIcon))",
								opacity: 1.0,
							}}
						/>
					)}
				</div>
			</ButtonBase>
		</Box>
	);
};

export default ContextOption;
