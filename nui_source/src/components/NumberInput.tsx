import { NumberInput as MantineNumberInput, Sx } from "@mantine/core";
import { useEffect, useRef, useState } from "react";
import { GrTooltip } from "react-icons/gr";
import Tooltip from "./Tooltip";

interface NumberInputProps {
    label?: string;
    placeholder?: string;
    value: number;
    onChange?: (event: number) => void;
    error?: string;
    asterisk?: boolean;
    disabled?: boolean;
    icon?: React.ReactNode;
    width?: string;
    style?: React.CSSProperties;
    id?: string;
    rightSection?: React.ReactNode;
    hideControls?: boolean;
    precision?: number;
    variant?: "unstyled";
    alignEnd?: boolean;
    tooltip?: string;
    min?: number;
    max?: number;
    onBlur?: () => void;
    rootStyle?: React.CSSProperties;
    inputSx?: Sx;
}

const NumberInput: React.FC<NumberInputProps> = ({
    label,
    placeholder,
    value,
    onChange,
    error,
    asterisk,
    disabled,
    icon,
    width,
    style,
    id,
    rightSection,
    hideControls,
    precision,
    variant,
    alignEnd,
    tooltip,
    min,
    max,
    onBlur,
    rootStyle,
    inputSx,
}) => {
    const [isFocused, setIsFocused] = useState(false);

    const styling = {
        width: width,
        ...style,
    };

    const elementRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        if (!elementRef || !elementRef.current) return;

        const ensureFocus = () =>
            setIsFocused(document.activeElement == elementRef.current);

        elementRef.current.addEventListener("focus", ensureFocus);
        elementRef.current.addEventListener("blur", ensureFocus);

        return () => {
            if (elementRef.current) {
                elementRef.current.removeEventListener("focus", ensureFocus);
                elementRef.current.removeEventListener("blur", ensureFocus);
            }
        };
    }, []);

    return (
        <div className="input-root" style={rootStyle}>
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
            <MantineNumberInput
                id={id}
                value={value}
                onChange={onChange}
                placeholder={placeholder}
                error={error}
                withAsterisk={asterisk}
                disabled={disabled}
                icon={icon}
                style={styling}
                rightSection={rightSection}
                ref={elementRef || undefined}
                className={`${isFocused && "isFocused"} ${alignEnd && "alignEnd"
                    } ${variant && variant}`}
                precision={precision}
                hideControls={hideControls}
                variant={variant}
                min={min}
                max={max}
                onBlur={onBlur}
                sx={inputSx}
            />
        </div>
    );
};

export default NumberInput;
