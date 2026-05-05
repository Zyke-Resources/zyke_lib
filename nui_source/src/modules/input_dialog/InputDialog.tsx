import {
	cloneElement,
	isValidElement,
	useEffect,
	useState,
	type CSSProperties,
	type FC,
	type ReactNode,
} from "react";
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
	type:
		| "paragraph"
		| "hint"
		| "text"
		| "number"
		| "select"
		| "checkbox"
		| "slider"
		| "textarea";
	name?: string;
	label?: string;
	title?: string;
	text?: string | string[];
	placeholder?: string;
	description?: string;
	icon?: any;
	severity?: "info" | "warning" | "error" | "danger";
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
	timeout?: number;
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

const DEFAULT_FORM_BUTTON_COLOR = "var(--blue2)";

const DEFAULT_FORM_BUTTON: FormButton = {
	text: "Confirm",
	color: DEFAULT_FORM_BUTTON_COLOR,
	action: "primary",
};

const getResolvedButtons = (options: FormOptions): FormButton[] => {
	if (options.buttons?.length) return options.buttons;

	return [
		{
			...DEFAULT_FORM_BUTTON,
			text: options.submitText ?? DEFAULT_FORM_BUTTON.text,
			icon: options.submitIcon,
			color: options.submitColor ?? DEFAULT_FORM_BUTTON_COLOR,
		},
	];
};

const getButtonTimeout = (button: FormButton) => {
	const timeout = Number(button.timeout);
	if (!Number.isFinite(timeout) || timeout <= 0) return 0;

	return timeout;
};

const getButtonRemaining = (
	button: FormButton,
	now: number,
	timeoutStartedAt: number
) => {
	const timeout = getButtonTimeout(button);
	if (timeout <= 0) return 0;

	const elapsed = (now - timeoutStartedAt) / 1000;
	return Math.max(0, Math.ceil(timeout - elapsed));
};

const HINT_SEVERITY = {
	info: {
		color: "var(--blue2)",
		icon: "info",
	},
	warning: {
		color: "var(--orange2)",
		icon: "warning",
	},
	error: {
		color: "var(--red3)",
		icon: "error",
	},
	danger: {
		color: "var(--red3)",
		icon: "error",
	},
};

const getHintConfig = (severity?: FormInput["severity"]) => {
	return HINT_SEVERITY[severity || "info"] || HINT_SEVERITY.info;
};

const getColoredHintIcon = (icon: ReactNode, color: string) => {
	if (!icon) return undefined;
	if (!isValidElement<{ style?: CSSProperties }>(icon)) return icon;

	return cloneElement(icon, {
		style: {
			...icon.props.style,
			color,
			fill: color,
		},
	});
};

