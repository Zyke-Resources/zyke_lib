import React from "react";

interface MaterialIconProps {
	name: string;
	outlined?: boolean;
	size?: string | number;
	color?: string;
	style?: React.CSSProperties;
	className?: string;
}

/**
 * Renders a Material Icon using the Google Fonts icon font.
 * Pass any valid Material Icon name as `name`.
 *
 * Styled to visually match MUI SVG icons (same size, color, alignment).
 * Color defaults to "currentColor" so it inherits from parent CSS selectors
 * (e.g. Modal Header & svg or Button & svg equivalents).
 *
 * @see https://fonts.google.com/icons
 *
 * @example
 * <MaterialIcon name="attach_money" />
 * <MaterialIcon name="person" outlined />
 */
const MaterialIcon: React.FC<MaterialIconProps> = ({
	name,
	outlined = false,
	size,
	color,
	style,
	className,
}) => {
	return (
		<span
			className={`${outlined ? "material-icons-outlined" : "material-icons"} ${className || ""}`}
			style={{
				fontSize: size || "1.5rem",
				verticalAlign: "middle",
				display: "inline-flex",
				alignItems: "center",
				justifyContent: "center",
				lineHeight: 1,
				width: size || "1.5rem",
				height: size || "1.5rem",
				flexShrink: 0,
				userSelect: "none",
				...(color ? { color } : {}),
				...style,
			}}
		>
			{name}
		</span>
	);
};

export default MaterialIcon;
