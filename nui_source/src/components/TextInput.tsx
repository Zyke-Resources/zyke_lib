import { TextInput as MantineTextInput, Sx, Box } from "@mantine/core";
import React, { useEffect, useLayoutEffect, useRef, useState } from "react";
import { GrTooltip } from "react-icons/gr";
import Tooltip from "./Tooltip";

interface TextInput {
    label?: string;
    placeholder?: string;
    description?: string;
    value: string;
    onChange?: (event: React.ChangeEvent<HTMLInputElement>) => void;
    error?: string | boolean;
    asterisk?: boolean;
    disabled?: boolean;
    icon?: React.ReactNode;
    width?: string;
    style?: React.CSSProperties;
    id?: string;
    className?: string;
    variant?: "unstyled";
    tooltip?: string;
    sx?: Sx;
    autoWidth?: boolean;
    blurOnEnter?: boolean;
    forceFocus?: boolean;
}

const TextInput: React.FC<TextInput> = ({
    label,
    placeholder,
    description,
    value,
    onChange,
    error,
    asterisk,
    disabled,
    icon,
    width,
    style,
    id,
    variant,
    tooltip,
    sx,
    autoWidth,
    blurOnEnter,
    forceFocus,
}) => {
    const [isFocused, setIsFocused] = useState(false);
    const [computedWidthPx, setComputedWidthPx] = useState<number | undefined>(
        undefined
    );

    const styling = {
        width: autoWidth
            ? computedWidthPx
                ? `${computedWidthPx}px`
                : undefined
            : width,
        display: autoWidth ? "inline-block" : undefined,
        ...style,
    } as React.CSSProperties;

    const elementRef = useRef<HTMLInputElement>(null);
    const mirrorRef = useRef<HTMLSpanElement>(null);

    const shouldBlurOnEnter = blurOnEnter ?? true;

    const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (
            shouldBlurOnEnter &&
            (e.key === "Enter" ||
                e.code === "Enter" ||
                (e as unknown as { keyCode?: number }).keyCode === 13)
        ) {
            e.preventDefault();
            e.currentTarget.blur();
        }
    };

    useEffect(() => {
        if (!elementRef.current) return;

        const ensureFocus = () =>
            setIsFocused(document.activeElement === elementRef.current);

        elementRef.current.addEventListener("focus", ensureFocus);
        elementRef.current.addEventListener("blur", ensureFocus);

        if (forceFocus) elementRef.current.focus();

        return () => {
            if (elementRef.current) {
                elementRef.current.removeEventListener("focus", ensureFocus);
                elementRef.current.removeEventListener("blur", ensureFocus);
            }
        };
    }, []);

    useLayoutEffect(() => {
        if (!autoWidth) return;
        const inputEl = elementRef.current;
        const mirrorEl = mirrorRef.current;
        if (!inputEl || !mirrorEl) return;

        const syncMirrorStyles = () => {
            const cs = window.getComputedStyle(inputEl);
            mirrorEl.style.fontFamily = cs.fontFamily;
            mirrorEl.style.fontSize = cs.fontSize;
            mirrorEl.style.fontWeight = cs.fontWeight as string;
            mirrorEl.style.letterSpacing = cs.letterSpacing;
            mirrorEl.style.paddingLeft = cs.paddingLeft;
            mirrorEl.style.paddingRight = cs.paddingRight;
            mirrorEl.style.borderLeftWidth = cs.borderLeftWidth;
            mirrorEl.style.borderRightWidth = cs.borderRightWidth;
        };

        const compute = () => {
            const text = inputEl.value || inputEl.placeholder || " ";
            mirrorEl.textContent = text;
            const extra = 0;
            const newWidth = Math.ceil(mirrorEl.offsetWidth) + extra;
            setComputedWidthPx(newWidth);
        };

        syncMirrorStyles();
        compute();

        const onResize = () => {
            syncMirrorStyles();
            compute();
        };

        window.addEventListener("resize", onResize);
        return () => {
            window.removeEventListener("resize", onResize);
        };
    }, [autoWidth, value, placeholder, variant, icon]);

    return (
        <Box className={`input-root ${variant && variant}`} sx={sx}>
            <div
                style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                }}
            >
                <p className="label">{label}</p>
                {tooltip && (
                    <Tooltip label={tooltip} position="top" withArrow>
                        <GrTooltip className="tooltip-icon" />
                    </Tooltip>
                )}
            </div>
            <MantineTextInput
                id={id}
                value={value}
                onChange={onChange}
                placeholder={placeholder}
                description={description}
                error={error}
                withAsterisk={asterisk}
                disabled={disabled}
                icon={icon}
                style={styling}
                ref={elementRef}
                className={isFocused ? "focused" : undefined}
                variant={variant}
                inputContainer={(children) => <>{children}</>}
                onKeyDown={handleKeyDown}
            />
            {autoWidth && (
                <span
                    ref={mirrorRef}
                    aria-hidden
                    style={{
                        position: "absolute",
                        visibility: "hidden",
                        whiteSpace: "pre",
                        left: "-9999px",
                        top: 0,
                    }}
                />
            )}
        </Box>
    );
};

export default TextInput;