const InputDialog: FC = () => {
	const { openModal, closeModal } = useModalContext();
	const [formData, setFormData] = useState<FormData | null>(null);
	const [values, setValues] = useState<Record<string, any>>({});
	const [timeoutStartedAt, setTimeoutStartedAt] = useState(Date.now());
	const [countdownNow, setCountdownNow] = useState(Date.now());

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
			if (
				input.type === "paragraph" ||
				input.type === "hint" ||
				!input.name
			) {
				return;
			}

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
		const now = Date.now();
		setTimeoutStartedAt(now);
		setCountdownNow(now);
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

	const options = formData?.options || {};
	const showCancel = options.showCancel !== false; // Default true
	const modalWidth = options.width || "30rem";
	const resolvedButtons = getResolvedButtons(options);
	const hasTimedButtons = resolvedButtons.some(
		(btn) => getButtonTimeout(btn) > 0
	);

	// Enter key submits the form
	useEffect(() => {
		if (!formData) return;

		const handleKeyDown = (e: KeyboardEvent) => {
			if (e.key === "Enter") {
				e.preventDefault();

				const primaryButton = resolvedButtons[0];
				if (
					primaryButton &&
					getButtonRemaining(
						primaryButton,
						countdownNow,
						timeoutStartedAt
					) > 0
				) {
					return;
				}

				sendResult(true, primaryButton?.action || "primary");
			}
		};

		window.addEventListener("keydown", handleKeyDown);
		return () => window.removeEventListener("keydown", handleKeyDown);
	}, [formData, values, countdownNow, timeoutStartedAt]);

	useEffect(() => {
		if (!formData || !hasTimedButtons) return;

		const interval = window.setInterval(() => {
			setCountdownNow(Date.now());
		}, 250);

		return () => window.clearInterval(interval);
	}, [formData, hasTimedButtons]);

	const renderInput = (input: FormInput) => {
		switch (input.type) {
			case "paragraph":
				return <FormParagraph input={input} />;

			case "hint":
				return <FormHint input={input} />;

			case "text":
				return (
					<TextInput
						label={input.label}
						placeholder={input.placeholder}
						icon={resolveIcon(input.icon)}
						value={values[input.name || ""] || ""}
						onChange={(e) =>
							input.name && setValue(input.name, e.target.value)
						}
						disabled={input.disabled}
					/>
				);

			case "number":
				return (
					<NumberInput
						label={input.label}
						placeholder={input.placeholder}
						icon={resolveIcon(input.icon)}
						value={values[input.name || ""] ?? 0}
						onChange={(val) =>
							input.name && setValue(input.name, val)
						}
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
						value={values[input.name || ""] || ""}
						onChange={(val) =>
							input.name && setValue(input.name, val)
						}
						disabled={input.disabled}
						searchable={input.searchable}
						multiselect={input.multiselect}
					/>
				);

			case "checkbox":
				return (
					<Checkbox
						label={input.label}
						checked={values[input.name || ""] || false}
						onChange={() =>
							input.name &&
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
						value={values[input.name || ""] ?? input.min ?? 0}
						onChange={(val) =>
							input.name && setValue(input.name, val)
						}
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
						value={values[input.name || ""] || ""}
						onChange={(e) =>
							input.name && setValue(input.name, e.target.value)
						}
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
						{resolvedButtons.map((btn) => {
							const remaining = getButtonRemaining(
								btn,
								countdownNow,
								timeoutStartedAt
							);
							const isWaiting = remaining > 0;

							return (
								<Button
									key={btn.action || btn.text}
									icon={resolveIcon(btn.icon)}
									color={btn.color || DEFAULT_FORM_BUTTON_COLOR}
									wide={!hasMultipleButtons}
									disabled={isWaiting}
									onClick={() => {
										if (isWaiting) return;

										sendResult(
											true,
											btn.action || "primary"
										);
									}}
									loadDelay={300}
									iconStyling={{ marginRight: "0.5rem" }}
								>
									{isWaiting
										? `${btn.text} (${remaining}s)`
										: btn.text}
								</Button>
							);
						})}
					</div>
				</div>
			)}
		</Modal>
	);
};

const FormParagraph: FC<{ input: FormInput }> = ({ input }) => {
	const content = input.text ?? input.description ?? "";
	const paragraphs = Array.isArray(content) ? content : [content];
	const icon = resolveIcon(input.icon);

	return (
		<div
			style={{
				display: "flex",
				gap: "0.75rem",
				padding: "0.15rem 0 0.35rem 0",
				color: "rgba(var(--textMuted))",
				boxSizing: "border-box",
			}}
		>
			{icon && (
				<div
					style={{
						display: "flex",
						alignItems: "flex-start",
						justifyContent: "center",
						width: "1.8rem",
						paddingTop: "0.1rem",
						color: "rgba(var(--iconMuted))",
						flexShrink: 0,
					}}
				>
					{icon}
				</div>
			)}
			<div>
				{input.label && (
					<p
						style={{
							margin: "0 0 0.25rem 0",
							color: "rgba(var(--text))",
							fontSize: "1.25rem",
							fontWeight: 500,
							lineHeight: 1.35,
						}}
					>
						{input.label}
					</p>
				)}
				{paragraphs.map((paragraph, idx) => (
					<p
						key={`${input.name || input.label || "paragraph"}-${idx}`}
						style={{
							margin:
								idx === paragraphs.length - 1
									? "0"
									: "0 0 0.55rem 0",
							fontSize: "1.2rem",
							lineHeight: 1.45,
							whiteSpace: "pre-wrap",
						}}
					>
						{paragraph}
					</p>
				))}
			</div>
		</div>
	);
};

const FormHint: FC<{ input: FormInput }> = ({ input }) => {
	const content = input.text ?? input.description ?? "";
	const paragraphs = Array.isArray(content) ? content : [content];
	const title = input.title ?? input.label;
	const config = getHintConfig(input.severity);
	const hintColor = `rgba(${config.color}, 1)`;
	const icon = getColoredHintIcon(
		input.icon === false ? undefined : resolveIcon(input.icon || config.icon),
		hintColor
	);

	const renderIcon = () =>
		icon ? (
			<div
				style={{
					display: "flex",
					alignItems: "flex-start",
					justifyContent: "center",
					width: "1.8rem",
					paddingTop: "0.05rem",
					color: hintColor,
					flexShrink: 0,
				}}
			>
				{icon}
			</div>
		) : null;

	return (
		<div
			style={{
				margin: "0.15rem 0 0.35rem 0",
				borderRadius: "var(--mborderRadius)",
				border: "1px solid rgba(var(--grey5), 0.85)",
				borderLeft: `0.3rem solid ${hintColor}`,
				background: "rgba(var(--dark3), 0.92)",
				boxSizing: "border-box",
				color: "rgba(var(--textMuted))",
				overflow: "hidden",
				width: "100%",
			}}
		>
			{title && (
				<div
					style={{
						display: "flex",
						alignItems: "center",
						gap: "0.75rem",
						padding: "0.65rem 0.85rem",
						background: `rgba(${config.color}, 0.16)`,
						boxSizing: "border-box",
					}}
				>
					{renderIcon()}
					<p
						style={{
							margin: 0,
							color: "rgba(var(--text))",
							fontSize: "1.22rem",
							fontWeight: 600,
							lineHeight: 1.35,
						}}
					>
						{title}
					</p>
				</div>
			)}
			<div
				style={{
					display: title ? "block" : "flex",
					gap: "0.75rem",
					padding:
						title && icon
							? "0.85rem 1rem 0.9rem calc(0.85rem + 1.8rem + 0.75rem)"
							: "0.85rem 1rem 0.9rem 0.85rem",
					boxSizing: "border-box",
				}}
			>
				{!title && renderIcon()}
				<div style={{ minWidth: 0 }}>
					{paragraphs.map((paragraph, idx) => (
						<p
							key={`${input.name || title || "hint"}-${idx}`}
							style={{
								margin:
									idx === paragraphs.length - 1
										? "0"
										: "0 0 0.55rem 0",
								fontSize: "1.12rem",
								lineHeight: 1.45,
								whiteSpace: "pre-wrap",
								wordBreak: "break-word",
							}}
						>
							{paragraph}
						</p>
					))}
				</div>
			</div>
		</div>
	);
};

export default InputDialog;
