import { FC, useState, useCallback, useRef, useEffect, useMemo } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { useModalContext } from "../../context/ModalContext";
import CloseIcon from "@mui/icons-material/Close";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import ContextOption from "./ContextOption";
import MetadataPanel from "./MetadataPanel";
import MaterialIcon from "../../components/MaterialIcon";
import iconRegistry from "../../components/IconRegistry";
import Button from "../../components/Button";
import "./context_menu.css";

export interface ContextMetadata {
	label: string;
	value: any;
	progress?: number;
	colorScheme?: string;
}

export interface ContextAmount {
	default?: number;
	min?: number;
	max: number;
	step?: number;
	vars?: Record<string, number>;
}

export type ContextHints = string | string[];

export interface ContextOptionData {
	title: string;
	description?: string;
	icon?: string;
	iconColor?: string;
	disabled?: boolean;
	readOnly?: boolean;
	menu?: string | any;
	onSelect?: any;
	arrow?: boolean;
	event?: string;
	serverEvent?: string;
	args?: any;
	metadata?: ContextMetadata[];
	progress?: number;
	colorScheme?: string;
	image?: string;
	value?: any;
	amount?: ContextAmount;
}

export interface ContextMenuData {
	id?: string;
	title: string;
	description?: string;
	icon?: string;
	position?: "top-left" | "top-right" | "bottom-left" | "bottom-right";
	mode?: "action" | "select" | "multiselect";
	canClose?: boolean;
	hints?: ContextHints;

	menu?: string;
	onExit?: any;
	onBack?: any;
	options: ContextOptionData[];
}

interface ContextMenuProps {
	data: ContextMenuData | null;
	navigatedData: ContextMenuData | null;
	onSelect: (index: number, amount?: number) => void;
	onConfirm: (selected: any[]) => void;
	onNavigate: (target: string | any) => void;
	onBack: (menuId: string) => void;
	onClose: () => void;
}

export const MODAL_ID = "zyke_context_menu";

export const resolveTemplate = (
	template: string | undefined | null,
	amount: number,
	vars?: Record<string, number>
): string => {
	if (!template || !template.includes("{")) return template || "";
	return template.replace(/\{([^}]+)\}/g, (_, expr: string) => {
		let resolved = expr
			.trim()
			.replace(/\bamount\b/g, String(amount));
		if (vars) {
			for (const [key, val] of Object.entries(vars)) {
				resolved = resolved.replace(
					new RegExp(`\\b${key}\\b`, "g"),
					String(val)
				);
			}
		}
		if (/^[\d\s+\-*/().]+$/.test(resolved)) {
			try {
				const result = new Function(
					'"use strict"; return (' + resolved + ")"
				)();
				return typeof result === "number"
					? Number.isInteger(result)
						? String(result)
						: result.toFixed(2)
					: String(result);
			} catch {
				return resolved;
			}
		}
		return `{${expr}}`;
	});
};

const resolveIcon = (icon?: any) => {
	if (!icon) return undefined;
	if (typeof icon === "string") {
		if (iconRegistry[icon]) return iconRegistry[icon];
		return <MaterialIcon name={icon} />;
	}
	return icon;
};

const getCornerPosition = (position?: string): React.CSSProperties => {
	switch (position) {
		case "top-left":
			return { top: "5vh", right: "calc(50vw + 40rem)" };
		case "top-right":
			return { top: "5vh", left: "calc(50vw + 40rem)" };
		case "bottom-left":
			return { bottom: "5vh", right: "calc(50vw + 40rem)" };
		case "bottom-right":
			return { bottom: "5vh", left: "calc(50vw + 40rem)" };
		default:
			return { top: "5vh", left: "calc(50vw + 40rem)" };
	}
};

const isLeftPosition = (position?: string) =>
	position === "top-left" || position === "bottom-left";

const normalizeHints = (hints?: ContextHints): string[] => {
	if (!hints) return [];

	const rawHints = Array.isArray(hints) ? hints : [hints];

	return rawHints
		.filter((hint): hint is string => typeof hint === "string")
		.map((hint) => hint.trim())
		.filter(Boolean);
};

const getHintDuration = (hint: string) => {
	return Math.min(11000, Math.max(3500, 2100 + hint.length * 80));
};

