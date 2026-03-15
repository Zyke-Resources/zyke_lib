import React, { useEffect, useState } from "react";
import TextInput from "./TextInput";
import { useDebouncedValue } from "@mantine/hooks";
import { Sx } from "@mantine/core";

interface LocalProps {
    value: string;
    onChange: (value: string) => void;
    delay?: number;
    style?: React.CSSProperties;
    icon?: React.ReactNode;
    label?: string;
    placeholder?: string;
    tooltip?: string;
    error?: string | boolean;
    disabled?: boolean;
    variant?: "unstyled";
    sx?: Sx;
    autoWidth?: boolean;
    blurOnEnter?: boolean;
}

const DebouncedTextInput: React.FC<LocalProps> = ({
    value,
    onChange,
    delay,
    style,
    icon,
    label,
    placeholder,
    tooltip,
    error,
    disabled,
    variant,
    sx,
    autoWidth,
    blurOnEnter,
}) => {
    const [innerInput, setInnerInput] = useState<string>(value);
    const [searchStr] = useDebouncedValue(innerInput, delay || 300);

    useEffect(() => {
        if (value === innerInput) return;

        setInnerInput(value);
    }, [value]);

    useEffect(() => {
        onChange(searchStr);
    }, [searchStr]);

    return (
        <TextInput
            label={label || ""}
            placeholder={placeholder}
            icon={icon}
            value={innerInput}
            onChange={(e) => setInnerInput(e.target.value)}
            style={style}
            tooltip={tooltip}
            error={error}
            disabled={disabled}
            variant={variant}
            sx={sx}
            autoWidth={autoWidth}
            blurOnEnter={blurOnEnter}
        />
    );
};

export default DebouncedTextInput;
