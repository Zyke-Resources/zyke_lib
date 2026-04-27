import { useEffect, useState, type FC } from "react";
import { listen, send } from "../../utils/Nui";
import Modal from "../modal/Modal";
import { useModalContext } from "../../context/ModalContext";

import TextInput from "../../components/TextInput";
import NumberInput from "../../components/NumberInput";
import Select from "../../components/mantine/Select";
import Checkbox from "../../components/mantine/Checkbox";
import Slider from "../../components/mantine/Slider";
import TextArea from "../../components/TextArea";
import MaterialIcon from "../../components/MaterialIcon";
import Button from "../../components/Button";
import iconRegistry from "../../components/IconRegistry";

/** Resolve a string icon name from Lua into a React icon component.
 *  Priority: IconRegistry (SVG) → MaterialIcon (font fallback) */
const resolveIcon = (icon?: any) => {
	if (!icon) return undefined;
	if (typeof icon === "string") {
		// Check registry first (SVG icons from MUI / react-icons)
		if (iconRegistry[icon]) return iconRegistry[icon];
		// Fallback to Material Icons font
		return <MaterialIcon name={icon} />;
	}
	return icon;
};

interface FormInput {
	type: "text" | "number" | "select" | "checkbox" | "slider" | "textarea";
	name: string;
	label?: string;
	placeholder?: string;
	description?: string;
	icon?: any;
	disabled?: boolean;
	defaultValue?: any;

	// Select-specific
	content?: any[];
	searchable?: boolean;
	multiselect?: boolean;

	// Number/Slider-specific
	min?: number;
	max?: number;
	step?: number;

	// Slider-specific
	marks?: { value: number; label?: string }[];

	// TextArea-specific
	minRows?: number;
	maxRows?: number;
	maxLength?: number;
}

interface FormButton {
	text: string;
	icon?: string;
	color?: string;
	action?: string;
}

interface FormOptions {
	icon?: string;
	width?: string;
	/** @deprecated Use buttons[] instead */
	submitText?: string;
	/** @deprecated Use buttons[] instead */
	submitIcon?: string;
	/** @deprecated Use buttons[] instead */
	submitColor?: string;
	disableClickOutside?: boolean;
	showCancel?: boolean;
	buttons?: FormButton[];
}

interface FormData {
	formId: string;
	title: string;
	inputs: FormInput[];
	options?: FormOptions;
}

const MODAL_ID = "zyke_form";

