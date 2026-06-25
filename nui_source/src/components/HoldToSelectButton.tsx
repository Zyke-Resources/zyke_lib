import {
	cloneElement,
	isValidElement,
	useEffect,
	useRef,
	useState,
	type CSSProperties,
	type FC,
	type PointerEvent,
	type ReactNode,
} from "react";
import Button, { type ButtonProps } from "./Button";

const holdDuration = 1400;

interface HoldToSelectButtonProps
	extends Omit<ButtonProps, "onClick" | "loadDelay" | "shouldLoad"> {
	onSelect: () => void;
}

const HoldToSelectButton: FC<HoldToSelectButtonProps> = ({
	onSelect,
	disabled,
	loading,
	icon,
	...buttonProps
}) => {
	const [holding, setHolding] = useState(false);
	const timeoutRef = useRef<number | null>(null);
	const isDisabled = disabled || loading;

	const clearHold = (): void => {
		if (timeoutRef.current !== null) {
			window.clearTimeout(timeoutRef.current);
			timeoutRef.current = null;
		}

		setHolding(false);
	};

	const confirm = (): void => {
		clearHold();
		onSelect();
	};

	const startHold = (event: PointerEvent<HTMLDivElement>): void => {
		if (event.button !== 0) return;
		if (isDisabled || holding) return;

		event.preventDefault();
		setHolding(true);
		timeoutRef.current = window.setTimeout(confirm, holdDuration);
	};

	useEffect(() => {
		return () => {
			if (timeoutRef.current !== null) {
				window.clearTimeout(timeoutRef.current);
			}
		};
	}, []);

	return (
		<div
			style={{
				display: "inline-flex",
				width: buttonProps.wide ? "100%" : "fit-content",
			}}
			onPointerDown={startHold}
			onPointerLeave={clearHold}
			onPointerCancel={clearHold}
			onPointerUp={clearHold}
		>
			<Button
				{...buttonProps}
				icon={
					icon ? (
						<HoldSelectIcon
							duration={holdDuration}
							holding={holding}
							icon={icon}
						/>
					) : undefined
				}
				disabled={disabled}
				loading={loading}
			/>
		</div>
	);
};

export default HoldToSelectButton;

interface HoldSelectIconProps {
	duration: number;
	holding: boolean;
	icon: ReactNode;
}

const HoldSelectIcon: FC<HoldSelectIconProps> = ({
	duration,
	holding,
	icon,
}) => (
	<span
		style={{
			position: "relative",
			display: "inline-grid",
			placeItems: "center",
			flex: "0 0 1.5rem",
			width: "1.5rem",
			height: "1.5rem",
			marginRight: "0.5rem",
		}}
	>
		<span style={getIconLayerStyle(!holding)}>
			{getIconWithoutMargin(icon)}
		</span>
		<span style={getIconLayerStyle(holding)}>
			<HoldProgressIcon duration={duration} holding={holding} />
		</span>
	</span>
);

const getIconWithoutMargin = (icon: ReactNode): ReactNode => {
	if (!isValidElement<{ style?: CSSProperties }>(icon)) return icon;

	return cloneElement(icon, {
		style: {
			...icon.props.style,
			marginRight: 0,
		},
	});
};

const getIconLayerStyle = (visible: boolean): CSSProperties => ({
	position: "absolute",
	inset: 0,
	display: "grid",
	placeItems: "center",
	opacity: visible ? 1 : 0,
	pointerEvents: "none",
	transition: "opacity 140ms ease",
});

interface HoldProgressIconProps {
	duration: number;
	holding: boolean;
}

const HoldProgressIcon: FC<HoldProgressIconProps> = ({
	duration,
	holding,
}) => {
	const circumference = 69.12;

	return (
		<svg
			viewBox="0 0 28 28"
			width="1em"
			height="1em"
			aria-hidden="true"
			style={{ marginRight: 0 }}
		>
			<circle
				cx="14"
				cy="14"
				r="11"
				fill="none"
				stroke="currentColor"
				strokeOpacity="0.35"
				strokeWidth="3"
			/>
			<circle
				cx="14"
				cy="14"
				r="11"
				fill="none"
				stroke="currentColor"
				strokeDasharray={circumference}
				strokeLinecap="round"
				strokeWidth="3"
				transform="rotate(-90 14 14)"
				style={{
					strokeDashoffset: holding ? 0 : circumference,
					transition: `stroke-dashoffset ${
						holding ? duration : 160
					}ms ${holding ? "linear" : "ease-out"}`,
				}}
			/>
		</svg>
	);
};
