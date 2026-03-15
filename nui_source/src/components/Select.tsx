import React, { CSSProperties, FC } from "react";
import { Select as MantineSelect, SelectItem } from "@mantine/core";
import { GrTooltip } from "react-icons/gr";
import Tooltip from "./Tooltip";
import "../styling/select.css";

export interface SelectOption {
    name: string;
    value?: string;
    label?: string;
    key?: string;
}

interface SelectProps {
    label?: string;
    placeholder?: string;
    description?: string;
    value?: string;
    searchValue?: string;
    onChange?: (value: string) => void;
    onSearchChange?: (value: string) => void;
    error?: string | boolean;
    asterisk?: boolean;
    disabled?: boolean;
    content?: SelectOption[];
    icon?: React.ReactNode;
    searchable?: boolean;
    maxDropdownHeight?: number;
    style?: CSSProperties;
    itemComponent?:
        | FC<{ item: SelectOption }>
        | React.ForwardRefExoticComponent<
              React.PropsWithoutRef<SelectOption> &
                  React.RefAttributes<HTMLDivElement>
          >;
    rightSection?: React.ReactNode;
    dropdownPosition?: "bottom" | "top" | "flip" | undefined;
    variant?: "unstyled";
    tooltip?: string;
    searchFields?: string[];
}

const Select: FC<SelectProps> = ({
    label,
    placeholder,
    description,
    value,
    searchValue,
    onChange,
    onSearchChange,
    error,
    asterisk,
    disabled,
    content,
    icon,
    searchable,
    maxDropdownHeight,
    style,
    itemComponent,
    rightSection,
    dropdownPosition,
    variant,
    tooltip,
    searchFields = ["label"],
}) => {
    const options = (content || []).map((item, idx) => {
        const computedValue = item.value || item.name || `option-${idx}`;
        return {
            ...item,
            key: `${item.name || item.value}-${idx}`,
            value: computedValue,
        };
    });

    const optionsFilter = (value: string, item: SelectItem) => {
        const splittedSearch = value
            ? value.toLowerCase().trim().split(" ")
            : [];

        const words: string[] = [];

        searchFields.forEach((field) => {
            const fieldValue = (item as any)[field];
            if (typeof fieldValue === "string") {
                words.push(...fieldValue.toLowerCase().trim().split(" "));
            }
        });

        return splittedSearch.every((searchWord) =>
            words.some((word) => word.includes(searchWord))
        );
    };

    return (
        <div className="input-root">
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
            <MantineSelect
                placeholder={placeholder}
                description={description}
                value={value}
                searchValue={searchValue}
                onChange={onChange}
                onSearchChange={onSearchChange}
                data={options}
                disabled={disabled}
                error={error}
                withAsterisk={asterisk}
                icon={icon}
                searchable={searchable}
                maxDropdownHeight={maxDropdownHeight || 300}
                transitionProps={{
                    transition: "pop-top-left",
                    duration: 200,
                    exitDuration: 200,
                    timingFunction: "ease",
                }}
                style={style}
                itemComponent={itemComponent}
                rightSection={rightSection}
                dropdownPosition={dropdownPosition}
                className={`${variant && variant}`}
                variant={variant}
                filter={optionsFilter}
            />
        </div>
    );
};

export default Select;
