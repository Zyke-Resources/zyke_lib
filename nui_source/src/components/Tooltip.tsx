import { Tooltip as MantineTooltip } from "@mantine/core";

interface TooltipProps {
    disabled?: boolean;
    label?: string | undefined;
    children: React.ReactNode;
    withArrow?: boolean;
    /** Allows form buttons to show response feedback without relying on hover state */
    opened?: boolean;
    position?:
    | "bottom"
    | "left"
    | "right"
    | "top"
    | "bottom-end"
    | "bottom-start"
    | "left-end"
    | "left-start"
    | "right-end"
    | "right-start"
    | "top-end"
    | "top-start";
}

const Tooltip: React.FC<TooltipProps> = ({
    disabled,
    label,
    children,
    withArrow,
    opened,
    position,
}) => {
    return (
        <MantineTooltip
            label={label || ""}
            disabled={!label || disabled}
            withArrow={withArrow}
            opened={opened}
            arrowSize={11}
            position={position}
            multiline
            withinPortal
            zIndex={9999}
            style={{
                width: "fit-content",
                maxWidth: "220px",
                textAlign: "center",
            }}
        >
            <div>{children}</div>
        </MantineTooltip>
    );
};

export default Tooltip;
