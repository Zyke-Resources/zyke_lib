import { Box, Textarea as MantineTextArea } from "@mantine/core";
import { forwardRef } from "react";
import { nanoid } from "nanoid";

interface TextAreaProps {
	label?: string;
	description?: string;
	placeholder?: string;
	value?: string;
	onChange?: (event: React.ChangeEvent<HTMLTextAreaElement>) => void;
	error?: React.ReactNode;
	asterisk?: boolean;
	disabled?: boolean;
	icon?: React.ReactNode;
	width?: string | number;
	style?: any;
	autosize?: boolean;
	minRows?: number;
	maxRows?: number;
	maxLength?: number;
	displayMaxLength?: number; // Percentage
	showLimitAbove?: boolean;
}

const TextArea = forwardRef<HTMLTextAreaElement, TextAreaProps>(
	(
		{
			label,
			description,
			placeholder,
			value,
			onChange,
			error,
			asterisk,
			disabled,
			icon,
			width,
			style,
			autosize,
			minRows,
			maxRows,
			maxLength,
			displayMaxLength, // Percentage
			showLimitAbove,
		},
		ref
	) => {
		const displayMaxCharacters = maxLength !== undefined && maxLength > 0;
		let id = undefined;
		if (displayMaxCharacters) {
			id = nanoid();
		}

		const charLength = value?.length || 0;

		const charLimitBelowStyling = {};

		const charLimitAboveStyling = {
			position: "absolute",
			top: "0",
			right: "0",
		};

		const shouldDisplayMaxLength =
			displayMaxCharacters && maxLength && displayMaxLength &&
			charLength > maxLength * (displayMaxLength / 100);

		return (
			<Box
				sx={{
					position: "relative",
				}}
			>
				<MantineTextArea
					id={id}
					label={label}
					description={description}
					placeholder={placeholder}
					value={value}
					onChange={onChange}
					error={error}
					withAsterisk={asterisk !== undefined && asterisk !== false}
					disabled={disabled}
					icon={icon}
					minRows={minRows}
					maxRows={maxRows}
					sx={{
						width: width,
						["& textarea"]: {
							fontWeight: "400",
							minHeight: "3rem",
						},
						...style,

						["& .mantine-Textarea-icon"]: {
							alignItems: "flex-start",
							paddingTop: "0.6rem",
						},
					} as any}
					ref={ref}
					autosize={autosize}
					maxLength={maxLength}
				/>
				{shouldDisplayMaxLength && (
					<Box
						sx={
							(showLimitAbove
								? { ...charLimitAboveStyling }
								: { ...charLimitBelowStyling }) as any
						}
					>
						<p
							style={{
								fontSize: "1.3rem",
								margin: "0.2rem 0.3rem -0.5rem 0",
								textAlign: "end",
								color:
									charLength === maxLength
										? "var(--red)"
										: "var(--secText)",
								fontWeight:
									charLength === maxLength ? "400" : "400",
							}}
						>
							{charLength}/{maxLength}
						</p>
					</Box>
				)}
			</Box>
		);
	}
);

export default TextArea;