const ContextFooterHint: FC<{ hints?: ContextHints }> = ({ hints }) => {
	const messages = useMemo(() => normalizeHints(hints), [hints]);
	const messagesKey = messages.join("\u0001");
	const [hintIndex, setHintIndex] = useState(0);
	const [scrollDistance, setScrollDistance] = useState(0);
	const [scrollDuration, setScrollDuration] = useState(0);
	const viewportRef = useRef<HTMLSpanElement>(null);
	const textRef = useRef<HTMLSpanElement>(null);

	const hint = messages[hintIndex] ?? messages[0] ?? "";
	const duration = Math.max(
		getHintDuration(hint),
		scrollDistance > 0 ? scrollDuration + 2400 : 0
	);

	useEffect(() => {
		setHintIndex(0);
	}, [messagesKey]);

	useEffect(() => {
		const viewport = viewportRef.current;
		const text = textRef.current;

		if (!viewport || !text) return;

		const measure = () => {
			const overflow = Math.ceil(text.scrollWidth - viewport.clientWidth);
			const distance = Math.max(0, overflow);

			setScrollDistance(distance);
			setScrollDuration(distance > 0 ? Math.max(4500, distance * 45) : 0);
		};

		measure();
		window.addEventListener("resize", measure);

		return () => window.removeEventListener("resize", measure);
	}, [hint]);

	useEffect(() => {
		if (messages.length <= 1) return;

		const timeout = window.setTimeout(() => {
			setHintIndex((current) => (current + 1) % messages.length);
		}, duration);

		return () => window.clearTimeout(timeout);
	}, [messages.length, hintIndex, duration]);

	if (!hint) return null;

	return (
		<p className="context-menu-footer-hint">
			<InfoOutlinedIcon
				sx={{
					fontSize: "1.35rem",
					color: "rgba(var(--secIcon))",
					flexShrink: 0,
				}}
			/>
			<span ref={viewportRef} className="context-menu-footer-hint-viewport">
				<span
					key={`${hintIndex}:${hint}`}
					ref={textRef}
					className={scrollDistance > 0 ? "is-scrolling" : undefined}
					style={{
						"--context-hint-shift": `-${scrollDistance}px`,
						"--context-hint-scroll-duration": `${scrollDuration}ms`,
					} as React.CSSProperties}
				>
					{hint}
				</span>
			</span>
		</p>
	);
};