const InputDialog: FC = () => {
	const { openModal, closeModal } = useModalContext();
	const [formData, setFormData] = useState<FormData | null>(null);
	const [values, setValues] = useState<Record<string, any>>({});

	const setValue = (name: string, value: any) => {
		setValues((prev) => ({ ...prev, [name]: value }));
	};

	const sendResult = (submitted: boolean, action?: string) => {
		if (!formData) return;

		const data: Record<string, any> = {
			formId: formData.formId,
			submitted,
			values: submitted ? values : null,
		};

		if (submitted && action) {
			data.action = action;
		}

		send("FormResult", data, "Form");

		closeModal(MODAL_ID);

		// Delay cleanup until after the modal exit animation (200ms)
		setTimeout(() => {
			setFormData(null);
			setValues({});
		}, 250);
	};

	// Listen for open events from Lua
	listen("OpenForm", (data: FormData) => {
		// Set default values
		const defaults: Record<string, any> = {};
		data.inputs.forEach((input) => {
			if (input.defaultValue !== undefined) {
				defaults[input.name] = input.defaultValue;
			} else {
				switch (input.type) {
					case "checkbox":
						defaults[input.name] = false;
						break;
					case "number":
						defaults[input.name] = input.min ?? 0;
						break;
					case "slider":
						defaults[input.name] = input.min ?? 0;
						break;
					default:
						defaults[input.name] = "";
						break;
				}
			}
		});

		setValues(defaults);
		setFormData(data);
		openModal(MODAL_ID, true, () => sendResult(false));
	});

	// Listen for close events from Lua (Z.closeForm / Z.closeFormById)
	listen("CloseForm", () => {
		closeModal(MODAL_ID);
		setTimeout(() => {
			setFormData(null);
			setValues({});
		}, 250);
	});

	// Enter key submits the form
	useEffect(() => {
		if (!formData) return;

		const handleKeyDown = (e: KeyboardEvent) => {
			if (e.key === "Enter") {
				e.preventDefault();
				sendResult(true, "primary");
			}
		};

		window.addEventListener("keydown", handleKeyDown);
		return () => window.removeEventListener("keydown", handleKeyDown);
	}, [formData, values]);

	const renderInput = (input: FormInput) => {
		switch (input.type) {
			case "text":
				return (
					<TextInput
						label={input.label}
						placeholder={input.placeholder}
						icon={resolveIcon(input.icon)}
						value={values[input.name] || ""}
						onChange={(e) => setValue(input.name, e.target.value)}
						disabled={input.disabled}
					/>
				);

			case "number":
				return (
					<NumberInput
						label={input.label}
						placeholder={input.placeholder}
						icon={resolveIcon(input.icon)}
						value={values[input.name] ?? 0}
						onChange={(val) => setValue(input.name, val)}
						disabled={input.disabled}
						min={input.min}
						max={input.max}
						hideControls
					/>
				);

			case "select":
				return (
					<Select
						label={input.label}
						placeholder={input.placeholder}
						description={input.description}
						icon={resolveIcon(input.icon)}
						content={input.content}
						value={values[input.name] || ""}
						onChange={(val) => setValue(input.name, val)}
						disabled={input.disabled}
						searchable={input.searchable}
						multiselect={input.multiselect}
					/>
				);

			case "checkbox":
				return (
					<Checkbox
						label={input.label}
						checked={values[input.name] || false}
						onChange={() =>
							setValue(input.name, !values[input.name])
						}
						description={input.description}
						disabled={input.disabled}
						box
					/>
				);

			case "slider":
				return (
					<Slider
						label={input.label}
						description={input.description}
						value={values[input.name] ?? input.min ?? 0}
						onChange={(val) => setValue(input.name, val)}
						disabled={input.disabled}
						min={input.min}
						max={input.max}
						step={input.step}
						marks={input.marks}
					/>
				);

			case "textarea":
				return (
					<TextArea
						label={input.label}
						placeholder={input.placeholder}
						description={input.description}
						icon={resolveIcon(input.icon)}
						value={values[input.name] || ""}
						onChange={(e) => setValue(input.name, e.target.value)}
						disabled={input.disabled}
						minRows={input.minRows || 3}
						maxRows={input.maxRows || 6}
						maxLength={input.maxLength}
						autosize
					/>
				);

			default:
				return null;
		}
	};

	const options = formData?.options || {};
	const showCancel = options.showCancel !== false; // Default true
	const modalWidth = options.width || "30rem";

	// Build resolved buttons
	// Prefer buttons[] array, fall back to old submitText/submitIcon/submitColor
	const resolvedButtons: FormButton[] = options.buttons?.length
		? options.buttons
		: [
			{
				text: options.submitText || "Confirm",
				icon: options.submitIcon,
				color: options.submitColor || "var(--blue1)",
				action: "primary",
			},
		];

	const hasMultipleButtons = resolvedButtons.length > 1 || showCancel;

	return (
		<Modal
			id={MODAL_ID}
			title={formData?.title || "Form"}
			icon={options.icon ? resolveIcon(options.icon) : undefined}
			closeButton
			width={modalWidth}
			onClose={() => sendResult(false)}
			disableClickOutside={options.disableClickOutside}
		>
			{formData && (
				<div
					style={{
						display: "flex",
						flexDirection: "column",
						gap: "0.25rem",
					}}
				>
					{formData.inputs.map((input, idx) => (
						<div key={input.name || `input-${idx}`}>
							{renderInput(input)}
						</div>
					))}

					{/* Footer */}
					<div
						style={{
							display: "flex",
							justifyContent: "flex-end",
							gap: "0.5rem",
							marginTop: "0.25rem",
						}}
					>
						{showCancel && (
							<Button
								icon={resolveIcon("close")}
								color="var(--red3)"
								onClick={() => sendResult(false)}
								iconStyling={{ marginRight: "0.5rem" }}
							>
								Cancel
							</Button>
						)}
						{resolvedButtons.map((btn) => (
							<Button
								key={btn.action || btn.text}
								icon={resolveIcon(btn.icon)}
								color={btn.color || "var(--blue1)"}
								wide={!hasMultipleButtons}
								onClick={() =>
									sendResult(true, btn.action || "primary")
								}
								loadDelay={300}
								iconStyling={{ marginRight: "0.5rem" }}
							>
								{btn.text}
							</Button>
						))}
					</div>
				</div>
			)}
		</Modal>
	);
};

export default InputDialog;
