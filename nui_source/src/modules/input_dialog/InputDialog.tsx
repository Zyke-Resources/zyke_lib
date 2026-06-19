import {
	cloneElement,
	isValidElement,
	useEffect,
	useRef,
	useState,
	type CSSProperties,
	type FC,
	type ReactNode,
} from "react";
import { Code } from "@mantine/core";
import { callback, listen, send } from "../../utils/Nui";
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
import Tooltip from "../../components/Tooltip";
import iconRegistry from "../../components/IconRegistry";

/** Resolve a string icon name from Lua into a React icon component
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
		| "info"
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
	value?: FormInfoValue;
	rows?: FormInfoRow[];
	plain?: boolean;
	disabled?: boolean;
	defaultValue?: any;
	forceUppercase?: boolean;

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

	// Text/TextArea-specific
	minRows?: number;
	maxRows?: number;
	maxLength?: number;
}

type FormInfoValue = string | number | boolean | null | undefined;

interface FormInfoRow {
	title?: string;
	label?: string;
	value?: FormInfoValue;
}

interface FormButton {
	text: string;
	icon?: string;
	color?: string;
	action?: string;
	timeout?: number;
	close?: boolean;
	buttonKey?: string;
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

type FormTextSegment =
	| { type: "text"; content: string }
	| { type: "inlineCode"; content: string }
	| { type: "blockCode"; content: string };

const MODAL_ID = "zyke_form";

const DEFAULT_FORM_BUTTON_COLOR = "var(--blue2)";

const DEFAULT_FORM_BUTTON: FormButton = {
	text: "Confirm",
	color: DEFAULT_FORM_BUTTON_COLOR,
	action: "primary",
	buttonKey: "button_1",
};

// Lua injects buttonKey for callback routing. The fallback keeps legacy buttons stable in browser/dev mode
const getResolvedButtons = (options: FormOptions): FormButton[] => {
	if (options.buttons?.length) {
		return options.buttons.map((button, index) => ({
			...button,
			buttonKey: button.buttonKey || `button_${index + 1}`,
		}));
	}

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

const getButtonKey = (button: FormButton) =>
	button.buttonKey || button.action || button.text;

const getActionValue = (button: FormButton) => button.action || "primary";

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

const parseFormTextSegments = (text: string): FormTextSegment[] => {
	const segments: FormTextSegment[] = [];
	const markerRegex = /```([\s\S]*?)```|``([^`\n]+)``|`([^`\n]+)`/g;
	let cursor = 0;
	let match: RegExpExecArray | null;

	while ((match = markerRegex.exec(text))) {
		if (match.index > cursor) {
			segments.push({
				type: "text",
				content: text.slice(cursor, match.index),
			});
		}

		if (match[1] !== undefined) {
			segments.push({
				type: "blockCode",
				content: match[1].replace(/^\n/, "").replace(/\n$/, ""),
			});
		} else {
			segments.push({
				type: "inlineCode",
				content: match[2] ?? match[3],
			});
		}

		cursor = markerRegex.lastIndex;
	}

	if (cursor < text.length) {
		segments.push({ type: "text", content: text.slice(cursor) });
	}

	return segments.length > 0 ? segments : [{ type: "text", content: text }];
};

const renderFormattedFormText = (text: string, keyPrefix: string) =>
	parseFormTextSegments(text).map((segment, idx) => {
		const key = `${keyPrefix}-${idx}`;

		if (segment.type === "inlineCode") {
			return (
				<Code key={key}>
					{segment.content}
				</Code>
			);
		}

		if (segment.type === "blockCode") {
			return (
				<Code
					key={key}
					block
					style={{
						margin: "0.3rem 0",
						whiteSpace: "pre-wrap",
					}}
				>
					{segment.content}
				</Code>
			);
		}

		return <span key={key}>{segment.content}</span>;
	});

const formatFormInfoValue = (value: FormInfoValue) => {
	if (value === null || value === undefined) return "";
	if (typeof value === "boolean") return value ? "true" : "false";

	return String(value);
};

const getFormInfoRows = (input: FormInput): FormInfoRow[] => {
	if (Array.isArray(input.rows) && input.rows.length > 0) return input.rows;

	return [
		{
			title: input.title ?? input.label,
			value: input.value,
		},
	];
};

const InputDialog: FC = () => {
	const { openModal, closeModal } = useModalContext();
	const [formData, setFormData] = useState<FormData | null>(null);
	// NUI listeners and modal close handlers can run after React state changes, so refs carry the latest form values
	const formDataRef = useRef<FormData | null>(null);
	const [values, setValues] = useState<Record<string, any>>({});
	const valuesRef = useRef<Record<string, any>>({});
	const [timeoutStartedAt, setTimeoutStartedAt] = useState(Date.now());
	const [countdownNow, setCountdownNow] = useState(Date.now());
	const [loadingButtons, setLoadingButtons] = useState<
		Record<string, boolean>
	>({});
	const loadingButtonsRef = useRef<Record<string, boolean>>({});
	const [buttonTooltips, setButtonTooltips] = useState<Record<string, string>>(
		{}
	);
	const tooltipTimeouts = useRef<Record<string, number>>({});

	const clearButtonTooltips = () => {
		Object.values(tooltipTimeouts.current).forEach((timeout) =>
			window.clearTimeout(timeout)
		);
		tooltipTimeouts.current = {};
		setButtonTooltips({});
	};

	const clearLoadingButtons = () => {
		loadingButtonsRef.current = {};
		setLoadingButtons({});
	};

	const setButtonLoading = (buttonKey: string, isLoading: boolean) => {
		const next = { ...loadingButtonsRef.current };

		if (isLoading) {
			next[buttonKey] = true;
		} else {
			delete next[buttonKey];
		}

		loadingButtonsRef.current = next;
		setLoadingButtons(next);
	};

	const setValue = (name: string, value: any) => {
		setValues((prev) => {
			const next = { ...prev, [name]: value };
			valuesRef.current = next;
			return next;
		});
	};

	const sendResult = (
		submitted: boolean,
		action?: string,
		shouldCloseModal = true
	) => {
		const currentForm = formDataRef.current;
		if (!currentForm) return;

		formDataRef.current = null;

		const data: Record<string, any> = {
			formId: currentForm.formId,
			submitted,
			values: submitted ? valuesRef.current : null,
		};

		if (submitted && action) {
			data.action = action;
		}

		send("FormResult", data, "Form");

		if (shouldCloseModal) closeModal(MODAL_ID);

		// Delay cleanup until after the modal exit animation (200ms)
		setTimeout(() => {
			setFormData(null);
			valuesRef.current = {};
			setValues({});
			clearButtonTooltips();
			clearLoadingButtons();
		}, 250);
	};

	const showButtonTooltip = (
		buttonKey: string,
		label: string,
		duration = 3000
	) => {
		setButtonTooltips((prev) => ({ ...prev, [buttonKey]: label }));

		if (tooltipTimeouts.current[buttonKey]) {
			window.clearTimeout(tooltipTimeouts.current[buttonKey]);
		}

		tooltipTimeouts.current[buttonKey] = window.setTimeout(() => {
			setButtonTooltips((prev) => {
				const next = { ...prev };
				delete next[buttonKey];
				return next;
			});

			delete tooltipTimeouts.current[buttonKey];
		}, duration);
	};

	const handleSelectResponse = (buttonKey: string, response: any) => {
		if (response?.tooltip) {
			showButtonTooltip(
				buttonKey,
				response.tooltip,
				response.tooltipDuration || 3000
			);
		}
	};

	const runButtonSelect = async (button: FormButton) => {
		// close=false buttons call Lua without resolving the form, then update only this button's UI state
		const currentForm = formDataRef.current;
		if (!currentForm) return;

		const buttonKey = getButtonKey(button);
		if (loadingButtonsRef.current[buttonKey]) return;

		let isPending = false;
		setButtonLoading(buttonKey, true);

		try {
			const response = await callback(
				"FormSelect",
				{
					formId: currentForm.formId,
					action: getActionValue(button),
					buttonKey,
					values: valuesRef.current,
				},
				"Form"
			);

			if (response?.pending) {
				isPending = true;
				return;
			}

			handleSelectResponse(buttonKey, response);
		} finally {
			if (!isPending) {
				setButtonLoading(buttonKey, false);
			}
		}
	};

	const pressButton = (button: FormButton, isWaiting: boolean) => {
		if (isWaiting) return;

		const buttonKey = getButtonKey(button);
		if (loadingButtonsRef.current[buttonKey]) return;

		if (button.close === false) {
			runButtonSelect(button);
			return;
		}

		sendResult(true, getActionValue(button));
	};

	listen(
		"FormSelectResult",
		({
			formId,
			action,
			buttonKey: responseButtonKey,
			response,
		}: {
			formId: string;
			action?: string;
			buttonKey?: string;
			response?: any;
		}) => {
			// Lua returns select results asynchronously so callbacks can yield without keeping the NUI fetch open
			const currentForm = formDataRef.current;
			if (!currentForm || currentForm.formId !== formId) return;

			const button =
				resolvedButtons.find(
					(btn) => getButtonKey(btn) === responseButtonKey
				) ||
				resolvedButtons.find(
					(btn) => getActionValue(btn) === action
				) || resolvedButtons[0];
			const buttonKey = button
				? getButtonKey(button)
				: responseButtonKey || action || "primary";

			handleSelectResponse(buttonKey, response || {});
			setButtonLoading(buttonKey, false);
		}
	);

	// Listen for open events from Lua
	listen("OpenForm", (data: FormData) => {
		// Set default values
		const defaults: Record<string, any> = {};
		data.inputs.forEach((input) => {
			if (
				input.type === "paragraph" ||
				input.type === "hint" ||
				input.type === "info" ||
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

			if (
				input.type === "text" &&
				input.forceUppercase &&
				typeof defaults[input.name] === "string"
			) {
				defaults[input.name] = defaults[input.name].toUpperCase();
			}
		});

		valuesRef.current = defaults;
		setValues(defaults);
		const now = Date.now();
		setTimeoutStartedAt(now);
		setCountdownNow(now);
		clearButtonTooltips();
		clearLoadingButtons();
		formDataRef.current = data;
		setFormData(data);
		openModal(MODAL_ID, true, () => sendResult(false, undefined, false));
	});

	// Listen for close events from Lua (Z.closeForm / Z.closeFormById)
	listen("CloseForm", () => {
		formDataRef.current = null;
		closeModal(MODAL_ID);
		setTimeout(() => {
			setFormData(null);
			valuesRef.current = {};
			setValues({});
			clearButtonTooltips();
			clearLoadingButtons();
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

				const primaryButton =
					resolvedButtons.find((btn) => btn.close !== false) ||
					resolvedButtons[0];
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

				if (primaryButton) pressButton(primaryButton, false);
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

	useEffect(() => {
		return () => {
			Object.values(tooltipTimeouts.current).forEach((timeout) =>
				window.clearTimeout(timeout)
			);
		};
	}, []);

	const renderInput = (input: FormInput) => {
		switch (input.type) {
			case "paragraph":
				return <FormParagraph input={input} />;

			case "hint":
				return <FormHint input={input} />;

			case "info":
				return <FormInfo input={input} />;

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
						maxLength={input.maxLength}
						forceUppercase={input.forceUppercase}
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
			onClose={() => sendResult(false, undefined, false)}
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
							const buttonKey = getButtonKey(btn);
							const buttonTooltip = buttonTooltips[buttonKey];
							const isNonClosingAction = btn.close === false;

							return (
								<Tooltip
									key={buttonKey}
									label={buttonTooltip}
									position="bottom"
									withArrow
									opened={Boolean(buttonTooltip)}
								>
									<Button
										icon={resolveIcon(btn.icon)}
										color={
											btn.color ||
											DEFAULT_FORM_BUTTON_COLOR
										}
										wide={!hasMultipleButtons}
										disabled={isWaiting}
										loading={Boolean(
											loadingButtons[buttonKey]
										)}
										onClick={() =>
											pressButton(btn, isWaiting)
										}
										loadDelay={
											isNonClosingAction ? undefined : 300
										}
										iconStyling={{
											marginRight: "0.5rem",
										}}
									>
										{isWaiting
											? `${btn.text} (${remaining}s)`
											: btn.text}
									</Button>
								</Tooltip>
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
				fontFamily: "var(--font)",
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
					<div
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
						{renderFormattedFormText(
							paragraph,
							`${input.name || input.label || "paragraph"}-${idx}`
						)}
					</div>
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
	const contentSize = "1.25rem";
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
					color: hintColor,
					flexShrink: 0,
					lineHeight: 1,
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
				background: `rgba(${config.color}, 0.24)`,
				boxSizing: "border-box",
				color: "rgba(var(--textMuted))",
				fontFamily: "var(--font)",
				display: "flex",
				alignItems: "flex-start",
				gap: "0.75rem",
				padding: title ? "0.85rem 1rem" : "0.6rem 1rem",
				width: "100%",
			}}
		>
			{renderIcon()}
			<div style={{ minWidth: 0 }}>
				{title && (
					<p
						style={{
							margin: "0 0 0.35rem 0",
							color: "rgba(var(--text))",
							fontSize: "1.45rem",
							lineHeight: 1.15,
						}}
					>
						{title}
					</p>
				)}
				<div>
					{paragraphs.map((paragraph, idx) => (
						<div
							key={`${input.name || title || "hint"}-${idx}`}
							style={{
								margin:
									idx === paragraphs.length - 1
										? "0"
										: "0 0 0.55rem 0",
								color: "rgba(var(--textMuted))",
								fontSize: contentSize,
								lineHeight: title ? 1.45 : 1.25,
								whiteSpace: "pre-wrap",
								wordBreak: "break-word",
							}}
						>
							{renderFormattedFormText(
								paragraph,
								`${input.name || title || "hint"}-${idx}`
							)}
						</div>
					))}
				</div>
			</div>
		</div>
	);
};

const FormInfo: FC<{ input: FormInput }> = ({ input }) => {
	const rows = getFormInfoRows(input);
	const plain = input.plain === true;

	return (
		<div
			style={{
				margin: "0.15rem 0 0.35rem 0",
				minWidth: 0,
				display: "flex",
				flexDirection: "column",
				overflow: plain ? undefined : "hidden",
				border: plain ? undefined : "1px solid rgb(var(--grey3))",
				borderRadius: plain ? undefined : "var(--lborderRadius)",
				background: plain ? undefined : "rgb(var(--dark4))",
				boxShadow: plain
					? undefined
					: "0 0 3px rgba(0, 0, 0, 0.2)",
				boxSizing: "border-box",
				fontFamily: "var(--font)",
				width: "100%",
			}}
		>
			<div
				style={{
					display: "flex",
					flexDirection: "column",
					padding: "0.48rem 0.65rem 0.58rem",
				}}
			>
				{rows.map((row, idx) => {
					const label = row.title ?? row.label ?? "";
					const value = formatFormInfoValue(row.value);

					return (
						<div
							key={`${input.name || input.label || "info"}-${idx}`}
							style={{
								minWidth: 0,
								display: "flex",
								alignItems: "center",
								justifyContent: "space-between",
								gap: "1rem",
								padding: "0.34rem 0",
								boxSizing: "border-box",
							}}
						>
							<span
								style={{
									minWidth: 0,
									overflow: "hidden",
									textOverflow: "ellipsis",
									whiteSpace: "nowrap",
									lineHeight: 1.25,
									color: "rgb(var(--secText))",
									fontSize: "1.16rem",
									fontWeight: 500,
									textTransform: "uppercase",
								}}
							>
								{label}
							</span>
							<strong
								style={{
									minWidth: 0,
									overflow: "hidden",
									textOverflow: "ellipsis",
									whiteSpace: "nowrap",
									lineHeight: 1.25,
									color: "rgb(var(--text))",
									fontSize: "1.24rem",
									fontWeight: 600,
									textAlign: "right",
								}}
							>
								{value}
							</strong>
						</div>
					);
				})}
			</div>
		</div>
	);
};

export default InputDialog;