const ContextMenu: FC<ContextMenuProps> = ({
	data,
	navigatedData,
	onSelect,
	onConfirm,
	onNavigate,
	onBack,
	onClose,
}) => {
	const { modalsOpen } = useModalContext();
	const wrapperRef = useRef<HTMLDivElement>(null);
	const hoveredElRef = useRef<HTMLElement | null>(null);
	const failedImages = useRef<Set<string>>(new Set());
	const loadedImages = useRef<Set<string>>(new Set());
	const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);
	const [selectedIndices, setSelectedIndices] = useState<Set<number>>(new Set());
	const [amounts, setAmounts] = useState<Record<number, number>>({});

	const activeData = navigatedData || data;
	const isOpen = !!modalsOpen[MODAL_ID];

	useEffect(() => {
		if (!isOpen) {
			setHoveredIndex(null);
			hoveredElRef.current = null;
			setSelectedIndices(new Set());
			setAmounts({});
			failedImages.current.clear();
			loadedImages.current.clear();
		}
	}, [isOpen]);

	useEffect(() => {
		if (isOpen && activeData) {
			const initial: Record<number, number> = {};
			activeData.options.forEach((opt, i) => {
				if (opt.amount) {
					initial[i] = opt.amount.default ?? opt.amount.min ?? 1;
				}
			});
			setAmounts(initial);
		}
	}, [isOpen, data, navigatedData]);

	const mode = activeData?.mode || "action";
	const canClose = activeData?.canClose !== false;
	const hasParent = !!(activeData?.menu);
	const position = activeData?.position || "top-right";
	const leftSide = isLeftPosition(position);

	const hoveredOption =
		hoveredIndex !== null && activeData
			? activeData.options[hoveredIndex]
			: null;
	const hasMetadata =
		hoveredOption &&
		(hoveredOption.metadata?.length || hoveredOption.image);

	const handleHover = useCallback(
		(index: number | null, element?: HTMLElement | null) => {
			hoveredElRef.current = element ?? null;

			if (index === null) {
				setHoveredIndex(null);
				return;
			}

			if (!activeData) return;
			const opt = activeData.options[index];

			if (opt?.image && !failedImages.current.has(opt.image) && !loadedImages.current.has(opt.image)) {
				const imgUrl = opt.image;
				const img = new Image();
				img.onload = () => {
					loadedImages.current.add(imgUrl);
					setHoveredIndex(index);
				};
				img.onerror = () => {
					failedImages.current.add(imgUrl);
					setHoveredIndex(null);
				};
				img.src = imgUrl;
				return;
			}

			if (opt?.image && failedImages.current.has(opt.image)) {
				setHoveredIndex(null);
				return;
			}

			setHoveredIndex(index);
		},
		[activeData]
	);

	const handleAmountChange = useCallback(
		(index: number, delta: number) => {
			if (!activeData) return;
			const opt = activeData.options[index];
			if (!opt?.amount) return;

			const step = opt.amount.step ?? 1;
			const min = opt.amount.min ?? 1;
			const max = opt.amount.max;
			const change = delta * step;

			setAmounts((prev) => {
				const current = prev[index] ?? opt.amount!.default ?? min;
				const next = Math.min(max, Math.max(min, current + change));
				return { ...prev, [index]: next };
			});
		},
		[activeData]
	);

	let metadataTop = 0;

	if (hasMetadata && hoveredElRef.current && wrapperRef.current) {
		const wrapperRect = wrapperRef.current.getBoundingClientRect();
		const optionRect = hoveredElRef.current.getBoundingClientRect();
		metadataTop = optionRect.top - wrapperRect.top;
	}

	const handleOptionClick = useCallback(
		(index: number) => {
			if (!activeData) return;
			const option = activeData.options[index];
			if (!option || option.disabled || option.readOnly) return;

			if (option.menu) {
				onNavigate(option.menu);
				return;
			}

			if (mode === "action") {
				onSelect(index, option.amount ? amounts[index] : undefined);
				return;
			}

			if (mode === "select") {
				setSelectedIndices(new Set([index]));
				return;
			}

			if (mode === "multiselect") {
				setSelectedIndices((prev) => {
					const next = new Set(prev);
					if (next.has(index)) {
						next.delete(index);
					} else {
						next.add(index);
					}
					return next;
				});
			}
		},
		[activeData, mode, onSelect, onNavigate, amounts]
	);

	const handleConfirm = useCallback(() => {
		if (!activeData || selectedIndices.size === 0) return;
		const selected = Array.from(selectedIndices).map((i) => {
			const opt = activeData.options[i];
			const base = opt.value !== undefined ? opt.value : opt;
			if (opt.amount && amounts[i] !== undefined) {
				return typeof base === "object" && base !== null
					? { ...base, amount: amounts[i] }
					: { value: base, amount: amounts[i] };
			}
			return base;
		});
		onConfirm(selected);
	}, [activeData, selectedIndices, onConfirm, amounts]);

	const handleBack = useCallback(() => {
		if (!activeData) return;
		setSelectedIndices(new Set());
		setHoveredIndex(null);
		onBack(activeData.id || "");
	}, [activeData, onBack]);

	const metadataAnchor: React.CSSProperties = leftSide
		? { left: "100%", marginLeft: "0.8rem" }
		: { right: "100%", marginRight: "0.8rem" };

	return (
		<>
			{isOpen && canClose && (
				<div
					onClick={onClose}
					style={{
						position: "fixed",
						inset: 0,
						zIndex: 999,
					}}
				/>
			)}

			<div
				ref={wrapperRef}
				style={{
					position: "fixed",
					zIndex: 1001,
					...getCornerPosition(position),
				}}
			>
				<AnimatePresence>
					{isOpen && (
						<motion.div
							initial={{ opacity: 0, scale: 0.98 }}
							animate={{ opacity: 1, scale: 1 }}
							exit={{ opacity: 0, scale: 0.98 }}
							transition={{ duration: 0.2 }}
							style={{
								width: "40rem",
								maxHeight: "80vh",
								background: "rgba(var(--dark))",
								borderRadius: "var(--lborderRadius)",
								boxShadow: "0 0 5px 0 rgba(0, 0, 0, 0.5)",
								border: "1px solid rgba(var(--grey3))",
								display: "flex",
								flexDirection: "column",
								overflow: "hidden",
							}}
						>
							<div
								style={{
									width: "100%",
									boxSizing: "border-box",
									padding: "0.25rem 0.75rem",
									height: "3.5rem",
									display: "flex",
									justifyContent: "space-between",
									alignItems: "center",
									background: "rgba(var(--grey))",
									boxShadow:
										"0 2px 3px 0 rgba(0, 0, 0, 0.2)",
									borderBottom:
										"1px solid rgba(var(--grey3))",
									flexShrink: 0,
								}}
							>
								<div
									style={{
										display: "flex",
										alignItems: "center",
										overflow: "hidden",
										flex: 1,
										minWidth: 0,
									}}
								>
									{hasParent && (
										<div
											onClick={handleBack}
											style={{
												cursor: "pointer",
												display: "flex",
												alignItems: "center",
												justifyContent: "center",
												padding: "0.3rem",
												borderRadius: "50%",
												transition:
													"background 0.15s",
												marginRight: "0.5rem",
											}}
											onMouseOver={(e) => {
												e.currentTarget.style.background =
													"rgba(var(--grey2))";
											}}
											onMouseOut={(e) => {
												e.currentTarget.style.background =
													"transparent";
											}}
										>
											<ArrowBackIcon
												sx={{
													color: "rgba(var(--icon))",
													fontSize: "1.8rem",
												}}
											/>
										</div>
									)}
									{activeData?.icon &&
										resolveIcon(activeData.icon)}
									{activeData?.title && (
										<h1
											className="truncate"
											style={{
												margin: "0.2rem 0 0 0.5rem",
												fontSize: "2rem",
											}}
										>
											{activeData.title}
										</h1>
									)}
								</div>

								{canClose && (
									<div
										onClick={onClose}
										style={{
											cursor: "pointer",
											display: "flex",
											alignItems: "center",
											justifyContent: "center",
											padding: "0.2rem",
											borderRadius: "50%",
											transition: "background 0.15s",
										}}
										onMouseOver={(e) => {
											e.currentTarget.style.background =
												"rgba(var(--grey2))";
										}}
										onMouseOut={(e) => {
											e.currentTarget.style.background =
												"transparent";
										}}
									>
										<CloseIcon
											sx={{
												color: "rgba(var(--icon))",
												width: "1.65rem",
												height: "1.65rem",
											}}
										/>
									</div>
								)}
							</div>

							{activeData && (
								<div
									style={{
										display: "flex",
										flexDirection: "column",
										flex: 1,
										minHeight: 0,
										padding: "0.5rem 1rem 1rem 1rem",
										overflow: "hidden",
									}}
								>
									{activeData.description && (
										<p
											style={{
												margin: "0 0 0.5rem 0",
												fontSize: "1.2rem",
												color: "rgba(var(--secText))",
											}}
										>
											{activeData.description}
										</p>
									)}

									<div className="context-menu-list">
										{activeData.options.map(
											(option, i) => (
												<ContextOption
													key={i}
													option={option}
													index={i}
													mode={mode}
													selected={selectedIndices.has(i)}
													onHover={handleHover}
													onClick={handleOptionClick}
													currentAmount={amounts[i]}
													onAmountChange={handleAmountChange}
												/>
											)
										)}
									</div>

									{mode !== "action" && (
										<div
											style={{
												display: "flex",
												justifyContent: "flex-end",
												gap: "0.5rem",
												marginTop: "0.5rem",
												paddingTop: "0.5rem",
												borderTop:
													"1px solid rgba(var(--grey3))",
											}}
										>
											<Button
												icon={resolveIcon("close")}
												color="var(--red3)"
												onClick={onClose}
												iconStyling={{
													marginRight: "0.5rem",
												}}
											>
												Cancel
											</Button>
											<Button
												icon={resolveIcon("check")}
												color="var(--blue1)"
												onClick={handleConfirm}
												disabled={
													selectedIndices.size ===
													0
												}
												iconStyling={{
													marginRight: "0.5rem",
												}}
											>
												Confirm
											</Button>
										</div>
									)}
								</div>
							)}

							<div className="context-menu-footer">
								<p
									className="context-menu-footer-instruction"
								>
									Press <kbd style={{ fontSize: "1.1rem" }}>ESC</kbd> to close
								</p>
								<ContextFooterHint hints={activeData?.hints} />
							</div>
						</motion.div>
					)}
				</AnimatePresence>

				<AnimatePresence>
					{isOpen && hasMetadata && (
						<motion.div
							initial={{
								opacity: 0,
								x: leftSide ? -8 : 8,
							}}
							animate={{ opacity: 1, x: 0 }}
							exit={{
								opacity: 0,
								x: leftSide ? -8 : 8,
							}}
							transition={{ duration: 0.12 }}
							style={{
								position: "absolute",
								top: metadataTop,
								maxHeight: "80vh",
								...metadataAnchor,
								background: "rgba(var(--dark))",
								borderRadius: "var(--lborderRadius)",
								boxShadow:
									"0 0 5px 0 rgba(0, 0, 0, 0.5)",
								border:
									"1px solid rgba(var(--grey3))",
								overflow: "hidden",
								minWidth: "16rem",
								maxWidth: "22rem",
							}}
						>
							<MetadataPanel
								title={hoveredOption!.title}
								image={hoveredOption!.image}
								metadata={hoveredOption!.metadata?.map((m) => ({
									...m,
									label: resolveTemplate(m.label, amounts[hoveredIndex!] ?? 0, hoveredOption!.amount?.vars),
									value: resolveTemplate(typeof m.value === "string" ? m.value : String(m.value), amounts[hoveredIndex!] ?? 0, hoveredOption!.amount?.vars),
								}))}
								visible={true}
							/>
						</motion.div>
					)}
				</AnimatePresence>
			</div>
		</>
	);
};

export default ContextMenu;
