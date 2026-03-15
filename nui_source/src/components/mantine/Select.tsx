import { Select as _Select, MultiSelect as _MultiSelect } from "@mantine/core";
import "../../styling/select.css";
import { GrTooltip } from "react-icons/gr";
import Tooltip from "../Tooltip";

interface SelectProps {
	label?: string;
	placeholder?: string;
	description?: string;
	value?: any;
	searchValue?: string;
	onChange?: (value: any) => void;
	onSearchChange?: (value: string) => void;
	error?: React.ReactNode;
	asterisk?: boolean;
	disabled?: boolean;
	content?: any[];
	icon?: React.ReactNode;
	searchable?: boolean;
	maxDropdownHeight?: number;
	multiselect?: boolean;
	style?: any;
	nothingFound?: React.ReactNode;
	tooltip?: string;
}

const Select: React.FC<SelectProps> = ({
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
	multiselect,
	style,
	nothingFound,
	tooltip,
}) => {
	return (
		<div className="select-root">
			{tooltip && (
				<div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
					<p className="label">{label}</p>
					<Tooltip label={tooltip} position="top" withArrow>
						<GrTooltip className="tooltip-icon" />
					</Tooltip>
				</div>
			)}
			{multiselect ? (
				<_MultiSelect
					label={tooltip ? undefined : label}
					placeholder={placeholder}
					description={description}
					value={value}
					searchValue={searchValue}
					onChange={onChange}
					onSearchChange={onSearchChange}
					data={content || []}
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
					nothingFound={nothingFound}
				/>
			) : (
				<_Select
					label={tooltip ? undefined : label}
					placeholder={placeholder}
					description={description}
					value={value}
					searchValue={searchValue}
					onChange={onChange}
					onSearchChange={onSearchChange}
					data={content || []}
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
					nothingFound={nothingFound}
				/>
			)}
		</div>
	);
};

export default Select;
