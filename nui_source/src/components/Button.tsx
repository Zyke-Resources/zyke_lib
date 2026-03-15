import { Box, Button as MUIButton, SxProps, Theme } from "@mui/material";
import KeyboardDoubleArrowRightIcon from "@mui/icons-material/KeyboardDoubleArrowRight";
import ContentPasteGoIcon from "@mui/icons-material/ContentPasteGo";
import CheckIcon from "@mui/icons-material/Check";
import _color from "./Color";
import { Loader } from "@mantine/core";
import GetVarValue from "./GetVarValue";
import chroma from "chroma-js";
import React, { useState } from "react";
import Tooltip from "./Tooltip";

export interface ButtonProps {
    icon?: React.ReactNode;
    rightIcon?: "dialog" | "newPage" | "confirm";
    useRightIconAnimation?: boolean;
    tooltipLabel?: string | undefined;
    disableRipple?: boolean;

    hollow?: boolean;
    removeDefaultComponent?: boolean;
    color?: string;
    buttonStyling?: SxProps<Theme>;
    boxStyling?: SxProps<Theme>;
    textStyling?: React.CSSProperties;
    iconStyling?: React.CSSProperties;
    textContainerStyling?: SxProps<Theme>;
    wide?: boolean;

    disabled?: boolean;
    loading?: boolean;
    loadDelay?: number | [number, number];
    shouldLoad?: () => boolean;

    onClick?: (e?: React.MouseEventHandler<HTMLButtonElement>) => void;
    onMouseEnter?: React.MouseEventHandler<HTMLButtonElement>;
    onMouseLeave?: React.MouseEventHandler<HTMLButtonElement>;

    children?: React.ReactNode;
}

const rightIcons = {
    ["dialog"]: <ContentPasteGoIcon className="rightIcon" />,
    ["newPage"]: <KeyboardDoubleArrowRightIcon className="rightIcon" />,
    ["confirm"]: <CheckIcon className="rightIcon" />,
};

const Button: React.FC<ButtonProps> = ({
    icon,
    rightIcon,
    useRightIconAnimation,
    tooltipLabel,
    disableRipple = false,

    hollow = false,
    removeDefaultComponent,
    color,
    buttonStyling,
    boxStyling,
    iconStyling,
    textStyling,
    textContainerStyling,
    wide,

    disabled,
    loading = false,
    loadDelay,
    shouldLoad,

    onClick,
    onMouseEnter,
    onMouseLeave,

    children,
}) => {
    const [internalLoading, setInternalLoading] = useState(false);
    const isLoading = loading || internalLoading;

    const isClickDisabled = disabled || isLoading || false;
    const { backgroundColor, borderColor, textColor, hoverValue } = getColor(
        hollow,
        color,
        isClickDisabled
    );

    const _onClick = () => {
        if (isClickDisabled) return;

        let _shouldLoad = true;
        if (shouldLoad) _shouldLoad = shouldLoad();

        if (loadDelay && _shouldLoad) {
            setInternalLoading(true);

            let toWait;
            if (Array.isArray(loadDelay)) {
                toWait =
                    loadDelay[0] +
                    Math.random() * (loadDelay[1] - loadDelay[0]);
            } else {
                toWait = loadDelay;
            }

            setTimeout(async () => {
                if (onClick) {
                    await onClick();
                }

                setInternalLoading(false);
            }, toWait);
        } else {
            if (_shouldLoad && onClick) onClick();
        }
    };

    return (
        <Tooltip label={tooltipLabel}>
            <MUIButton
                disableRipple={disableRipple}
                variant="contained"
                onClick={_onClick}
                disabled={disabled || false}
                sx={{
                    display: "flex",
                    justifyContent: "start",
                    alignItems: "center",

                    textTransform: "none",

                    padding: "0.35rem 0.45rem 0.35rem 0.6rem !important",
                    boxSizing: "border-box",

                    margin: "0.5rem 0 0 0",
                    minHeight: "0 !important",
                    minWidth: "0 !important",
                    width: wide ? "100%" : "fit-content",
                    height: "fit-content",
                    borderRadius: "var(--mborderRadius)",

                    background: `${backgroundColor} !important`,
                    border: `1px solid ${borderColor.hex()} !important`,

                    pointerEvents: isLoading ? "none" : undefined,

                    ["&:hover"]: {
                        background: !isClickDisabled
                            ? `${hoverValue} !important`
                            : undefined,

                        ["& .rightIcon"]: {
                            transform: useRightIconAnimation
                                ? "translateX(35%)"
                                : undefined,
                        },
                    },

                    ["& .rightIcon"]: {
                        transform: !useRightIconAnimation
                            ? "translateX(35%)"
                            : undefined,
                        marginRight: "1rem",
                    },

                    ...buttonStyling,
                }}
                onMouseEnter={onMouseEnter}
                onMouseLeave={onMouseLeave}
            >
                <Box
                    sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        width: "100%",

                        "& svg": {
                            marginRight: "0.5rem",
                            fontSize: "1.5rem",
                            color: `${textColor.hex()}`,
                            fill: `${textColor.hex()}`,
                            transition: "all 0.2s ease-in-out",
                            ...iconStyling,
                        },

                        "& .material-icons, & .material-icons-outlined": {
                            marginRight: "0.5rem",
                            fontSize: "1.5rem !important",
                            color: `${textColor.hex()} !important`,
                            width: "1.5rem",
                            height: "1.5rem",
                            transition: "all 0.2s ease-in-out",
                            ...iconStyling,
                        },

                        "& p": {
                            color: `${textColor.hex()}`,
                            fontSize: "1.4rem",
                            margin: "0rem 0.2rem 0 0",
                            fontWeight: hollow ? "400" : "400",
                            transition: "all 0.2s ease-in-out",
                            ...textStyling,
                        },

                        ...boxStyling,
                    }}
                >
                    <Box
                        sx={{
                            display: "flex",
                            alignItems: "center",
                            justifyContent: wide ? "center" : "start",
                            width: "100%",

                            ...textContainerStyling,
                        }}
                    >
                        {icon && (
                            <LeftIcon
                                icon={icon}
                                color={textColor.hex()}
                                loading={isLoading}
                                iconStyling={iconStyling}
                            />
                        )}
                        {removeDefaultComponent ? children : <p>{children}</p>}
                    </Box>
                    {rightIcon && rightIcons[rightIcon]}
                </Box>
            </MUIButton>
        </Tooltip>
    );
};

export default Button;

interface LeftIconProps {
    color: string;
    icon: React.ReactNode;
    loading?: boolean;
    iconStyling?: React.CSSProperties;
}

const LeftIcon: React.FC<LeftIconProps> = ({
    color,
    icon,
    loading,
    iconStyling,
}) => {
    let size: string | number = "1.5rem";
    if (iconStyling?.fontSize) {
        size = iconStyling.fontSize;
    }

    const sizeWithUnits = typeof size === "number" ? `${size}px` : size;

    return loading ? (
        <Loader
            className="loader"
            style={{
                stroke: color,
                width: sizeWithUnits,
                height: sizeWithUnits,
            }}
        />
    ) : icon ? (
        <>{icon}</>
    ) : null;
};

const getColor = (hollow: boolean, color?: string, isDisabled?: boolean) => {
    const defaultBackground = "rgb(var(--grey))";
    const baseBackground: any = chroma(
        GetVarValue(color || defaultBackground)
    );

    let backgroundColor: any = baseBackground;

    if (hollow) backgroundColor = baseBackground.alpha(0.2);
    if (isDisabled) {
        if (hollow) {
            backgroundColor = backgroundColor
                .darken(0.5)
                .desaturate(1.5)
                .alpha(0.1);
        } else {
            backgroundColor = backgroundColor.alpha(0.5);
        }
    }

    let borderColor: any | "transparent" = chroma("rgba(0, 0, 0, 0)");
    if (!hollow) {
        borderColor = baseBackground.brighten(0.2);
        if (isDisabled) borderColor = backgroundColor.alpha(0);
    }

    const defaultText = "rgb(var(--text))";
    const baseText: any = chroma(GetVarValue(defaultText));
    let textColor: any = baseText;
    if (hollow) textColor = baseBackground;

    if (isDisabled) {
        if (hollow) {
            textColor = textColor.darken(0.5).desaturate(1.5);
        } else {
            textColor = textColor.alpha(0.5);
        }
    }

    return {
        backgroundColor,
        borderColor,
        textColor,
        hoverValue: backgroundColor.brighten(0.5).hex(),
    };
};
